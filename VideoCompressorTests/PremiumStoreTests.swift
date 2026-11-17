import Foundation
import Testing
@testable import VideoCompressor

struct PremiumStoreTests {
    /// A clock the test can move forward.
    final class Clock {
        var date = Date(timeIntervalSince1970: 1_800_000_000)
    }

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "premium-\(UUID().uuidString)")!
    }

    @Test func startsWithoutPremium() {
        let store = PremiumStore(defaults: makeDefaults())
        #expect(!store.isActive)
        #expect(store.expiry == nil)
    }

    @Test(arguments: ["444", "555", "666", "777", "999"])
    func validCodesUnlockFor48Hours(code: String) {
        let clock = Clock()
        let store = PremiumStore(defaults: makeDefaults(), now: { clock.date })
        #expect(store.redeem(code))
        #expect(store.isActive)
        #expect(store.expiry == clock.date.addingTimeInterval(48 * 60 * 60))
    }

    @Test(arguments: ["", "000", "123", "44", "4444", "abc", "888"])
    func invalidCodesAreRejected(code: String) {
        let store = PremiumStore(defaults: makeDefaults())
        #expect(!store.redeem(code))
        #expect(!store.isActive)
    }

    @Test func premiumEndsAfter48Hours() {
        let clock = Clock()
        let store = PremiumStore(defaults: makeDefaults(), now: { clock.date })
        store.redeem("555")

        clock.date.addTimeInterval(48 * 60 * 60 - 1)
        store.refresh()
        #expect(store.isActive)

        clock.date.addTimeInterval(1)
        store.refresh()
        #expect(!store.isActive)
    }

    @Test func cancellingEndsPremiumImmediately() {
        let defaults = makeDefaults()
        let store = PremiumStore(defaults: defaults)
        store.redeem("666")
        #expect(store.isActive)

        store.cancel()
        #expect(!store.isActive)
        #expect(!PremiumStore(defaults: defaults).isActive)

        // A code can be redeemed again afterwards.
        #expect(store.redeem("444"))
    }

    @Test func premiumPersistsAcrossLaunches() {
        let clock = Clock()
        let defaults = makeDefaults()
        PremiumStore(defaults: defaults, now: { clock.date }).redeem("777")

        let relaunched = PremiumStore(defaults: defaults, now: { clock.date })
        #expect(relaunched.isActive)

        // Relaunching after the deadline starts without Premium.
        clock.date.addTimeInterval(49 * 60 * 60)
        let later = PremiumStore(defaults: defaults, now: { clock.date })
        #expect(!later.isActive)
    }

    @Test(arguments: [
        (172_800.0, "48:00:00"),
        (172_799.0, "47:59:59"),
        (3_661.0, "01:01:01"),
        (59.2, "00:01:00"),
        (0.0, "00:00:00"),
        (-5.0, "00:00:00")
    ])
    func countdownFormat(remaining: Double, text: String) {
        #expect(PremiumStore.countdownText(remaining) == text)
    }
}
