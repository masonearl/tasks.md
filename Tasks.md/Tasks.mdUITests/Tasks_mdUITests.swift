//
//  Tasks_mdUITests.swift
//  Tasks.mdUITests
//
//  Created by Mason Earl on 10/9/25.
//

import XCTest

#if os(macOS)
final class Tasks_mdUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAddTaskFromToolbar() throws {
        let app = XCUIApplication()
        app.launchArguments += ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 8), "A main window should open on launch\n\(app.debugDescription)")

        let composer = app.textFields["inlineAddTaskField"].firstMatch
        XCTAssertTrue(composer.waitForExistence(timeout: 6), "Inline Add Task field should be visible on launch\n\(app.debugDescription)")

        app.buttons["addTaskToolbarButton"].click()
        composer.typeText("App Review can add a task")

        let addButton = app.buttons["inlineAddTaskButton"].firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 3), "Add button should be enabled after typing")
        addButton.click()

        XCTAssertTrue(
            app.buttons["App Review can add a task"].waitForExistence(timeout: 5),
            "The new task should appear in the list\n\(app.debugDescription)"
        )
    }
    @MainActor
    func testSearchAndCompletionFilters() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        let search = app.textFields["taskSearchField"]
        XCTAssertTrue(search.waitForExistence(timeout: 8))
        search.click()
        search.typeText("Polish")
        XCTAssertTrue(app.buttons["Polish the task list"].exists)
        XCTAssertFalse(app.buttons["Share release notes"].exists)
        app.buttons["Clear search"].click()
        app.buttons["Mark complete: Polish the task list"].click()
        XCTAssertFalse(app.buttons["Polish the task list"].exists)
        app.radioButtons["Done"].click()
        XCTAssertTrue(app.buttons["Polish the task list"].exists)
        app.radioButtons["Today"].click()
        XCTAssertTrue(app.buttons["Review the Mac update"].exists)
        XCTAssertFalse(app.buttons["Plan the next release"].exists)
    }

    @MainActor
    func testKeyboardShortcutsAndRename() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.textFields["inlineAddTaskField"].waitForExistence(timeout: 8))
        app.typeKey("n", modifierFlags: .command)
        app.typeText("Keyboard task\n")
        let task = app.buttons["Keyboard task"]
        XCTAssertTrue(task.waitForExistence(timeout: 4))
        task.click()
        let edit = app.textFields["editTaskTitleField"]
        XCTAssertTrue(edit.waitForExistence(timeout: 3))
        edit.typeKey("a", modifierFlags: .command)
        edit.typeText("Renamed task\n")
        XCTAssertTrue(app.buttons["Renamed task"].waitForExistence(timeout: 3))
        app.typeKey("f", modifierFlags: .command)
        app.typeText("No such task")
        XCTAssertTrue(app.staticTexts["No matching tasks"].exists)
    }

    @MainActor
    func testRelaunchShowsTheMainWindow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 8))
        app.terminate()
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(app.textFields["inlineAddTaskField"].exists)
    }

}
#endif
