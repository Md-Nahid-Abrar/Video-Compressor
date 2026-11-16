import SwiftUI

/// Section 2: three compression levels, replaced by Export once one is chosen.
struct CompressionSection: View {
    let isEnabled: Bool
    let selectedPreset: CompressionPreset?
    let estimate: (CompressionPreset) -> SizeEstimate?
    let onChoose: (CompressionPreset) -> Void
    let onChange: () -> Void
    let onExport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Compression")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            if let selectedPreset {
                VStack(spacing: 10) {
                    Button("Export", systemImage: "square.and.arrow.down.on.square", action: onExport)
                        .buttonStyle(.glow)
                        .accessibilityIdentifier("home.export")
                    HStack(spacing: 6) {
                        Text(selectedPreset.fullTitle)
                            .foregroundStyle(Theme.textSecondary)
                        Text("·").foregroundStyle(Theme.textSecondary)
                        Button("Change compression", action: onChange)
                            .foregroundStyle(Theme.accentText)
                            .fontWeight(.semibold)
                            .accessibilityIdentifier("home.changeCompression")
                    }
                    .font(.subheadline)
                    .frame(minHeight: 44)
                }
                .transition(.scale(scale: 0.94).combined(with: .opacity))
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    GlassEffectContainer(spacing: 12) {
                        HStack(spacing: 12) {
                            ForEach(CompressionPreset.allCases) { preset in
                                PresetButton(preset: preset, estimate: estimate(preset)) {
                                    onChoose(preset)
                                }
                            }
                        }
                    }
                    .disabled(!isEnabled)
                    if !isEnabled {
                        Text("Select a video to choose a compression level.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .transition(.scale(scale: 0.94).combined(with: .opacity))
            }
        }
    }
}

#Preview {
    ZStack {
        StarfieldBackground()
        CompressionSection(
            isEnabled: false,
            selectedPreset: nil,
            estimate: { _ in nil },
            onChoose: { _ in },
            onChange: {},
            onExport: {}
        )
        .padding()
    }
}
