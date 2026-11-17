import SwiftUI
import UIKit

/// Colors and metrics shared across the app. Every color adapts to light and dark appearance.
///
/// Palette: navy background, yellow headlines, orange-to-pink buttons, green accents.
enum Theme {
    static let backgroundTop = Color(light: 0xF4F7FF, dark: 0x070F2B)
    static let backgroundBottom = Color(light: 0xD9E3FF, dark: 0x0E1F52)
    static let textPrimary = Color(light: 0x0B1538, dark: 0xFFFFFF)
    static let textSecondary = Color(light: 0x4A5578, dark: 0xA8B3D1)
    static let star = Color(light: 0x3B5BDB, dark: 0xFFFFFF)
    static let cardFill = Color(light: 0xFFFFFF, lightAlpha: 0.75, dark: 0xFFFFFF, darkAlpha: 0.06)
    static let cardStroke = Color(light: 0x1E3A8A, lightAlpha: 0.18, dark: 0x9DB4FF, darkAlpha: 0.22)

    /// Yellow used for headlines.
    static let headline = Color(light: 0xB27600, dark: 0xFFD60A)
    /// Green used for accents: icons, links, highlighted figures.
    static let accent = Color(light: 0x15803D, dark: 0x4ADE80)

    static let buttonStart = Color(hex: 0xFF8A1F)
    static let buttonEnd = Color(hex: 0xFF2D78)
    /// Color of the glow that flares around buttons when tapped.
    static let glow = Color(hex: 0xFF5A6E)
    static let arrowGreen = Color(hex: 0x3DBE6B)
    static let success = Color(hex: 0x22C55E)
    static let warning = Color(light: 0xB25E00, dark: 0xFFC46B)

    static let levelHigh = Color(light: 0x15803D, dark: 0x4ADE80)
    static let levelMedium = Color(light: 0xB27600, dark: 0xFFD60A)
    static let levelLow = Color(light: 0xD92D20, dark: 0xFF453A)

    /// Face and base of the raised 3D buttons.
    static let raisedFace = Color(light: 0xFFFFFF, dark: 0x1C2C66)
    static let raisedBase = Color(light: 0x9FB0E6, dark: 0x050A1F)

    static let primaryGradient = LinearGradient(
        colors: [buttonStart, buttonEnd],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let pillGradient = primaryGradient

    static let cornerRadius: CGFloat = 22
    static let contentMaxWidth: CGFloat = 560
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    init(light: UInt32, lightAlpha: Double = 1, dark: UInt32, darkAlpha: Double = 1) {
        self.init(uiColor: UIColor { traits in
            let isDark = traits.userInterfaceStyle == .dark
            let hex = isDark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: isDark ? darkAlpha : lightAlpha
            )
        })
    }
}
