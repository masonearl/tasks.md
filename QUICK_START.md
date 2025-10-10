# Quick Start Guide - Tasks.md App

Get up and running with development in 30 minutes.

---

## Prerequisites

- macOS 14.0+
- Xcode 15.0+
- Active iCloud account
- Basic SwiftUI knowledge

---

## Step 1: Create Xcode Project (5 min)

1. Open Xcode → Create New Project
2. Select **Multiplatform App** template
3. Product Name: `TasksApp`
4. Interface: **SwiftUI**
5. Language: **Swift**
6. Storage: **None**

### Enable Capabilities

1. Select project in navigator
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add:
   - ✅ iCloud (iCloud Documents)
   - ✅ Push Notifications
   - ✅ Background Modes (Background fetch)

---

## Step 2: Project Structure (10 min)

Create this folder structure in your project:

```
TasksApp/
├── Shared/
│   ├── Models/
│   │   ├── Task.swift
│   │   ├── TaskSection.swift
│   │   └── TaskMetadata.swift
│   ├── Services/
│   │   ├── TaskFileManager.swift
│   │   ├── MarkdownParser.swift
│   │   └── CloudSyncService.swift
│   └── Views/
│       ├── TaskListView.swift
│       ├── TaskRowView.swift
│       └── TaskDetailView.swift
├── macOS/
│   └── ContentView.swift
└── iOS/
    └── ContentView.swift
```

---

## Step 3: Create Core Models (5 min)

### Task.swift
```swift
import Foundation

struct Task: Identifiable, Codable {
    let id: UUID
    var content: String
    var isComplete: Bool
    var metadata: TaskMetadata
    
    init(content: String, isComplete: Bool = false) {
        self.id = UUID()
        self.content = content
        self.isComplete = isComplete
        self.metadata = TaskMetadata()
    }
}
```

### TaskMetadata.swift
```swift
import Foundation

struct TaskMetadata: Codable {
    var priority: Priority = .none
    var reminder: Date?
    var dueDate: Date?
    var tags: [String] = []
    
    enum Priority: String, Codable, CaseIterable {
        case none, low, medium, high
    }
}
```

### TaskSection.swift
```swift
import Foundation

struct TaskSection: Identifiable {
    let id = UUID()
    var title: String
    var tasks: [Task]
    
    init(title: String, tasks: [Task] = []) {
        self.title = title
        self.tasks = tasks
    }
}
```

---

## Step 4: Markdown Parser (10 min)

### MarkdownParser.swift
```swift
import Foundation

struct MarkdownParser {
    
    static func parse(_ markdown: String) -> [TaskSection] {
        var sections: [TaskSection] = []
        var currentSection: TaskSection?
        
        let lines = markdown.components(separatedBy: .newlines)
        
        for line in lines {
            // Section header
            if line.hasPrefix("## ") {
                if let section = currentSection {
                    sections.append(section)
                }
                let title = String(line.dropFirst(3))
                currentSection = TaskSection(title: title)
            }
            // Task line
            else if line.hasPrefix("- [ ] ") || line.hasPrefix("- [x] ") {
                let isComplete = line.hasPrefix("- [x]")
                let content = extractContent(from: line)
                
                let task = Task(
                    content: content,
                    isComplete: isComplete
                )
                
                currentSection?.tasks.append(task)
            }
        }
        
        if let section = currentSection {
            sections.append(section)
        }
        
        return sections
    }
    
    static func generate(from sections: [TaskSection]) -> String {
        var markdown = "# Tasks\n\n"
        
        for section in sections {
            markdown += "## \(section.title)\n"
            for task in section.tasks {
                let checkbox = task.isComplete ? "[x]" : "[ ]"
                markdown += "- \(checkbox) \(task.content)\n"
            }
            markdown += "\n"
        }
        
        return markdown
    }
    
    private static func extractContent(from line: String) -> String {
        // Remove "- [ ] " or "- [x] " prefix
        let withoutCheckbox = line
            .replacingOccurrences(of: "- [ ] ", with: "")
            .replacingOccurrences(of: "- [x] ", with: "")
        
        return withoutCheckbox.trimmingCharacters(in: .whitespaces)
    }
}
```

