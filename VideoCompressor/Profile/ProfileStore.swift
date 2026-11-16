import Foundation

/// Reads and writes the profile fields in UserDefaults. Nothing leaves the device.
nonisolated struct ProfileStore: Sendable {
    static let defaultName = "Your Name"
    static let defaultEmail = "you@example.com"

    nonisolated(unsafe) let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var name: String {
        get { defaults.string(forKey: StorageKey.profileName) ?? Self.defaultName }
        nonmutating set { defaults.set(newValue, forKey: StorageKey.profileName) }
    }

    var email: String {
        get { defaults.string(forKey: StorageKey.profileEmail) ?? Self.defaultEmail }
        nonmutating set { defaults.set(newValue, forKey: StorageKey.profileEmail) }
    }
}
