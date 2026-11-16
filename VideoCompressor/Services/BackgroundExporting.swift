import Foundation

/// Keeps an export running after the user leaves the app, when the system allows it.
protocol BackgroundExporting: AnyObject {
    /// Starts background continuation for one export.
    /// - Parameter onExpire: Called when the system or the user stops the background task.
    /// - Returns: `true` when the export can continue in the background.
    func begin(title: String, subtitle: String, onExpire: @escaping () -> Void) -> Bool
    func update(progress: Double)
    func end(success: Bool)
}
