import Foundation

/// Predicts the compressed file size from the encoder settings.
nonisolated enum SizeEstimator {
    /// Allowance for the MP4 container's own bookkeeping.
    static let containerOverhead = 1.01

    static func estimate(for metadata: VideoMetadata, settings: EncodingSettings) -> SizeEstimate {
        let bitsPerSecond = Double(settings.videoBitrate + (settings.audioBitrate ?? 0))
        let bytes = bitsPerSecond * metadata.duration / 8 * containerOverhead
        // Never promise a file larger than the one the user already has.
        let capped = min(Int64(bytes.rounded()), Int64(Double(metadata.fileSize) * 0.98))
        return SizeEstimate(originalBytes: metadata.fileSize, estimatedBytes: max(capped, 0))
    }

    static func estimate(for metadata: VideoMetadata, preset: CompressionPreset) -> SizeEstimate {
        estimate(for: metadata, settings: .make(for: metadata, preset: preset))
    }
}
