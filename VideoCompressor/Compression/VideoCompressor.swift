import AVFoundation
import Foundation
import VideoToolbox

/// Re-encodes a video to HEVC with explicit bitrate, resolution, frame rate and color settings.
///
/// The pipeline decodes with `AVAssetReader` and encodes with `AVAssetWriter`. It avoids video
/// compositions and Metal so the work can continue while the app is in the background.
nonisolated struct VideoCompressor: VideoCompressing {
    @concurrent
    func compress(
        source: URL,
        destination: URL,
        settings: EncodingSettings,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws(CompressionError) -> CompressionResult {
        do {
            return try await run(source: source, destination: destination, settings: settings, progress: progress)
        } catch {
            TemporaryFiles.remove(destination)
            throw Self.map(error)
        }
    }

    // MARK: - Pipeline

    /// How long the encoder may go without reading or writing a sample before it is treated as stuck.
    static let stallTimeout: Duration = .seconds(30)

    private func run(
        source: URL,
        destination: URL,
        settings: EncodingSettings,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> CompressionResult {
        let asset = AVURLAsset(url: source)
        let duration = try await asset.load(.duration).seconds
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw CompressionError.noVideoTrack
        }
        let audioTrack = settings.audioBitrate == nil ? nil : try await asset.loadTracks(withMediaType: .audio).first
        let transform = try await videoTrack.load(.preferredTransform)

        TemporaryFiles.remove(destination)
        let reader = try AVAssetReader(asset: asset)
        let writer = try AVAssetWriter(outputURL: destination, fileType: .mp4)
        writer.shouldOptimizeForNetworkUse = true
        let activity = ActivityClock()

        // Video: decode to planar YUV (10-bit for HDR), encode to HEVC.
        let pixelFormat = settings.isHDR
            ? kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange
            : kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        let videoOutput = AVAssetReaderTrackOutput(
            track: videoTrack,
            outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: pixelFormat]
        )
        videoOutput.alwaysCopiesSampleData = false
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: Self.videoSettings(for: settings))
        videoInput.transform = transform
        videoInput.expectsMediaDataInRealTime = false
        guard reader.canAdd(videoOutput), writer.canAdd(videoInput) else {
            throw CompressionError.unreadable
        }
        reader.add(videoOutput)
        writer.add(videoInput)
        var pumps = [SamplePump(
            output: videoOutput,
            input: videoInput,
            label: "video",
            activity: activity,
            frameInterval: settings.frameRateCap.map { 1 / $0 },
            duration: duration,
            progress: progress
        )]

        // Audio: decode to PCM, encode to AAC.
        if let audioTrack, let audioBitrate = settings.audioBitrate {
            let audioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: Self.pcmSettings(for: settings))
            audioOutput.alwaysCopiesSampleData = false
            let audioInput = AVAssetWriterInput(
                mediaType: .audio,
                outputSettings: Self.aacSettings(for: settings, bitrate: audioBitrate)
            )
            audioInput.expectsMediaDataInRealTime = false
            if reader.canAdd(audioOutput), writer.canAdd(audioInput) {
                reader.add(audioOutput)
                writer.add(audioInput)
                pumps.append(SamplePump(output: audioOutput, input: audioInput, label: "audio", activity: activity))
            }
        }

        guard reader.startReading() else {
            throw reader.error ?? CompressionError.unreadable
        }
        guard writer.startWriting() else {
            throw writer.error ?? CompressionError.failed(String(localized: "The encoder stopped unexpectedly.", bundle: L10n.bundle))
        }
        writer.startSession(atSourceTime: .zero)

        do {
            // Video and audio are pumped concurrently so the writer can interleave them.
            // A watchdog runs alongside and fails the export if the encoder stops making progress.
            let pumpList = pumps
            try await withThrowingTaskGroup(of: Bool.self) { group in
                for pump in pumpList {
                    group.addTask {
                        await pump.run()
                        return true
                    }
                }
                group.addTask {
                    try await Self.watchForStall(activity)
                    return false
                }
                var remaining = pumpList.count
                while remaining > 0, let wasPump = try await group.next() {
                    if wasPump { remaining -= 1 }
                }
                group.cancelAll()
            }
            try Task.checkCancellation()
        } catch {
            reader.cancelReading()
            writer.cancelWriting()
            // Prefer the underlying AVFoundation error, which explains the failure.
            throw reader.error ?? writer.error ?? error
        }

        if reader.status == .failed, let error = reader.error {
            writer.cancelWriting()
            throw error
        }

        await writer.finishWriting()
        guard writer.status == .completed else {
            throw writer.error ?? CompressionError.failed(String(localized: "The encoder stopped unexpectedly.", bundle: L10n.bundle))
        }
        progress(1)

        let originalBytes = Int64((try? source.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        let compressedBytes = Int64((try? destination.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        return CompressionResult(outputURL: destination, originalBytes: originalBytes, compressedBytes: compressedBytes)
    }

    /// Returns when cancelled; throws if no sample has moved for `stallTimeout`.
    private static func watchForStall(_ activity: ActivityClock) async throws {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(2))
            if Task.isCancelled { return }
            if activity.idleTime > stallTimeout {
                throw CompressionError.failed(String(localized: "The encoder stopped responding. Try again.", bundle: L10n.bundle))
            }
        }
    }

    // MARK: - Settings

    static func videoSettings(for settings: EncodingSettings) -> [String: any Sendable] {
        let profile = settings.isHDR ? kVTProfileLevel_HEVC_Main10_AutoLevel : kVTProfileLevel_HEVC_Main_AutoLevel
        let compression: [String: any Sendable] = [
            AVVideoAverageBitRateKey: settings.videoBitrate,
            AVVideoExpectedSourceFrameRateKey: settings.frameRate,
            AVVideoMaxKeyFrameIntervalDurationKey: 2.0,
            AVVideoProfileLevelKey: profile as String,
            AVVideoAllowFrameReorderingKey: true
        ]
        var result: [String: any Sendable] = [
            AVVideoCodecKey: AVVideoCodecType.hevc.rawValue,
            AVVideoWidthKey: settings.width,
            AVVideoHeightKey: settings.height,
            AVVideoScalingModeKey: AVVideoScalingModeResizeAspect,
            AVVideoCompressionPropertiesKey: compression
        ]
        if let primaries = settings.colorPrimaries,
           let transfer = settings.transferFunction,
           let matrix = settings.yCbCrMatrix {
            result[AVVideoColorPropertiesKey] = [
                AVVideoColorPrimariesKey: primaries,
                AVVideoTransferFunctionKey: transfer,
                AVVideoYCbCrMatrixKey: matrix
            ]
        }
        return result
    }

    static func pcmSettings(for settings: EncodingSettings) -> [String: any Sendable] {
        [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false,
            AVNumberOfChannelsKey: settings.audioChannelCount,
            AVSampleRateKey: settings.audioSampleRate
        ]
    }

    static func aacSettings(for settings: EncodingSettings, bitrate: Int) -> [String: any Sendable] {
        [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: settings.audioChannelCount,
            AVSampleRateKey: settings.audioSampleRate,
            AVEncoderBitRateKey: bitrate
        ]
    }

    // MARK: - Errors

    private static func map(_ error: any Error) -> CompressionError {
        if let error = error as? CompressionError { return error }
        if error is CancellationError { return .cancelled }
        let nsError = error as NSError
        if nsError.domain == AVFoundationErrorDomain {
            switch AVError.Code(rawValue: nsError.code) {
            case .operationInterrupted, .sessionWasInterrupted, .mediaServicesWereReset:
                return .interrupted
            case .diskFull, .outOfMemory:
                return .insufficientSpace
            case .operationCancelled:
                return .cancelled
            default:
                break
            }
        }
        if nsError.domain == NSCocoaErrorDomain, nsError.code == NSUserCancelledError {
            return .cancelled
        }
        return .failed(nsError.localizedDescription)
    }
}
