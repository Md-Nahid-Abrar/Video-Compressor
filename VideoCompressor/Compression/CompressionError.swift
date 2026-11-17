import Foundation

/// Failures surfaced to the user during inspection or compression.
nonisolated enum CompressionError: Error, Hashable, Sendable {
    case unreadable
    case noVideoTrack
    case insufficientSpace
    case interrupted
    case cancelled
    case failed(String)

    var message: String {
        switch self {
        case .unreadable:
            String(localized: "This video couldn't be opened. Try choosing it again.", bundle: L10n.bundle)
        case .noVideoTrack:
            String(localized: "This file doesn't contain any video.", bundle: L10n.bundle)
        case .insufficientSpace:
            String(localized: "There isn't enough free storage to compress this video. Free up some space and try again.", bundle: L10n.bundle)
        case .interrupted:
            String(localized: "Compression was interrupted because the app left the foreground. Keep the app open and try again.", bundle: L10n.bundle)
        case .cancelled:
            String(localized: "Compression was cancelled.", bundle: L10n.bundle)
        case .failed(let reason):
            String(localized: "Compression failed. \(reason)", bundle: L10n.bundle)
        }
    }
}
