# Tasks.md App - Features & Roadmap

## MVP Features (Phase 1)

### ✅ File Selection & Management
- Browse and select tasks.md file location
- Remember selected file path
- Auto-detect tasks.md in common locations:
  - `~/Documents/tasks.md`
  - `~/iCloud Drive/Documents/tasks.md`
  - Project root directories

### ✅ Task Display
- Parse and display all tasks from tasks.md
- Organize by sections (## headers)
- Show task status (complete/incomplete)
- Preserve markdown formatting
- Real-time file watching

### ✅ Task Completion
- Tap to check/uncheck tasks
- Instantly updates tasks.md file
- Changes sync via iCloud to other devices

### ✅ Basic UI
- Clean, minimal design
- Light/dark mode support
- Task list view
- Section headers

---

## Enhanced Features (Phase 2)

### 📅 Reminders & Notifications
**Syntax:** `@remind(2025-10-15T09:00)`

- Set reminder date/time for any task
- Local notifications on Mac & iOS
- Snooze reminders
- Reminder badge on app icon
- Today view widget showing due reminders

**UI:**
- Date/time picker in task detail view
- "Set Reminder" button
- Clear reminder option

### 🎯 Priority Levels
**Syntax:** `@priority(high|medium|low)`

- Three priority levels: High, Medium, Low
- Visual indicators (colors, icons)
- Filter by priority
- Auto-sort by priority

**UI:**
- Color-coded task rows:
  - High: Red accent
  - Medium: Orange accent
  - Low: Blue accent
- Priority badge/icon

### 📆 Due Dates
**Syntax:** `@due(2025-10-20)`

- Set due dates for tasks
- Calendar view of upcoming tasks
- Overdue task highlighting
- "Due Today" and "Due This Week" filters

**UI:**
- Calendar picker
- Due date shown on task row
- Overdue tasks highlighted in red

### 🏷️ Tags
**Syntax:** `@tags(work,important,quick)`

- Multiple tags per task
- Filter by tag
- Tag autocomplete
- Common tag suggestions

**UI:**
- Tag chips below task content
- Tag filter sidebar
- Tag management screen

---

## Advanced Features (Phase 3)

### 📊 Analytics & Insights
- Completion rate (daily, weekly, monthly)
- Task velocity (tasks completed over time)
- Productivity streaks
- Time of day analysis
- Category breakdown (work vs personal)

**UI:**
- Dashboard with charts
- Streak counter
- Weekly summary

### 🔍 Search & Filtering
- Full-text search across all tasks
- Search by tag, priority, due date
- Saved search filters
- Recent searches

**UI:**
- Search bar at top
- Filter chips
- Quick filter buttons

### 🔄 Recurring Tasks
**Syntax:** `@repeat(daily|weekly|monthly)`

- Create recurring tasks
- Auto-generate next instance when completed
- Custom repeat intervals
- Skip/postpone recurrence

**Examples:**
```markdown
- [ ] Daily standup @repeat(daily) @remind(09:00)
- [ ] Weekly review @repeat(weekly:monday) @remind(17:00)
- [ ] Pay rent @repeat(monthly:1) @due(2025-11-01)
```

### 📍 Location Reminders
**Syntax:** `@location(Grocery Store)`

- Trigger reminders when arriving/leaving location
- Geofencing integration
- Location suggestions based on contacts/maps

### ⚡ Quick Entry
- Global keyboard shortcut (Mac)
- Quick add task without opening app
- Siri shortcuts
- Voice input for new tasks

### 🔗 Task Links & References
**Syntax:** `@link(task-id)` or `→ Task Name`

- Link related tasks
- Create subtasks
- Dependency tracking
- Task hierarchy visualization

---

## Platform-Specific Features

### macOS
- Menu bar app option
- Keyboard shortcuts for everything
- Touch Bar support (if applicable)
- Share extension (add tasks from other apps)
- Spotlight integration

### iOS/iPadOS
- Widget (Today view, Lock Screen)
- App Shortcuts
- Siri integration
- Share sheet extension
- Apple Watch companion app (future)

---

## UI/UX Enhancements

### Design
- Notion-like clean aesthetic
- Smooth animations
- Haptic feedback (iOS)
- Customizable themes
- Font size adjustment

### Gestures
- Swipe to complete (iOS)
- Swipe to delete
- Long press for options
- Drag to reorder

### Accessibility
- VoiceOver support
- Dynamic Type
- High contrast mode
- Reduced motion option

---

## Settings & Customization

### File Settings
- Select tasks.md location
- Auto-backup options
- Sync status indicator
- Export/import tasks

### Notification Settings
- Reminder sound selection
- Notification timing
- Quiet hours
- Badge preferences

### Display Settings
- Sort order (priority, due date, creation date)
- Compact/comfortable view
- Show/hide completed tasks
- Accent color selection

### Advanced Settings
- Markdown flavor selection
- Custom metadata tags
- Backup frequency
- Debug mode

---

## Data & Sync

### Backup
- Auto-backup to iCloud
- Export to JSON/CSV
- Manual backup on demand
- Restore from backup

### Import/Export
- Import from other apps (Things, Todoist, etc.)
- Export to various formats
- Share tasks via link/email

---

## Implementation Timeline

### Week 1: Foundation
- [x] Project setup
- [ ] Basic file reading/writing
- [ ] Markdown parser
- [ ] Task list UI
- [ ] Check/uncheck functionality

### Week 2: Core Features
- [ ] iCloud sync setup
- [ ] File watching implementation
- [ ] Priority parsing & display
- [ ] Reminder notifications
- [ ] Due date support

### Week 3: Mobile
- [ ] iOS app creation
- [ ] Shared code refactoring
- [ ] Mobile UI optimization
- [ ] Cross-device sync testing

### Week 4: Polish
- [ ] Settings screen
- [ ] Analytics dashboard
- [ ] Widget implementation
- [ ] App Store assets
- [ ] Beta testing

### Future Phases
- [ ] Recurring tasks
- [ ] Location reminders
- [ ] Task links
- [ ] Apple Watch app
- [ ] Collaboration features

---

## Success Metrics

### Usage
- Daily active users
- Tasks completed per day
- Average session time
- Retention rate

### Performance
- File sync latency < 500ms
- App launch time < 1s
- Zero data loss incidents
- 99.9% crash-free rate

### User Satisfaction
- App Store rating > 4.5
- Feature request feedback
- Bug report frequency
- User testimonials

---

## Future Vision

### Long-term Goals
1. Best tasks.md app for developers
2. Seamless integration with coding workflow
3. Powerful features without sacrificing simplicity
4. Community-driven feature development

### Potential Expansions
- Team collaboration mode
- API for third-party integrations
- Web viewer (read-only)
- Android app (if demand exists)
- VS Code extension
- GitHub integration

---

## User Stories

### Developer (Primary User)
> "I want to manage my tasks in Cursor where I spend most of my time, but also have a nice app view with reminders when I'm away from my computer."

### Knowledge Worker
> "I need a simple task manager that syncs between my Mac and iPhone without learning a complex system."

### Minimalist
> "I want powerful features but with a clean, distraction-free interface that doesn't overwhelm me."

---

## Competitive Advantages

vs. Things/Todoist/Notion:
- ✅ Markdown-based (portable, future-proof)
- ✅ Edit in any text editor
- ✅ No vendor lock-in
- ✅ Free iCloud sync (no subscription)
- ✅ Developer-friendly workflow

vs. Plain Markdown:
- ✅ Reminders & notifications
- ✅ Rich metadata support
- ✅ Mobile app
- ✅ Analytics
- ✅ Better UX

