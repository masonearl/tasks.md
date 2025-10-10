# Tasks.md App - Technical Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         iCloud Drive                         │
│                         tasks.md File                        │
│                   (Single Source of Truth)                   │
└────────────┬──────────────────────────────┬─────────────────┘
             │                              │
             │                              │
    ┌────────▼────────┐          ┌─────────▼────────┐
    │   Mac App       │          │   iOS App        │
    │   (SwiftUI)     │          │   (SwiftUI)      │
    │                 │          │                  │
    │  - FileManager  │          │  - FileManager   │
    │  - FilePresenter│          │  - FilePresenter │
    │  - Notifications│          │  - Notifications │
    └────────┬────────┘          └─────────┬────────┘
             │                              │
    ┌────────▼──────────────────────────────▼────────┐
    │          Cursor / Text Editor                  │
    │          Direct File Editing                   │
    └────────────────────────────────────────────────┘
```

---

## Core Components

### 1. File Manager Service

**Purpose:** Handle all file I/O operations with tasks.md

```swift
class TaskFileManager: ObservableObject {
    @Published var tasks: [TaskSection] = []
    private var fileURL: URL
    private var fileMonitor: DispatchSourceFileSystemObject?
    
    // Core Functions
    func loadTasks() -> [TaskSection]
    func saveTasks(_ tasks: [TaskSection])
    func watchForChanges()
    func handleFileChange()
}
```

**Responsibilities:**
- Read tasks.md from iCloud Drive
- Parse markdown into Task objects
- Write Task objects back to markdown
- Monitor file changes using DispatchSource
- Handle conflicts and merges

**Key Implementation:**
```swift
// Watch file for changes
func watchForChanges() {
    let fileDescriptor = open(fileURL.path, O_EVTONLY)
    let source = DispatchSource.makeFileSystemObjectSource(
        fileDescriptor: fileDescriptor,
        eventMask: .write,
        queue: DispatchQueue.main
    )
    
    source.setEventHandler { [weak self] in
        self?.handleFileChange()
    }
    
    source.resume()
    fileMonitor = source
}
```

---

### 2. Markdown Parser

**Purpose:** Convert between markdown text and Task objects

```swift
struct MarkdownParser {
    // Parse markdown → Tasks
    static func parse(_ markdown: String) -> [TaskSection]
    
    // Tasks → markdown
    static func generate(from sections: [TaskSection]) -> String
    
    // Parse metadata tags
    static func extractMetadata(from line: String) -> TaskMetadata
}
```

**Parsing Rules:**
```markdown
# Section Name              → TaskSection
## Subsection               → TaskSection (nested)
- [ ] Task                  → Task (incomplete)
- [x] Task                  → Task (complete)
@priority(high)             → Metadata: priority
@remind(2025-10-15T09:00)   → Metadata: reminder
@due(2025-10-20)            → Metadata: due date
@tags(work,important)       → Metadata: tags
```

**Example Implementation:**
```swift
static func parse(_ markdown: String) -> [TaskSection] {
    var sections: [TaskSection] = []
    var currentSection: TaskSection?
    
    for line in markdown.components(separatedBy: "\n") {
        if line.starts(with: "## ") {
            // New section
            if let section = currentSection {
                sections.append(section)
            }
            currentSection = TaskSection(title: String(line.dropFirst(3)))
        } else if line.starts(with: "- [ ] ") || line.starts(with: "- [x] ") {
            // Task line
            let isComplete = line.contains("[x]")
            let content = extractContent(from: line)
            let metadata = extractMetadata(from: line)
            
            let task = Task(
                content: content,
                isComplete: isComplete,
                metadata: metadata
            )
            currentSection?.tasks.append(task)
        }
    }
    
    if let section = currentSection {
        sections.append(section)
    }
    
    return sections
}
```

---

### 3. Cloud Sync Service

**Purpose:** Handle iCloud synchronization

```swift
class CloudSyncService: ObservableObject {
    private let containerIdentifier = "iCloud.com.yourcompany.tasksapp"
    
