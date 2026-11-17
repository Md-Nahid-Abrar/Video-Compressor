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
        let videoProvider = reader.outputProvider(for: videoOutput)
        let videoReceiver = writer.inputReceiver(for: videoInput)

        // Audio: decode to PCM, encode to AAC.
        let audioProvider: SampleProvider?
        let audioReceiver: AVAssetWriterInput.SampleBufferReceiver?
        if let audioTrack, let audioBitrate = settings.audioBitrate {
            let audioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: Self.pcmSettings(for: settings))
            audioOutput.alwaysCopiesSampleData = false
            let audioInput = AVAssetWriterInput(
                mediaType: .audio,
                outputSettings: Self.aacSettings(for: settings, bitrate: audioBitrate)
            )
            audioProvider = reader.outputProvider(for: audioOutput)
            audioReceiver = writer.inputReceiver(for: audioInput)
        } else {
            audioProvider = nil
            audioReceiver = nil
        }

        try reader.start()
        try writer.start()
        writer.startSession(atSourceTime: .zero)

        do {
            // Video and audio are pumped concurrently so the writer can interleave them.
            async let video: Void = Self.pumpVideo(
                from: videoProvider,
                to: videoReceiver,
                frameInterval: settings.frameRateCap.map { 1 / $0 },
                duration: duration,
                progress: progress
            )
            async let audio: Void = Self.pumpAudio(from: audioProvider, to: audioReceiver)
            try await video
            try await audio
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

    // MARK: - Sample pumps

    private typealias SampleProvider = AVAssetReaderOutput.Provider<CMReadySampleBuffer<CMSampleBuffer.DynamicContent>>

    private static func pumpVideo(
        from provider: sending SampleProvider,
        to receiver: sending AVAssetWriterInput.SampleBufferReceiver,
        frameInterval: Double?,
        duration: Double,
        progress: @Sendable (Double) -> Void
    ) async throws {
        var nextKeepTime = -Double.infinity
        var lastReported = 0.0
        while let buffer = try await provider.next() {
            try Task.checkCancellation()
            let time = buffer.presentationTimeStamp.seconds

            if let frameInterval {
                // Drop frames that arrive before the next output slot.
                if time + frameInterval * 0.1 < nextKeepTime { continue }
                let base = nextKeepTime.isFinite ? max(nextKeepTime, time - frameInterval) : time
                nextKeepTime = base + frameInterval
            }

            try await receiver.append(buffer)

            if duration > 0 {
                let fraction = min(max(time / duration, 0), 1)
                if fraction - lastReported >= 0.005 {
                    lastReported = fraction
                    progress(fraction)
                }
            }
        }
        receiver.finish()
    }

    private static func pumpAudio(
        from provider: sending SampleProvider?,
        to receiver: sending AVAssetWriterInput.SampleBufferReceiver?
    ) async throws {
        guard let provider, let receiver else { return }
        while let buffer = try await provider.next() {
            try Task.checkCancellation()
            try await receiver.append(buffer)
        }
        receiver.finish()
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
