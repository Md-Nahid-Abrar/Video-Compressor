import SwiftUI

/// Which of the two videos to play full screen.
enum PlaybackChoice: String, Identifiable {
    case original
    case compressed

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .original: "Original Video"
        case .compressed: "Compressed Video"
        }
    }
}
