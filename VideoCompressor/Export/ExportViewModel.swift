import Foundation
import UIKit

/// Runs one compression and tracks its progress, result, and what the user does with it.
@Observable
final class ExportViewModel {
    enum Phase: Equatable {
        case compressing
        case finished(CompressionResult)
        case failed(String)
    }

    enum SaveState: Equatable {
        case idle
        case saving
        case saved
    }

    let request: ExportRequest
    private let services: AppServices
    private var task: Task<Void, Never>?
    private var hasStarted = false
    private var stoppedBySystem = false

    private(set) var phase: Phase = .compressing
    private(set) var progress = 0.0
    private(set) var continuesInBackground = false
    private(set) var saveState: SaveState = .idle
    var saveError: PhotoSaveError?

    init(request: ExportRequest, services: AppServices) {
        self.request = request
        self.services = services
    }

    var isCompressing: Bool {
        phase == .compressing
    }

    var isSaveErrorPresented: Bool {
        get { saveError != nil }
        set { if !newValue { saveError = nil } }
    }

    // MARK: - Compression

    /// Begins compressing. Safe to call more than once; only the first call starts work.
    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        run()
    }

    func retry() {
        guard !isCompressing else { return }
        run()
    }

    /// Stops the compression and discards any partial output.
    func cancel() {
        task?.cancel()
        task = nil
        finishSession(success: false)
    }

    private func run() {
        phase = .compressing
        progress = 0
        saveState = .idle
        stoppedBySystem = false
        task = Task { [weak self] in
            await self?.perform()
        }
    }

    private func perform() async {
        await services.notifier.requestAuthorization()
        guard !Task.isCancelled else { return }

        continuesInBackground = services.background.begin(
            title: String(localized: "Compressing video"),
            subtitle: request.preset.fullTitle,
            onExpire: { [weak self] in
                self?.stoppedBySystem = true
                self?.task?.cancel()
            }
        )
        UIApplication.shared.isIdleTimerDisabled = true

        do {
            try checkFreeSpace()
            let destination = try makeDestination()
            let result = try await services.compressor.compress(
                source: request.sourceURL,
                destination: destination,
                settings: request.settings,
                progress: { [weak self] value in
                    Task { @MainActor in
                        self?.report(value)
                    }
                }
            )
            guard !Task.isCancelled else {
                TemporaryFiles.remove(result.outputURL)
                return
            }
            progress = 1
            phase = .finished(result)
            finishSession(success: true)
            await services.notifier.notifyCompleted()
        } catch {
            if error == .cancelled {
                // A user cancel leaves the screen; only a system stop needs explaining.
                guard stoppedBySystem else { return }
                phase = .failed(String(localized: "Compression was stopped before it finished. Try again."))
            } else {
                phase = .failed(error.message)
            }
            finishSession(success: false)
        }
    }

    private func report(_ value: Double) {
        guard isCompressing, value > progress else { return }
        progress = value
        services.background.update(progress: value)
    }

    private func finishSession(success: Bool) {
        services.background.end(success: success)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func makeDestination() throws(CompressionError) -> URL {
        do {
            return try TemporaryFiles.makeExportURL()
        } catch {
            throw .failed(error.localizedDescription)
        }
    }

    /// The output is never larger than the source, so the source size is a safe requirement.
    private func checkFreeSpace() throws(CompressionError) {
        let directory = FileManager.default.temporaryDirectory
        guard let available = try? directory.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            .volumeAvailableCapacityForImportantUsage else { return }
        let required = request.metadata.fileSize + 50_000_000
        if available < required {
            throw .insufficientSpace
        }
    }

    // MARK: - Saving

    func saveToPhotos() async {
        guard case .finished(let result) = phase, saveState == .idle else { return }
        saveState = .saving
        do {
            try await services.photoSaver.saveVideo(at: result.outputURL, creationDate: request.metadata.creationDate)
            saveState = .saved
        } catch {
            saveState = .idle
            saveError = error
        }
    }
}
