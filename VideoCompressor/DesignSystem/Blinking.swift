import SwiftUI

/// Fades content in and out, forever.
struct Blinking: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            // A phase animator animates only the opacity, so it can never disturb layout.
            content.phaseAnimator([1.0, 0.2]) { view, opacity in
                view.opacity(opacity)
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
