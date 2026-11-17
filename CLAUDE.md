#  Project Context

## Overview

- iOS 26 SwiftUI app targeting iPhone only (no iPad)
- Minimum deployment: iOS 26
- Swift 6 with strict concurrency
- Uses SwiftUI throughout - no UIKit unless absolutely necessary

## Architecture

- MVVM with @OBservable ViewModels (NOT observableObjects)
- Views on their ViewModel as a @State property
- ViewModels handle all business logic - Views are declaritive only
- Navigation uses NavigationStack with NavigationPath - never NavigationView
- Dependency injection through the SwiftUI Enviroment
- use AppStorage for simple user prefernces
- use SwiftData for persistent models

## Build System
- use BuildProject for completion (not shell commands or xcodebuild)
- Previews are available via RenderPreview
- SPM for package management - no CocoaPods
- Build target: "VideoCompressor" iOS (scheme `VideoCompressor`)

## Testing
- Use Swift Testing framework -- NOT XCTest
- Test functions use @Test attribute, not func textXYZ()
- Use #expect() for assertions - not XCTAssertEqual
- Test targets: VideoCompressorTests (unit), VideoCompressorUITests (UI), VideoCompressorPerformanceTests (performance)
- Run with RunAllTests or RunSomeTests MCP tools


## Documentation & APIs
- Use DocumentationSearch for Apple API questions
- Do NOT hallucinate API names - Verify with the docs first
- prefer async/await - never completion handlers
- use structured concurrency (TaskGroup) over manual task management
- Error handling: use typed throws where supported

## Code Style
- All new views must include a #Preview Block
- Use SF symbols for icons - reference by exact name
- Prefer Liquid Glass materials for iOS 26 UI
- File organization: one type per file
- Naming: PascalCase for types, cameCase for properties
- Group files by feature, not by type (Weather/, Profile/, Settings/)


## Project Notes (Video Compressor)
- UI tests and performance tests use XCTest, because Swift Testing has no UI automation or `measure` API. Everything else uses Swift Testing.
- If the Xcode MCP tools above are not connected, build and test with `xcodebuild -project VideoCompressor.xcodeproj -scheme VideoCompressor -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' test`.
- The app target uses main-actor default isolation (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`). Types used off the main actor are marked `nonisolated`; background work uses `@concurrent`. See `Swift-Concurrency-Updates.md`.
- UI test launch arguments are defined in `VideoCompressor/App/LaunchOptions.swift`.
- The app language (English, Spanish, Bengali) is chosen in Settings, not by the device. Views get it from the SwiftUI environment; code outside views must pass `bundle: L10n.bundle` to `String(localized:)`. After adding or changing strings, build, then run `xcrun xcstringstool sync VideoCompressor/Resources/Localizable.xcstrings --stringsdata <the build's .stringsdata files>` and add the `es` and `bn` translations.
- `RootView` rebuilds on a language change, so state that must survive it (router, `HomeViewModel`, `PremiumStore`) lives in `VideoCompressorApp`.
- Premium is a test-phase feature unlocked by hardcoded promo codes in `PremiumStore`; it changes nothing yet. Submit Rating is a placeholder.
- Screenshots of every screen: `TEST_RUNNER_SCREENSHOT_DIR=<folder> xcodebuild test -only-testing:VideoCompressorUITests/ScreenshotTour ...`.
- Compression has two engines behind `VideoCompressing`, chosen by `AppConfig.compressionEngine`. The active one is FFmpeg (`FFmpegCompressor`), which runs FFmpeg's command-line front end in-process through the embedded `FFmpegCmd` framework. The AVFoundation engine (`VideoCompressor`, using `SamplePump`) is kept as a fallback. Both take the same `EncodingSettings`.
- FFmpeg is the one exception to the "no third-party code" rule. It is built from the official source by `Scripts/build-ffmpeg.sh` (LGPL configuration only, no GPL components) and committed as `Vendor/FFmpeg/FFmpegCmd.xcframework`. Rerun the script only to change the FFmpeg version or configuration; it needs a work folder without spaces in its path and uses `~/Library/Caches/VideoCompressorFFmpeg` by default.
- FFmpeg's front end keeps global state, so `FFmpegRunner` runs one command at a time. Do not call `ffcmd_run` from anywhere else.
- Do not replace the AVFoundation engine's pull model with the newer async reader/writer API without a stress test; that API stalled intermittently.
