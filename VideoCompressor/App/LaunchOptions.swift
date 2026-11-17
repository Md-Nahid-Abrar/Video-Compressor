import Foundation

/// Launch arguments used by UI tests to put the app into a known state.
nonisolated enum LaunchOptions {
    private static let arguments = ProcessInfo.processInfo.arguments

    /// Wipes stored preferences before the first view appears.
    static let resetState = arguments.contains("-UITestResetState")
    /// Skips the welcome screen.
    static let skipWelcome = arguments.contains("-UITestSkipWelcome")
    /// "Select Video" loads a generated sample clip instead of opening the Photos picker.
    static let useSampleVideo = arguments.contains("-UITestSampleVideo")
    /// "Select Video" loads a generated clip in an unsupported container.
    static let useUnsupportedVideo = arguments.contains("-UITestUnsupportedVideo")
    /// Premium lasts a few seconds instead of 48 hours, so expiry can be tested.
    static let shortPremium = arguments.contains("-UITestShortPremium")
    /// The generated sample clip is portrait (720×1280) instead of landscape.
    static let usePortraitSample = arguments.contains("-UITestPortraitVideo")
}
