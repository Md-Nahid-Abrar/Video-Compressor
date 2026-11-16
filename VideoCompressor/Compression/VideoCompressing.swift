import Foundation

/// Compresses a video file.
nonisolated protocol VideoCompressing: Sendable {
    /// - Parameter progress: Called off the main actor with a value from 0 to 1.
    func compress(
        source: URL,
        destination: URL,
        settings: EncodingSettings,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws(CompressionError) -> CompressionResult
}
