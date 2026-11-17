import Foundation

/// Failures when saving a video to the photo library.
nonisolated enum PhotoSaveError: Error, Hashable, Sendable {
    case accessDenied
    case failed(String)

    var message: String {
        switch self {
        case .accessDenied:
            String(localized: "Video Compressor doesn't have permission to add videos to your photo library. You can allow it in Settings.", bundle: L10n.bundle)
        case .failed(let reason):
            String(localized: "The video couldn't be saved. \(reason)", bundle: L10n.bundle)
        }
    }
}
