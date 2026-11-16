import Foundation

/// Dependencies shared through the SwiftUI environment.
@Observable
final class AppServices {
    let compressor: any VideoCompressing
    let inspector: any VideoInspecting
    let photoSaver: any PhotoLibrarySaving
    let notifier: any CompletionNotifying
    let background: any BackgroundExporting
    let defaults: UserDefaults
    /// When set, "Select Video" uses this provider instead of the Photos picker (UI tests only).
    let sampleVideoProvider: (@Sendable () async throws -> URL)?

    init(
        compressor: any VideoCompressing,
        inspector: any VideoInspecting,
        photoSaver: any PhotoLibrarySaving,
        notifier: any CompletionNotifying,
        background: any BackgroundExporting,
        defaults: UserDefaults = .standard,
        sampleVideoProvider: (@Sendable () async throws -> URL)? = nil
    ) {
        self.compressor = compressor
        self.inspector = inspector
        self.photoSaver = photoSaver
        self.notifier = notifier
        self.background = background
        self.defaults = defaults
        self.sampleVideoProvider = sampleVideoProvider
    }

    /// The services used by the shipping app.
    static func live() -> AppServices {
        AppServices(
            compressor: VideoCompressor(),
            inspector: VideoInspector(),
            photoSaver: PhotoLibrarySaver(),
            notifier: NotificationService(),
            background: BackgroundExportCoordinator(),
            sampleVideoProvider: debugSampleProvider
        )
    }

    private static var debugSampleProvider: (@Sendable () async throws -> URL)? {
        #if DEBUG
        if LaunchOptions.useUnsupportedVideo {
            return { try await SampleVideoFactory.makeClip(kind: .unsupportedContainer) }
        }
        if LaunchOptions.useSampleVideo {
            return { try await SampleVideoFactory.makeClip(kind: .supported) }
        }
        #endif
        return nil
    }
}
