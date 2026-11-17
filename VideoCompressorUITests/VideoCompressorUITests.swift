import XCTest

final class VideoCompressorUITests: XCTestCase {
    private var app: XCUIApplication!

    @MainActor
    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    @MainActor
    private func launch(_ arguments: String...) {
        app.launchArguments = arguments
        app.launch()
    }

    /// Answers the notification permission prompt shown at the first export.
    @MainActor
    private func allowNotificationsIfAsked() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allow = springboard.buttons["Allow"]
        if allow.waitForExistence(timeout: 5) {
            allow.tap()
        }
    }

    // MARK: - Welcome

    @MainActor
    func testWelcomeShowsComparisonAndContinuesToHome() {
        launch("-UITestResetState")

        XCTAssertTrue(app.staticTexts["Compress Video"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Without Visible Quality Loss"].exists)
        let continueButton = app.buttons["welcome.continue"]
        XCTAssertTrue(continueButton.exists)
        continueButton.tap()

        XCTAssertTrue(app.buttons["home.selectVideo"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["home.profile"].exists)
        XCTAssertTrue(app.buttons["home.settings"].exists)
    }

    @MainActor
    func testWelcomeIsShownOnlyOnce() {
        launch("-UITestResetState")
        app.buttons["welcome.continue"].firstMatch.tap()
        XCTAssertTrue(app.buttons["home.selectVideo"].waitForExistence(timeout: 5))

        app.terminate()
        launch()
        XCTAssertTrue(app.buttons["home.selectVideo"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["welcome.continue"].exists)
    }

    // MARK: - Home

    @MainActor
    func testPresetsAreDisabledUntilVideoIsSelected() {
        launch("-UITestResetState", "-UITestSkipWelcome", "-UITestSampleVideo")

        for preset in ["high", "medium", "low"] {
            let button = app.buttons["home.preset.\(preset)"]
            XCTAssertTrue(button.waitForExistence(timeout: 10))
            XCTAssertFalse(button.isEnabled, "\(preset) should be disabled before a video is selected")
        }
        XCTAssertFalse(app.buttons["home.export"].exists)

        app.buttons["home.selectVideo"].tap()
        XCTAssertTrue(app.buttons["home.changeVideo"].waitForExistence(timeout: 30))
        for preset in ["high", "medium", "low"] {
            XCTAssertTrue(app.buttons["home.preset.\(preset)"].isEnabled)
        }
    }

    @MainActor
    func testChoosingPresetShowsExportAndCanBeChanged() {
        launch("-UITestResetState", "-UITestSkipWelcome", "-UITestSampleVideo")
        app.buttons["home.selectVideo"].tap()
        XCTAssertTrue(app.buttons["home.changeVideo"].waitForExistence(timeout: 30))

        app.buttons["home.preset.medium"].tap()
        XCTAssertTrue(app.buttons["home.export"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["home.preset.medium"].exists)

        app.buttons["home.changeCompression"].tap()
        XCTAssertTrue(app.buttons["home.preset.high"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["home.export"].exists)
    }

    @MainActor
    func testUnsupportedVideoIsRejected() {
        launch("-UITestResetState", "-UITestSkipWelcome", "-UITestUnsupportedVideo")
        app.buttons["home.selectVideo"].tap()

        let alert = app.alerts["Unsupported Video"]
        XCTAssertTrue(alert.waitForExistence(timeout: 30))
        XCTAssertTrue(alert.buttons["Choose Another Video"].exists)
        alert.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["home.selectVideo"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["home.preset.medium"].isEnabled)
    }

    // MARK: - Export

    @MainActor
    func testExportCompressesAndOffersSaveAndShare() {
        launch("-UITestResetState", "-UITestSkipWelcome", "-UITestSampleVideo")
        app.buttons["home.selectVideo"].tap()
        XCTAssertTrue(app.buttons["home.changeVideo"].waitForExistence(timeout: 30))
        app.buttons["home.preset.high"].tap()
        app.buttons["home.export"].tap()

        allowNotificationsIfAsked()

        XCTAssertTrue(app.staticTexts["export.finishedTitle"].waitForExistence(timeout: 90))
        XCTAssertTrue(app.buttons["export.save"].exists)
        XCTAssertTrue(app.buttons["export.share"].exists)

        // The play buttons appear only after saving (or sharing).
        XCTAssertFalse(app.buttons["export.playOriginal"].exists)
        app.buttons["export.save"].tap()
        allowNotificationsIfAsked()
        XCTAssertTrue(app.buttons["export.playOriginal"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["export.playCompressed"].exists)

        for (button, title) in [("export.playOriginal", "Original Video"), ("export.playCompressed", "Compressed Video")] {
            app.buttons[button].tap()
            XCTAssertTrue(app.buttons["playback.close"].waitForExistence(timeout: 5))
            XCTAssertEqual(app.staticTexts["playback.title"].label, title)
            app.buttons["playback.close"].tap()
            XCTAssertTrue(app.buttons[button].waitForExistence(timeout: 5))
        }

        app.buttons["export.done"].tap()
        XCTAssertTrue(app.buttons["home.changeVideo"].waitForExistence(timeout: 5))
    }

    // MARK: - Profile and settings

    @MainActor
    func testProfilePersistsAcrossRelaunch() {
        launch("-UITestResetState", "-UITestSkipWelcome")
        app.buttons["home.profile"].tap()

        let name = app.textFields["profile.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        XCTAssertEqual(name.value as? String, "Your Name")
        name.tap()
        name.press(forDuration: 1.2)
        if app.menuItems["Select All"].waitForExistence(timeout: 2) {
            app.menuItems["Select All"].tap()
        }
        name.typeText("Alex Rivera")

        app.terminate()
        launch("-UITestSkipWelcome")
        app.buttons["home.profile"].tap()
        let reloaded = app.textFields["profile.name"]
        XCTAssertTrue(reloaded.waitForExistence(timeout: 5))
        XCTAssertTrue((reloaded.value as? String)?.contains("Alex Rivera") == true)
    }

    @MainActor
    func testSettingsShowsVersionAndTogglesAppearance() {
        launch("-UITestResetState", "-UITestSkipWelcome")
        app.buttons["home.settings"].tap()

        XCTAssertTrue(app.staticTexts["settings.version"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Video Compressor"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["settings.supportEmail"].exists)

        let appearance = app.buttons["settings.appearance"]
        XCTAssertEqual(appearance.value as? String, "Dark")
        appearance.tap()
        XCTAssertEqual(appearance.value as? String, "Light")
        appearance.tap()
        XCTAssertEqual(appearance.value as? String, "Dark")

        // Rating: stars stay unlit until tapped, and Submit is disabled until then.
        let submit = app.buttons["settings.submitRating"]
        app.swipeUp()
        XCTAssertTrue(submit.waitForExistence(timeout: 5))
        XCTAssertFalse(submit.isEnabled)
        app.buttons["settings.star.4"].tap()
        XCTAssertTrue(submit.isEnabled)
        XCTAssertTrue(app.buttons["settings.star.4"].isSelected)
        XCTAssertFalse(app.buttons["settings.star.5"].isSelected)

        app.swipeUp()
        XCTAssertTrue(app.buttons["settings.invite"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["settings.privacyPolicy"].exists)
        XCTAssertTrue(app.buttons["settings.sendFeedback"].exists)
    }

    // MARK: - Premium

    @MainActor
    private func redeem(_ code: String) {
        let field = app.textFields["promo.code"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(code)
        app.buttons["promo.activate"].tap()
    }

    @MainActor
    func testPromoCodeUnlocksPremiumAndItCanBeCancelled() {
        launch("-UITestResetState", "-UITestSkipWelcome")
        let premiumButton = app.buttons["home.premium"]
        let badge = app.descendants(matching: .any)["premium.badge"]
        XCTAssertTrue(premiumButton.waitForExistence(timeout: 10))
        XCTAssertEqual(premiumButton.label, "Premium")
        XCTAssertFalse(badge.exists)

        premiumButton.tap()
        redeem("123")
        XCTAssertTrue(app.staticTexts["promo.error"].waitForExistence(timeout: 5))
        XCTAssertFalse(badge.exists)

        redeem("444")
        XCTAssertTrue(badge.waitForExistence(timeout: 5))
        let countdown = app.staticTexts["premium.countdown"]
        XCTAssertTrue(countdown.label.hasPrefix("Ends in 4"), "Unexpected countdown: \(countdown.label)")
        XCTAssertEqual(premiumButton.label, "Cancel Premium")

        // Premium survives a relaunch.
        app.terminate()
        launch("-UITestSkipWelcome")
        XCTAssertTrue(badge.waitForExistence(timeout: 10))

        // Cancel Premium asks first, then ends it.
        app.buttons["home.premium"].tap()
        app.alerts.buttons["Keep Premium"].tap()
        XCTAssertTrue(badge.exists)
        app.buttons["home.premium"].tap()
        app.alerts.buttons["Cancel Premium"].tap()
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: badge)
        wait(for: [gone], timeout: 5)
        XCTAssertEqual(app.buttons["home.premium"].label, "Premium")
    }

    @MainActor
    func testPremiumEndsWhenCountdownFinishes() {
        launch("-UITestResetState", "-UITestSkipWelcome", "-UITestShortPremium")
        app.buttons["home.premium"].tap()
        redeem("999")
        let badge = app.descendants(matching: .any)["premium.badge"]
        XCTAssertTrue(badge.waitForExistence(timeout: 5))
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: badge)
        wait(for: [gone], timeout: 15)
        XCTAssertEqual(app.buttons["home.premium"].label, "Premium")
    }

    // MARK: - Language

    @MainActor
    func testLanguageCanBeSwitchedToSpanishAndBengali() {
        launch("-UITestResetState", "-UITestSkipWelcome")
        app.buttons["home.settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))

        app.buttons["settings.language"].tap()
        app.buttons["Español"].tap()
        XCTAssertTrue(app.navigationBars["Ajustes"].waitForExistence(timeout: 5))

        app.buttons["settings.language"].tap()
        app.buttons["বাংলা"].tap()
        XCTAssertTrue(app.navigationBars["সেটিংস"].waitForExistence(timeout: 5))

        app.buttons["settings.language"].tap()
        app.buttons["English"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }

    // MARK: - Performance

    @MainActor
    func testLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