---

## Step 5: File Manager (MVP) (5 min)

### TaskFileManager.swift
```swift
import Foundation
import SwiftUI

class TaskFileManager: ObservableObject {
    @Published var sections: [TaskSection] = []
    
    private var fileURL: URL?
    
    func loadTasks(from url: URL) {
        self.fileURL = url
        
        guard let markdown = try? String(contentsOf: url, encoding: .utf8) else {
            print("Failed to read file")
            return
        }
        
        sections = MarkdownParser.parse(markdown)
    }
    
    func saveTasks() {
        guard let fileURL = fileURL else { return }
        
        let markdown = MarkdownParser.generate(from: sections)
        
        do {
            try markdown.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✅ Saved tasks")
        } catch {
            print("❌ Failed to save: \(error)")
        }
    }
    
    func toggleTask(_ task: Task) {
        for i in 0..<sections.count {
            if let index = sections[i].tasks.firstIndex(where: { $0.id == task.id }) {
                sections[i].tasks[index].isComplete.toggle()
                saveTasks()
                return
            }
        }
    }
}
```

---

## Step 6: Basic UI (5 min)

### ContentView.swift (macOS)
```swift
import SwiftUI

struct ContentView: View {
    @StateObject private var fileManager = TaskFileManager()
    @State private var showingFilePicker = false
    
    var body: some View {
        NavigationView {
            if fileManager.sections.isEmpty {
                VStack {
                    Text("No tasks.md file selected")
                        .font(.headline)
                    Button("Select File") {
                        showingFilePicker = true
                    }
                }
            } else {
                TaskListView(fileManager: fileManager)
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.plainText]
        ) { result in
            switch result {
            case .success(let url):
                fileManager.loadTasks(from: url)
            case .failure(let error):
                print(error)
            }
        }
    }
}
```

### TaskListView.swift
```swift
import SwiftUI

struct TaskListView: View {
    @ObservedObject var fileManager: TaskFileManager
    
    var body: some View {
        List {
            ForEach(fileManager.sections) { section in
                Section(header: Text(section.title)) {
                    ForEach(section.tasks) { task in
                        TaskRowView(task: task, fileManager: fileManager)
                    }
                }
            }
        }
        .navigationTitle("Tasks")
    }
}
```

### TaskRowView.swift
```swift
import SwiftUI

struct TaskRowView: View {
    let task: Task
    @ObservedObject var fileManager: TaskFileManager
    
    var body: some View {
        HStack {
            Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isComplete ? .green : .gray)
                .onTapGesture {
                    fileManager.toggleTask(task)
                }
            
            Text(task.content)
                .strikethrough(task.isComplete)
                .foregroundColor(task.isComplete ? .secondary : .primary)
        }
    }
}
```

---

## Step 7: Test It! (2 min)

1. Create a test file `tasks.md`:
```markdown
# Tasks

## Work
- [ ] Test task 1
- [ ] Test task 2
- [x] Completed task

## Personal
- [ ] Another task
```

2. Run the app
3. Click "Select File" and choose your tasks.md
4. Click tasks to check them off
5. Open tasks.md in Cursor and verify changes

---

## Next Steps

### Immediate
- ✅ Add file watching (see ARCHITECTURE.md)
- ✅ Add iCloud sync (see ARCHITECTURE.md)
- ✅ iOS version

### Soon
- Priority parsing
- Reminder notifications
- Better UI polish

### Future
- See FEATURES.md for full roadmap

---

## Troubleshooting

### File not updating?
- Check file permissions
- Verify atomic write is enabled
- Add file watching (DispatchSource)

### iCloud not syncing?
- Verify iCloud capability is enabled
- Check iCloud Drive is active in System Settings
- Use correct container identifier

### Build errors?
- Clean build folder (Cmd+Shift+K)
- Update to latest Xcode
- Check target deployment versions

---

## Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [FileManager Guide](https://developer.apple.com/documentation/foundation/filemanager)
- [iCloud Design Guide](https://developer.apple.com/icloud/)

---

## Support

Questions? Check:
1. README.md - Project overview
2. ARCHITECTURE.md - Technical details
3. FEATURES.md - Feature roadmap

Happy coding! 🚀











