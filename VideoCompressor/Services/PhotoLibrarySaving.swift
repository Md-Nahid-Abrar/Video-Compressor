import Foundation

/// Adds a video file to the user's photo library.
nonisolated protocol PhotoLibrarySaving: Sendable {
    func saveVideo(at url: URL, creationDate: Date?) async throws(PhotoSaveError)
}
