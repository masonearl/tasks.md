import Combine
import Foundation

@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var sections: [TaskSection] = []
    @Published private(set) var lastErrorMessage: String?
    private let fileCoordinator = FileCoordinatorService()
    private var fileUrl: URL?
    private var loadedText = ""

    func load(from text: String) {
        loadedText = text
        let parsed = MarkdownParser.parse(text)
        if parsed.sections != sections { sections = parsed.sections }
    }

    func bind(to url: URL) {
        fileUrl = url
        lastErrorMessage = nil
    }

    func dismissError() { lastErrorMessage = nil }

    func availableSectionTitles() -> [String] {
        var seen = Set<String>()
        return sections.map(\.title).filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    @discardableResult
    func addTask(title: String) -> Bool {
        addTask(title: title, inSectionTitle: availableSectionTitles().first ?? "Tasks")
    }

    @discardableResult
    func addTask(title: String, inSectionTitle sectionTitle: String) -> Bool {
        let title = singleLine(title)
        let section = singleLine(sectionTitle)
        guard !title.isEmpty else {
            lastErrorMessage = "Enter a task title."
            return false
        }
        let target = section.isEmpty ? "Tasks" : section
        return write { current in
            let document = MarkdownParser.parse(current)
            var lines = document.lines
            if let section = document.sections.first(where: { $0.title == target }),
               let header = document.sectionHeaderIndices[section.id] {
                var insertion = document.sectionHeaderIndices.values.filter { $0 > header }.min() ?? lines.count
                while insertion > header + 1 && lines[insertion - 1].trimmingCharacters(in: .whitespaces).isEmpty {
                    insertion -= 1
                }
                lines.insert("- [ ] " + title, at: insertion)
            } else {
                if lines.last != "" { lines.append("") }
                lines.append(contentsOf: ["## " + target, "- [ ] " + title, ""])
            }
            return lines.joined(separator: document.lineEnding)
        }
    }

    @discardableResult
    func toggle(task: TaskItem) -> Bool {
        update(task) { line in
            var result = Self.settingCompletion(line, completed: !task.isCompleted)
            result = Self.removingTag("completed", from: result)
            result = Self.removingTag("repeated", from: result)
            if !task.isCompleted {
                result += " @completed(\(ISO8601DateFormatter().string(from: Date())))"
            }
            return result
        }
    }

    @discardableResult
    func updateTitle(task: TaskItem, newTitle: String) -> Bool {
        let title = singleLine(newTitle)
        guard !title.isEmpty else { return false }
        return update(task) { line in
            guard let box = line.range(of: "]") else { return line }
            let tags = MarkdownParser.tagRegex.matches(in: line, range: NSRange(line.startIndex..., in: line))
                .compactMap { Range($0.range, in: line).map { String(line[$0]) } }
            return String(line[...box.lowerBound]) + " " + title + (tags.isEmpty ? "" : " " + tags.joined(separator: " "))
        }
    }

    func addRepeatTag(task: TaskItem, repeatType: String) {
        guard ["daily", "weekly", "monthly"].contains(repeatType) else { return }
        update(task) { Self.removingTag("repeat", from: $0) + " @repeat(\(repeatType))" }
    }

    func removeRepeatTag(task: TaskItem) {
        update(task) { Self.removingTag("repeat", from: $0) }
    }

    /// Mark each completed occurrence after generating its successor, making reloads idempotent.
    func processRepeatingTasks(now: Date = Date(), calendar: Calendar = .current) {
        guard sections.flatMap(\.tasks).contains(where: { $0.isCompleted && $0.tags.custom["repeat"] != nil && $0.tags.custom["repeated"] == nil }) else { return }
        write { current in
            let document = MarkdownParser.parse(current)
            var lines = document.lines
            let tasks = document.sections.flatMap(\.tasks)
                .sorted { (document.taskLineIndices[$0.id] ?? 0) > (document.taskLineIndices[$1.id] ?? 0) }
            for task in tasks {
                guard task.isCompleted, let completed = task.tags.completedAt,
                      let frequency = task.tags.custom["repeat"], task.tags.custom["repeated"] == nil,
                      let index = document.taskLineIndices[task.id] else { continue }
                let component: Calendar.Component
                switch frequency {
                case "daily": component = .day
                case "weekly": component = .weekOfYear
                case "monthly": component = .month
                default: continue
                }
                guard let nextDate = calendar.date(byAdding: component, value: 1, to: completed), nextDate <= now else { continue }
                var next = Self.settingCompletion(lines[index], completed: false)
                next = Self.removingTag("completed", from: next)
                // Advance a due date by the same interval, retaining its plain-date format.
                if let due = task.tags.dueDate, let nextDue = calendar.date(byAdding: component, value: 1, to: due) {
                    let formatter = DateFormatter()
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    formatter.calendar = calendar
                    formatter.timeZone = calendar.timeZone
                    formatter.dateFormat = "yyyy-MM-dd"
                    next = Self.removingTag("due", from: next) + " @due(\(formatter.string(from: nextDue)))"
                }
                lines[index] += " @repeated(\(ISO8601DateFormatter().string(from: now)))"
                lines.insert(next, at: index + 1)
            }
            return lines.joined(separator: document.lineEnding)
        }
    }

    @discardableResult
    private func update(_ task: TaskItem, transform: (String) -> String) -> Bool {
        let expected = loadedText
        return write { current in
            // Matching a duplicate by occurrence is safe only against the version shown to the user.
            guard current == expected else { throw EditError.changedExternally }
            let document = MarkdownParser.parse(current)
            guard let index = document.taskLineIndices[task.id] else { throw EditError.changedExternally }
            var lines = document.lines
            lines[index] = transform(lines[index])
            return lines.joined(separator: document.lineEnding)
        }
    }

    @discardableResult
    private func write(_ update: (String) throws -> String) -> Bool {
        guard let fileUrl else {
            lastErrorMessage = "No tasks file is selected."
            return false
        }
        let accessed = fileUrl.startAccessingSecurityScopedResource()
        defer { if accessed { fileUrl.stopAccessingSecurityScopedResource() } }
        do {
            try fileCoordinator.write(url: fileUrl, update: update)
            load(from: try fileCoordinator.read(url: fileUrl))
            lastErrorMessage = nil
            return true
        } catch {
            if let latest = try? fileCoordinator.read(url: fileUrl) { load(from: latest) }
            lastErrorMessage = error.localizedDescription
            return false
        }
    }

    private func singleLine(_ value: String) -> String {
        value.components(separatedBy: .newlines).joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }

    private static func settingCompletion(_ line: String, completed: Bool) -> String {
        var result = line
        if let range = result.range(of: "- \\[[ xX]\\]", options: .regularExpression) {
            result.replaceSubrange(range, with: completed ? "- [x]" : "- [ ]")
        }
        return result
    }

    private static func removingTag(_ key: String, from line: String) -> String {
        let regex = try! NSRegularExpression(pattern: "[ \\t]*@" + NSRegularExpression.escapedPattern(for: key) + "\\([^)]*\\)")
        return regex.stringByReplacingMatches(in: line, range: NSRange(line.startIndex..., in: line), withTemplate: "")
    }

    private enum EditError: LocalizedError {
        case changedExternally
        var errorDescription: String? {
            "This file changed in another app. The latest tasks are loaded; please try your edit again."
        }
    }
}
