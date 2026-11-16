import Foundation

/// Editable profile fields that persist as the user types.
@Observable
final class ProfileViewModel {
    private let store: ProfileStore

    var name: String {
        didSet { store.name = name }
    }

    var email: String {
        didSet { store.email = email }
    }

    init(store: ProfileStore = ProfileStore()) {
        self.store = store
        name = store.name
        email = store.email
    }

    /// A loose check that catches obvious typos without rejecting unusual addresses.
    var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.contains(" ") else { return false }
        let parts = trimmed.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty else { return false }
        let domain = parts[1].split(separator: ".", omittingEmptySubsequences: false)
        return domain.count >= 2 && domain.allSatisfy { !$0.isEmpty }
    }
}
