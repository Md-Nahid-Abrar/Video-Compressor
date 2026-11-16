import Foundation

/// Accepts only Apple-standard containers and codecs.
nonisolated enum FormatValidator {
    static let supportedContainers: Set<String> = ["mp4", "mov", "m4v"]
    /// H.264 (avc1, avc3), HEVC (hvc1, hev1) and Dolby Vision HEVC (dvh1, dvhe).
    static let supportedCodecs: Set<String> = ["avc1", "avc3", "hvc1", "hev1", "dvh1", "dvhe"]

    static func validate(_ metadata: VideoMetadata) -> FormatRejection? {
        validate(
            containerExtension: metadata.containerExtension,
            codec: metadata.codec,
            hasProtectedContent: metadata.hasProtectedContent
        )
    }

    static func validate(containerExtension: String, codec: String?, hasProtectedContent: Bool = false) -> FormatRejection? {
        if hasProtectedContent { return .protectedContent }
        let ext = containerExtension.lowercased()
        guard supportedContainers.contains(ext) else { return .unsupportedContainer(ext) }
        guard let codec, !codec.isEmpty else { return .noVideoTrack }
        guard supportedCodecs.contains(codec.lowercased()) else { return .unsupportedCodec(codec) }
        return nil
    }
}
