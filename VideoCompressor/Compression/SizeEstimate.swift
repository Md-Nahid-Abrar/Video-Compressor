import Foundation

/// The predicted outcome of compressing a video.
nonisolated struct SizeEstimate: Hashable, Sendable {
    var originalBytes: Int64
    var estimatedBytes: Int64

    /// Share of the original size that is removed, from 0 to 1.
    var reduction: Double {
        guard originalBytes > 0 else { return 0 }
        return 1 - Double(estimatedBytes) / Double(originalBytes)
    }
}
