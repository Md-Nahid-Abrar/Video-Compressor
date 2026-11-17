import Foundation

/// Builds the FFmpeg command line for one compression.
nonisolated enum FFmpegArguments {
    /// - Parameter progressFile: FFmpeg appends machine-readable progress reports to this file.
    static func make(
        source: URL,
        destination: URL,
        settings: EncodingSettings,
        progressFile: URL
    ) -> [String] {
        var arguments = [
            "ffmpeg",
            "-hide_banner", "-nostdin", "-y",
            "-loglevel", "warning",
            "-nostats", "-progress", progressFile.path, "-stats_period", "0.25",
            "-i", source.path,
            "-map", "0:v:0"
        ]
        if settings.audioBitrate != nil {
            arguments += ["-map", "0:a:0"]
        }
        // Location and other personal metadata are not copied into the result.
        arguments += ["-map_metadata", "-1"]

        // Video: hardware HEVC with an explicit bitrate, size, frame rate and keyframe spacing.
        // FFmpeg turns rotated sources upright before filtering, so the target size is given as displayed.
        let width = settings.isRotated ? settings.height : settings.width
        let height = settings.isRotated ? settings.width : settings.height
        var filters = ["scale=\(width):\(height):flags=bicubic"]
        if let cap = settings.frameRateCap {
            filters.append("fps=\(number(cap))")
        }
        arguments += [
            "-vf", filters.joined(separator: ","),
            "-c:v", "hevc_videotoolbox",
            // Lets the encoder fall back to software where no hardware encoder exists, such as the Simulator.
            "-allow_sw", "1",
            "-b:v", String(settings.videoBitrate),
            "-profile:v", settings.isHDR ? "main10" : "main",
            "-pix_fmt", settings.isHDR ? "p010le" : "nv12",
            "-g", String(max(Int((settings.frameRate * 2).rounded()), 1)),
            "-tag:v", "hvc1"
        ]
        if let primaries = settings.colorPrimaries.flatMap({ colorPrimaries[$0] }) {
            arguments += ["-color_primaries", primaries]
        }
        if let transfer = settings.transferFunction.flatMap({ transferFunctions[$0] }) {
            arguments += ["-color_trc", transfer]
        }
        if let matrix = settings.yCbCrMatrix.flatMap({ colorMatrices[$0] }) {
            arguments += ["-colorspace", matrix]
        }

        // Audio: AAC at the preset's bitrate.
        if let audioBitrate = settings.audioBitrate {
            arguments += [
                "-c:a", "aac",
                "-b:a", String(audioBitrate),
                "-ac", String(settings.audioChannelCount),
                "-ar", String(Int(settings.audioSampleRate))
            ]
        }

        arguments += ["-movflags", "+faststart", "-f", "mp4", destination.path]
        return arguments
    }

    private static func number(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(value)
    }

    // Apple's names for color properties, as read from the source video, mapped to FFmpeg's.
    private static let colorPrimaries = [
        "ITU_R_709_2": "bt709",
        "ITU_R_2020": "bt2020",
        "SMPTE_C": "smpte170m",
        "EBU_3213": "bt470bg",
        "P3_D65": "smpte432"
    ]

    private static let transferFunctions = [
        "ITU_R_709_2": "bt709",
        "ITU_R_2100_HLG": "arib-std-b67",
        "SMPTE_ST_2084_PQ": "smpte2084",
        "IEC_sRGB": "iec61966-2-1"
    ]

    private static let colorMatrices = [
        "ITU_R_709_2": "bt709",
        "ITU_R_601_4": "smpte170m",
        "ITU_R_2020": "bt2020nc"
    ]
}
