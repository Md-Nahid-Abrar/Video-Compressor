# Release checklist

Things that need you or your Apple account before TestFlight and App Store submission.

## Before the first upload
- [ ] Replace `developer@gmail.com` in `VideoCompressor/App/AppConfig.swift` with a support address you monitor.
- [ ] Sign in to Xcode with the Apple ID for team `FGASU9H6S2` and confirm automatic signing resolves for `com.mdnahidabrar.VideoCompressor`.
- [ ] Create the app record in App Store Connect. "Video Compressor" is likely taken as a store name, so choose a unique listing name (the home-screen name can stay).
- [ ] Product → Archive in Xcode, then Validate App, then Distribute to TestFlight.

## Test-phase features to resolve before App Store review
These work as specified for testing, but each is a likely rejection if submitted as is.
- [ ] **Promo-code Premium.** Guideline 3.1.1 does not allow unlocking features with codes or keys outside In-App Purchase, and Premium currently unlocks nothing. Before release, sell it through StoreKit with real benefits, or remove it. The codes are also readable inside the app binary.
- [ ] **Submit Rating button.** It does nothing. Wire it to the system rating prompt (`requestReview`) or remove it.
- [ ] **Invite Others.** It copies the privacy policy link as a stand-in. Replace with the App Store link once the app has one.
- [ ] **Privacy Policy link.** It points to a Google Doc in edit mode. Publish a read-only page and use the same URL in App Store Connect.
- [ ] **Feedback.** Sending opens the user's Mail app addressed to the feedback address; it needs a mail account on the device.

## FFmpeg licence obligations (LGPL 2.1)
The app embeds FFmpeg as a separate dynamic framework. To stay compliant:
- [ ] Keep the Acknowledgements screen in Settings, which credits FFmpeg and shows the licence text.
- [ ] Make the exact source available: the FFmpeg 8.1 release plus this repository's `Scripts/build-ffmpeg.sh` and `Vendor/FFmpegCommand/` (the script contains the small patch applied to FFmpeg). If the repository is private, publish those files somewhere users can reach.
- [ ] Mention FFmpeg and its licence in the App Store description or support page.
- [ ] Do not enable GPL or non-free components (for example x264 or x265) in the build script.
- [ ] After archiving, confirm `FFmpegCmd.framework` is inside the app's `Frameworks` folder and signed with your team.

## Check on a real iPhone (cannot be tested in the Simulator)
- [ ] Start an export, leave the app, and confirm it keeps running with the system progress indicator and finishes with the notification. If the export instead fails with the "interrupted" message, tell Claude; the app already falls back safely.
- [ ] Compress an HDR video shot on the phone and confirm the result still looks HDR in Photos.
- [ ] Share a result by AirDrop and by a messaging app.
- [ ] With the FFmpeg engine: compress a long 4K video, an HDR video and a portrait video; confirm speed, orientation and HDR are right, and that Cancel stops it promptly.

## App Store Connect metadata
- [ ] Support URL and Privacy Policy URL (both required).
- [ ] App Privacy answers: "Data Not Collected". The profile name and email never leave the device.
- [ ] Screenshots for iPhone 6.9" (iPhone-only app, no iPad screenshots needed). If you reuse the welcome screen, keep the "Example" caption visible.
- [ ] Category: Photo & Video. Age rating questionnaire.
- [ ] Export compliance: already declared in Info.plist (`ITSAppUsesNonExemptEncryption = NO`).

## Already in place
- Privacy manifest (`PrivacyInfo.xcprivacy`) with required-reason entries for UserDefaults and disk space.
- Photo library add-only usage string.
- `BGTaskSchedulerPermittedIdentifiers` and the `processing` background mode for background export.
- 1024 px app icon without alpha.
- One third-party component, FFmpeg (LGPL), embedded as a framework. No network access, no tracking.
