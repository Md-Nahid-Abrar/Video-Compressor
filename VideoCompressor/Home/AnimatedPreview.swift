import SwiftUI

/// A GIF-style preview that loops through a handful of video frames.
struct AnimatedPreview: View {
    let frames: [CGImage]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private static let frameInterval = 0.2

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        Group {
            if frames.isEmpty {
                Image(systemName: "film")
                    .font(.title)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                TimelineView(.periodic(from: .now, by: Self.frameInterval)) { context in
                    let tick = Int(context.date.timeIntervalSinceReferenceDate / Self.frameInterval)
                    let index = reduceMotion ? 0 : tick % frames.count
                    Image(decorative: frames[index], scale: 1)
                        .resizable()
                        .scaledToFill()
                }
            }
        }
        .frame(width: 84, height: 84)
        .background(Theme.cardFill)
        .clipShape(shape)
        .overlay { shape.strokeBorder(Theme.cardStroke, lineWidth: 1) }
        .accessibilityHidden(true)
    }
}
