import SwiftUI

/// A rounded Liquid Glass panel used for each section.
struct GlassCard<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(Theme.cardFill)
            }
            .glassEffect(.regular, in: .rect(cornerRadius: Theme.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .strokeBorder(Theme.cardStroke, lineWidth: 1)
            }
    }
}

#Preview {
    ZStack {
        StarfieldBackground()
        GlassCard {
            Text("Section").foregroundStyle(Theme.textPrimary)
        }
        .padding()
    }
}
