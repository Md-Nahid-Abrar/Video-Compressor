import SwiftUI
import UIKit

/// Colors and metrics shared across the app. Every color adapts to light and dark appearance.
enum Theme {
    static let backgroundTop = Color(light: 0xF8F5FF, dark: 0x06051A)
    static let backgroundBottom = Color(light: 0xE4DBFF, dark: 0x1C1042)
    static let textPrimary = Color(light: 0x1A1433, dark: 0xFFFFFF)
    static let textSecondary = Color(light: 0x5E5878, dark: 0xA9A6BC)
    static let star = Color(light: 0x8B5CF6, dark: 0xFFFFFF)
    static let cardFill = Color(light: 0xFFFFFF, lightAlpha: 0.72, dark: 0xFFFFFF, darkAlpha: 0.06)
    static let cardStroke = Color(light: 0x8B5CF6, lightAlpha: 0.22, dark: 0xB69CFF, darkAlpha: 0.22)

    static let accent = Color(hex: 0x8B5CF6)
    static let accentBright = Color(hex: 0xA855F7)
    static let accentDeep = Color(hex: 0x6D4AE8)
    static let accentText = Color(light: 0x6D3FE0, dark: 0x9B7BFF)

    static let pillStart = Color(hex: 0xFF8A1F)
    static let pillEnd = Color(hex: 0xFF2D78)
    static let arrowGreen = Color(hex: 0x3DBE6B)
    static let success = Color(hex: 0x34C759)
    static let warning = Color(light: 0xB25E00, dark: 0xFFC46B)

    static let primaryGradient = LinearGradient(
        colors: [accentBright, accentDeep],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let pillGradient = LinearGradient(
        colors: [pillStart, pillEnd],
        startPoint: .leading,
        endPoint: .trailing
    )

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
