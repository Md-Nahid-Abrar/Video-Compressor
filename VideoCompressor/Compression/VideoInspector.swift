import AVFoundation
import CoreGraphics
import Foundation

/// Reads video properties with AVFoundation.
nonisolated struct VideoInspector: VideoInspecting {
    @concurrent
    func inspect(url: URL) async throws(CompressionError) -> VideoMetadata {
        do {
            return try await load(url: url)
        } catch let error as CompressionError {
            throw error
        } catch {
            throw .unreadable
        }
    }

    @concurrent
    func thumbnail(for url: URL) async -> CGImage? {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 480, height: 480)
        return try? await generator.image(at: .zero).image
    }

    private func load(url: URL) async throws -> VideoMetadata {
        let asset = AVURLAsset(url: url)
        let (duration, isProtected) = try await asset.load(.duration, .hasProtectedContent)
        let fileSize = Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        let creationDate = try? await asset.load(.creationDate)?.load(.dateValue)

        var metadata = VideoMetadata(
            duration: duration.seconds.isFinite ? duration.seconds : 0,
            pixelWidth: 0,
            pixelHeight: 0,
            isRotated: false,
            frameRate: 0,
            videoBitrate: 0,
            codec: "",
            containerExtension: url.pathExtension.lowercased(),
            fileSize: fileSize,
            audio: nil,
            isHDR: false,
            hasProtectedContent: isProtected,
            creationDate: creationDate
        )

        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            return metadata
        }
        let (size, transform, frameRate, bitrate, descriptions) = try await track.load(
            .naturalSize, .preferredTransform, .nominalFrameRate, .estimatedDataRate, .formatDescriptions
        )
        metadata.pixelWidth = Int(abs(size.width).rounded())
        metadata.pixelHeight = Int(abs(size.height).rounded())
        metadata.isRotated = abs(transform.b) == 1 && abs(transform.c) == 1
        metadata.frameRate = Double(frameRate)
        metadata.videoBitrate = Double(bitrate)

        if let description = descriptions.first {
            metadata.codec = description.mediaSubType.description.trimmingCharacters(in: CharacterSet(charactersIn: "'"))
            let extensions = description.extensions
            metadata.colorPrimaries = extensions[.colorPrimaries]?.propertyListRepresentation as? String
            metadata.transferFunction = extensions[.transferFunction]?.propertyListRepresentation as? String
            metadata.yCbCrMatrix = extensions[.yCbCrMatrix]?.propertyListRepresentation as? String
        }
        let characteristics = try await track.load(.mediaCharacteristics)
        metadata.isHDR = characteristics.contains(.containsHDRVideo)

        if let audioTrack = try await asset.loadTracks(withMediaType: .audio).first {
            let (audioBitrate, audioDescriptions) = try await audioTrack.load(.estimatedDataRate, .formatDescriptions)
            let stream = audioDescriptions.first?.audioStreamBasicDescription
            metadata.audio = AudioInfo(
                channelCount: Int(stream?.mChannelsPerFrame ?? 2),
                sampleRate: stream?.mSampleRate ?? 44_100,
                bitrate: Double(audioBitrate)
            )
        }
        return metadata
    }
}
