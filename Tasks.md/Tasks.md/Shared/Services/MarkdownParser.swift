import Foundation

public enum MarkdownParser {
    public struct ParsedDocument {
        public var sections: [TaskSection]
        public var lines: [String]
        public var taskLineIndices: [String: Int]
        public var sectionHeaderIndices: [String: Int]
        public var lineEnding: String
    }

    static let tagRegex = try! NSRegularExpression(pattern: "@([a-zA-Z0-9_-]+)\\((.*?)\\)")

    public static func parse(_ text: String) -> ParsedDocument {
        let lineEnding = text.contains("\r\n") ? "\r\n" : "\n"
        let lines = text.components(separatedBy: lineEnding)
        var currentPath: [String] = []
        var currentTasks: [TaskItem] = []
        var sections: [TaskSection] = []
        var titleOccurrences: [String: Int] = [:]
        var sectionOccurrences: [String: Int] = [:]
        var taskLineIndices: [String: Int] = [:]
        var sectionHeaderIndices: [String: Int] = [:]
        var sectionID = ""
        var fence: (character: Character, count: Int)?

        func flushSection() {
            guard !currentTasks.isEmpty || !currentPath.isEmpty else { return }
            sections.append(TaskSection(title: currentPath.last ?? "", path: [], tasks: currentTasks, id: sectionID))
            currentTasks.removeAll()
        }

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let first = trimmed.first, first == "`" || first == "~" {
                let count = trimmed.prefix(while: { $0 == first }).count
                if count >= 3 {
                    if let current = fence {
                        if first == current.character && count >= current.count && trimmed.dropFirst(count).trimmingCharacters(in: .whitespaces).isEmpty {
                            fence = nil
                        }
                    } else {
                        fence = (first, count)
                    }
                    continue
                }
            }
            guard fence == nil else { continue }
            if let heading = headingTitle(line) {
                flushSection()
                currentPath = [heading]
                let occurrence = sectionOccurrences[heading, default: 0]
                sectionOccurrences[heading] = occurrence + 1
                sectionID = "\(heading)\u{241F}\(occurrence)"
                sectionHeaderIndices[sectionID] = index
                continue
            }
            if let task = parseTask(line: line, sectionPath: currentPath, titleOccurrences: &titleOccurrences) {
                currentTasks.append(task)
                taskLineIndices[task.id] = index
            }
        }
        flushSection()
        return ParsedDocument(sections: sections, lines: lines, taskLineIndices: taskLineIndices, sectionHeaderIndices: sectionHeaderIndices, lineEnding: lineEnding)
    }

    static func headingTitle(_ line: String) -> String? {
        guard line.hasPrefix("## ") || line.hasPrefix("### ") else { return nil }
        return String(line.drop(while: { $0 == "#" || $0 == " " })).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func parseTask(line: String, sectionPath: [String], titleOccurrences: inout [String: Int]) -> TaskItem? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("- [ ]") || trimmed.hasPrefix("- [x]") || trimmed.hasPrefix("- [X]") else { return nil }
        let isCompleted = trimmed.hasPrefix("- [x]") || trimmed.hasPrefix("- [X]")
        let afterBox = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
        var tags = TaskItem.Tags()
        let matches = tagRegex.matches(in: afterBox, range: NSRange(afterBox.startIndex..., in: afterBox))
        for match in matches {
            let key = String(afterBox[Range(match.range(at: 1), in: afterBox)!])
            let value = String(afterBox[Range(match.range(at: 2), in: afterBox)!])
            switch key {
            case "priority": tags.priority = TaskItem.Priority(rawValue: value)
            case "due": tags.dueDate = parseDate(value)
            case "remind": tags.remindAt = parseDate(value)
            case "completed": tags.completedAt = parseDate(value)
            default: tags.custom[key] = value
            }
        }
        let title = tagRegex.stringByReplacingMatches(in: afterBox, range: NSRange(afterBox.startIndex..., in: afterBox), withTemplate: "")
            .trimmingCharacters(in: .whitespaces)
        let key = (sectionPath + [title]).joined(separator: "\u{241F}")
        let occurrence = titleOccurrences[key, default: 0]
        titleOccurrences[key] = occurrence + 1
        return TaskItem(id: "\(key)\u{241F}\(occurrence)", title: title, isCompleted: isCompleted, sectionPath: sectionPath, tags: tags)
    }

    static func parseDate(_ value: String) -> Date? {
        fractionalISO.date(from: value) ?? iso.date(from: value) ?? ymd.date(from: value)
    }

    private static let fractionalISO: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    private static let iso = ISO8601DateFormatter()
    private static let ymd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter
    }()
}
