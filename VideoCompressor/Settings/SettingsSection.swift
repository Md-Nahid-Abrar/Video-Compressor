import SwiftUI

/// A titled glass card used for each group of settings.
struct SettingsSection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder var content: Content

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
