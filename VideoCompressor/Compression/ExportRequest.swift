import Foundation

/// A video and the settings chosen for compressing it.
nonisolated struct ExportRequest: Hashable, Sendable {
    var sourceURL: URL
    var metadata: VideoMetadata
    var preset: CompressionPreset
    var settings: EncodingSettings

    init(sourceURL: URL, metadata: VideoMetadata, preset: CompressionPreset) {
        self.sourceURL = sourceURL
        self.metadata = metadata
        self.preset = preset
        self.settings = .make(for: metadata, preset: preset)
    }
}
