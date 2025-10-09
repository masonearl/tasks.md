import Combine
import Foundation

@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var sections: [TaskSection] = []
    private let fileCoordinator = FileCoordinatorService()
    private var fileUrl: URL?

    func load(from text: String) {
        let parsed = MarkdownParser.parse(text)
        self.sections = parsed.sections
    }

    func bind(to url: URL) {
        self.fileUrl = url
    }

    func updateTitle(task: TaskItem, newTitle: String) {
        guard let fileUrl else { return }
        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }
        _ = fileUrl.startAccessingSecurityScopedResource()
        defer { fileUrl.stopAccessingSecurityScopedResource() }
        do {
            try fileCoordinator.write(url: fileUrl) { current in
                var lines = current.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
                var currentPath: [String] = []

                func isTaskLine(_ s: String) -> Bool {
                    let t = s.trimmingCharacters(in: .whitespaces)
                    return t.hasPrefix("- [ ]") || t.hasPrefix("- [x]") || t.hasPrefix("- [X]")
                }

                func replaceTitle(in s: String) -> String {
                    let t = s.trimmingCharacters(in: .whitespaces)
                    guard let r = t.range(of: "] ") else { return s }
                    var before = String(t[..<r.upperBound])
                    var after = String(t[r.upperBound...])
                    // keep tags after title intact
                    var tagSuffix = ""
                    if let tagStart = after.firstIndex(of: "@") {
                        tagSuffix = String(after[tagStart...])
                    }
                    return before + trimmedTitle + (tagSuffix.isEmpty ? "" : " " + tagSuffix)
                }

                for i in lines.indices {
                    let line = lines[i]
                    if line.hasPrefix("## ") || line.hasPrefix("### ") {
                        let trimmed = line.trimmingCharacters(in: .whitespaces)
                        let level = trimmed.prefix { $0 == "#" }.count
                        let title = trimmed.drop(while: { $0 == "#" || $0 == " " })
                        if level >= 2 { currentPath = [String(title)] }
                        continue
                    }
                    guard currentPath == task.sectionPath, isTaskLine(line) else { continue }
                    // match by current extracted title
                    let existingTitle = extractTitle(from: line)
                    if existingTitle == task.title {
                        lines[i] = replaceTitle(in: line)
                        break
                    }
                }
                return lines.joined(separator: "\n")
            }
            let updated = try fileCoordinator.read(url: fileUrl)
            self.load(from: updated)
        } catch {
        }
    }

    private func extractTitle(from s: String) -> String {
        let t = s.trimmingCharacters(in: .whitespaces)
        guard let r = t.range(of: "] ") else { return t }
        var after = String(t[r.upperBound...])
        // remove @key(value) tags
        let regex = try? NSRegularExpression(pattern: "@([a-zA-Z0-9_-]+)\\((.*?)\\)")
        if let regex {
            let matches = regex.matches(in: after, range: NSRange(location: 0, length: after.utf16.count))
            for m in matches.reversed() {
                if let range = Range(m.range, in: after) { after.removeSubrange(range) }
            }
        }
        return after.trimmingCharacters(in: .whitespaces)
    }

    func availableSectionTitles() -> [String] {
        sections.map { $0.title }.filter { !$0.isEmpty }
    }

    func addTask(title: String) {
        // Backward-compat: insert into first section or default
        let target = availableSectionTitles().first ?? "Tasks"
        addTask(title: title, inSectionTitle: target)
    }

    func addTask(title: String, inSectionTitle sectionTitle: String) {
        guard let fileUrl else { return }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        _ = fileUrl.startAccessingSecurityScopedResource()
        defer { fileUrl.stopAccessingSecurityScopedResource() }
        do {
            try fileCoordinator.write(url: fileUrl) { current in
                var lines = current.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

                func isHeader(_ s: String) -> Bool {
                    let t = s.trimmingCharacters(in: .whitespaces)
                    return t.hasPrefix("## ") || t.hasPrefix("### ")
                }
                func headerTitle(_ s: String) -> String {
                    let t = s.trimmingCharacters(in: .whitespaces)
                    let _ = t.prefix { $0 == "#" }.count
                    let title = t.drop(while: { $0 == "#" || $0 == " " })
                    return String(title)
                }

                if let headerIndex = lines.firstIndex(where: { isHeader($0) && headerTitle($0) == sectionTitle }) {
                    // insert before next header or EOF
                    var i = lines.index(after: headerIndex)
                    while i < lines.endIndex {
                        if isHeader(lines[i]) { break }
                        i = lines.index(after: i)
                    }
                    var insertIndex = i
                    if insertIndex > headerIndex + 1 && !lines[lines.index(before: insertIndex)].isEmpty {
                        lines.insert("", at: insertIndex)
                        insertIndex = lines.index(after: insertIndex)
                    }
                    lines.insert("- [ ] " + trimmedTitle, at: insertIndex)
                } else {
                    // If section is missing, create it at end
                    if !lines.isEmpty && !lines.last!.isEmpty { lines.append("") }
                    lines.append("## " + sectionTitle)
                    lines.append("- [ ] " + trimmedTitle)
                }
                return lines.joined(separator: "\n")
            }
            let updated = try fileCoordinator.read(url: fileUrl)
            self.load(from: updated)
        } catch {
        }
    }

    func toggle(task: TaskItem) {
        guard let fileUrl else { return }
        _ = fileUrl.startAccessingSecurityScopedResource()
        defer { fileUrl.stopAccessingSecurityScopedResource() }
        do {
            try fileCoordinator.write(url: fileUrl) { current in
                var lines = current.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
                var currentPath: [String] = []
                let iso = ISO8601DateFormatter()
                iso.formatOptions = [.withInternetDateTime]

                func isTaskLine(_ s: String) -> Bool {
                    let t = s.trimmingCharacters(in: .whitespaces)
                    return t.hasPrefix("- [ ]") || t.hasPrefix("- [x]") || t.hasPrefix("- [X]")
                }

                func extractTitle(from s: String) -> String {
                    let t = s.trimmingCharacters(in: .whitespaces)
                    guard let r = t.range(of: "] ") else { return t }
                    var after = String(t[r.upperBound...])
                    // remove @key(value) tags
                    let regex = try? NSRegularExpression(pattern: "@([a-zA-Z0-9_-]+)\\((.*?)\\)")
                    if let regex {
                        let matches = regex.matches(in: after, range: NSRange(location: 0, length: after.utf16.count))
                        for m in matches.reversed() {
                            if let range = Range(m.range, in: after) { after.removeSubrange(range) }
                        }
                    }
                    return after.trimmingCharacters(in: .whitespaces)
                }

                func toggleLine(_ s: String, complete: Bool) -> String {
                    var out = s
                    if complete {
                        out = out.replacingOccurrences(of: "- [ ]", with: "- [x]")
                        if !out.contains("@completed(") {
                            out += " @completed(\(iso.string(from: Date())))"
                        }
                    } else {
                        out = out.replacingOccurrences(of: "- [x]", with: "- [ ]").replacingOccurrences(of: "- [X]", with: "- [ ]")
                        // remove any @completed(...)
                        if let regex = try? NSRegularExpression(pattern: "@completed\\((.*?)\\)") {
                            out = regex.stringByReplacingMatches(in: out, range: NSRange(location: 0, length: out.utf16.count), withTemplate: "")
                            out = out.replacingOccurrences(of: "  ", with: " ").trimmingCharacters(in: .whitespaces)
                        }
                    }
                    return out
                }

                for i in lines.indices {
                    let line = lines[i]
                    if line.hasPrefix("## ") || line.hasPrefix("### ") {
                        let trimmed = line.trimmingCharacters(in: .whitespaces)
                        let level = trimmed.prefix { $0 == "#" }.count
                        let title = trimmed.drop(while: { $0 == "#" || $0 == " " })
                        if level >= 2 { currentPath = [String(title)] }
                        continue
                    }
                    guard currentPath == task.sectionPath, isTaskLine(line) else { continue }
                    let title = extractTitle(from: line)
                    if title == task.title {
                        let willComplete = !line.contains("- [x]") && !line.contains("- [X]")
                        lines[i] = toggleLine(line, complete: willComplete)
                        break
                    }
                }
                return lines.joined(separator: "\n")
            }
            // Re-read updated content and refresh sections
            let updated = try fileCoordinator.read(url: fileUrl)
            self.load(from: updated)
        } catch {
        }
    }
}


