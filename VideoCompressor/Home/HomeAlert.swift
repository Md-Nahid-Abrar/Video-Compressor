import Foundation

/// Problems reported on the home screen after picking a video.
nonisolated enum HomeAlert: Hashable, Sendable {
    case rejected(FormatRejection)
    case loadFailed(String)

    var title: String {
        switch self {
        case .rejected: String(localized: "Unsupported Video")
        case .loadFailed: String(localized: "Couldn't Load Video")
        }
    }

    var message: String {
        switch self {
        case .rejected(let rejection): rejection.message
        case .loadFailed(let message): message
        }
    }
}
