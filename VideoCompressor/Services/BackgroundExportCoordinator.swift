import BackgroundTasks
import UIKit

/// Wraps `BGContinuedProcessingTask` so an export started in the foreground can finish in the background.
///
/// The export itself runs independently. This coordinator asks the system for background time, mirrors
/// progress into the system's Live Activity, and reports back if the system or user ends the task.
/// Where continued processing is unavailable (for example in the Simulator) it falls back to a short
/// background grace period.
final class BackgroundExportCoordinator: BackgroundExporting {
    private var task: BGContinuedProcessingTask?
    private var onExpire: (() -> Void)?
    private var outcome: Bool?
    private var fraction = 0.0
    private var graceTask = UIBackgroundTaskIdentifier.invalid

    private static let progressUnits: Int64 = 1000

    func begin(title: String, subtitle: String, onExpire: @escaping () -> Void) -> Bool {
        end(success: false)
        self.onExpire = onExpire
        outcome = nil
        fraction = 0

        let identifier = AppConfig.backgroundTaskPrefix + UUID().uuidString
        let registered = BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: .main) { [weak self] task in
            MainActor.assumeIsolated {
                self?.attach(task)
            }
        }
        if registered {
            let request = BGContinuedProcessingTaskRequest(identifier: identifier, title: title, subtitle: subtitle)
            request.strategy = .fail
            do {
                try BGTaskScheduler.shared.submit(request)
                return true
            } catch {
                // Fall through to the grace period below.
            }
        }

        graceTask = UIApplication.shared.beginBackgroundTask(withName: "Video export") { [weak self] in
            MainActor.assumeIsolated {
                self?.endGraceTask()
            }
        }
        return false
    }

    func update(progress: Double) {
        fraction = min(max(progress, 0), 1)
        task?.progress.completedUnitCount = Int64(fraction * Double(Self.progressUnits))
    }

    func end(success: Bool) {
        outcome = success
        task?.setTaskCompleted(success: success)
        task = nil
        onExpire = nil
        endGraceTask()
    }

    private func attach(_ newTask: BGTask) {
        guard let continued = newTask as? BGContinuedProcessingTask else {
            newTask.setTaskCompleted(success: false)
            return
        }
        // The export may already be over by the time the system launches the task.
        if let outcome {
            continued.setTaskCompleted(success: outcome)
            return
        }
        task = continued
        continued.progress.totalUnitCount = Self.progressUnits
        continued.progress.completedUnitCount = Int64(fraction * Double(Self.progressUnits))
        continued.expirationHandler = { @Sendable [weak self] in
            Task { @MainActor in
                self?.expire()
            }
        }
    }

    private func expire() {
        let handler = onExpire
        end(success: false)
        handler?()
    }

    private func endGraceTask() {
        guard graceTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(graceTask)
        graceTask = .invalid
    }
}
