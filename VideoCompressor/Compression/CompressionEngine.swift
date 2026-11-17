import Foundation

/// The available ways of compressing a video. Both produce HEVC in an MP4 file from the same settings.
nonisolated enum CompressionEngine: String, CaseIterable, Sendable {
    /// The embedded FFmpeg library, driven by a command line.
    case ffmpeg
    /// Apple's AVFoundation reader and writer.
    case avFoundation

    func makeCompressor() -> any VideoCompressing {
        switch self {
        case .ffmpeg: FFmpegCompressor()
        case .avFoundation: VideoCompressor()
        }
    }
}
