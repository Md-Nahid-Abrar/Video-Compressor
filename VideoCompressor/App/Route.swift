import Foundation

/// Destinations pushed onto the main navigation stack.
nonisolated enum Route: Hashable, Sendable {
    case settings
    case profile
    case export(ExportRequest)
}
