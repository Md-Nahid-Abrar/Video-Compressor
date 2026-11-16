import Foundation

/// Keys for values persisted in UserDefaults.
nonisolated enum StorageKey {
    static let hasSeenWelcome = "hasSeenWelcome"
    static let appearance = "appearance"
    static let profileName = "profileName"
    static let profileEmail = "profileEmail"

    static let all = [hasSeenWelcome, appearance, profileName, profileEmail]
}
