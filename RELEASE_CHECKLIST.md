# Release checklist

Things that need you or your Apple account before TestFlight and App Store submission.

## Before the first upload
- [ ] Replace `developer@gmail.com` in `VideoCompressor/App/AppConfig.swift` with a support address you monitor.
- [ ] Sign in to Xcode with the Apple ID for team `FGASU9H6S2` and confirm automatic signing resolves for `com.mdnahidabrar.VideoCompressor`.
- [ ] Create the app record in App Store Connect. "Video Compressor" is likely taken as a store name, so choose a unique listing name (the home-screen name can stay).
- [ ] Product → Archive in Xcode, then Validate App, then Distribute to TestFlight.

## Check on a real iPhone (cannot be tested in the Simulator)
- [ ] Start an export, leave the app, and confirm it keeps running with the system progress indicator and finishes with the notification. If the export instead fails with the "interrupted" message, tell Claude; the app already falls back safely.
- [ ] Compress an HDR video shot on the phone and confirm the result still looks HDR in Photos.
- [ ] Share a result by AirDrop and by a messaging app.

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
- No third-party code, no network access, no tracking.
