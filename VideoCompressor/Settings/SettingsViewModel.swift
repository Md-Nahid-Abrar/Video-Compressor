import Foundation

/// Values shown on the Settings screen.
@Observable
final class SettingsViewModel {
    let appName = AppConfig.appName
    let versionText = String(localized: "Version \(AppConfig.version) (\(AppConfig.build))", bundle: L10n.bundle)
    let supportEmail = AppConfig.supportEmail
    let privacyPolicyURL = AppConfig.privacyPolicyURL

    var supportURL: URL? {
        URL(string: "mailto:\(supportEmail)")
    }

    /// A `mailto:` link that opens a feedback email with the user's text filled in.
    func feedbackURL(message: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = AppConfig.feedbackEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "\(AppConfig.appName) Feedback (\(AppConfig.version))"),
            URLQueryItem(name: "body", value: message)
        ]
        return components.url
    }
}
