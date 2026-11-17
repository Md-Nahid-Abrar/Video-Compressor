import Foundation
import Testing
@testable import VideoCompressor

struct ExportViewModelTests {
    private let request = ExportRequest(
        sourceURL: URL(fileURLWithPath: "/tmp/source.mov"),
        metadata: Fixtures.metadata(duration: 1, videoBitrate: 1_000_000),
        preset: .medium
    )

    @Test func successfulExportFinishesAndNotifies() async {
        let support = TestServices()
        let viewModel = ExportViewModel(request: request, services: support.make())
        viewModel.start()
        await waitUntil { !viewModel.isCompressing }

        guard case .finished(let result) = viewModel.phase else {
            Issue.record("Expected finished, got \(viewModel.phase)")
            return
        }
        #expect(result.compressedBytes == 40)
        #expect(viewModel.progress == 1)
        #expect(viewModel.continuesInBackground)
        #expect(support.background.endedWith == [true])
        await waitUntil { support.notifier.completedCount == 1 }
        #expect(support.notifier.completedCount == 1)
    }

    @Test func failureShowsMessageAndCanRetry() async {
        let support = TestServices()
        let services = support.make(compressor: FakeCompressor(outcome: .failure(.interrupted)))
        let viewModel = ExportViewModel(request: request, services: services)
        viewModel.start()
        await waitUntil { !viewModel.isCompressing }

        #expect(viewModel.phase == .failed(CompressionError.interrupted.message))
        #expect(support.background.endedWith == [false])
        #expect(support.notifier.completedCount == 0)

        viewModel.retry()
        #expect(viewModel.isCompressing)
        await waitUntil { !viewModel.isCompressing }
        #expect(viewModel.phase == .failed(CompressionError.interrupted.message))
    }

    @Test func startIsIdempotent() async {
        let support = TestServices()
        let viewModel = ExportViewModel(request: request, services: support.make())
        viewModel.start()
        viewModel.start()
        await waitUntil { !viewModel.isCompressing }
        #expect(support.background.endedWith == [true])
    }

    @Test func foregroundOnlyModeIsReported() async {
        let support = TestServices()
        support.background.allowsBackground = false
        let viewModel = ExportViewModel(request: request, services: support.make())
        viewModel.start()
        await waitUntil { !viewModel.isCompressing }
        #expect(!viewModel.continuesInBackground)
    }

    @Test func savingToPhotos() async {
        let support = TestServices()
        let viewModel = ExportViewModel(request: request, services: support.make())
        viewModel.start()
        await waitUntil { !viewModel.isCompressing }

        await viewModel.saveToPhotos()
        #expect(viewModel.saveState == .saved)
        #expect(support.saver.savedURLs.count == 1)

        // A second tap does nothing once saved.
        await viewModel.saveToPhotos()
        #expect(support.saver.savedURLs.count == 1)
    }

    @Test func playbackUnlocksAfterSavingOrSharing() async {
        let support = TestServices()
        let saved = ExportViewModel(request: request, services: support.make())
        saved.start()
        await waitUntil { !saved.isCompressing }
        #expect(!saved.canPlayBack)
        await saved.saveToPhotos()
        #expect(saved.canPlayBack)

        let shared = ExportViewModel(request: request, services: support.make())
        shared.start()
        await waitUntil { !shared.isCompressing }
        #expect(!shared.canPlayBack)
        shared.markShared()
        #expect(shared.canPlayBack)
    }

    @Test func deniedPhotoAccessSurfacesError() async {
        let support = TestServices()
        support.saver.error = .accessDenied
        let viewModel = ExportViewModel(request: request, services: support.make())
        viewModel.start()
        await waitUntil { !viewModel.isCompressing }

        await viewModel.saveToPhotos()
        #expect(viewModel.saveState == .idle)
        #expect(viewModel.saveError == .accessDenied)
    }
}
