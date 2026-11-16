import SwiftUI

/// Lets the user set a display name and email that are stored only on this device.
struct ProfileView: View {
    @State private var viewModel: ProfileViewModel
    @FocusState private var focusedField: Field?

    private enum Field {
        case name
        case email
    }

    init(defaults: UserDefaults = .standard) {
        _viewModel = State(initialValue: ProfileViewModel(store: ProfileStore(defaults: defaults)))
    }

    var body: some View {
        ScreenContainer {
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 92))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Theme.primaryGradient)
                    .shadow(color: Theme.accentBright.opacity(0.5), radius: 16)
                    .padding(.top, 12)
                    .accessibilityHidden(true)

                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        field(title: "Name") {
                            TextField("Your Name", text: $viewModel.name)
                                .textContentType(.name)
                                .textInputAutocapitalization(.words)
                                .submitLabel(.next)
                                .focused($focusedField, equals: .name)
                                .onSubmit { focusedField = .email }
                                .accessibilityIdentifier("profile.name")
                        }
                        field(title: "Email") {
                            TextField("you@example.com", text: $viewModel.email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .submitLabel(.done)
                                .focused($focusedField, equals: .email)
                                .onSubmit { focusedField = nil }
                                .accessibilityIdentifier("profile.email")
                        }
                        if !viewModel.isEmailValid {
                            Label("Enter a valid email address", systemImage: "exclamationmark.circle")
                                .font(.footnote)
                                .foregroundStyle(Theme.warning)
                                .accessibilityIdentifier("profile.emailHint")
                        }
                    }
                }

                Label("Saved on this device only", systemImage: "lock.fill")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
    }

    private func field(title: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            content()
                .font(.body)
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 14)
                .frame(minHeight: 48)
                .background(Theme.cardFill, in: .rect(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Theme.cardStroke, lineWidth: 1)
                }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
