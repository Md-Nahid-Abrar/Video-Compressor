import SwiftUI

/// Before/after sizes side by side, joined by a green arrow.
struct ComparisonCard: View {
    let originalText: String
    let compressedText: String
    var originalCaption: String?
    var compressedCaption: String?
    var footnote: String?
    var compressedIsPlaceholder = false

    var body: some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack(alignment: .center, spacing: 10) {
                    column(title: "Original", value: originalText, caption: originalCaption, prominent: true)
                    Image(systemName: "arrow.right")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Theme.arrowGreen, in: .circle)
                        .accessibilityHidden(true)
                    column(title: "Compressed", value: compressedText, caption: compressedCaption, prominent: !compressedIsPlaceholder)
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
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            SizePill(text: value, isProminent: prominent)
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
