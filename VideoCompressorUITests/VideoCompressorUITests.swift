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
    }

    // MARK: - Performance

    @MainActor
    func testLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
