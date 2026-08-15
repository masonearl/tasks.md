# Tasks.md App - Features & Roadmap

Status key: ✅ shipped in the App Store app / current codebase · ☐ wishlist (not in v1.1)

---

## Shipped (v1.0 → v1.1)

### ✅ File Selection & Management
- [x] Browse and select a tasks.md (or any `.md`) file
- [x] Remember selection with a security-scoped bookmark
- [x] First-launch sample file (`My Tasks.md` in Documents)
- [x] Manual Refresh (macOS toolbar) + reload when the app becomes active
- [x] **v1.1:** Reliable external-edit watching (DispatchSource + NSFilePresenter + short mtime/size poll) on iOS and macOS

### ✅ Task Display & Editing
- [x] Parse and display tasks from markdown
- [x] Organize by `##` / `###` section headers
- [x] Show complete / incomplete checkboxes
- [x] Tap to check/uncheck → writes markdown (`@completed(...)` on complete)
- [x] Inline title editing
- [x] Add new task with section / category picker
- [x] Create a new section from the add-task sheet

### ✅ Tag parsing (display / write-back as implemented)
- [x] `@priority(high|medium|low)`
- [x] `@due(...)` / `@remind(...)` date parsing
- [x] `@repeat(daily|weekly|monthly)` + periodic regeneration of due repeats
- [x] `@completed(...)` timestamps

### ✅ Platform
- [x] Native SwiftUI multiplatform target (iOS + macOS)
- [x] Sandboxed user-selected file access
- [x] About / Help links to https://github.com/masonearl/tasks.md
- [x] One-time App Store purchase (no accounts)

---

## Enhanced Features (wishlist)

### 📅 Reminders & Notifications
**Syntax:** `@remind(2025-10-15T09:00)`

- [ ] Local notifications on Mac & iOS when `@remind` fires
- [ ] Snooze / badge / Today widget for reminders

### 🎯 Priority UX
- [ ] Color-coded rows / filter-by-priority UI (tags already parse)

### 📆 Due date UX
- [ ] Calendar view, overdue highlighting, due-today filters

### 🏷️ Free-form tags
**Syntax:** `@tags(work,important,quick)` — not shipped

- [ ] Multiple tags, filter chips, tag management

---

## Advanced Features (wishlist)

### 📊 Analytics & Insights
- [ ] Completion stats, streaks, dashboards

### 🔍 Search & Filtering
- [ ] Full-text search, saved filters

### 🔄 Recurring Tasks (beyond current `@repeat`)
- [ ] Custom intervals, skip/postpone, richer recurrence UI  
  (basic `@repeat(daily|weekly|monthly)` regeneration **is** shipped)

### 📍 Location Reminders
- [ ] Geofencing / `@location(...)`

### ⚡ Quick Entry
- [ ] Global shortcut, Siri, menu bar quick add

### 🔗 Task Links & References
- [ ] Subtasks / dependencies

---

## Platform-Specific Wishlist

### macOS
- [ ] Menu bar mode, Share extension, Spotlight

### iOS/iPadOS
- [ ] Home Screen / Lock Screen widgets
- [ ] App Shortcuts / Siri
- [ ] Apple Watch companion

---

## UI/UX Wishlist

- [ ] Swipe gestures, drag reorder, richer theming
- [ ] Broader VoiceOver / Dynamic Type polish pass

---

## Settings Wishlist

- [ ] Auto-backup / export-import
- [ ] Notification preferences
- [ ] Sort order and compact layout options

---

## Intentionally out of scope for v1.1

- Watch app, widgets, collaboration, analytics, accounts, new monetization
- Companion `tasks.meta.json` (tags live in the markdown file)
- Rewriting storage to a custom iCloud container (user-picked file + iCloud Drive is enough)

---

## Competitive Advantages

vs. Things/Todoist/Notion:
- ✅ Markdown-based (portable, future-proof)
- ✅ Edit in any text editor (Cursor-friendly)
- ✅ No vendor lock-in
- ✅ No subscription for sync when using iCloud Drive / Dropbox / Git
- ✅ Developer-friendly workflow

vs. Plain Markdown alone:
- ✅ Native checkbox UI and write-back
- ✅ Section organization and tag-aware editing
- ✅ Mobile + Mac app over the same file
