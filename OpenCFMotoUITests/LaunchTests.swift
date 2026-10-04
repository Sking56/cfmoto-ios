import XCTest

final class LaunchTests: XCTestCase {
    @MainActor
    func testLaunchShowsPrototypeStatus() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["prototypeTitle"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Research prototype"].exists)
        XCTAssertTrue(app.staticTexts["Pairing and mirroring are not available yet."].exists)
    }
}
