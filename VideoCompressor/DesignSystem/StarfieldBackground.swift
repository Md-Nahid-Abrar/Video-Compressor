import SwiftUI

/// The app's backdrop: a vertical gradient scattered with softly twinkling stars.
struct StarfieldBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let stars: [Star] = Star.makeField(count: 90)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.backgroundTop, Theme.backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            TimelineView(.animation(minimumInterval: 0.12, paused: reduceMotion)) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                Canvas { graphics, size in
                    for star in Self.stars {
                        let twinkle = reduceMotion ? 1 : 0.65 + 0.35 * sin(time * star.speed + star.phase)
                        let rect = CGRect(
                            x: star.x * size.width,
                            y: star.y * size.height,
                            width: star.size,
                            height: star.size
                        )
                        graphics.fill(
                            Path(ellipseIn: rect),
                            with: .color(Theme.star.opacity(star.opacity * twinkle))
                        )
                    }
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

private struct Star {
    let x: Double
    let y: Double
    let size: Double
    let opacity: Double
    let speed: Double
    let phase: Double

    /// A fixed pseudo-random layout so the field looks the same on every launch.
    static func makeField(count: Int) -> [Star] {
        var state: UInt64 = 0x9E3779B97F4A7C15
        func next() -> Double {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return Double((state >> 33) % 10_000) / 10_000
        }
        return (0..<count).map { _ in
            Star(
                x: next(),
                y: next(),
                size: 1 + next() * 2,
                opacity: 0.25 + next() * 0.55,
                speed: 0.6 + next() * 1.4,
                phase: next() * .pi * 2
            )
        }
    }
}

#Preview {
    StarfieldBackground()
}
