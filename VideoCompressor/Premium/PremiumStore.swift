import Foundation

/// Tracks Premium status, which a promo code unlocks for a fixed period.
@Observable
final class PremiumStore {
    /// Codes accepted during the test phase.
    static let promoCodes: Set<String> = ["444", "555", "666", "777", "999"]
    static let standardDuration: TimeInterval = 48 * 60 * 60

    private let defaults: UserDefaults
    private let duration: TimeInterval
    private let now: () -> Date
    private var expiryTask: Task<Void, Never>?

    /// When Premium ends, or `nil` when the user is not Premium.
    private(set) var expiry: Date?

    init(
        defaults: UserDefaults = .standard,
        duration: TimeInterval = PremiumStore.standardDuration,
        now: @escaping () -> Date = { Date.now }
    ) {
        self.defaults = defaults
        self.duration = duration
        self.now = now
        let stored = defaults.double(forKey: StorageKey.premiumExpiry)
        expiry = stored > 0 ? Date(timeIntervalSince1970: stored) : nil
        refresh()
    }

    var isActive: Bool {
        expiry != nil
    }

    /// Activates Premium when `code` is one of the accepted promo codes.
    @discardableResult
    func redeem(_ code: String) -> Bool {
        guard Self.promoCodes.contains(code.trimmingCharacters(in: .whitespaces)) else { return false }
        let date = now().addingTimeInterval(duration)
        expiry = date
        defaults.set(date.timeIntervalSince1970, forKey: StorageKey.premiumExpiry)
        scheduleExpiry()
        return true
    }

    /// Ends Premium if its time has passed. Called on a timer and whenever the app becomes active.
    func refresh() {
        guard let expiry else { return }
        if expiry <= now() {
            self.expiry = nil
            defaults.removeObject(forKey: StorageKey.premiumExpiry)
            expiryTask?.cancel()
            expiryTask = nil
        } else {
            scheduleExpiry()
        }
    }

    private func scheduleExpiry() {
        expiryTask?.cancel()
        guard let expiry else { return }
        let delay = max(expiry.timeIntervalSince(now()), 0)
        expiryTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.refresh()
        }
    }

    /// Formats a remaining time as `HH:MM:SS`.
    nonisolated static func countdownText(_ remaining: TimeInterval) -> String {
        let total = max(Int(remaining.rounded(.up)), 0)
        return String(format: "%02d:%02d:%02d", total / 3600, total % 3600 / 60, total % 60)
    }
}
