import AVFoundation
import UIKit

/// A view backed by an `AVPlayerLayer`. SwiftUI has no control-free video surface, so this is UIKit.
final class PlayerUIView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    var playerLayer: AVPlayerLayer {
        // The layer class is fixed above, so this cast always succeeds.
        layer as! AVPlayerLayer
    }
}
