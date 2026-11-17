import AVFoundation
import Foundation
import Synchronization

/// Moves samples for one track from a reader output to a writer input.
///
/// The writer calls back on a private serial queue whenever it can accept more data, and the pump
/// feeds it until it is full or the track ends. This is AVFoundation's long-established pull model.
/// Everything except `state` is touched only on that queue, which is what makes the type safe to share.
nonisolated final class SamplePump: @unchecked Sendable {
    private struct State {
        var isFinished = false
        var continuation: CheckedContinuation<Void, Never>?
    }

    private let output: AVAssetReaderOutput
    private let input: AVAssetWriterInput
    private let queue: DispatchQueue
    private let activity: ActivityClock
    private let frameInterval: Double?
    private let duration: Double
    private let progress: (@Sendable (Double) -> Void)?
    private let state = Mutex(State())

    // Used only on `queue`.
    private var nextKeepTime = -Double.infinity
    private var lastReported = 0.0

    /// - Parameters:
    ///   - frameInterval: When set, frames closer together than this are dropped to cap the frame rate.
    ///   - progress: Called with a value from 0 to 1 as samples are written.
    init(
        output: AVAssetReaderOutput,
        input: AVAssetWriterInput,
        label: String,
        activity: ActivityClock,
        frameInterval: Double? = nil,
        duration: Double = 0,
        progress: (@Sendable (Double) -> Void)? = nil
    ) {
        self.output = output
        self.input = input
        self.queue = DispatchQueue(label: "VideoCompressor.pump.\(label)")
        self.activity = activity
        self.frameInterval = frameInterval
        self.duration = duration
        self.progress = progress
    }

    /// Runs until the track is exhausted, the writer refuses a sample, or the task is cancelled.
    func run() async {
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                let alreadyFinished = state.withLock { state in
                    if state.isFinished { return true }
                    state.continuation = continuation
                    return false
                }
                if alreadyFinished {
                    continuation.resume()
                    return
                }
                input.requestMediaDataWhenReady(on: queue) { [self] in
                    drain()
                }
            }
        } onCancel: {
            // Resuming here, rather than waiting for the writer, guarantees a cancelled or
            // stalled pump always returns.
            finish()
        }
    }

    private func drain() {
        while input.isReadyForMoreMediaData {
            if state.withLock({ $0.isFinished }) {
                input.markAsFinished()
                return
            }
            guard let buffer = output.copyNextSampleBuffer() else {
                input.markAsFinished()
                finish()
                return
            }
            activity.touch()
            let time = CMSampleBufferGetPresentationTimeStamp(buffer).seconds

            if let frameInterval {
                // Drop frames that arrive before the next output slot.
                if time + frameInterval * 0.1 < nextKeepTime { continue }
                let base = nextKeepTime.isFinite ? max(nextKeepTime, time - frameInterval) : time
                nextKeepTime = base + frameInterval
            }

            guard input.append(buffer) else {
                finish()
                return
            }

            if let progress, duration > 0 {
                let fraction = min(max(time / duration, 0), 1)
                if fraction - lastReported >= 0.005 {
                    lastReported = fraction
                    progress(fraction)
                }
            }
        }
    }

    private func finish() {
        let continuation = state.withLock { state in
            state.isFinished = true
            let continuation = state.continuation
            state.continuation = nil
            return continuation
        }
        continuation?.resume()
    }
}
