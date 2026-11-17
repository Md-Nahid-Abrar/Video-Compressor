import SwiftUI

/// A button that looks like a raised key: a solid face sitting on a darker base, casting a shadow.
/// Pressing it pushes the face down onto the base and flares the glow.
struct RaisedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        RaisedButtonBody(configuration: configuration)
    }
}

private struct RaisedButtonBody: View {
    let configuration: ButtonStyle.Configuration

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let depth: CGFloat = 7
    private var isPressed: Bool { configuration.isPressed }
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 18, style: .continuous) }
    private var travel: CGFloat { isPressed && !reduceMotion ? Self.depth - 2 : 0 }

    var body: some View {
        configuration.label
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity)
            .background {
                ZStack {
                    // The base stays put while the face travels down onto it.
                    shape.fill(Theme.raisedBase)
                        .offset(y: Self.depth - travel)
                    shape.fill(Theme.raisedFace)
                    shape.strokeBorder(Color.white.opacity(isPressed ? 0.7 : 0.14), lineWidth: 1)
                }
            }
            .offset(y: travel)
            .padding(.bottom, Self.depth)
            .shadow(color: .black.opacity(isEnabled ? 0.45 : 0), radius: 8, y: 10)
            .shadow(color: Theme.glow.opacity(isPressed ? 0.9 : 0), radius: 22)
            .brightness(isPressed ? 0.08 : 0)
            .opacity(isEnabled ? 1 : 0.45)
            .animation(isPressed ? .easeOut(duration: 0.08) : .easeOut(duration: 0.45), value: isPressed)
            .sensoryFeedback(.impact(weight: .medium), trigger: isPressed) { _, pressed in pressed }
            .contentShape(shape)
    }
}

extension ButtonStyle where Self == RaisedButtonStyle {
    static var raised: RaisedButtonStyle { RaisedButtonStyle() }
}

#Preview {
    ZStack {
        StarfieldBackground()
        HStack(spacing: 12) {
            Button("High") {}.buttonStyle(.raised)
            Button("Medium") {}.buttonStyle(.raised).disabled(true)
        }
        .padding()
    }
}
