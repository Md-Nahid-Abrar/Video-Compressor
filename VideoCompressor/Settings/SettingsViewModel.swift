import Foundation

/// Values shown on the Settings screen.
@Observable
final class SettingsViewModel {
    let appName = AppConfig.appName
    let versionText = String(localized: "Version \(AppConfig.version) (\(AppConfig.build))")
    let supportEmail = AppConfig.supportEmail

    var supportURL: URL? {
        URL(string: "mailto:\(supportEmail)")
    }
}
