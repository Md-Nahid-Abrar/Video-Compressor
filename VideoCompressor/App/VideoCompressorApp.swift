import SwiftUI

@main
struct VideoCompressorApp: App {
    // These live above the root view so they survive the rebuild that follows a language change.
    @State private var services: AppServices
    @State private var router = AppRouter()
    @State private var home: HomeViewModel
    @State private var premium: PremiumStore

    init() {
        if LaunchOptions.resetState {
            StorageKey.all.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        }
        if LaunchOptions.skipWelcome {
            UserDefaults.standard.set(true, forKey: StorageKey.hasSeenWelcome)
        }
        NotificationService.installForegroundPresenter()
        TemporaryFiles.removeAll()

        let services = AppServices.live()
        _services = State(initialValue: services)
        _home = State(initialValue: HomeViewModel(services: services))
        _premium = State(initialValue: PremiumStore(
            duration: LaunchOptions.shortPremium ? 5 : PremiumStore.standardDuration
        ))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(services)
                .environment(router)
                .environment(home)
                .environment(premium)
        }
    }
}
