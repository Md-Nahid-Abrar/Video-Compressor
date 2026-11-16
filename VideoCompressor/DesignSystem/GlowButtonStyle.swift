import SwiftUI

/// A button whose glow flares when pressed and fades out after release.
struct GlowButtonStyle: ButtonStyle {
    enum Kind {
        /// Purple gradient call-to-action.
        case primary
        /// Translucent card-like button.
        case secondary
        /// Green confirmation state.
        case success
    }

    var kind: Kind = .primary

    func makeBody(configuration: Configuration) -> some View {
        GlowButtonBody(configuration: configuration, kind: kind)
    }
}

private struct GlowButtonBody: View {
    let configuration: ButtonStyle.Configuration
    let kind: GlowButtonStyle.Kind

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isPressed: Bool { configuration.isPressed }
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous) }

    private var glowColor: Color {
        switch kind {
        case .primary, .secondary: Theme.accentBright
        case .success: Theme.success
        }
    }

    var body: some View {
        configuration.label
            .font(.headline.weight(.bold))
            .multilineTextAlignment(.center)
            .foregroundStyle(kind == .secondary ? Theme.textPrimary : Color.white)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background { background }
            .overlay {
                shape.strokeBorder(Color.white.opacity(isPressed ? 0.7 : 0), lineWidth: 1.5)
            }
            .shadow(
                color: glowColor.opacity(isEnabled ? (isPressed ? 0.95 : (kind == .secondary ? 0 : 0.45)) : 0),
                radius: isPressed ? 30 : 14
            )
            .brightness(isPressed ? 0.12 : 0)
            .scaleEffect(isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(isEnabled ? 1 : 0.4)
            .animation(isPressed ? .easeOut(duration: 0.08) : .easeOut(duration: 0.55), value: isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: isPressed) { _, pressed in pressed }
            .contentShape(shape)
    }

    @ViewBuilder
    private var background: some View {
        switch kind {
        case .primary:
            shape.fill(Theme.primaryGradient)
        case .success:
            shape.fill(Theme.success.gradient)
        case .secondary:
            shape.fill(Theme.cardFill)
                .overlay { shape.strokeBorder(Theme.cardStroke, lineWidth: 1) }
        }
    }
}

extension ButtonStyle where Self == GlowButtonStyle {
    static var glow: GlowButtonStyle { GlowButtonStyle() }
    static func glow(_ kind: GlowButtonStyle.Kind) -> GlowButtonStyle { GlowButtonStyle(kind: kind) }
}

#Preview {
    ZStack {
        StarfieldBackground()
        VStack(spacing: 20) {
            Button("Continue") {}.buttonStyle(.glow)
            Button("Secondary") {}.buttonStyle(.glow(.secondary))
            Button("Saved") {}.buttonStyle(.glow(.success))
            Button("Disabled") {}.buttonStyle(.glow).disabled(true)
        }
        .padding()
    }
}
