import SwiftUI

@main
struct VideoCompressorApp: App {
    @State private var services: AppServices

    init() {
        if LaunchOptions.resetState {
            StorageKey.all.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        }
        if LaunchOptions.skipWelcome {
            UserDefaults.standard.set(true, forKey: StorageKey.hasSeenWelcome)
        }
        NotificationService.installForegroundPresenter()
        TemporaryFiles.removeAll()
        _services = State(initialValue: AppServices.live())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(services)
        }
    }
}
