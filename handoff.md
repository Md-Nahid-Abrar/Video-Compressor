# Video Compressor — Handoff

Status as of 2026-11-17. This describes version 1.0.2 of the app and how it got here.

## Where things stand

- **Current version:** 1.0.2, at the commit "Version 1.0.2: Add Premium, settings sections, localization and video playback" (`b2145ec`). Local `main` and GitHub `main` both end there.
- **Repository:** https://github.com/Md-Nahid-Abrar/Video-Compressor
- **App identity:** bundle ID `com.mdnahidabrar.SimpleVideoCompressor`, team `65TG6A2C74`, display name "Video Compressor". The app itself still reports version 1.0 (build 1); "1.0.2" is the commit-history label.
- **Platform:** iPhone only, iOS 26.0 and later, portrait. Built with Xcode 27.2 and Swift 6.
- **Not yet done:** real-device testing, a signed archive, and the TestFlight upload. See "Open items".

## What the app does

A native iOS app that compresses a video chosen from Photos, then saves or shares the result. Everything runs on the device; the app makes no network requests.

1. **Welcome** (first launch only): a before/after example, "Compress Video — Without Visible Quality Loss", and a Continue button.
2. **Home:**
   - *Premium strip* at the top. Empty for regular users. While Premium is active it shows "Ends in HH:MM:SS" on the left and a glowing "P Premium" badge on the right.
   - *Select Video* opens the Photos picker. Once a video loads it shows a thumbnail, size, resolution, frame rate and duration.
   - *Compression Level* has three raised 3D buttons — High, Medium, Low — disabled until a video is loaded. Each shows its own estimated size. Tapping one replaces the row with an Export button and a blinking "Change compression" link.
   - *Estimated Size* shows original size against the estimated compressed size.
   - *Bottom bar:* Settings, Premium, Profile.
3. **Export:** progress bar, a warning not to quit, Cancel with confirmation, and a local notification "Video compressed successfully" at the end.
4. **Result:** original and compressed sizes, "Save to Photos" (becomes "Saved to Photos") and "Share with Others" (system share sheet). After either is tapped, "Play Original Video" and "Play Compressed Video" appear; each opens the system video player full screen with a close button.
5. **Settings:** app name and version, Light/Dark button, Language, Feedback, Provide Rating, Invite Others, Privacy Policy link, support email.
6. **Profile:** name and email, edited by keyboard and stored only on the device.

Unsupported videos are rejected with a message and a "Choose Another Video" button. Supported input is MP4, MOV or M4V containing H.264 or HEVC.

### Premium (test phase)

- The Premium button opens a pop-up for a 3-digit promo code. The accepted codes are hardcoded in `PremiumStore`: 444, 555, 666, 777, 999.
- A valid code makes the user Premium for 48 hours. The expiry is stored on the device and survives relaunch; when the countdown ends the user reverts automatically.
- While Premium is active the button reads "Cancel Premium" and ends it after a confirmation.
- Premium unlocks nothing yet.

### Settings details

- **Language:** English (default), Spanish, Bengali. The choice is made in the app, not taken from the device. Apple's own screens (Photos picker, share sheet, permission prompts) stay in the device language.
- **Feedback:** opens the Mail app addressed to the feedback address with the user's text filled in. It needs a mail account on the device.
- **Provide Rating:** five stars light up when tapped. The Submit button does nothing yet.
- **Invite Others:** copies the privacy policy link to the clipboard as a stand-in.

## How compression works

- **Pipeline:** `AVAssetReader` decodes, `AVAssetWriter` encodes to HEVC in an MP4 file. No third-party code, no FFmpeg.
- **Frames are streamed** one at a time; the whole video is never held in memory.
- **Sample moving:** each track has a `SamplePump` that feeds the writer whenever it asks for more data (`requestMediaDataWhenReady`). See "History" for why this replaced the newer async API.
- **Stall watchdog:** if no sample is read or written for 30 seconds, the export fails with "The encoder stopped responding. Try again." instead of hanging.
- **Audio** is always re-encoded to AAC, stereo at most.
- **Color** tags are copied from the source. HDR sources use 10-bit HEVC.
- **Output** is written to the app's temporary folder and cleaned up on the next launch.

| Preset | Max long edge | Max FPS | Bits per pixel | Bitrate cap vs. source | Audio per channel |
|---|---|---|---|---|---|
| Low compression | original | 60 | 0.085 | 60% | 64 kbps |
| Medium compression | 1920 | 30 | 0.050 | 35% | 64 kbps |
| High compression | 1280 | 30 | 0.040 | 15% | 48 kbps |

The video bitrate is the lower of the bits-per-pixel target and the cap, so output is never larger than the source. The size estimate is `(video + audio bitrate) × duration ÷ 8`.

**Background export:** the app requests an iOS 26 continued-processing task so an export can finish after the user leaves the app. If the system refuses (always the case in the Simulator), it falls back to foreground-only and shows "Keep the app open" instead.

## Project layout

```
VideoCompressor.xcodeproj        one scheme: VideoCompressor
Config/Info.plist                background task identifier, background mode, encryption flag
VideoCompressor/
  App/           app entry, root view, router, shared services, launch options, language helper
  DesignSystem/  theme, starfield background, glow and raised button styles, cards
  Welcome/  Home/  Export/  Settings/  Profile/  Premium/     one folder per feature
  Compression/   presets, settings, size estimate, format validation, inspector, encoder
  Services/      Photos save, notifications, background export
  Resources/     asset catalog, string catalog, privacy manifest
VideoCompressorTests/             unit tests (Swift Testing)
VideoCompressorUITests/           UI tests and screenshot tour (XCTest)
VideoCompressorPerformanceTests/  performance tests (XCTest)
CLAUDE.md                project rules and conventions
RELEASE_CHECKLIST.md     steps that need the owner's Apple account
```

