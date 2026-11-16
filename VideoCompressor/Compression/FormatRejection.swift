import Foundation

/// Why a picked video cannot be compressed.
nonisolated enum FormatRejection: Hashable, Sendable {
    case unsupportedContainer(String)
    case unsupportedCodec(String)
    case noVideoTrack
    case protectedContent

    var message: String {
        switch self {
        case .unsupportedContainer(let ext):
            let name = ext.isEmpty ? String(localized: "this") : ".\(ext)"
            return String(localized: "Videos in \(name) format aren't supported. Choose an MP4, MOV or M4V video.")
        case .unsupportedCodec:
            return String(localized: "This video isn't encoded with H.264 or HEVC. Choose an MP4, MOV or M4V video that uses one of those formats.")
        case .noVideoTrack:
            return String(localized: "This file doesn't contain any video. Choose a different video.")
        case .protectedContent:
            return String(localized: "This video is copy-protected and can't be compressed. Choose a different video.")
        }
    }
}
