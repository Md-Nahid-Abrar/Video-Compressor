import Foundation
import Testing
@testable import VideoCompressor

/// Runs the real encoder on a small bundled clip (640×360, 30 fps, H.264 + AAC, 2 s).
struct VideoCompressorIntegrationTests {
    @Test func inspectorReadsFixture() async throws {
        let metadata = try await VideoInspector().inspect(url: Fixtures.movieURL)
        #expect(metadata.pixelWidth == 640)
        #expect(metadata.pixelHeight == 360)
        #expect(metadata.codec == "avc1")
        #expect(metadata.containerExtension == "mov")
        #expect(abs(metadata.duration - 2) < 0.2)
        #expect(abs(metadata.frameRate - 30) < 1)
        #expect(metadata.audio?.channelCount == 2)
        #expect(FormatValidator.validate(metadata) == nil)
    }

    @Test(arguments: CompressionEngine.allCases, CompressionPreset.allCases)
    func compressesToSmallerHEVC(engine: CompressionEngine, preset: CompressionPreset) async throws {
        let source = Fixtures.movieURL
        let inspector = VideoInspector()
        let metadata = try await inspector.inspect(url: source)
        let settings = EncodingSettings.make(for: metadata, preset: preset)
        let destination = try TemporaryFiles.makeExportURL()
        defer { TemporaryFiles.remove(destination) }

        let result = try await engine.makeCompressor().compress(
            source: source,
            destination: destination,
            settings: settings,
            progress: { _ in }
        )

        #expect(result.compressedBytes > 0)
        #expect(result.compressedBytes < result.originalBytes)

        let output = try await inspector.inspect(url: destination)
        #expect(output.codec == "hvc1")
        #expect(output.containerExtension == "mp4")
        #expect(output.pixelWidth == settings.width)
        #expect(output.pixelHeight == settings.height)
        #expect(abs(output.duration - metadata.duration) < 0.2)
        #expect(output.audio != nil)
        #expect(FormatValidator.validate(output) == nil)
    }

    @Test(arguments: CompressionEngine.allCases)
    func frameRateCapHalvesFrames(engine: CompressionEngine) async throws {
        let source = try await SampleVideoFactory.makeClip(width: 640, height: 360, frameRate: 60, seconds: 1)
        defer { TemporaryFiles.remove(source) }
        let inspector = VideoInspector()
        let metadata = try await inspector.inspect(url: source)
        #expect(abs(metadata.frameRate - 60) < 1)

        let settings = EncodingSettings.make(for: metadata, preset: .medium)
        #expect(settings.frameRateCap == 30)
        let destination = try TemporaryFiles.makeExportURL()
        defer { TemporaryFiles.remove(destination) }
        _ = try await engine.makeCompressor().compress(source: source, destination: destination, settings: settings, progress: { _ in })

        let output = try await inspector.inspect(url: destination)
        #expect(abs(output.frameRate - 30) < 1.5)
    }

    /// Portrait iPhone videos are stored sideways with a rotation flag. AVFoundation keeps the flag;
    /// FFmpeg turns the picture upright. Either way the result must display the same as the source.
    @Test(arguments: CompressionEngine.allCases)
    func rotatedVideoKeepsItsOrientation(engine: CompressionEngine) async throws {
        let source = Fixtures.rotatedMovieURL
        let inspector = VideoInspector()
        let metadata = try await inspector.inspect(url: source)
        #expect(metadata.isRotated)
        #expect(metadata.displaySize == CGSize(width: 360, height: 640))

        let destination = try TemporaryFiles.makeExportURL()
        defer { TemporaryFiles.remove(destination) }
        _ = try await engine.makeCompressor().compress(
            source: source,
            destination: destination,
            settings: .make(for: metadata, preset: .medium),
            progress: { _ in }
        )

        let output = try await inspector.inspect(url: destination)
        #expect(output.displaySize == metadata.displaySize)
    }

    @Test(arguments: CompressionEngine.allCases)
    func missingFileFails(engine: CompressionEngine) async {
        let destination = URL(fileURLWithPath: NSTemporaryDirectory()).appending(path: "out-\(UUID().uuidString).mp4")
        await #expect(throws: CompressionError.self) {
            try await engine.makeCompressor().compress(
                source: URL(fileURLWithPath: "/nonexistent/video.mov"),
                destination: destination,
                settings: .make(for: Fixtures.metadata(), preset: .medium),
                progress: { _ in }
            )
        }
    }
}
