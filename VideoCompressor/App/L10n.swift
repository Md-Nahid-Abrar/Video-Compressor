import Foundation

/// Shortcuts for resolving strings and formats in the language chosen in Settings,
/// for code that runs outside a SwiftUI view.
nonisolated enum L10n {
    static var bundle: Bundle { AppLanguage.current.bundle }
    static var locale: Locale { AppLanguage.current.locale }
}
