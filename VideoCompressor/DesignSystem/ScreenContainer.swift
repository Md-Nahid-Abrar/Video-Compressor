import SwiftUI

/// Places scrollable content over the starfield at a readable width on every device.
struct ScreenContainer<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            StarfieldBackground()
            ScrollView {
                content
                    .frame(maxWidth: Theme.contentMaxWidth)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

#Preview {
    ScreenContainer {
        Text("Content").foregroundStyle(Theme.textPrimary)
    }
}
