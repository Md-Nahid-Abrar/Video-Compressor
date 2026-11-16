import Foundation
import UserNotifications

/// Shows the completion notification as a banner even when the app is in the foreground.
nonisolated final class ForegroundNotificationPresenter: NSObject, UNUserNotificationCenterDelegate, Sendable {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
