import SwiftUI

/// "Expires in 47:59:59", ticking once a second.
struct PremiumCountdown: View {
    let expiry: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Text("Expires in \(PremiumStore.countdownText(expiry.timeIntervalSince(context.date)))")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
        }
        .accessibilityIdentifier("premium.countdown")
    }
}
