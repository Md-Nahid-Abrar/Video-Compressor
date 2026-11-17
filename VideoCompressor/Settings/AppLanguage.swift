import Foundation

/// Languages the app can display, chosen in Settings. English is the default.
nonisolated enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case english = "en"
    case spanish = "es"
    case bengali = "bn"

    var id: String { rawValue }

    /// The language's own name, shown untranslated so speakers can always find it.
    var displayName: String {
        switch self {
        case .english: "English"
        case .spanish: "Español"
        case .bengali: "বাংলা"
        }
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    /// The bundle holding this language's strings.
    var bundle: Bundle {
        guard let path = Bundle.main.path(forResource: rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return .main }
        return bundle
    }

    /// The language currently selected by the user.
    static var current: AppLanguage {
        resolve(UserDefaults.standard.string(forKey: StorageKey.language))
    }

    /// Maps a stored value to a language, falling back to English.
    static func resolve(_ stored: String?) -> AppLanguage {
        stored.flatMap(AppLanguage.init(rawValue:)) ?? .english
    }
}
