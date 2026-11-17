import Foundation
import Synchronization

/// Records when the encoder last made progress, so a stall can be detected.
nonisolated final class ActivityClock: Sendable {
    private let lastActivity = Mutex(ContinuousClock.now)

    func touch() {
        lastActivity.withLock { $0 = .now }
    }

    /// Time since the last sample was read or written.
    var idleTime: Duration {
        lastActivity.withLock { ContinuousClock.now - $0 }
    }
}
