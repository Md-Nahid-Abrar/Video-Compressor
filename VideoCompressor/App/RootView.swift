import SwiftUI

/// Switches between the welcome screen and the main flow, and applies the chosen appearance.
struct RootView: View {
    @Environment(AppServices.self) private var services
    @AppStorage(StorageKey.hasSeenWelcome) private var hasSeenWelcome = false
    @AppStorage(StorageKey.appearance) private var appearance: AppearanceMode = .dark

    var body: some View {
        ZStack {
            if hasSeenWelcome {
                MainFlowView(services: services)
                    .transition(.move(edge: .trailing))
            } else {
                WelcomeView {
                    withAnimation(.smooth(duration: 0.45)) {
                        hasSeenWelcome = true
                    }
                }
                .transition(.move(edge: .leading))
            }
        }
        .preferredColorScheme(appearance.colorScheme)
        .tint(Theme.accent)
    }
}

#Preview {
    RootView()
        .environment(AppServices.live())
}
