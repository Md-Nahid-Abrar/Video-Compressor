import XCTest

/// Walks through every screen and saves a screenshot of each.
///
/// Skipped unless a destination folder is provided:
/// `TEST_RUNNER_SCREENSHOT_DIR=/some/folder xcodebuild test -only-testing:VideoCompressorUITests/ScreenshotTour`
final class ScreenshotTour: XCTestCase {
    private var app: XCUIApplication!
    private var directory: URL!

    @MainActor
    override func setUp() async throws {
        continueAfterFailure = true
        guard let path = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"], !path.isEmpty else {
            throw XCTSkip("Set SCREENSHOT_DIR to run the screenshot tour.")
        }
        directory = URL(fileURLWithPath: path, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        app = XCUIApplication()
    }

    /// Leaves the app in its default state (English, dark, not Premium) for whatever runs next.
    @MainActor
    override func tearDown() async throws {
        guard let app else { return }
        app.terminate()
        app.launchArguments = ["-UITestResetState"]
        app.launch()
        app.terminate()
    }

    @MainActor
    private func capture(_ name: String) {
        Thread.sleep(forTimeInterval: 0.8)
        let data = XCUIScreen.main.screenshot().pngRepresentation
        try? data.write(to: directory.appendingPathComponent("\(name).png"))
    }

    @MainActor
    private func allowNotificationsIfAsked() {
        let allow = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Allow"]
        if allow.waitForExistence(timeout: 5) { allow.tap() }
    }

    @MainActor
    private func exportSample() {
        app.buttons["home.selectVideo"].tap()
        XCTAssertTrue(app.buttons["home.changeVideo"].waitForExistence(timeout: 30))
    }

    @MainActor
    func testTour() {
        app.launchArguments = ["-UITestResetState", "-UITestSampleVideo"]
        app.launch()
        XCTAssertTrue(app.buttons["welcome.continue"].waitForExistence(timeout: 10))
        capture("01-welcome")

        app.buttons["welcome.continue"].tap()
        XCTAssertTrue(app.buttons["home.selectVideo"].waitForExistence(timeout: 5))
        capture("02-home-empty")

        exportSample()
        capture("03-home-video-loaded")

        app.buttons["home.preset.high"].tap()
        XCTAssertTrue(app.buttons["home.export"].waitForExistence(timeout: 5))
        capture("04-home-level-chosen")

        app.buttons["home.premium"].tap()
        let field = app.textFields["promo.code"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("444")
        capture("05-promo-code")
        app.buttons["promo.activate"].tap()
        XCTAssertTrue(app.switches["premium.hardwareAcceleration"].waitForExistence(timeout: 5))
        capture("06-home-premium")

        app.buttons["home.export"].tap()
        allowNotificationsIfAsked()
        capture("07-compressing")
        XCTAssertTrue(app.staticTexts["export.finishedTitle"].waitForExistence(timeout: 90))
        Thread.sleep(forTimeInterval: 6)
        capture("08-result-landscape")
        app.buttons["export.play"].tap()
        Thread.sleep(forTimeInterval: 1)
        capture("09-result-playing")
        app.buttons["export.done"].tap()

        app.buttons["home.settings"].tap()
        XCTAssertTrue(app.buttons["settings.appearance"].waitForExistence(timeout: 5))
        capture("10-settings-top")
        app.swipeUp()
        capture("11-settings-middle")
        app.swipeUp()
        capture("12-settings-bottom")

        app.swipeDown()
        app.swipeDown()
        app.buttons["settings.language"].tap()
        app.buttons["العربية"].tap()
        XCTAssertTrue(app.navigationBars["الإعدادات"].waitForExistence(timeout: 5))
        capture("13-settings-arabic")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["home.export"].waitForExistence(timeout: 5))
        capture("14-home-arabic")

        app.buttons["home.settings"].tap()
        app.buttons["settings.language"].tap()
        app.buttons["বাংলা"].tap()
        XCTAssertTrue(app.navigationBars["সেটিংস"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["home.export"].waitForExistence(timeout: 5))
        capture("15-home-bengali")

        app.buttons["home.settings"].tap()
        app.buttons["settings.appearance"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["home.export"].waitForExistence(timeout: 5))
        capture("16-home-bengali-light")
    }

    @MainActor
    func testPortraitResult() {
        app.launchArguments = ["-UITestResetState", "-UITestSkipWelcome", "-UITestSampleVideo", "-UITestPortraitVideo"]
        app.launch()
        XCTAssertTrue(app.buttons["home.selectVideo"].waitForExistence(timeout: 10))
        exportSample()
        capture("17-home-portrait-video")
        app.buttons["home.preset.medium"].tap()
        app.buttons["home.export"].tap()
        allowNotificationsIfAsked()
        XCTAssertTrue(app.staticTexts["export.finishedTitle"].waitForExistence(timeout: 90))
        Thread.sleep(forTimeInterval: 6)
        capture("18-result-portrait")
    }
}
