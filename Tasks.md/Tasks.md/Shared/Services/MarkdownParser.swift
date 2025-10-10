import Foundation

public enum MarkdownParser {
    public struct ParsedDocument {
        public var sections: [TaskSection]
        public var lines: [String]
    }

    private static let tagRegex = try! NSRegularExpression(pattern: "@([a-zA-Z0-9_-]+)\\((.*?)\\)")

    public static func parse(_ text: String) -> ParsedDocument {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var currentPath: [String] = []
        var currentTasks: [TaskItem] = []
        var sections: [TaskSection] = []

        func flushSectionIfNeeded() {
            guard !currentTasks.isEmpty || !currentPath.isEmpty else { return }
            let title = currentPath.last ?? ""
            let path = Array(currentPath.dropLast())
            sections.append(TaskSection(title: title, path: path, tasks: currentTasks))
            currentTasks.removeAll()
        }

        for line in lines {
            if let heading = parseHeading(line) {
                flushSectionIfNeeded()
                currentPath = heading
                continue
            }
            if let task = parseTask(line: line, sectionPath: currentPath) {
                currentTasks.append(task)
            }
        }
        flushSectionIfNeeded()

        return ParsedDocument(sections: sections, lines: lines)
    }

    private static func parseHeading(_ line: String) -> [String]? {
        guard line.hasPrefix("## ") || line.hasPrefix("### ") else { return nil }
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let level = trimmed.prefix { $0 == "#" }.count
        let title = trimmed.drop(while: { $0 == "#" || $0 == " " })
        if level >= 2 { return [String(title)] }
        return nil
    }

    private static func parseTask(line: String, sectionPath: [String]) -> TaskItem? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("- [ ]") || trimmed.hasPrefix("- [x]") || trimmed.hasPrefix("- [X]") else { return nil }
        let isCompleted = trimmed.contains("- [x]") || trimmed.contains("- [X]")

        let afterBox: String
        if let range = trimmed.range(of: "] ") {
            afterBox = String(trimmed[range.upperBound...])
        } else {
            afterBox = trimmed
        }

        var tags = TaskItem.Tags()
        var title = afterBox
        let matches = tagRegex.matches(in: afterBox, range: NSRange(location: 0, length: afterBox.utf16.count))
        for m in matches.reversed() {
            let key = String(afterBox[Range(m.range(at: 1), in: afterBox)!])
            let value = String(afterBox[Range(m.range(at: 2), in: afterBox)!])
            switch key {
            case "priority": tags.priority = TaskItem.Priority(rawValue: value)
            case "due": tags.dueDate = parseDate(value)
            case "remind": tags.remindAt = parseDate(value)
            case "completed": tags.completedAt = parseDate(value)
            case "repeat": tags.custom["repeat"] = value
            default: tags.custom[key] = value
            }
            if let r = Range(m.range, in: afterBox) { title.removeSubrange(r) }
        }
        title = title.trimmingCharacters(in: .whitespaces)

        let id = makeStableId(sectionPath: sectionPath, title: title)
        return TaskItem(id: id, title: title, isCompleted: isCompleted, sectionPath: sectionPath, tags: tags)
    }

    private static func makeStableId(sectionPath: [String], title: String) -> String {
        let input = (sectionPath + [title]).joined(separator: "\u{241F}")
        return String(input.hashValue)
    }

    private static func parseDate(_ s: String) -> Date? {
        if let d = isoFormatter.date(from: s) { return d }
        if let d = ymdFormatter.date(from: s) { return d }
        return nil
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let ymdFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}


