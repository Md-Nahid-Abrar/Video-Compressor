import SwiftUI

/// The app's light or dark appearance, chosen in Settings.
nonisolated enum AppearanceMode: String, CaseIterable, Identifiable, Sendable {
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme {
        switch self {
        case .light: .light
        case .dark: .dark
        }
    }

    var title: String {
        switch self {
        case .light: String(localized: "Light")
        case .dark: String(localized: "Dark")
        }
    }

    var symbolName: String {
        switch self {
        case .light: "sun.max.fill"
        case .dark: "moon.stars.fill"
        }
    }

    var toggled: AppearanceMode {
        self == .dark ? .light : .dark
    }
}
