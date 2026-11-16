import Foundation
import Testing
@testable import VideoCompressor

struct HomeViewModelTests {
    private let sampleURL = URL(fileURLWithPath: "/tmp/does-not-matter.mov")

    @Test func presetsAreDisabledBeforeSelection() {
        let viewModel = HomeViewModel(services: TestServices().make())
        #expect(!viewModel.presetsEnabled)
        viewModel.choose(.medium)
        #expect(viewModel.selectedPreset == nil)
        #expect(viewModel.exportRequest == nil)
        #expect(viewModel.currentEstimate == nil)
    }

    @Test func withoutSampleProviderOpensPicker() {
        let viewModel = HomeViewModel(services: TestServices().make())
        viewModel.selectVideoTapped()
        #expect(viewModel.isPickerPresented)
    }

    @Test func loadingAVideoEnablesPresetsAndEstimates() async {
        let url = sampleURL
        let viewModel = HomeViewModel(services: TestServices().make(sample: { url }))
        viewModel.selectVideoTapped()
        await waitUntil { viewModel.selection != nil }

        #expect(viewModel.presetsEnabled)
        #expect(viewModel.alert == nil)

        viewModel.choose(.medium)
        let medium = viewModel.currentEstimate
        viewModel.choose(.high)
        let high = viewModel.currentEstimate
        #expect(medium != nil)
        #expect(high != nil)
        #expect(medium!.estimatedBytes > high!.estimatedBytes)
        #expect(viewModel.exportRequest?.preset == .high)

        viewModel.clearPreset()
        #expect(viewModel.selectedPreset == nil)
        #expect(viewModel.exportRequest == nil)
    }

    @Test func unsupportedFormatIsRejected() async {
        let url = sampleURL
        let services = TestServices().make(metadata: Fixtures.metadata(codec: "apcn"), sample: { url })
        let viewModel = HomeViewModel(services: services)
        viewModel.selectVideoTapped()
        await waitUntil { viewModel.alert != nil }

        #expect(viewModel.alert == .rejected(.unsupportedCodec("apcn")))
        #expect(viewModel.selection == nil)
        #expect(!viewModel.presetsEnabled)
    }

    @Test func loadFailureShowsAlert() async {
        let services = TestServices().make(sample: { throw CompressionError.unreadable })
        let viewModel = HomeViewModel(services: services)
        viewModel.selectVideoTapped()
        await waitUntil { viewModel.alert != nil }

        #expect(viewModel.alert == .loadFailed(CompressionError.unreadable.message))
        #expect(!viewModel.isLoading)
    }
}
