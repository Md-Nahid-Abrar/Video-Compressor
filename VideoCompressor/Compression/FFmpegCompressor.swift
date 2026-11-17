import AVFoundation
import Foundation

/// Compresses video with the embedded FFmpeg library, driven by a command line.
///
/// The settings come from the same `EncodingSettings` as the AVFoundation engine, so presets and
/// size estimates are identical; only the tool doing the work differs. FFmpeg's hardware HEVC
/// encoder (`hevc_videotoolbox`) is used.
nonisolated struct FFmpegCompressor: VideoCompressing {
    /// How long FFmpeg may go without reporting new progress before it is treated as stuck.
    static let stallTimeout: Duration = .seconds(30)

    private enum Event: Sendable {
        case finished(FFmpegRunner.Outcome)
        case monitorEnded(stalled: Bool)
    }

    @concurrent
    func compress(
        source: URL,
        destination: URL,
        settings: EncodingSettings,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws(CompressionError) -> CompressionResult {
        guard FileManager.default.isReadableFile(atPath: source.path) else {
            throw .unreadable
        }
        TemporaryFiles.remove(destination)
        let progressFile = FileManager.default.temporaryDirectory
            .appending(path: "ffmpeg-progress-\(UUID().uuidString).txt")
        defer { TemporaryFiles.remove(progressFile) }

        let arguments = FFmpegArguments.make(
            source: source,
            destination: destination,
            settings: settings,
            progressFile: progressFile
        )
        // Only the progress bar depends on the duration, so a failure to read it is not fatal.
        let duration = (try? await AVURLAsset(url: source).load(.duration).seconds) ?? 0
        let id = UUID()

        var outcome = FFmpegRunner.Outcome(exitCode: 1, log: "")
        var stalled = false
        await withTaskGroup(of: Event.self) { group in
            group.addTask {
                await withTaskCancellationHandler {
                    .finished(await FFmpegRunner.run(arguments: arguments, id: id))
                } onCancel: {
                    FFmpegRunner.cancel(id: id)
                }
            }
            group.addTask {
                .monitorEnded(stalled: await Self.monitor(
                    progressFile: progressFile,
                    duration: duration,
                    id: id,
                    progress: progress
                ))
            }
            for await event in group {
                switch event {
                case .finished(let result):
                    outcome = result
                    group.cancelAll()
                case .monitorEnded(let didStall):
                    stalled = stalled || didStall
                }
            }
        }

        if stalled {
            TemporaryFiles.remove(destination)
            throw .failed(String(localized: "The encoder stopped responding. Try again.", bundle: L10n.bundle))
        }
        if Task.isCancelled || outcome.exitCode == FFmpegRunner.cancelledExitCode {
            TemporaryFiles.remove(destination)
            throw .cancelled
        }
        guard outcome.exitCode == 0 else {
            TemporaryFiles.remove(destination)
            throw Self.error(from: outcome.log)
        }
        progress(1)

        let originalBytes = Int64((try? source.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        let compressedBytes = Int64((try? destination.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        guard compressedBytes > 0 else {
            throw .failed(String(localized: "The encoder stopped unexpectedly.", bundle: L10n.bundle))
        }
        return CompressionResult(outputURL: destination, originalBytes: originalBytes, compressedBytes: compressedBytes)
    }

    // MARK: - Progress

    /// Reads FFmpeg's progress file until cancelled. Returns `true` if it gave up because FFmpeg stalled.
    private static func monitor(
        progressFile: URL,
        duration: Double,
        id: UUID,
        progress: @Sendable (Double) -> Void
    ) async -> Bool {
        let clock = ContinuousClock()
        var lastPosition = -1.0
        var lastChange = clock.now
        var lastReported = 0.0

        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(250))
            if Task.isCancelled {
                // Repeating the request covers the instant between a command starting and FFmpeg
                // clearing its cancel flag.
                FFmpegRunner.cancel(id: id)
                return false
            }
            if let position = latestPosition(in: progressFile), position != lastPosition {
                lastPosition = position
                lastChange = clock.now
                if duration > 0 {
                    let fraction = min(max(position / duration, 0), 1)
                    if fraction - lastReported >= 0.005 {
                        lastReported = fraction
                        progress(fraction)
                    }
                }
            } else if clock.now - lastChange > stallTimeout {
                FFmpegRunner.cancel(id: id)
                return true
            }
        }
        return false
    }

    /// The output position, in seconds, from the most recent progress report.
    static func latestPosition(in file: URL) -> Double? {
        guard let handle = try? FileHandle(forReadingFrom: file) else { return nil }
        defer { try? handle.close() }
        let size = (try? handle.seekToEnd()) ?? 0
        try? handle.seek(toOffset: size > 2048 ? size - 2048 : 0)
        guard let data = try? handle.readToEnd(), let text = String(data: data, encoding: .utf8) else { return nil }
        return position(inProgressReport: text)
    }

    /// Parses the last `out_time_us=` value (microseconds) from FFmpeg's `-progress` output.
    static func position(inProgressReport text: String) -> Double? {
        let key = "out_time_us="
        guard let range = text.range(of: key, options: .backwards) else { return nil }
        let value = text[range.upperBound...].prefix { $0.isNumber }
        guard let microseconds = Double(value) else { return nil }
        return microseconds / 1_000_000
    }

    // MARK: - Errors

    static func error(from log: String) -> CompressionError {
        let lowered = log.lowercased()
        if lowered.contains("no space left") {
            return .insufficientSpace
        }
        if lowered.contains("matches no streams") || lowered.contains("does not contain any stream") {
            return .noVideoTrack
        }
        let lastLine = log
            .split(whereSeparator: \.isNewline)
            .last
            .map { $0.trimmingCharacters(in: .whitespaces) } ?? ""
        return .failed(lastLine)
    }
}
