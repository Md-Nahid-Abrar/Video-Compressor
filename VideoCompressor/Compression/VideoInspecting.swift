import CoreGraphics
import Foundation

/// Reads a video file's properties.
nonisolated protocol VideoInspecting: Sendable {
    func inspect(url: URL) async throws(CompressionError) -> VideoMetadata
    /// Evenly spaced frames from the start of the video, for an animated preview.
    func previewFrames(for url: URL, duration: Double) async -> [CGImage]
}
