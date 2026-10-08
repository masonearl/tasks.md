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

    @Test func assignsUniqueIdsToDuplicateTitles() {
        let markdown = """
        ## Work
        - [ ] Same title
        - [ ] Same title
        """

        let doc = MarkdownParser.parse(markdown)
        let ids = doc.sections[0].tasks.map(\.id)
        #expect(Set(ids).count == 2)
        #expect(ids[0] != ids[1])
    }

    @Test func parsesRepeatTag() {
        let markdown = """
        ## Habits
        - [ ] Daily review @repeat(daily)
        """

        let doc = MarkdownParser.parse(markdown)
        #expect(doc.sections.first?.tasks.first?.tags.custom["repeat"] == "daily")
    }

    @Test @MainActor func addTaskWritesCheckboxIntoExistingSection() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("add-task-\(UUID().uuidString).md")
        let initial = """
        ## Work
        - [ ] Existing
        """
        try initial.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let store = TaskStore()
        store.bind(to: url)
        store.load(from: initial)

        let added = store.addTask(title: "Reviewer task", inSectionTitle: "Work")
        #expect(added)
        #expect(store.lastErrorMessage == nil)
        #expect(store.sections.first { $0.title == "Work" }?.tasks.contains(where: { $0.title == "Reviewer task" }) == true)

        let text = try String(contentsOf: url, encoding: .utf8)
        #expect(text.contains("- [ ] Reviewer task"))
        #expect(text.contains("- [ ] Existing"))
    }

    @Test @MainActor func addTaskCreatesMissingSection() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("add-task-section-\(UUID().uuidString).md")
        let initial = "# Tasks\n"
        try initial.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let store = TaskStore()
        store.bind(to: url)
        store.load(from: initial)

        let added = store.addTask(title: "Inbox item", inSectionTitle: "Personal")
        #expect(added)

        let text = try String(contentsOf: url, encoding: .utf8)
        #expect(text.contains("## Personal"))
        #expect(text.contains("- [ ] Inbox item"))
    }

    @Test @MainActor func addTaskFailsWithoutABoundFile() {
        let store = TaskStore()
        let added = store.addTask(title: "Orphan", inSectionTitle: "Tasks")
        #expect(!added)
        #expect(store.lastErrorMessage != nil)
    }

    @Test func defaultTasksFileWritesStarterMarkdown() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("starter-\(UUID().uuidString).md")
        try DefaultTasksFile.starterMarkdown.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let text = try String(contentsOf: url, encoding: .utf8)
        #expect(text.contains("## Today"))
        #expect(text.contains("- [ ] Check off this task"))
    }

    @Test func newTasksFileNameHasNoColons() {
        let name = NewTasksFileName.make(date: Date(timeIntervalSince1970: 0))
        #expect(name == "Tasks 1970-01-01 000000.md")
        #expect(!name.contains(":"))
        #expect(!name.contains("/"))
    }

    @Test func bookmarkStoreRoundTripsALocalFile() throws {
        let suite = "bookmark-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("bookmark-\(UUID().uuidString).md")
        try "# Tasks\n".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let store = BookmarkStore(defaults: defaults)
        store.saveBookmark(for: url)
        #expect(defaults.data(forKey: "tasksFileBookmark") != nil)

        let resolved = store.resolveBookmark()
        #expect(resolved?.standardizedFileURL.path == url.standardizedFileURL.path)
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
        Thread.sleep(forTimeInterval: 0.2)
        let updated = "## Tasks\n- [ ] One\n- [ ] Two from Cursor\n"
        try updated.write(to: url, atomically: true, encoding: .utf8)

        let second = FileWatcher.signature(for: url)
        #expect(second != nil)
        #expect(first != second)
    }
}
