import SwiftUI

/// Pop-up for entering a 3-digit promo code, or for seeing the remaining Premium time.
struct PromoCodeSheet: View {
    @Environment(PremiumStore.self) private var premium
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var showsError = false
    @FocusState private var isCodeFocused: Bool

    private static let codeLength = 3

    var body: some View {
        ZStack {
            StarfieldBackground()
            VStack(spacing: 16) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.headline)
                    .accessibilityHidden(true)

                if let expiry = premium.expiry {
                    activeContent(expiry: expiry)
                } else {
                    entryContent
                }
            }
            .padding(24)
            .frame(maxWidth: Theme.contentMaxWidth)
        }
        .presentationDetents([.height(400)])
        .presentationDragIndicator(.visible)
    }

    private var entryContent: some View {
        VStack(spacing: 16) {
            Text("Enter Promo Code")
                .font(.system(.title2, weight: .black))
                .foregroundStyle(Theme.headline)
            Text("Enter your 3-digit code to unlock Premium for 48 hours.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            TextField("000", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .multilineTextAlignment(.center)
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 160, height: 60)
                .background(Theme.cardFill, in: .rect(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(showsError ? Theme.levelLow : Theme.cardStroke, lineWidth: 1.5)
                }
                .focused($isCodeFocused)
                .onChange(of: code) { _, newValue in
                    let digits = String(newValue.filter(\.isNumber).prefix(Self.codeLength))
                    if digits != newValue { code = digits }
                    if !digits.isEmpty { showsError = false }
                }
                .accessibilityLabel("Promo code")
                .accessibilityIdentifier("promo.code")

            if showsError {
                Text("That code isn't valid. Try again.")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Theme.levelLow)
                    .accessibilityIdentifier("promo.error")
            }

            HStack(spacing: 12) {
                Button("Cancel", role: .cancel) { dismiss() }
                    .buttonStyle(.glow(.secondary))
                    .accessibilityIdentifier("promo.cancel")
                Button("Activate") { activate() }
                    .buttonStyle(.glow)
                    .disabled(code.count != Self.codeLength)
                    .accessibilityIdentifier("promo.activate")
            }
        }
        .onAppear { isCodeFocused = true }
    }

    private func activeContent(expiry: Date) -> some View {
        VStack(spacing: 16) {
            Text("Premium Is Active")
                .font(.system(.title2, weight: .black))
                .foregroundStyle(Theme.headline)
                .accessibilityIdentifier("promo.active")
            PremiumCountdown(expiry: expiry)
            Button("Done") { dismiss() }
                .buttonStyle(.glow)
                .accessibilityIdentifier("promo.done")
        }
    }

    private func activate() {
        if premium.redeem(code) {
            dismiss()
        } else {
            showsError = true
            code = ""
        }
    }
}

#Preview {
    PromoCodeSheet()
        .environment(PremiumStore())
}
