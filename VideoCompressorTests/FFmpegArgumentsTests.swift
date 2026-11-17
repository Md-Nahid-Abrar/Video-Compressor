import Foundation
import Testing
@testable import VideoCompressor

struct FFmpegArgumentsTests {
    private let source = URL(fileURLWithPath: "/tmp/in put.mov")
    private let destination = URL(fileURLWithPath: "/tmp/out.mp4")
    private let progressFile = URL(fileURLWithPath: "/tmp/progress.txt")

    private func arguments(_ metadata: VideoMetadata, _ preset: CompressionPreset) -> [String] {
        FFmpegArguments.make(
            source: source,
            destination: destination,
            settings: .make(for: metadata, preset: preset),
            progressFile: progressFile
        )
    }

    /// The value following a flag, such as "-b:v".
    private func value(_ flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
        return arguments[index + 1]
    }

    @Test func mediumPresetProducesExpectedCommand() {
        let metadata = Fixtures.metadata()
        let settings = EncodingSettings.make(for: metadata, preset: .medium)
        let args = arguments(metadata, .medium)

        #expect(args.first == "ffmpeg")
        #expect(args.last == "/tmp/out.mp4")
        #expect(value("-i", in: args) == "/tmp/in put.mov")
        #expect(value("-c:v", in: args) == "hevc_videotoolbox")
        #expect(value("-b:v", in: args) == String(settings.videoBitrate))
        #expect(value("-vf", in: args) == "scale=1920:1080:flags=bicubic,fps=30")
        #expect(value("-profile:v", in: args) == "main")
        #expect(value("-pix_fmt", in: args) == "nv12")
        #expect(value("-g", in: args) == "60")
        #expect(value("-tag:v", in: args) == "hvc1")
        #expect(value("-c:a", in: args) == "aac")
        #expect(value("-b:a", in: args) == "128000")
        #expect(value("-ac", in: args) == "2")
        #expect(value("-ar", in: args) == "48000")
        #expect(value("-progress", in: args) == "/tmp/progress.txt")
        #expect(!args.contains("-noautorotate"))
        #expect(args.contains("-nostdin"))
    }

    @Test(arguments: [
        (CompressionPreset.low, "scale=3840:2160:flags=bicubic"),
        (CompressionPreset.medium, "scale=1920:1080:flags=bicubic,fps=30"),
        (CompressionPreset.high, "scale=1280:720:flags=bicubic,fps=30")
    ])
    func filtersFollowPreset(preset: CompressionPreset, filters: String) {
        #expect(value("-vf", in: arguments(Fixtures.metadata(), preset)) == filters)
    }

    @Test func rotatedSourceIsScaledAsDisplayed() {
        var metadata = Fixtures.metadata()
        metadata.isRotated = true
        let args = arguments(metadata, .high)
        #expect(value("-vf", in: args) == "scale=720:1280:flags=bicubic,fps=30")
    }

    @Test func noFrameRateFilterWhenSourceIsAlreadySlowEnough() {
        let args = arguments(Fixtures.metadata(frameRate: 24), .high)
        #expect(value("-vf", in: args) == "scale=1280:720:flags=bicubic")
        #expect(value("-g", in: args) == "48")
    }

    @Test func videoWithoutAudioMapsNoAudio() {
        let args = arguments(Fixtures.metadata(audio: nil), .medium)
        #expect(args.filter { $0 == "-map" }.count == 1)
        #expect(!args.contains("-c:a"))
        #expect(!args.contains("0:a:0"))
    }

    @Test func hdrUsesTenBitAndKeepsColorTags() {
        var metadata = Fixtures.metadata(isHDR: true)
        metadata.colorPrimaries = "ITU_R_2020"
        metadata.transferFunction = "ITU_R_2100_HLG"
        metadata.yCbCrMatrix = "ITU_R_2020"
        let args = arguments(metadata, .low)

        #expect(value("-profile:v", in: args) == "main10")
        #expect(value("-pix_fmt", in: args) == "p010le")
        #expect(value("-color_primaries", in: args) == "bt2020")
        #expect(value("-color_trc", in: args) == "arib-std-b67")
        #expect(value("-colorspace", in: args) == "bt2020nc")
    }

    @Test func unknownColorTagsAreLeftToFFmpeg() {
        var metadata = Fixtures.metadata()
        metadata.colorPrimaries = "SomethingNew"
        let args = arguments(metadata, .medium)
        #expect(!args.contains("-color_primaries"))
    }

    @Test func progressReportParsing() {
        let report = """
        frame=30
        out_time_us=1000000
        progress=continue
        frame=75
        out_time_us=2500000
        out_time=00:00:02.500000
        progress=continue

        """
        #expect(FFmpegCompressor.position(inProgressReport: report) == 2.5)
        #expect(FFmpegCompressor.position(inProgressReport: "frame=1\n") == nil)
        #expect(FFmpegCompressor.position(inProgressReport: "out_time_us=N/A\n") == nil)
    }

    @Test func errorsAreMappedFromFFmpegLog() {
        #expect(FFmpegCompressor.error(from: "av_interleaved_write_frame(): No space left on device\n") == .insufficientSpace)
        #expect(FFmpegCompressor.error(from: "Stream map '0:v:0' matches no streams.\n") == .noVideoTrack)
        #expect(FFmpegCompressor.error(from: "first\nsomething odd happened\n") == .failed("something odd happened"))
    }
}
