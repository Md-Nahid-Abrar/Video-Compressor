import Foundation
import Photos

/// Saves videos with PhotoKit using add-only access.
nonisolated struct PhotoLibrarySaver: PhotoLibrarySaving {
    func saveVideo(at url: URL, creationDate: Date?) async throws(PhotoSaveError) {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw .accessDenied
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .video, fileURL: url, options: nil)
                request.creationDate = creationDate
            }
        } catch {
            throw .failed(error.localizedDescription)
        }
    }
}
