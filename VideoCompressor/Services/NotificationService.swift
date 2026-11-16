import Foundation
import UserNotifications

/// Posts a local notification when compression completes.
nonisolated struct NotificationService: CompletionNotifying {
    private static let presenter = ForegroundNotificationPresenter()

    /// Lets notifications appear as banners while the app is open. Call once at launch.
    static func installForegroundPresenter() {
        UNUserNotificationCenter.current().delegate = presenter
    }

    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        guard await center.notificationSettings().authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    func notifyCompleted() async {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Video compressed successfully")
        content.body = String(localized: "Your video is ready to save or share.")
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try? await center.add(request)
    }
}
