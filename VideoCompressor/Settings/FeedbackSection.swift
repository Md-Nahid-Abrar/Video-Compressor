import SwiftUI

/// Lets the user write feedback and send it by email.
struct FeedbackSection: View {
    let makeURL: (String) -> URL?

    @Environment(\.openURL) private var openURL
    @State private var message = ""
    @State private var showsMailUnavailable = false

    private var trimmed: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        SettingsSection(title: "Feedback") {
            TextEditor(text: $message)
                .font(.body)
                .foregroundStyle(Theme.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(height: 96)
                .padding(8)
                .background(Theme.cardFill, in: .rect(cornerRadius: 14))
                .overlay(alignment: .topLeading) {
                    if message.isEmpty {
                        Text("Tell us what you think…")
                            .font(.body)
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Theme.cardStroke, lineWidth: 1)
                }
                .accessibilityLabel("Feedback")
                .accessibilityIdentifier("settings.feedbackText")

            Button("Send Feedback", systemImage: "paperplane.fill") {
                send()
            }
            .buttonStyle(.glow)
            .disabled(trimmed.isEmpty)
            .accessibilityIdentifier("settings.sendFeedback")
        }
        .alert("Mail Isn't Set Up", isPresented: $showsMailUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Set up an email account on this device, or write to \(AppConfig.feedbackEmail).")
        }
    }

    private func send() {
        guard let url = makeURL(trimmed) else { return }
        openURL(url) { accepted in
            if !accepted {
                showsMailUnavailable = true
            }
        }
    }
}
