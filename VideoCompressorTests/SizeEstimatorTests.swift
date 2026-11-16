import Testing
@testable import VideoCompressor

struct SizeEstimatorTests {
    @Test func estimatesDifferPerPresetAndStayOrdered() {
        let metadata = Fixtures.metadata()
        let low = SizeEstimator.estimate(for: metadata, preset: .low).estimatedBytes
        let medium = SizeEstimator.estimate(for: metadata, preset: .medium).estimatedBytes
        let high = SizeEstimator.estimate(for: metadata, preset: .high).estimatedBytes
        #expect(metadata.fileSize > low)
        #expect(low > medium)
        #expect(medium > high)
        #expect(high > 0)
    }

    @Test func estimateMatchesBitrateTimesDuration() {
        let metadata = Fixtures.metadata(duration: 10)
        let settings = EncodingSettings.make(for: metadata, preset: .medium)
        let expected = Double(settings.videoBitrate + 128_000) * 10 / 8 * SizeEstimator.containerOverhead
        let estimate = SizeEstimator.estimate(for: metadata, settings: settings)
        #expect(abs(Double(estimate.estimatedBytes) - expected) < 2)
    }

    @Test(arguments: CompressionPreset.allCases)
    func neverLargerThanOriginal(preset: CompressionPreset) {
        // A tiny, already heavily compressed video.
        let metadata = Fixtures.metadata(width: 320, height: 240, frameRate: 15, videoBitrate: 80_000)
        let estimate = SizeEstimator.estimate(for: metadata, preset: preset)
        #expect(estimate.estimatedBytes < metadata.fileSize)
        #expect(estimate.reduction > 0)
    }

    @Test func reductionIsAFraction() {
        let estimate = SizeEstimate(originalBytes: 50_000_000, estimatedBytes: 25_000_000)
        #expect(estimate.reduction == 0.5)
        #expect(SizeEstimate(originalBytes: 0, estimatedBytes: 0).reduction == 0)
    }
}
