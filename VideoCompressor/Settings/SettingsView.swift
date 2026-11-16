import SwiftUI

/// App details, appearance switch and support contact.
struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @AppStorage(StorageKey.appearance) private var appearance: AppearanceMode = .dark

    var body: some View {
        ScreenContainer {
            VStack(spacing: 20) {
                header
                appearanceCard
                supportCard
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "arrow.down.right.and.arrow.up.left")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 88, height: 88)
                .background(Theme.primaryGradient, in: .rect(cornerRadius: 22))
                .shadow(color: Theme.accentBright.opacity(0.5), radius: 16)
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

    private var appearanceCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Appearance")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
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
    }

    private var supportCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Support")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                if let url = viewModel.supportURL {
                    Link(destination: url) {
                        Label(viewModel.supportEmail, systemImage: "envelope.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.accentText)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                    .accessibilityIdentifier("settings.supportEmail")
                    .accessibilityHint("Opens a new email")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
