import SwiftUI

/// Before/after sizes side by side, joined by a green arrow centered on the two size pills.
struct ComparisonCard: View {
    let originalText: String
    let compressedText: String
    var originalCaption: String?
    var compressedCaption: String?
    var footnote: String?
    var compressedIsPlaceholder = false
    var isCompact = false

    var body: some View {
        GlassCard(padding: isCompact ? 12 : 18) {
            VStack(spacing: isCompact ? 6 : 12) {
                // Aligning on the pills' center line keeps the arrow level with them,
                // whatever sits above or below.
                HStack(alignment: .pillCenter, spacing: 10) {
                    column(title: "Original", value: originalText, caption: originalCaption, prominent: true)
                    Image(systemName: "arrow.forward")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Theme.arrowGreen, in: .circle)
                        .alignmentGuide(.pillCenter) { $0[VerticalAlignment.center] }
                        .accessibilityHidden(true)
                    column(
                        title: "Compressed",
                        value: compressedText,
                        caption: compressedCaption,
                        prominent: !compressedIsPlaceholder
                    )
                }
                if let footnote {
                    Text(footnote)
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func column(title: LocalizedStringKey, value: String, caption: String?, prominent: Bool) -> some View {
        VStack(spacing: isCompact ? 5 : 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            SizePill(text: value, isProminent: prominent)
                .alignmentGuide(.pillCenter) { $0[VerticalAlignment.center] }
            if let caption {
                Text(caption)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private extension VerticalAlignment {
    /// The vertical center of the size pills.
    enum PillCenter: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[VerticalAlignment.center]
        }
    }

    static let pillCenter = VerticalAlignment(PillCenter.self)
}

#Preview {
    ZStack {
        StarfieldBackground()
        ComparisonCard(
            originalText: "314 MB",
            compressedText: "20 MB",
            originalCaption: "1920 × 1080",
            compressedCaption: "1920 × 1080",
            footnote: "Example"
        )
        .padding()
    }
}
