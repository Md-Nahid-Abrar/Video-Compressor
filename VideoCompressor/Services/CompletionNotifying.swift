import Foundation

/// Tells the user that a compression has finished.
nonisolated protocol CompletionNotifying: Sendable {
    func requestAuthorization() async
    func notifyCompleted() async
}
