import CoreGraphics
import Foundation

/// Reads a video file's properties.
nonisolated protocol VideoInspecting: Sendable {
    func inspect(url: URL) async throws(CompressionError) -> VideoMetadata
    func thumbnail(for url: URL) async -> CGImage?
}
