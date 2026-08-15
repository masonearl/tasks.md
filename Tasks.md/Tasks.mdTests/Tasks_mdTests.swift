//
//  Tasks_mdTests.swift
//  Tasks.mdTests
//
//  Created by Mason Earl on 10/9/25.
//

import Foundation
import Testing
@testable import Tasks_md

struct Tasks_mdTests {

    @Test func parsesSectionsAndCheckboxes() {
        let markdown = """
        ## Work
        - [ ] Ship file watching @priority(high)
        - [x] Publish v1.0 @completed(2025-10-13T17:17:57Z)

        ## Personal
        - [ ] Call dentist @due(2026-08-20)
        """

        let doc = MarkdownParser.parse(markdown)
        #expect(doc.sections.count == 2)
        #expect(doc.sections[0].title == "Work")
        #expect(doc.sections[0].tasks.count == 2)
        #expect(doc.sections[0].tasks[0].title == "Ship file watching")
        #expect(doc.sections[0].tasks[0].isCompleted == false)
        #expect(doc.sections[0].tasks[0].tags.priority == .high)
        #expect(doc.sections[0].tasks[1].isCompleted == true)
        #expect(doc.sections[1].title == "Personal")
        #expect(doc.sections[1].tasks[0].tags.dueDate != nil)
    }

    @Test func parsesRepeatTag() {
        let markdown = """
        ## Habits
        - [ ] Daily review @repeat(daily)
        """

        let doc = MarkdownParser.parse(markdown)
        #expect(doc.sections.first?.tasks.first?.tags.custom["repeat"] == "daily")
    }

    @Test func fileSignatureChangesWhenFileIsWritten() throws {
        let dir = FileManager.default.temporaryDirectory
        let url = dir.appendingPathComponent("tasks-watcher-\(UUID().uuidString).md")
        let initial = "## Tasks\n- [ ] One\n"
        try initial.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let first = FileWatcher.signature(for: url)
        #expect(first != nil)

        // Ensure mtime can move forward on coarse filesystems
        Thread.sleep(forTimeInterval: 0.05)
        let updated = "## Tasks\n- [ ] One\n- [ ] Two from Cursor\n"
        try updated.write(to: url, atomically: true, encoding: .utf8)

        let second = FileWatcher.signature(for: url)
        #expect(second != nil)
        #expect(first != second)
    }
}
