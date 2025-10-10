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
        // Note: Auto-organizing disabled for performance
        // organizeCompletedTasks()
    }
    
    /// Scans file and moves all completed tasks to Completed section
    func organizeCompletedTasks() {
        guard let fileUrl else { return }
        _ = fileUrl.startAccessingSecurityScopedResource()
        defer { fileUrl.stopAccessingSecurityScopedResource() }
        
        do {
            try fileCoordinator.write(url: fileUrl) { current in
                var lines = current.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
                var completedTasks: [(line: String, section: String)] = []
                var currentSection = "Tasks"
                
                func isHeader(_ s: String) -> Bool {
                    let t = s.trimmingCharacters(in: .whitespaces)
                    return t.hasPrefix("## ") || t.hasPrefix("### ")
                }
                
                func headerTitle(_ s: String) -> String {
                    let t = s.trimmingCharacters(in: .whitespaces)
                    return String(t.drop(while: { $0 == "#" || $0 == " " }))
                }
                
                func isCompletedTask(_ s: String) -> Bool {
                    let t = s.trimmingCharacters(in: .whitespaces)
                    return t.hasPrefix("- [x]") || t.hasPrefix("- [X]")
                }
                
                // First pass: collect completed tasks and their sections
                var linesToRemove: [Int] = []
                for i in lines.indices {
                    let line = lines[i]
                    if isHeader(line) {
                        let title = headerTitle(line)
                        currentSection = title
                    } else if isCompletedTask(line) && currentSection != "Completed" {
                        completedTasks.append((line: line, section: currentSection))
                        linesToRemove.append(i)
                    }
                }
                
                // Remove completed tasks from their original sections (in reverse order)
                for i in linesToRemove.reversed() {
                    lines.remove(at: i)
                }
                
                // Add/append to Completed section
                if !completedTasks.isEmpty {
                    if let headerIndex = lines.firstIndex(where: { isHeader($0) && headerTitle($0) == "Completed" }) {
                        // Find insertion point (before next section or EOF)
                        var insertIndex = lines.index(after: headerIndex)
                        while insertIndex < lines.endIndex {
                            if isHeader(lines[insertIndex]) { break }
                            insertIndex = lines.index(after: insertIndex)
                        }
                        // Insert completed tasks
                        for task in completedTasks {
                            lines.insert(task.line, at: insertIndex)
                            insertIndex = lines.index(after: insertIndex)
                        }
                    } else {
                        // Create Completed section at the end
                        if !lines.isEmpty && !lines.last!.isEmpty { lines.append("") }
                        lines.append("## Completed")
                        for task in completedTasks {
                            lines.append(task.line)
                        }
                    }
                }
                
                return lines.joined(separator: "\n")
            }
            
            // Reload the organized content
            let updated = try fileCoordinator.read(url: fileUrl)
            let parsed = MarkdownParser.parse(updated)
            self.sections = parsed.sections
        } catch {
            // If organization fails, continue with original sections
        }
    }

    func bind(to url: URL) {
        self.fileUrl = url
    }
    
    func processRepeatingTasks() {
        guard let fileUrl else { return }
        
        // Quick check - if no completed tasks with repeat tags, skip processing
        let quickCheck = try? fileCoordinator.read(url: fileUrl)
        guard let quickCheck = quickCheck, 
              quickCheck.contains("@repeat(") && 
              (quickCheck.contains("- [x]") || quickCheck.contains("- [X]")) else {
            return
        }
        
        // Additional check - only process if we have a reasonable number of tasks
        let taskCount = quickCheck.components(separatedBy: "- [").count
        guard taskCount < 100 else {
            print("Skipping repeat processing - too many tasks (\(taskCount))")
            return
        }
        
        _ = fileUrl.startAccessingSecurityScopedResource()
        defer { fileUrl.stopAccessingSecurityScopedResource() }
        
        do {
            try fileCoordinator.write(url: fileUrl) { current in
                var lines = current.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
                var newTasksToAdd: [String] = []
                var currentSection = "Tasks"
                
                func isHeader(_ s: String) -> Bool {
                    let t = s.trimmingCharacters(in: .whitespaces)
                    return t.hasPrefix("## ") || t.hasPrefix("### ")
                }
                
                func headerTitle(_ s: String) -> String {
                    let t = s.trimmingCharacters(in: .whitespaces)
                    return String(t.drop(while: { $0 == "#" || $0 == " " }))
                }
                
                func isCompletedTask(_ s: String) -> Bool {
                    let t = s.trimmingCharacters(in: .whitespaces)
                    return t.hasPrefix("- [x]") || t.hasPrefix("- [X]")
                }
                
                func hasRepeatTag(_ s: String) -> Bool {
                    return s.contains("@repeat(")
                }
                
                func shouldRepeat(_ s: String, repeatType: String) -> Bool {
                    // Extract completion date from the task
                    guard let completedMatch = s.range(of: "@completed(") else { return false }
                    let afterCompleted = String(s[completedMatch.upperBound...])
                    guard let endParen = afterCompleted.firstIndex(of: ")") else { return false }
                    let dateString = String(afterCompleted[..<endParen])
                    
                    guard let completedDate = parseDate(dateString) else { return false }
                    let now = Date()
                    let timeInterval = now.timeIntervalSince(completedDate)
                    
                    switch repeatType.lowercased() {
                    case "daily":
                        return timeInterval >= 24 * 60 * 60 // 24 hours
                    case "weekly":
                        return timeInterval >= 7 * 24 * 60 * 60 // 7 days
                    case "monthly":
                        return timeInterval >= 30 * 24 * 60 * 60 // 30 days
                    default:
                        return false
                    }
                }
                
                func parseDate(_ dateString: String) -> Date? {
                    let isoFormatter = ISO8601DateFormatter()
                    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    return isoFormatter.date(from: dateString)
                }
                
                func createNewTask(from completedTask: String) -> String {
                    // Remove completed status and completed date tag
                    var newTask = completedTask
                    newTask = newTask.replacingOccurrences(of: "- [x]", with: "- [ ]").replacingOccurrences(of: "- [X]", with: "- [ ]")
                    
                    // Remove completed date tag
                    if let regex = try? NSRegularExpression(pattern: "@completed\\((.*?)\\)") {
                        newTask = regex.stringByReplacingMatches(in: newTask, range: NSRange(location: 0, length: newTask.utf16.count), withTemplate: "")
                    }
                    
                    return newTask.trimmingCharacters(in: .whitespaces)
                }
                
                // Find completed tasks with repeat tags
                for line in lines {
                    if isHeader(line) {
                        currentSection = headerTitle(line)
                        continue
                    }
                    
                    if isCompletedTask(line) && hasRepeatTag(line) {
                        // Check if this task should be repeated
                        if let repeatMatch = line.range(of: "@repeat(") {
                            let afterRepeat = String(line[repeatMatch.upperBound...])
                            if let endParen = afterRepeat.firstIndex(of: ")") {
                                let repeatType = String(afterRepeat[..<endParen])
                                if shouldRepeat(line, repeatType: repeatType) {
                                    let newTask = createNewTask(from: line)
                                    newTasksToAdd.append(newTask)
                                }
                            }
                        }
                    }
                }
                
                // Add new tasks to their original sections
                if !newTasksToAdd.isEmpty {
                    for newTask in newTasksToAdd {
                        // Find the original section for this task
                        let taskTitle = extractTitleFromLine(newTask)
                        if let originalSection = findOriginalSection(for: taskTitle, in: lines) {
                            addTaskToSection(newTask, section: originalSection, in: &lines)
                        }
                    }
                }
                
                return lines.joined(separator: "\n")
            }
            
            // Reload the updated content
            let updated = try fileCoordinator.read(url: fileUrl)
            self.load(from: updated)
        } catch {
            print("Error processing repeating tasks: \(error)")
        }
    }
    
    private func extractTitleFromLine(_ line: String) -> String {
        let t = line.trimmingCharacters(in: .whitespaces)
        guard let r = t.range(of: "] ") else { return t }
        var after = String(t[r.upperBound...])
        // Remove tags
        let regex = try? NSRegularExpression(pattern: "@([a-zA-Z0-9_-]+)\\((.*?)\\)")
        if let regex {
            let matches = regex.matches(in: after, range: NSRange(location: 0, length: after.utf16.count))
            for m in matches.reversed() {
                if let range = Range(m.range, in: after) { after.removeSubrange(range) }
            }
        }
        return after.trimmingCharacters(in: .whitespaces)
    }
    
    private func findOriginalSection(for taskTitle: String, in lines: [String]) -> String? {
        // This is a simplified approach - in a real app you'd want to track original sections
        return "Tasks" // Default section
    }
    
    private func addTaskToSection(_ task: String, section: String, in lines: inout [String]) {
        func isHeader(_ s: String) -> Bool {
            let t = s.trimmingCharacters(in: .whitespaces)
            return t.hasPrefix("## ") || t.hasPrefix("### ")
        }
        
        func headerTitle(_ s: String) -> String {
            let t = s.trimmingCharacters(in: .whitespaces)
            return String(t.drop(while: { $0 == "#" || $0 == " " }))
        }
        
        if let headerIndex = lines.firstIndex(where: { isHeader($0) && headerTitle($0) == section }) {
            // Insert after the header
            var i = lines.index(after: headerIndex)
            while i < lines.endIndex && !isHeader(lines[i]) {
                i = lines.index(after: i)
            }
            lines.insert(task, at: i)
        } else {
            // Create section if it doesn't exist
            lines.append("")
            lines.append("## \(section)")
            lines.append(task)
        }
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
                    let before = String(t[..<r.upperBound])
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
        let titles = sections.map { $0.title }.filter { !$0.isEmpty }
        var seen = Set<String>()
        return titles.filter { seen.insert($0).inserted }
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

                // Find and toggle the task in place
                for i in lines.indices {
                    let line = lines[i]
                    if line.hasPrefix("## ") || line.hasPrefix("### ") {
                        let trimmed = line.trimmingCharacters(in: .whitespaces)
                        let level = trimmed.prefix { $0 == "#" }.count
                        let title = trimmed.drop(while: { $0 == "#" || $0 == " " })
                        if level >= 2 { currentPath = [String(title)] }
                        continue
                    }
                    
                    if currentPath == task.sectionPath && isTaskLine(line) {
                        let title = extractTitle(from: line)
                        if title == task.title {
                            lines[i] = toggleLine(line, complete: !task.isCompleted)
                            break
                        }
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
    
    func addRepeatTag(task: TaskItem, repeatType: String) {
        guard let fileUrl else { return }
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

                func addRepeatTag(to s: String, repeatType: String) -> String {
                    var out = s
                    // Remove existing repeat tag if any
                    if let regex = try? NSRegularExpression(pattern: "@repeat\\([^)]+\\)") {
                        out = regex.stringByReplacingMatches(in: out, range: NSRange(location: 0, length: out.utf16.count), withTemplate: "")
                    }
                    // Add new repeat tag
                    out += " @repeat(\(repeatType))"
                    return out.replacingOccurrences(of: "  ", with: " ").trimmingCharacters(in: .whitespaces)
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
                        lines[i] = addRepeatTag(to: line, repeatType: repeatType)
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
    
    func removeRepeatTag(task: TaskItem) {
        guard let fileUrl else { return }
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

                func removeRepeatTag(from s: String) -> String {
                    var out = s
                    // Remove repeat tag
                    if let regex = try? NSRegularExpression(pattern: "@repeat\\([^)]+\\)") {
                        out = regex.stringByReplacingMatches(in: out, range: NSRange(location: 0, length: out.utf16.count), withTemplate: "")
                    }
                    return out.replacingOccurrences(of: "  ", with: " ").trimmingCharacters(in: .whitespaces)
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
                        lines[i] = removeRepeatTag(from: line)
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
}


