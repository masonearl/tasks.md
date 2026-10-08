import Foundation
import Testing
@testable import Tasks_md

@MainActor
struct TaskEditingTests {
    private func withStore(_ text: String, run: (TaskStore, URL) throws -> Void) throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("tasks-test-\(UUID()).md")
        try text.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        let store = TaskStore()
        store.bind(to: url)
        store.load(from: text)
        try run(store, url)
    }

    @Test func editsTheSecondDuplicateWithoutChangingTheFirst() throws {
        try withStore("## Work\n- [ ] Same @priority(low)\n  - [ ] Same @priority(high)\n") { store, url in
            let second = store.sections[0].tasks[1]
            #expect(store.toggle(task: second))
            #expect(!store.sections[0].tasks[0].isCompleted)
            #expect(store.sections[0].tasks[1].isCompleted)
            #expect(store.sections[0].tasks[1].tags.completedAt != nil)
            #expect(store.updateTitle(task: store.sections[0].tasks[1], newTitle: "Renamed 👋"))
            let text = try String(contentsOf: url, encoding: .utf8)
            #expect(text.contains("- [ ] Same @priority(low)"))
            #expect(text.contains("  - [x] Renamed 👋 @priority(high)"))
        }
    }

    @Test func repeatMenuEditsTheCorrectDuplicate() throws {
        try withStore("## Tasks\n- [ ] Same\n- [ ] Same\n") { store, _ in
            store.addRepeatTag(task: store.sections[0].tasks[1], repeatType: "weekly")
            #expect(store.sections[0].tasks[0].tags.custom["repeat"] == nil)
            #expect(store.sections[0].tasks[1].tags.custom["repeat"] == "weekly")
            store.removeRepeatTag(task: store.sections[0].tasks[1])
            #expect(store.sections[0].tasks[1].tags.custom["repeat"] == nil)
        }
    }

    @Test func externalEditsArePreservedAndStaleEditsAreReported() throws {
        try withStore("## Tasks\n- [ ] Same\n- [ ] Same\n") { store, url in
            let second = store.sections[0].tasks[1]
            let external = "## Tasks\n- [ ] Same\n- [ ] Added externally\n"
            try external.write(to: url, atomically: true, encoding: .utf8)
            #expect(!store.toggle(task: second))
            #expect(store.lastErrorMessage != nil)
            let savedText = try String(contentsOf: url, encoding: .utf8)
            #expect(savedText == external)
            #expect(store.sections[0].tasks[1].title == "Added externally")
        }
    }

    @Test func unreadableContentIsNeverReplacedWithAnEmptyDocument() throws {
        try withStore("## Tasks\n- [ ] Keep me\n") { store, url in
            let invalidUTF8 = Data([0xff, 0xfe, 0xff])
            try invalidUTF8.write(to: url)
            #expect(!store.addTask(title: "New"))
            #expect(store.lastErrorMessage != nil)
            let savedData = try Data(contentsOf: url)
            #expect(savedData == invalidUTF8)
        }
    }

    @Test func recurrenceIsIdempotentAndKeepsTheOriginalSection() throws {
        let initial = "## Habits\n- [x] Review @repeat(daily) @completed(2026-01-01T10:00:00Z) @due(2026-01-01)\n\n## Work\n- [ ] Other\n"
        try withStore(initial) { store, url in
            let now = ISO8601DateFormatter().date(from: "2026-01-03T12:00:00Z")!
            store.processRepeatingTasks(now: now)
            store.processRepeatingTasks(now: now)
            #expect(store.sections.count == 2)
            #expect(store.sections[0].tasks.count == 2)
            #expect(store.sections[0].tasks[0].isCompleted)
            #expect(store.sections[0].tasks[0].tags.custom["repeated"] != nil)
            #expect(!store.sections[0].tasks[1].isCompleted)
            #expect(store.sections[0].tasks[1].tags.custom["repeat"] == "daily")
            let savedText = try String(contentsOf: url, encoding: .utf8)
            #expect(savedText.contains("@due(2026-01-02)"))
        }
    }

    @Test func recurrenceWorksInLargeFiles() throws {
        let otherTasks = (0..<150).map { "- [ ] Task \($0)" }.joined(separator: "\n")
        try withStore("## Habits\n- [x] Review @repeat(weekly) @completed(2026-01-01T10:00:00.000Z)\n" + otherTasks) { store, _ in
            store.processRepeatingTasks(now: ISO8601DateFormatter().date(from: "2026-01-09T12:00:00Z")!)
            #expect(store.sections[0].tasks.count == 152)
        }
    }

    @Test func recurringTaskIsNotGeneratedBeforeItsNextDate() throws {
        try withStore("## Habits\n- [x] Review @repeat(monthly) @completed(2026-01-31T10:00:00Z)\n") { store, url in
            let before = try String(contentsOf: url, encoding: .utf8)
            store.processRepeatingTasks(now: ISO8601DateFormatter().date(from: "2026-02-01T12:00:00Z")!)
            let savedText = try String(contentsOf: url, encoding: .utf8)
            #expect(savedText == before)
            store.processRepeatingTasks(now: ISO8601DateFormatter().date(from: "2026-02-28T12:00:00Z")!)
            #expect(store.sections[0].tasks.count == 2)
        }
    }

    @Test func codeExamplesAreNotEditableTasks() throws {
        let initial = "## Guide\n```markdown\n## Work\n- [ ] Example\n```\n\n## Work\n- [ ] Real\n"
        try withStore(initial) { store, url in
            #expect(store.sections.flatMap(\.tasks).map(\.title) == ["Real"])
            #expect(store.addTask(title: "New", inSectionTitle: "Work"))
            let savedText = try String(contentsOf: url, encoding: .utf8)
            #expect(savedText.contains("## Work\n- [ ] Real\n- [ ] New"))
        }
    }

    @Test func duplicateSectionNamesHaveUniqueIdentities() {
        let document = MarkdownParser.parse("## Work\n- [ ] Same\n## Work\n- [ ] Same\n")
        #expect(Set(document.sections.map(\.id)).count == 2)
        #expect(Set(document.sections.flatMap(\.tasks).map(\.id)).count == 2)
    }

    @Test func checkboxTextInsideATitleDoesNotMarkTheTaskComplete() {
        let document = MarkdownParser.parse("- [ ] Explain - [x] syntax")
        #expect(document.sections[0].tasks[0].isCompleted == false)
    }

    @Test func completionToggleOnlyChangesTheLeadingCheckbox() throws {
        try withStore("## Tasks\n- [ ] Explain - [ ] syntax\n") { store, url in
            store.toggle(task: store.sections[0].tasks[0])
            let savedText = try String(contentsOf: url, encoding: .utf8)
            #expect(savedText.contains("- [x] Explain - [ ] syntax"))
        }
    }

    @Test func renamePreservesTagsAndDoesNotTreatEmailAsATag() throws {
        try withStore("## Tasks\n  - [ ] Email a@b.com @priority(high) @owner(Mason)\n") { store, url in
            store.updateTitle(task: store.sections[0].tasks[0], newTitle: "Call 📞 Mason")
            let savedText = try String(contentsOf: url, encoding: .utf8)
            #expect(savedText == "## Tasks\n  - [ ] Call 📞 Mason @priority(high) @owner(Mason)\n")
        }
    }

    @Test func todayFilterIncludesOverdueAndExcludesCompleted() {
        let tasks = MarkdownParser.parse("## Tasks\n- [ ] Past @due(2026-01-01)\n- [ ] Today @due(2026-01-03)\n- [ ] Later @due(2026-01-05)\n- [x] Done @due(2026-01-01)\n- [ ] No date").sections[0].tasks
        let now = ISO8601DateFormatter().date(from: "2026-01-03T12:00:00Z")!
        #expect(tasks.filter { TaskFilter.today.includes($0, now: now) }.map(\.title) == ["Past", "Today"])
        #expect(TaskSort.due.sorted(tasks).last?.title == "No date")
    }
    @Test func editsPreserveWindowsLineEndings() throws {
        try withStore("## Tasks\r\n- [ ] First\r\n") { store, url in
            #expect(store.sections[0].tasks[0].title == "First")
            store.updateTitle(task: store.sections[0].tasks[0], newTitle: "Renamed")
            store.addTask(title: "Second")
            let saved = try String(contentsOf: url, encoding: .utf8)
            #expect(saved == "## Tasks\r\n- [ ] Renamed\r\n- [ ] Second\r\n")
        }
    }

}
