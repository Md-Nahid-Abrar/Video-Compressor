import SwiftUI

/// Switches between the welcome screen and the main flow, and applies the chosen appearance and language.
struct RootView: View {
    @Environment(PremiumStore.self) private var premium
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(StorageKey.hasSeenWelcome) private var hasSeenWelcome = false
    @AppStorage(StorageKey.appearance) private var appearance: AppearanceMode = .dark
    @AppStorage(StorageKey.language) private var language: AppLanguage = .english

    var body: some View {
        ZStack {
            if hasSeenWelcome {
                MainFlowView()
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
        // Rebuilding on a language change makes every string, including ones computed in code, refresh.
        .id(language)
        .environment(\.locale, language.locale)
        .preferredColorScheme(appearance.colorScheme)
        .tint(Theme.accent)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                premium.refresh()
            }
        }
    }
}
