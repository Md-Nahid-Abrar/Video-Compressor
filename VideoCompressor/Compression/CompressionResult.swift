import Foundation

/// A finished compression.
nonisolated struct CompressionResult: Hashable, Sendable {
    var outputURL: URL
    var originalBytes: Int64
    var compressedBytes: Int64

    var reduction: Double {
        guard originalBytes > 0 else { return 0 }
        return 1 - Double(compressedBytes) / Double(originalBytes)
    }
}
