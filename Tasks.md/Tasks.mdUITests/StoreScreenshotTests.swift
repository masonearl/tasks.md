import XCTest

#if os(iOS)
final class StoreScreenshotTests: XCTestCase {
    @MainActor
    func testStoreScreenshotsAndTaskEntry() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--store-screenshots"]
        app.launch()
        XCTAssertTrue(app.textFields["inlineAddTaskField"].waitForExistence(timeout: 10))
        capture(app, "01-Your-tasks-your-file")
        app.buttons["Today"].tap()
        XCTAssertTrue(app.buttons["Review the project proposal"].exists)
        XCTAssertFalse(app.buttons["Weekly team review"].exists)
        capture(app, "02-Focus-on-today")
        app.buttons["All"].tap()
        let search = app.textFields["taskSearchField"]
        search.tap()
        search.typeText("Work")
        XCTAssertTrue(app.buttons["Draft October release notes"].exists)
        XCTAssertFalse(app.buttons["Book a weekend hike"].exists)
        app.buttons["Clear search"].tap()
        app.buttons["addTaskToolbarButton"].tap()
        app.textFields["inlineAddTaskField"].typeText("Plan the next project")
        app.buttons["inlineAddTaskButton"].tap()
        XCTAssertTrue(app.buttons["Plan the next project"].waitForExistence(timeout: 4))
        app.buttons["Mark complete: Plan the next project"].tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["Plan the next project"].exists)
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
#endif
