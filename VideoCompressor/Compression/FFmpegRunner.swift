import FFmpegCmd
import Foundation
import Synchronization

/// Runs FFmpeg commands one at a time.
///
/// FFmpeg's front end keeps global state, so only one command can run in the process at once.
/// Commands are queued on a private serial queue, and each can be cancelled by its identifier
/// whether it is running or still waiting.
nonisolated enum FFmpegRunner {
    struct Outcome: Sendable {
        var exitCode: Int32
        /// The last warnings and errors FFmpeg logged.
        var log: String
    }

    private struct State {
        var activeID: UUID?
        var cancelledBeforeStart: Set<UUID> = []
    }

    /// FFmpeg's exit code for a command stopped by `cancel`.
    static let cancelledExitCode: Int32 = 255

    private static let queue = DispatchQueue(label: "VideoCompressor.ffmpeg", qos: .userInitiated)
    private static let state = Mutex(State())

    static func run(arguments: [String], id: UUID) async -> Outcome {
        await withCheckedContinuation { continuation in
            queue.async {
                let skip = state.withLock { state in
                    if state.cancelledBeforeStart.remove(id) != nil { return true }
                    state.activeID = id
                    return false
                }
                if skip {
                    continuation.resume(returning: Outcome(exitCode: cancelledExitCode, log: ""))
                    return
                }

                let exitCode = execute(arguments)
                var buffer = [CChar](repeating: 0, count: 4096)
                _ = ffcmd_copy_log(&buffer, buffer.count)
                let log = String(cString: buffer)

                state.withLock { $0.activeID = nil }
                continuation.resume(returning: Outcome(exitCode: exitCode, log: log))
            }
        }
    }

    /// Stops the command with this identifier, or prevents it from starting.
    static func cancel(id: UUID) {
        state.withLock { state in
            if state.activeID == id {
                ffcmd_cancel()
            } else {
                state.cancelledBeforeStart.insert(id)
            }
        }
    }

    private static func execute(_ arguments: [String]) -> Int32 {
        let cStrings = arguments.map { strdup($0) }
        defer { cStrings.forEach { free($0) } }
        let argv = cStrings.map { UnsafePointer<CChar>($0) }
        return argv.withUnsafeBufferPointer { pointer in
            ffcmd_run(Int32(arguments.count), pointer.baseAddress)
        }
    }
}
