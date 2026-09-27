import XCTest

/// Launches the app (no Xcode debugger attached, no breakpoints) and taps through the tab bar
/// to check whether the UI actually responds to touches, independent of any breakpoint theory.
final class TabNavigationUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTapsSwitchTabs() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar never appeared")

        let trackerTab = tabBar.buttons.element(boundBy: 1)
        XCTAssertTrue(trackerTab.waitForExistence(timeout: 5))
        trackerTab.tap()

        let trackerTitle = app.navigationBars["Tracker"]
        XCTAssertTrue(trackerTitle.waitForExistence(timeout: 5), "Tapping the Tracker tab did not navigate there")

        let settingsTab = tabBar.buttons.element(boundBy: 2)
        settingsTab.tap()

        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5), "Tapping the Settings tab did not navigate there")
    }
}
