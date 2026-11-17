import SwiftUI

/// Fades the foreground between full white and full dark, forever.
struct Blinking: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let dark = Color(hex: 0x05070F)

    func body(content: Content) -> some View {
        if reduceMotion {
            content.foregroundStyle(Color.white)
        } else {
            // A phase animator animates only the color, so it can never disturb layout.
            content.phaseAnimator([true, false]) { view, isLit in
                view.foregroundStyle(isLit ? Color.white : Self.dark)
            } animation: { _ in
                .easeInOut(duration: 0.7)
            }
        }
    }
}

extension View {
    func blinking() -> some View {
        modifier(Blinking())
    }
}
