import SwiftUI

/// App details, appearance, language, feedback, rating, invite, and links.
struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @AppStorage(StorageKey.appearance) private var appearance: AppearanceMode = .dark
    @AppStorage(StorageKey.language) private var language: AppLanguage = .english

    var body: some View {
        ScreenContainer {
            VStack(spacing: 18) {
                header
                appearanceSection
                languageSection
                FeedbackSection(makeURL: viewModel.feedbackURL(message:))
                RatingSection()
                InviteSection(link: viewModel.privacyPolicyURL)
                linksSection
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "arrow.down.right.and.arrow.up.left")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 88, height: 88)
                .background(Theme.primaryGradient, in: .rect(cornerRadius: 22))
                .shadow(color: Theme.glow.opacity(0.5), radius: 16)
                .accessibilityHidden(true)
            Text(viewModel.appName)
                .font(.title.weight(.black))
                .foregroundStyle(Theme.textPrimary)
            Text(viewModel.versionText)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .accessibilityIdentifier("settings.version")
        }
        .padding(.top, 12)
    }

    private var appearanceSection: some View {
        SettingsSection(title: "Appearance") {
            Button {
                withAnimation(.smooth) {
                    appearance = appearance.toggled
                }
            } label: {
                Label(appearance.title, systemImage: appearance.symbolName)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.glow)
            .accessibilityIdentifier("settings.appearance")
            .accessibilityLabel("Appearance")
            .accessibilityValue(appearance.title)
            .accessibilityHint("Switches between light and dark mode")
        }
    }

    private var languageSection: some View {
        SettingsSection(title: "Language") {
            Picker("Language", selection: $language) {
                ForEach(AppLanguage.allCases) { option in
                    Text(verbatim: option.displayName).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.accentText)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.horizontal, 6)
            .background(Theme.cardFill, in: .rect(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.cardStroke, lineWidth: 1)
            }
            .accessibilityIdentifier("settings.language")
        }
    }

    private var linksSection: some View {
        SettingsSection(title: "Support") {
            Link(destination: viewModel.privacyPolicyURL) {
                linkLabel("Privacy Policy", symbol: "hand.raised.fill")
            }
            .accessibilityIdentifier("settings.privacyPolicy")
            .accessibilityHint("Opens in your browser")

            if let url = viewModel.supportURL {
                Link(destination: url) {
                    linkLabel(LocalizedStringKey(viewModel.supportEmail), symbol: "envelope.fill")
                }
                .accessibilityIdentifier("settings.supportEmail")
                .accessibilityHint("Opens a new email")
            }
        }
    }

    private func linkLabel(_ title: LocalizedStringKey, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.body.weight(.semibold))
            .foregroundStyle(Theme.accentText)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
