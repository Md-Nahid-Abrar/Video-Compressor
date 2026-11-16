import Foundation

/// Properties of a video's first audio track.
nonisolated struct AudioInfo: Hashable, Sendable {
    var channelCount: Int
    var sampleRate: Double
    var bitrate: Double
}
