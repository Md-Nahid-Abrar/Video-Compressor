import SwiftUI

/// One of the three compression level buttons.
struct PresetButton: View {
    let preset: CompressionPreset
    let estimate: SizeEstimate?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: preset.symbolName)
                    .font(.title2)
                    .foregroundStyle(Theme.accentText)
                    .frame(height: 30)
                Text(preset.title)
                    .font(.subheadline.weight(.bold))
                Text("compression")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Theme.textSecondary)
                Text(estimate.map { "≈ \($0.estimatedBytes.formattedFileSize)" } ?? " ")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.accentText)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.vertical, 10)
        }
        .buttonStyle(.glow(.secondary))
        .accessibilityLabel(preset.fullTitle)
        .accessibilityValue(estimate.map { String(localized: "About \($0.estimatedBytes.formattedFileSize)") } ?? "")
        .accessibilityIdentifier("home.preset.\(preset.rawValue)")
    }
}

#Preview {
    ZStack {
        StarfieldBackground()
        HStack {
            ForEach(CompressionPreset.allCases) { preset in
                PresetButton(preset: preset, estimate: nil) {}
            }
        }
        .padding()
    }
}
