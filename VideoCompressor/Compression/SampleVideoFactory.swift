#if DEBUG
import AVFoundation
import CoreVideo
import Foundation

/// Generates short clips for UI tests, unit tests and previews. Not compiled into release builds.
nonisolated enum SampleVideoFactory {
    enum Kind: Sendable {
        /// H.264 in a QuickTime movie, which the app accepts.
        case supported
        /// H.264 in a 3GP container, which the app rejects.
        case unsupportedContainer
    }

    @concurrent
    static func makeClip(
        kind: Kind = .supported,
        width: Int = 1280,
        height: Int = 720,
        frameRate: Int = 60,
        seconds: Double = 3
    ) async throws -> URL {
        let isSupported = kind == .supported
        let url = try TemporaryFiles.makeImportURL(pathExtension: isSupported ? "mov" : "3gp")
        let writer = try AVAssetWriter(outputURL: url, fileType: isSupported ? .mov : .mobile3GPP)

        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 12_000_000]
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height
            ]
        )
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? CompressionError.unreadable }
        writer.startSession(atSourceTime: .zero)

        let frameCount = Int(seconds * Double(frameRate))
        for frame in 0..<frameCount {
            while !input.isReadyForMoreMediaData {
                try await Task.sleep(for: .milliseconds(2))
            }
            guard let pool = adaptor.pixelBufferPool else { throw CompressionError.unreadable }
            var buffer: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)
            guard let buffer else { throw CompressionError.unreadable }
            fill(buffer, frame: frame)
            let time = CMTime(value: CMTimeValue(frame), timescale: CMTimeScale(frameRate))
            guard adaptor.append(buffer, withPresentationTime: time) else {
                throw writer.error ?? CompressionError.unreadable
            }
        }
        input.markAsFinished()
        await writer.finishWriting()
        guard writer.status == .completed else { throw writer.error ?? CompressionError.unreadable }
        return url
    }

    /// Paints shifting bands of noisy color so the encoder has real detail to work on.
    /// A handful of random rows are generated per frame and copied down the image, which keeps this fast.
    private static func fill(_ buffer: CVPixelBuffer, frame: Int) {
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let base = CVPixelBufferGetBaseAddress(buffer) else { return }
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let rowBytes = CVPixelBufferGetBytesPerRow(buffer)
        let patternCount = 12
        var seed = UInt32(truncatingIfNeeded: frame &* 2_654_435_761 &+ 12_345)
        var patterns = [UInt8](repeating: 255, count: patternCount * width * 4)
        for pattern in 0..<patternCount {
            let start = pattern * width * 4
            for x in 0..<width {
                seed = seed &* 1_664_525 &+ 1_013_904_223
                let noise = Int(seed >> 27)
                let offset = start + x * 4
                patterns[offset] = UInt8(truncatingIfNeeded: (x + frame * 6) / 4 + noise)
                patterns[offset + 1] = UInt8(truncatingIfNeeded: pattern * 20 + frame * 3 + noise)
                patterns[offset + 2] = UInt8(truncatingIfNeeded: x / 6 + frame * 2 + noise)
            }
        }
        patterns.withUnsafeBytes { bytes in
            guard let source = bytes.baseAddress else { return }
            for y in 0..<height {
                let pattern = (y / 8 + frame) % patternCount
                memcpy(base.advanced(by: y * rowBytes), source.advanced(by: pattern * width * 4), width * 4)
            }
        }
    }
}
#endif
