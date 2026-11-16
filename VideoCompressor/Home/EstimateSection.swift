import SwiftUI

/// Section 3: original size against the estimated compressed size.
struct EstimateSection: View {
    let originalBytes: Int64?
    let estimate: SizeEstimate?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Estimated Size")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            ComparisonCard(
                originalText: originalBytes?.formattedFileSize ?? "—",
                compressedText: estimate.map { "≈ \($0.estimatedBytes.formattedFileSize)" } ?? "—",
                footnote: footnote,
                compressedIsPlaceholder: estimate == nil
            )
            .accessibilityIdentifier("home.estimate")
        }
    }

    private var footnote: String {
        if let estimate {
            let percent = estimate.reduction.formatted(.percent.precision(.fractionLength(0)))
            return String(localized: "About \(percent) smaller")
        }
        if originalBytes != nil {
            return String(localized: "Choose a compression level to see the estimate.")
        }
        return String(localized: "Select a video to see how much space you'll save.")
    }
}

#Preview {
    ZStack {
        StarfieldBackground()
        EstimateSection(
            originalBytes: 50_000_000,
            estimate: SizeEstimate(originalBytes: 50_000_000, estimatedBytes: 25_000_000)
        )
        .padding()
    }
}
