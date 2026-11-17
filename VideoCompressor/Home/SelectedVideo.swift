import CoreGraphics
import Foundation

/// The video currently loaded on the home screen.
struct SelectedVideo {
    var url: URL
    var metadata: VideoMetadata
    /// Frames cycled to make the animated preview.
    var frames: [CGImage]
}
