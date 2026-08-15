# Tasks.md

A native SwiftUI app for iOS and macOS that treats your **tasks.md** markdown file as the database. Edit tasks in Cursor (or any text editor); the app watches the same file and stays in sync via iCloud Drive (or any folder you pick).

**App Store:** [Tasks.md](https://apps.apple.com/us/app/tasks-md/id6753879372) · Bundle ID `buildmase.app.Tasks-md` · One-time purchase · Seller Mason Earl  
**Source:** [github.com/masonearl/tasks.md](https://github.com/masonearl/tasks.md)

> Live store listing is **v1.0**. This repo targets **v1.1** (marketing `1.1`, build `2+`).

---

## What it does

- Opens a local `.md` file (security-scoped bookmark remembers your choice)
- Parses `##` / `###` sections and `- [ ]` / `- [x]` checkboxes
- Supports tags: `@priority(...)`, `@due(...)`, `@remind(...)`, `@repeat(...)`, `@completed(...)`
- Checking a box, editing a title, or adding a task writes back to the same markdown file
- **File watching** (DispatchSource + NSFilePresenter + short mtime/size poll) reloads when Cursor or another editor saves
- First launch copies a sample `My Tasks.md` into Documents if nothing is bookmarked yet
- Foreground / scene-active reload as a safety net
- No accounts, no subscription, no analytics

---

## Requirements

- iOS **18.6+** / macOS **15.6+** (as set in the Xcode project)
- Xcode 16+ recommended for building
- Optional: put `tasks.md` in iCloud Drive so phone and Mac share one file

---

## Markdown format

```markdown
# Tasks

## Work
- [ ] Ship v1.1 file watching @priority(high) @due(2026-08-20)
- [x] Publish App Store build @completed(2025-10-13T17:17:57Z)

## Habits
- [ ] Daily review @repeat(daily)
```

The app is the UI; the file remains portable plain text.

---

## Project layout

```
Tasks.md/
├── Tasks.md/                 # App sources (synchronized Xcode folder)
│   ├── Shared/               # Models, TaskStore, MarkdownParser, FileWatcher, views
│   ├── iOS/                  # Document picker
│   ├── macOS/                # NSOpenPanel picker
│   ├── Tasks_mdApp.swift
│   └── ContentView.swift
├── Tasks.md.xcodeproj
├── Tasks.mdTests/
└── Tasks.mdUITests/
```

Root docs (`README.md`, `FEATURES.md`, `ARCHITECTURE.md`) describe product intent and roadmap. Wishlist items in `FEATURES.md` that are not shipped stay unchecked.

---

## Build & run

1. Open `Tasks.md/Tasks.md.xcodeproj` in Xcode
2. Select the **Tasks.md** scheme (iOS Simulator or My Mac)
3. Ensure signing team `3FXGJUET7Y` (or your own) is selected
4. Run

### Verify file sync (v1.1)

1. Run the app and choose (or keep) a `tasks.md` file
2. Leave the app open
3. In Cursor or TextEdit, add a line like `- [ ] Hello from Cursor` under a `##` section and save
4. Within about a second the new task should appear in the app **without** tapping Refresh
5. Toggle a checkbox in the app; the markdown file should update on disk

---

## Versioning

| | Live App Store | This branch (v1.1) |
|--|--|--|
| Marketing (`CFBundleShortVersionString`) | 1.0 | **1.1** |
| Build (`CURRENT_PROJECT_VERSION`) | 1 (assumed from project) | **2** |

Keep marketing at **1.1** and bump build for each App Store archive.

---

## Privacy & business model

- Local file access only (user-selected / bookmarked)
- No login, no server-side task storage
- Paid up front on the App Store ($2.99 at launch)

---

## Roadmap

See [FEATURES.md](FEATURES.md) for ideas (widgets, Watch, collaboration, analytics, etc.). Those are **not** part of v1.1.
