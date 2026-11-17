import Foundation

/// Keys for values persisted in UserDefaults.
nonisolated enum StorageKey {
    static let hasSeenWelcome = "hasSeenWelcome"
    static let appearance = "appearance"
    static let language = "language"
    static let profileName = "profileName"
    static let profileEmail = "profileEmail"
    static let premiumExpiry = "premiumExpiry"

    static let all = [
        hasSeenWelcome, appearance, language, profileName, profileEmail, premiumExpiry
    ]
}
