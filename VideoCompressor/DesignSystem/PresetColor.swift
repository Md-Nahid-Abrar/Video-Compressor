import SwiftUI

extension CompressionPreset {
    /// Green for High, yellow for Medium, red for Low.
    var levelColor: Color {
        switch self {
        case .high: Theme.levelHigh
        case .medium: Theme.levelMedium
        case .low: Theme.levelLow
        }
    }
}
