import Foundation

/// Static app-wide configuration values.
nonisolated enum AppConfig {
    /// Support contact shown in Settings. Replace with a monitored address before App Store submission.
    static let supportEmail = "developer@gmail.com"

    /// Address that receives feedback written in Settings.
    static let feedbackEmail = "covidcovid1919covid19@gmail.com"

    /// The exact FFmpeg release this app's video library is built from.
    static let ffmpegSourceURL = URL(string: "https://ffmpeg.org/releases/ffmpeg-8.1.tar.xz")!

    static let privacyPolicyURL = URL(
        string: "https://docs.google.com/document/d/1ntlLtSBznjH6qx9PDYXyawEXYGedE_y5Ir8DwoxZcpY/edit?usp=sharing"
    )!

    /// Which engine compresses video. Change to `.avFoundation` to use Apple's frameworks instead of FFmpeg.
    static let compressionEngine: CompressionEngine = .ffmpeg

    static var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Video Compressor"
    }

    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    /// Prefix for continued-processing task identifiers. Matches the wildcard entry in Info.plist.
    static var backgroundTaskPrefix: String {
        (Bundle.main.bundleIdentifier ?? "com.mdnahidabrar.VideoCompressor") + ".export."
    }
}
