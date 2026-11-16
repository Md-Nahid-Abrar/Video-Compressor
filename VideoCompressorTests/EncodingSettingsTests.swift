import Testing
@testable import VideoCompressor

struct EncodingSettingsTests {
    @Test(arguments: [
        (CompressionPreset.low, 3840, 2160, 60.0),
        (CompressionPreset.medium, 1920, 1080, 30.0),
        (CompressionPreset.high, 1280, 720, 30.0)
    ])
    func resolutionAndFrameRateFollowPreset(preset: CompressionPreset, width: Int, height: Int, frameRate: Double) {
        let settings = EncodingSettings.make(for: Fixtures.metadata(), preset: preset)
        #expect(settings.width == width)
        #expect(settings.height == height)
        #expect(settings.frameRate == frameRate)
    }

    @Test func neverUpscalesSmallVideo() {
        let metadata = Fixtures.metadata(width: 640, height: 360, frameRate: 24, videoBitrate: 2_000_000)
        let settings = EncodingSettings.make(for: metadata, preset: .low)
        #expect(settings.width == 640)
        #expect(settings.height == 360)
        #expect(settings.frameRate == 24)
        #expect(settings.frameRateCap == nil)
    }

    @Test func portraitVideoScalesByLongEdge() {
        let metadata = Fixtures.metadata(width: 2160, height: 3840)
        let settings = EncodingSettings.make(for: metadata, preset: .high)
        #expect(settings.width == 720)
        #expect(settings.height == 1280)
    }

    @Test func dimensionsAreAlwaysEven() {
        let metadata = Fixtures.metadata(width: 1921, height: 1081)
        for preset in CompressionPreset.allCases {
            let settings = EncodingSettings.make(for: metadata, preset: preset)
            #expect(settings.width.isMultiple(of: 2))
            #expect(settings.height.isMultiple(of: 2))
        }
    }

    @Test(arguments: CompressionPreset.allCases)
    func bitrateStaysBelowSource(preset: CompressionPreset) {
        for bitrate in [300_000.0, 2_000_000, 50_000_000] {
            let metadata = Fixtures.metadata(videoBitrate: bitrate)
            let settings = EncodingSettings.make(for: metadata, preset: preset)
            #expect(Double(settings.videoBitrate) < bitrate)
        }
    }

    @Test func strongerPresetsUseLowerBitrate() {
        let metadata = Fixtures.metadata()
        let low = EncodingSettings.make(for: metadata, preset: .low).videoBitrate
        let medium = EncodingSettings.make(for: metadata, preset: .medium).videoBitrate
        let high = EncodingSettings.make(for: metadata, preset: .high).videoBitrate
        #expect(low > medium)
        #expect(medium > high)
    }

    @Test func frameRateCapOnlyWhenSourceIsFaster() {
        let fast = EncodingSettings.make(for: Fixtures.metadata(frameRate: 60), preset: .medium)
        let normal = EncodingSettings.make(for: Fixtures.metadata(frameRate: 29.97), preset: .medium)
        #expect(fast.frameRateCap == 30)
        #expect(normal.frameRateCap == nil)
    }

    @Test func audioSettingsFollowSource() {
        let stereo = EncodingSettings.make(for: Fixtures.metadata(), preset: .medium)
        #expect(stereo.audioBitrate == 128_000)
        #expect(stereo.audioChannelCount == 2)
        #expect(stereo.audioSampleRate == 48_000)

        let silent = EncodingSettings.make(for: Fixtures.metadata(audio: nil), preset: .medium)
        #expect(silent.audioBitrate == nil)

        let surround = Fixtures.metadata(audio: AudioInfo(channelCount: 6, sampleRate: 44_100, bitrate: 384_000))
        #expect(EncodingSettings.make(for: surround, preset: .high).audioChannelCount == 2)
        #expect(EncodingSettings.make(for: surround, preset: .high).audioBitrate == 96_000)
    }

    @Test func hdrIsCarriedThrough() {
        let settings = EncodingSettings.make(for: Fixtures.metadata(isHDR: true), preset: .medium)
        #expect(settings.isHDR)
    }
}