    func setupiCloudSync()
    func getTasksFileURL() -> URL
    func monitorCloudChanges()
}
```

**iCloud Setup:**
1. Enable iCloud capability in Xcode
2. Use `NSUbiquitousContainerIdentifier`
3. Store tasks.md in `Documents/` folder
4. Let iCloud handle sync automatically

```swift
func getTasksFileURL() -> URL {
    let containerURL = FileManager.default.url(
        forUbiquityContainerIdentifier: containerIdentifier
    )
    return containerURL!
        .appendingPathComponent("Documents")
        .appendingPathComponent("tasks.md")
}
```

---

### 4. Notification Service

**Purpose:** Handle reminders and notifications

```swift
class NotificationService {
    func scheduleReminder(for task: Task, at date: Date)
    func cancelReminder(for task: Task)
    func requestNotificationPermission()
}
```

**Implementation:**
```swift
func scheduleReminder(for task: Task, at date: Date) {
    let content = UNMutableNotificationContent()
    content.title = "Task Reminder"
    content.body = task.content
    content.sound = .default
    
    let components = Calendar.current.dateComponents(
        [.year, .month, .day, .hour, .minute],
        from: date
    )
    let trigger = UNCalendarNotificationTrigger(
        dateMatching: components,
        repeats: false
    )
    
    let request = UNNotificationRequest(
        identifier: task.id.uuidString,
        content: content,
        trigger: trigger
    )
    
    UNUserNotificationCenter.current().add(request)
}
```

---

## Data Models

### Task
```swift
struct Task: Identifiable, Codable {
    let id: UUID
    var content: String
    var isComplete: Bool
    var metadata: TaskMetadata
    var createdAt: Date
    var completedAt: Date?
    
    init(content: String, isComplete: Bool = false, metadata: TaskMetadata = .init()) {
        self.id = UUID()
        self.content = content
        self.isComplete = isComplete
        self.metadata = metadata
        self.createdAt = Date()
    }
}
```

### TaskMetadata
```swift
struct TaskMetadata: Codable {
    var priority: Priority = .none
    var reminder: Date?
    var dueDate: Date?
    var tags: [String] = []
    var notes: String?
    
    enum Priority: String, Codable {
        case none, low, medium, high
    }
}
```

### TaskSection
```swift
struct TaskSection: Identifiable {
    let id: UUID
    var title: String
    var tasks: [Task]
    var subsections: [TaskSection]
    
    init(title: String, tasks: [Task] = [], subsections: [TaskSection] = []) {
        self.id = UUID()
        self.title = title
        self.tasks = tasks
        self.subsections = subsections
    }
}
```

---

## File Sync Strategy

### Change Detection
1. App monitors file using `DispatchSource`
2. When file changes externally (Cursor edit):
   - Read file
   - Parse new content
   - Update UI
   - Preserve local-only metadata if needed

### Write Strategy
1. User makes change in app
2. Update Task object
3. Generate new markdown
4. Write atomically to tasks.md
5. iCloud syncs to other devices

### Conflict Resolution
- **Last Write Wins** - Simple, works for single user
- **Merge Strategy** (Future):
  - Compare timestamps
  - Keep both conflicting changes
  - Flag for manual resolution

---

## Security & Privacy

### iCloud
- End-to-end encrypted
- User owns their data
- No backend server needed

### Permissions
- File access (for tasks.md)
- Notifications (for reminders)
- Location (optional, for location reminders)

---

## Performance Considerations

### File Reading
- Cache parsed tasks in memory
- Only re-parse when file actually changes
- Use background queue for parsing

### File Writing
- Batch writes (don't write on every keystroke)
- Debounce changes (wait 500ms after last edit)
- Write atomically to prevent corruption

### UI Updates
- Update UI immediately (optimistic updates)
- Sync to file in background
- Rollback on failure

---

## Error Handling

### File Not Found
- Prompt user to select/create tasks.md
- Create default file in iCloud

### File Corrupted
- Keep backup of last known good state
- Offer to restore from backup
- Log error details

### Sync Conflicts
- Detect concurrent modifications
- Present diff to user
- Allow manual merge

---

## Testing Strategy

### Unit Tests
- Markdown parser (parse → generate → parse)
- Task model operations
- Metadata extraction

### Integration Tests
- File read/write cycle
- iCloud sync simulation
- Notification scheduling

### Manual Testing
1. Edit in Cursor → Check app updates
2. Edit in app → Check Cursor shows changes
3. Test on both Mac and iOS
4. Test with iCloud sync off (graceful degradation)

---

## Deployment

### App Store Requirements
- iCloud capability
- User notifications entitlement
- Privacy policy (for iCloud usage)
- App icons and screenshots

### Distribution
- Mac App Store
- iOS App Store
- Or distribute via TestFlight for personal use

---

## Future Enhancements

### Version Control Integration
- Auto-commit tasks.md to Git
- View history of changes
- Restore from previous versions

### Collaboration
- Shared tasks.md via iCloud shared folders
- Multi-user editing with conflict resolution

### AI Features
- Smart task prioritization
- Deadline suggestions based on history
- Natural language task input

---

## References

- [Apple FileManager Documentation](https://developer.apple.com/documentation/foundation/filemanager)
- [iCloud Drive Best Practices](https://developer.apple.com/icloud/)
- [User Notifications Framework](https://developer.apple.com/documentation/usernotifications)











