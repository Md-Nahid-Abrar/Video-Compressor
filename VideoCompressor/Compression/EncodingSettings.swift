import Foundation

/// Concrete encoder parameters derived from a video and a preset.
nonisolated struct EncodingSettings: Hashable, Sendable {
    /// Encoded width in pixels, before rotation. Always even.
    var width: Int
    /// Encoded height in pixels, before rotation. Always even.
    var height: Int
    var frameRate: Double
    /// When set, source frames are dropped so the output keeps this many frames per second.
    var frameRateCap: Double?
    /// Video bitrate in bits per second.
    var videoBitrate: Int
    /// Audio bitrate in bits per second, or `nil` when the source has no audio.
    var audioBitrate: Int?
    var audioChannelCount: Int
    var audioSampleRate: Double
    var isHDR: Bool
    var colorPrimaries: String?
    var transferFunction: String?
    var yCbCrMatrix: String?

    static let minimumVideoBitrate = 150_000.0

    static func make(for metadata: VideoMetadata, preset: CompressionPreset) -> EncodingSettings {
        // Resolution: scale down so the longest edge fits, never up.
        let longEdge = Double(max(metadata.pixelWidth, metadata.pixelHeight))
        var scale = 1.0
        if let maxLongEdge = preset.maxLongEdge, longEdge > Double(maxLongEdge) {
            scale = Double(maxLongEdge) / longEdge
        }
        let width = evenDimension(Double(metadata.pixelWidth) * scale)
        let height = evenDimension(Double(metadata.pixelHeight) * scale)

        // Frame rate: cap only when the source is meaningfully faster.
        let sourceFrameRate = metadata.frameRate > 0 ? metadata.frameRate : 30
        let needsCap = sourceFrameRate > preset.maxFrameRate * 1.1
        let frameRate = needsCap ? preset.maxFrameRate : sourceFrameRate

        // Bitrate: quality target, bounded by a share of the source so the result is always smaller.
        let target = preset.bitsPerPixel * Double(width * height) * frameRate
        let sourceBitrate = metadata.effectiveVideoBitrate
        var bitrate = target
        if sourceBitrate > 0 {
            bitrate = min(target, sourceBitrate * preset.sourceBitrateCap)
            bitrate = max(bitrate, min(minimumVideoBitrate, sourceBitrate * 0.9))
        }

        var audioBitrate: Int?
        var channels = 0
        var sampleRate = 44_100.0
        if let audio = metadata.audio {
            channels = min(max(audio.channelCount, 1), 2)
            audioBitrate = preset.audioBitratePerChannel * channels
            sampleRate = audio.sampleRate == 48_000 ? 48_000 : 44_100
        }

        return EncodingSettings(
            width: width,
            height: height,
            frameRate: frameRate,
            frameRateCap: needsCap ? preset.maxFrameRate : nil,
            videoBitrate: Int(bitrate.rounded()),
            audioBitrate: audioBitrate,
            audioChannelCount: channels,
            audioSampleRate: sampleRate,
            isHDR: metadata.isHDR,
            colorPrimaries: metadata.colorPrimaries,
            transferFunction: metadata.transferFunction,
            yCbCrMatrix: metadata.yCbCrMatrix
        )
    }

    private static func evenDimension(_ value: Double) -> Int {
        max(2, Int((value / 2).rounded()) * 2)
    }
}
