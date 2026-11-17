import SwiftUI

/// First-launch screen showing what the app does.
struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            StarfieldBackground()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 28) {
                        VStack(spacing: 6) {
                            Text("Compress Video")
                                .font(.system(.largeTitle, weight: .black))
                                .foregroundStyle(Theme.headline)
                            Text("Without Visible Quality Loss")
                                .font(.system(.title2, weight: .heavy))
                                .foregroundStyle(Theme.textPrimary)
                        }
                        .multilineTextAlignment(.center)
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.isHeader)

                        ComparisonCard(
                            originalText: "314 MB",
                            compressedText: "20 MB",
                            originalCaption: "1920 × 1080",
                            compressedCaption: "1920 × 1080",
                            footnote: String(localized: "Example. Results vary by video.", bundle: L10n.bundle)
                        )

                        Text("Shrink videos from your library, then save or share them in a tap.")
                            .font(.body)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: Theme.contentMaxWidth)
                    .padding(.horizontal, 24)
                    .padding(.top, 48)
                    .frame(maxWidth: .infinity)
                }
                .scrollBounceBehavior(.basedOnSize)

                Button("Continue", action: onContinue)
                    .buttonStyle(.glow)
                    .frame(maxWidth: Theme.contentMaxWidth)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .accessibilityIdentifier("welcome.continue")
            }
        }
    }
}

#Preview {
    WelcomeView {}
}
