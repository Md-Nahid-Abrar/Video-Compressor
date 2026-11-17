import SwiftUI

/// The "P Premium" mark, glowing and dimming continuously.
struct PremiumBadge: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                badge(isBright: true)
            } else {
                // A phase animator animates only the glow, so it can never disturb layout.
                badge(isBright: true).hidden().overlay {
                    Color.clear.phaseAnimator([false, true]) { _, isBright in
                        badge(isBright: isBright)
                    } animation: { _ in
                        .easeInOut(duration: 1.1)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("premium.badge")
    }

    private func badge(isBright: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "p.circle.fill")
                .font(.title3)
            Text("Premium")
                .font(.subheadline.weight(.heavy))
        }
        .foregroundStyle(Theme.headline)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Theme.headline.opacity(0.14), in: .capsule)
        .overlay { Capsule().strokeBorder(Theme.headline.opacity(0.5), lineWidth: 1) }
        .shadow(color: Theme.headline.opacity(isBright ? 0.9 : 0.1), radius: isBright ? 14 : 3)
        .opacity(isBright ? 1 : 0.5)
        .fixedSize()
    }
}

#Preview {
    ZStack {
        StarfieldBackground()
        PremiumBadge()
    }
}
