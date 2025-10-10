# Tasks.md App

A native macOS and iOS app that syncs with your tasks.md file, adding smart features like reminders, prioritization, and notifications while keeping your markdown file as the single source of truth.

## Core Concept

**tasks.md** is your database. The app enhances it with features while maintaining full compatibility with any text editor (especially Cursor).

---

## Architecture

### Single Source of Truth
- **tasks.md** = Master database (readable, portable, future-proof)
- Stored in **iCloud Drive** for automatic Mac/iOS sync
- Primary editing in **Cursor**
- Apps add enhanced features on top

### Two-Way Sync Flow
1. **Cursor edits** → Saves to tasks.md → iCloud syncs → Apps detect change → Update UI
2. **App edits** (check task, add reminder) → Update tasks.md → iCloud syncs → Cursor shows changes

### File Watching
- Mac/iOS apps use **FileManager** + **FilePresenter** APIs
- Monitor tasks.md for changes in real-time
- When file changes (from Cursor or other device), app reloads automatically
- iCloud handles the heavy lifting of sync

---

## Data Storage Options

### Option 1: Pure Markdown (Recommended)
Store everything IN tasks.md using custom markdown syntax:

```markdown
# Tasks

## Work
- [ ] Prepare for iOS debugging test @priority(high) @remind(2025-10-15T09:00)
- [ ] Fix map zoom issue @priority(medium) @due(2025-10-20)

## Personal
- [ ] Call dentist @remind(2025-10-10T14:00)
```

**Pros:**
- Everything in one file
- Still readable in Cursor
- No separate metadata to manage
- Portable and future-proof

**Cons:**
- Slightly verbose with tags
- Need to parse custom syntax

### Option 2: Companion Metadata File
- **tasks.md** = Clean tasks only (what you see in Cursor)
- **tasks.meta.json** = App-specific metadata (reminders, priority, colors, etc.)

Example tasks.md:
```markdown
# Tasks

## Work
- [ ] Prepare for iOS debugging test
- [ ] Fix map zoom issue
```

Example tasks.meta.json:
```json
{
  "tasks": {
    "Prepare for iOS debugging test": {
      "priority": "high",
      "reminder": "2025-10-15T09:00:00Z",
      "tags": ["work", "important"]
    },
    "Fix map zoom issue": {
      "priority": "medium",
      "due": "2025-10-20T23:59:59Z"
    }
  }
}
```

**Pros:**
- Clean, minimal tasks.md
- Rich metadata without cluttering
- Easy to add features without changing markdown

**Cons:**
- Two files to manage
- Tasks.md must match metadata (need sync logic)

---

## Features

### Core Features (MVP)
- ✅ Real-time sync with tasks.md file
- ✅ View all tasks organized by sections
- ✅ Check off completed tasks → updates markdown
- ✅ Add new tasks from app → writes to markdown
- ✅ Works on Mac and iOS (iCloud sync)

### Enhanced Features
- 📅 **Reminders** - Set notifications for tasks
- 🎯 **Priority Levels** - High, Medium, Low with visual indicators
- 📆 **Due Dates** - Calendar integration
- 🏷️ **Tags & Filters** - Organize and filter tasks
- 📊 **Progress Tracking** - Daily/weekly completion stats
- 🔍 **Search** - Quick find across all tasks
- 🎨 **Custom Themes** - Clean, minimal dark mode (Notion-like)

### Advanced Features (Future)
- 🔄 **Recurring Tasks** - Daily, weekly, monthly repeats
- 📍 **Location Reminders** - Trigger when near a place
- 🧠 **Smart Suggestions** - AI-powered task prioritization
- 📈 **Analytics** - Productivity insights
- 🔗 **Quick Actions** - Siri shortcuts, widgets

---

## Tech Stack

### Mac App
- **SwiftUI** - Modern UI framework
- **CloudKit/iCloud Drive** - File sync
- **FileManager** - Direct file access
- **Combine** - Reactive data flow
- **UserNotifications** - Local reminders

### iOS App
- **SwiftUI** - Shared UI with Mac
- **CloudKit/iCloud Drive** - Sync with Mac
- **UserNotifications** - Push notifications
- **WidgetKit** - Home screen widgets (optional)

### Parsing
- **Swift Markdown Parser** - For parsing tasks.md
  - Or custom regex-based parser
- **Codable** - For JSON metadata (if using Option 2)

---

## File Structure

```
Tasks.md App/
├── README.md                    # This file
├── ARCHITECTURE.md              # Detailed technical architecture
├── FEATURES.md                  # Feature specs and roadmap
├── TasksApp/                    # Xcode project
│   ├── Shared/                  # Shared code (Mac + iOS)
│   │   ├── Models/
│   │   │   ├── Task.swift
│   │   │   ├── TaskSection.swift
│   │   │   └── TaskMetadata.swift
│   │   ├── Services/
│   │   │   ├── TaskFileManager.swift
│   │   │   ├── MarkdownParser.swift
│   │   │   └── CloudSyncService.swift
│   │   └── Views/
│   │       ├── TaskListView.swift
│   │       ├── TaskRowView.swift
│   │       └── TaskDetailView.swift
│   ├── macOS/                   # Mac-specific code
│   │   └── ContentView.swift
│   └── iOS/                     # iOS-specific code
│       └── ContentView.swift
└── Prototypes/                  # Quick test apps
```

---

## Implementation Plan

### Phase 1: Basic Mac App (Week 1)
1. Create SwiftUI Mac app
2. File picker to select tasks.md location
3. Parse markdown → display tasks
4. File watcher for real-time updates
5. Check off tasks → update file

### Phase 2: Enhanced Features (Week 2)
1. Add priority parsing/display
2. Implement reminders with notifications
3. Due dates with calendar view
4. Tags and filtering

### Phase 3: iOS App (Week 3)
1. Port Mac app to iOS
2. iCloud Drive integration
3. Sync between devices
4. Mobile-optimized UI

### Phase 4: Polish (Week 4)
1. Widgets (iOS)
2. Quick actions
3. Analytics dashboard
4. Settings & customization

---

## Getting Started

### Prerequisites
- macOS 14.0+ (for development)
- Xcode 15.0+
- iCloud account (for sync)

### Development Setup
1. Clone/create Xcode project
2. Add FileManager + iCloud capabilities
3. Create task.md test file
4. Build and run

---

## Design Philosophy

1. **Markdown First** - tasks.md remains readable and portable
2. **Non-Destructive** - App never breaks your markdown file
3. **Cursor-Friendly** - Edit naturally in Cursor, apps adapt
4. **Simple & Clean** - Minimal, data-driven UI (no fluff)
5. **Reliable Sync** - iCloud handles it, always in sync

---

## Why This Approach Works

✅ **Future-Proof** - If app breaks, tasks.md still works everywhere  
✅ **Developer-Friendly** - Edit in Cursor where you already work  
✅ **Cross-Platform** - Mac, iOS, iPad all stay in sync  
✅ **Portable** - Move tasks.md anywhere, no vendor lock-in  
✅ **Powerful** - Get app features without sacrificing simplicity  

---

## Next Steps

1. Review this documentation
2. Decide on metadata storage approach (Option 1 or 2)
3. Create Xcode project structure
4. Build Phase 1 MVP
5. Test with real tasks.md file
6. Iterate based on usage

---

## Notes

- Start simple, add features gradually
- Test file watching thoroughly (Cursor saves, manual edits, etc.)
- Handle edge cases (file moved, deleted, conflicts)
- Consider version control (Git commits on changes)


## Completed
- [x] Update iPad version @completed(2025-10-08)