Conventions:
- MVVM with `@Observable` view models, `NavigationStack`, one type per file, files grouped by feature.
- The app target uses main-actor default isolation; types used off the main actor are marked `nonisolated` and background work uses `@concurrent`.
- Strings live in `Localizable.xcstrings`. Code outside views must pass `bundle: L10n.bundle` to `String(localized:)` so it follows the in-app language. `CLAUDE.md` has the steps for adding strings and translations.
- The root view rebuilds when the language changes, so state that must survive it (router, home view model, Premium) is owned by `VideoCompressorApp`.

## Build and test

```bash
xcodebuild -project VideoCompressor.xcodeproj -scheme VideoCompressor -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' test
```

- An "iPhone 17 Pro" simulator on iOS 26.5 was created for this project.
- UI tests use launch arguments defined in `VideoCompressor/App/LaunchOptions.swift`, including one that loads a generated sample clip instead of opening the Photos picker, and one that shortens Premium to a few seconds.
- UI and performance tests use XCTest because Swift Testing has no UI automation or `measure` API.
- `ScreenshotTour` walks every screen and saves screenshots. It is skipped unless a folder is given; `CLAUDE.md` has the command.

**Results for version 1.0.2** (iPhone 17 Pro simulator):

| Suite | Result |
|---|---|
| Unit | 48 passed, including the real encoder on a bundled clip |
| UI | 12 passed (the screenshot tour is skipped by default) |
| Performance | 2 passed |
| Encoder stress | about 100 consecutive compressions, no stall |
| Release archive | builds unsigned, no warnings |

**Measured in the Simulator at version 1.0.0** (not representative of a real iPhone, and not re-measured since the encoder change):

| Source | Preset | Estimate | Actual | Output |
|---|---|---|---|---|
| 1080p60 H.264, 24.3 MB | Medium | ≈ 4.9 MB | 4.93 MB | HEVC 1080p30, 3.2 Mbps |
| 4K30 HEVC, 30.5 MB | High | ≈ 910 kB | 813 kB | HEVC 720p30, 1.0 Mbps |

## History

1. **Planning.** Requirements were reviewed against the style guide images, `karpathy_claude.md` and `Swift-Concurrency-Updates.md`. Decisions made with the owner:
   - Native AVFoundation instead of terminal commands, which cannot run inside an iOS app.
   - Export continues in the background where iOS allows it.
   - The three preset buttons are replaced by Export, with a "Change compression" link.
   - Purple starfield theme; the comparison card keeps the orange-to-pink pills and green arrow.
   - Headline "Without Visible Quality Loss" rather than "Without Losing Quality", since compression is lossy.
   - The completion alert is a local notification, not a server push.
2. **Version 1.0.0 — "Add Video Compressor iOS app".** The full app, three test targets, app icon, privacy manifest and release checklist. Verified end to end in the Simulator.
3. **Version 1.0.1 — "Make the app iPhone-only".** Made by the owner in Xcode. The app originally targeted iPhone and iPad.
4. **Version 1.0.2 — Premium, settings sections, localization and playback.** Everything listed under "What the app does" that is not in 1.0.0, plus the owner's logo as the app icon and Xcode's recommended project settings.
5. **Encoder hang, fixed in 1.0.2.** Versions 1.0.0 and 1.0.1 moved samples with Apple's newer async reader/writer calls. In testing these occasionally never returned, leaving a compression frozen partway (seen twice in roughly forty runs). 1.0.2 uses the long-established pull model and adds the stall watchdog. Do not switch back without a stress test.
6. **Repository housekeeping.** Commit titles carry version prefixes with matching tags (`v1.0.0`, `v1.0.1`, `v1.0.2`). All commits are authored solely by the owner.

## Open items

**Must be checked on a real iPhone** (the Simulator cannot test these):
- Compress several videos, including a long 4K one, and confirm none stall. The rewritten encoder has only been exercised in the Simulator.
- Start an export, leave the app, and confirm it keeps running and finishes with the notification.
- Compress an HDR video and confirm the result still looks HDR in Photos.
- Share a result by AirDrop and by a messaging app.
- Send feedback from Settings and confirm the email arrives.
- Encoding speed and battery use on real hardware.

**Uncertain:**
- `Config/Info.plist` declares the `processing` background mode alongside the task identifier. It was not confirmed whether continued-processing tasks require it. Check during the device test, and remove it if unneeded so App Review does not question it.

**Test-phase features to resolve before App Store review:**
- **Promo-code Premium.** Apple does not allow unlocking features with codes outside In-App Purchase (guideline 3.1.1), and Premium currently unlocks nothing. Sell it through StoreKit with real benefits, or remove it. The codes are readable inside the app.
- **Submit Rating** does nothing. Wire it to the system rating prompt or remove it.
- **Invite Others** copies the privacy policy link. Replace it with the App Store link.
- **Privacy Policy** points to a Google Doc in edit mode. Publish a read-only page.

**Before App Store submission:**
- Replace `developer@gmail.com` in `VideoCompressor/App/AppConfig.swift` with a monitored support address.
- Choose a unique App Store listing name; "Video Compressor" is likely taken.
- Provide a Support URL and a Privacy Policy URL in App Store Connect.
- App Privacy answers: "Data Not Collected".
- Sign, archive, validate and upload with the owner's Apple account. Only an unsigned Release archive has been built so far.

**Known limitations:**
- No leak or memory profiling has been run on long or 4K videos.
- No performance baselines are set, so the performance tests record numbers but cannot fail on a slowdown.
- Export failures are shown to the user but not logged or reported anywhere.
- The play buttons appear as soon as Share is tapped, even if the share sheet is then dismissed; iOS does not report whether a share completed.
