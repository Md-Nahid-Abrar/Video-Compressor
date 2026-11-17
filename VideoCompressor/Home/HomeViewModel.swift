import Foundation
import PhotosUI
import SwiftUI

/// State and logic for picking a video and choosing a compression level.
@Observable
final class HomeViewModel {
    private let services: AppServices
    private var loadTask: Task<Void, Never>?

    var isPickerPresented = false
    var pickerItem: PhotosPickerItem? {
        didSet {
            guard let item = pickerItem else { return }
            load { try await item.loadTransferable(type: PickedMovie.self)?.url }
        }
    }
    var alert: HomeAlert?

    private(set) var selection: SelectedVideo?
    private(set) var isLoading = false
    private(set) var selectedPreset: CompressionPreset?

    init(services: AppServices) {
        self.services = services
    }

    // MARK: - Derived state

    var presetsEnabled: Bool {
        selection != nil && !isLoading
    }

    var isAlertPresented: Bool {
        get { alert != nil }
        set { if !newValue { alert = nil } }
    }

    func estimate(for preset: CompressionPreset) -> SizeEstimate? {
        guard let metadata = selection?.metadata else { return nil }
        return SizeEstimator.estimate(for: metadata, preset: preset)
    }

    var currentEstimate: SizeEstimate? {
        selectedPreset.flatMap(estimate(for:))
    }

    var exportRequest: ExportRequest? {
        guard let selection, let selectedPreset else { return nil }
        return ExportRequest(sourceURL: selection.url, metadata: selection.metadata, preset: selectedPreset)
    }

    // MARK: - Actions

    func selectVideoTapped() {
        if let provider = services.sampleVideoProvider {
            load { try await provider() }
        } else {
            isPickerPresented = true
        }
    }

    func choose(_ preset: CompressionPreset) {
        guard presetsEnabled else { return }
        selectedPreset = preset
    }

    func clearPreset() {
        selectedPreset = nil
    }

    func chooseAnotherVideo() {
        alert = nil
        selectVideoTapped()
    }

    // MARK: - Loading

    private func load(_ fetch: @escaping () async throws -> URL?) {
        loadTask?.cancel()
        isLoading = true
        selectedPreset = nil
        loadTask = Task { [weak self] in
            await self?.performLoad(fetch)
        }
    }

    private func performLoad(_ fetch: () async throws -> URL?) async {
        defer {
            if !Task.isCancelled {
                isLoading = false
                pickerItem = nil
            }
        }
        var importedURL: URL?
        do {
            guard let url = try await fetch() else {
                throw CompressionError.unreadable
            }
            importedURL = url
            let metadata = try await services.inspector.inspect(url: url)
            guard !Task.isCancelled else {
                TemporaryFiles.remove(url)
                return
            }
            if let rejection = FormatValidator.validate(metadata) {
                TemporaryFiles.remove(url)
                alert = .rejected(rejection)
                return
            }
            let frames = await services.inspector.previewFrames(for: url, duration: metadata.duration)
            guard !Task.isCancelled else {
                TemporaryFiles.remove(url)
                return
            }
            TemporaryFiles.remove(selection?.url)
            selection = SelectedVideo(url: url, metadata: metadata, frames: frames)
        } catch {
            TemporaryFiles.remove(importedURL)
            guard !Task.isCancelled else { return }
            let message = (error as? CompressionError)?.message ?? CompressionError.unreadable.message
            alert = .loadFailed(message)
        }
    }
}
