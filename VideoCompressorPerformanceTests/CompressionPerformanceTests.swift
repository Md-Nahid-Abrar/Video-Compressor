import XCTest
@testable import VideoCompressor

/// Measures the real encoder's speed, CPU and memory on a bundled clip.
final class CompressionPerformanceTests: XCTestCase {
    private var fixtureURL: URL {
        Bundle(for: Self.self).url(forResource: "Fixture", withExtension: "mov")!
    }

    func testCompressionPerformance() async throws {
        let source = fixtureURL
        let metadata = try await VideoInspector().inspect(url: source)
        let settings = EncodingSettings.make(for: metadata, preset: .medium)
        let options = XCTMeasureOptions()
        options.iterationCount = 5

        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()], options: options) {
            let finished = expectation(description: "compression finished")
            Task.detached {
                do {
                    let destination = try TemporaryFiles.makeExportURL()
                    _ = try await VideoCompressor().compress(
                        source: source,
                        destination: destination,
                        settings: settings,
                        progress: { _ in }
                    )
                    TemporaryFiles.remove(destination)
                } catch {
                    XCTFail("Compression failed: \(error)")
                }
                finished.fulfill()
            }
            wait(for: [finished], timeout: 60)
        }
    }

    func testSizeEstimationPerformance() {
        let metadata = VideoMetadata(
            duration: 600, pixelWidth: 3840, pixelHeight: 2160, isRotated: false, frameRate: 60,
            videoBitrate: 50_000_000, codec: "hvc1", containerExtension: "mov", fileSize: 3_750_000_000,
            audio: AudioInfo(channelCount: 2, sampleRate: 48_000, bitrate: 192_000), isHDR: false,
            hasProtectedContent: false
        )
        measure {
            for _ in 0..<10_000 {
                for preset in CompressionPreset.allCases {
                    _ = SizeEstimator.estimate(for: metadata, preset: preset)
                }
            }
        }
    }
}
