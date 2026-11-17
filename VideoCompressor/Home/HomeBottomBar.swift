import SwiftUI

/// The glass capsule at the bottom of Home: Settings, Premium, Profile.
struct HomeBottomBar: View {
    let isPremiumActive: Bool
    let onSettings: () -> Void
    let onPremium: () -> Void
    let onProfile: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            item("Settings", symbol: "gearshape.fill", identifier: "home.settings", action: onSettings)
            item(
                isPremiumActive ? "Cancel Premium" : "Premium",
                symbol: isPremiumActive ? "crown" : "crown.fill",
                identifier: "home.premium",
                isFeatured: true,
                action: onPremium
            )
            item("Profile", symbol: "person.crop.circle.fill", identifier: "home.profile", action: onProfile)
        }
        .padding(6)
        // A solid backing keeps the labels readable when colorful content scrolls underneath.
        .background(Theme.backgroundBottom.opacity(0.92), in: .capsule)
        .glassEffect(.regular, in: .capsule)
        .frame(maxWidth: 380)
        .padding(.horizontal, 24)
        .padding(.bottom, 4)
    }

    private func item(
        _ title: LocalizedStringKey,
        symbol: String,
        identifier: String,
        isFeatured: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: symbol)
                    .font(.title3)
                Text(title)
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .buttonStyle(BottomBarItemStyle(isFeatured: isFeatured))
        .accessibilityIdentifier(identifier)
    }
}

private struct BottomBarItemStyle: ButtonStyle {
    let isFeatured: Bool

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        configuration.label
            .foregroundStyle(isFeatured ? Theme.premium : Theme.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background {
                Capsule().fill(Theme.textPrimary.opacity(isPressed ? 0.26 : (isFeatured ? 0.12 : 0)))
            }
            .shadow(color: Theme.glow.opacity(isPressed ? 0.9 : 0), radius: 14)
            .contentShape(.capsule)
            .animation(isPressed ? .easeOut(duration: 0.08) : .easeOut(duration: 0.5), value: isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: isPressed) { _, pressed in pressed }
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        StarfieldBackground()
        HomeBottomBar(isPremiumActive: false, onSettings: {}, onPremium: {}, onProfile: {})
    }
}
