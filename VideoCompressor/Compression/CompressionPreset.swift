import Foundation

/// The three compression levels offered on the home screen.
nonisolated enum CompressionPreset: String, CaseIterable, Identifiable, Hashable, Sendable {
    case high
    case medium
    case low

    var id: String { rawValue }

    var title: String {
        switch self {
        case .high: String(localized: "High")
        case .medium: String(localized: "Medium")
        case .low: String(localized: "Low")
        }
    }

    var fullTitle: String {
        switch self {
        case .high: String(localized: "High compression")
        case .medium: String(localized: "Medium compression")
        case .low: String(localized: "Low compression")
        }
    }

    var symbolName: String {
        switch self {
        case .high: "arrow.down.right.and.arrow.up.left.circle.fill"
        case .medium: "circle.lefthalf.filled"
        case .low: "sparkles"
        }
    }

    /// Longest output edge in pixels. `nil` keeps the source resolution.
    var maxLongEdge: Int? {
        switch self {
        case .high: 1280
        case .medium: 1920
        case .low: nil
        }
    }

    var maxFrameRate: Double {
        switch self {
        case .high, .medium: 30
        case .low: 60
        }
    }

    /// HEVC bit budget per pixel per frame.
    var bitsPerPixel: Double {
        switch self {
        case .high: 0.040
        case .medium: 0.050
        case .low: 0.085
        }
    }

    /// Upper bound on the video bitrate as a fraction of the source bitrate.
    var sourceBitrateCap: Double {
        switch self {
        case .high: 0.15
        case .medium: 0.35
        case .low: 0.60
        }
    }

    /// AAC bitrate per audio channel, in bits per second.
    var audioBitratePerChannel: Int {
        switch self {
        case .high: 48_000
        case .medium, .low: 64_000
        }
    }
}
