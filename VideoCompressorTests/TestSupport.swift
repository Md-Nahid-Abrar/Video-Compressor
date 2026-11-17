import CoreGraphics
import Foundation
@testable import VideoCompressor

final class BundleToken {}

enum Fixtures {
    static var movieURL: URL {
        Bundle(for: BundleToken.self).url(forResource: "Fixture", withExtension: "mov")!
    }

    /// A 60-second 4K, 60 fps, 50 Mbps H.264 video with stereo audio.
    static func metadata(
        duration: Double = 60,
        width: Int = 3840,
        height: Int = 2160,
        frameRate: Double = 60,
        videoBitrate: Double = 50_000_000,
        codec: String = "avc1",
        container: String = "mov",
        audio: AudioInfo? = AudioInfo(channelCount: 2, sampleRate: 48_000, bitrate: 192_000),
        isHDR: Bool = false
    ) -> VideoMetadata {
        let bits = (videoBitrate + (audio?.bitrate ?? 0)) * duration
        return VideoMetadata(
            duration: duration,
            pixelWidth: width,
            pixelHeight: height,
            isRotated: false,
            frameRate: frameRate,
            videoBitrate: videoBitrate,
            codec: codec,
            containerExtension: container,
            fileSize: Int64(bits / 8),
            audio: audio,
            isHDR: isHDR,
            hasProtectedContent: false
        )
    }
}

nonisolated struct FakeInspector: VideoInspecting {
    var metadata: VideoMetadata

    func inspect(url: URL) async throws(CompressionError) -> VideoMetadata { metadata }
    func previewFrames(for url: URL, duration: Double) async -> [CGImage] { [] }
}

nonisolated struct FakeCompressor: VideoCompressing {
    var outcome: Result<Int64, CompressionError>

    func compress(
        source: URL,
        destination: URL,
        settings: EncodingSettings,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws(CompressionError) -> CompressionResult {
        progress(0.5)
        let bytes = try outcome.get()
        return CompressionResult(outputURL: destination, originalBytes: 100, compressedBytes: bytes)
    }
}

nonisolated final class FakePhotoSaver: PhotoLibrarySaving, @unchecked Sendable {
    var error: PhotoSaveError?
    private(set) var savedURLs: [URL] = []

    func saveVideo(at url: URL, creationDate: Date?) async throws(PhotoSaveError) {
        if let error { throw error }
        savedURLs.append(url)
    }
}

nonisolated final class FakeNotifier: CompletionNotifying, @unchecked Sendable {
    private(set) var completedCount = 0

    func requestAuthorization() async {}
    func notifyCompleted() async { completedCount += 1 }
}

final class FakeBackground: BackgroundExporting {
    var allowsBackground = true
    private(set) var endedWith: [Bool] = []
    private(set) var lastProgress = 0.0

    func begin(title: String, subtitle: String, onExpire: @escaping () -> Void) -> Bool { allowsBackground }
    func update(progress: Double) { lastProgress = progress }
    func end(success: Bool) { endedWith.append(success) }
}

struct TestServices {
    let saver = FakePhotoSaver()
    let notifier = FakeNotifier()
    let background = FakeBackground()

    func make(
        compressor: any VideoCompressing = FakeCompressor(outcome: .success(40)),
        metadata: VideoMetadata = Fixtures.metadata(),
        sample: (@Sendable () async throws -> URL)? = nil
    ) -> AppServices {
        AppServices(
            compressor: compressor,
            inspector: FakeInspector(metadata: metadata),
            photoSaver: saver,
            notifier: notifier,
            background: background,
            defaults: UserDefaults(suiteName: "tests-\(UUID().uuidString)")!,
            sampleVideoProvider: sample
        )
    }
}

/// Polls until `condition` is true or the timeout passes.
func waitUntil(timeout: Duration = .seconds(10), _ condition: () -> Bool) async {
    let deadline = ContinuousClock.now + timeout
    while !condition(), ContinuousClock.now < deadline {
        try? await Task.sleep(for: .milliseconds(20))
    }
}
