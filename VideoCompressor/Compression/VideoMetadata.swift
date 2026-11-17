import CoreGraphics
import Foundation

/// Everything the app needs to know about a picked video.
nonisolated struct VideoMetadata: Hashable, Sendable {
    /// Duration in seconds.
    var duration: Double
    /// Encoded width in pixels, before rotation is applied.
    var pixelWidth: Int
    /// Encoded height in pixels, before rotation is applied.
    var pixelHeight: Int
    /// Whether the display transform turns the picture a quarter turn.
    var isRotated: Bool
    var frameRate: Double
    /// Video bitrate in bits per second.
    var videoBitrate: Double
    /// FourCC of the video codec, such as "hvc1".
    var codec: String
    /// Lowercased file extension, such as "mov".
    var containerExtension: String
    var fileSize: Int64
    var audio: AudioInfo?
    var isHDR: Bool
    var colorPrimaries: String?
    var transferFunction: String?
    var yCbCrMatrix: String?
    var hasProtectedContent: Bool
    var creationDate: Date?

    /// Size as shown on screen, after rotation.
    var displaySize: CGSize {
        isRotated
            ? CGSize(width: pixelHeight, height: pixelWidth)
            : CGSize(width: pixelWidth, height: pixelHeight)
    }

    /// Video bitrate, falling back to the file's overall bitrate when the track does not report one.
    var effectiveVideoBitrate: Double {
        if videoBitrate > 0 { return videoBitrate }
        guard duration > 0 else { return 0 }
        return max(Double(fileSize) * 8 / duration - (audio?.bitrate ?? 0), 0)
    }

    /// Container and codec for display, such as "MOV · H.264".
    var formatName: String {
        let codecName = switch codec.lowercased() {
        case "avc1", "avc3": "H.264"
        case "hvc1", "hev1": "HEVC"
        case "dvh1", "dvhe": "Dolby Vision"
        default: codec.uppercased()
        }
        let container = containerExtension.uppercased()
        return codecName.isEmpty ? container : "\(container) · \(codecName)"
    }
}
