# Tasks.md architecture

## Source of truth

One user-selected UTF-8 markdown file supplies all tasks and tags. SwiftUI displays parsed sections; user actions edit only the affected lines. The app does not regenerate the entire document from its task model.

## Components

- **AppModel** owns the selected URL, security-scoped access, bookmark restoration, file watcher, and visible file errors. It validates a new file before replacing the current selection. Loading also processes due recurring tasks.
- **BookmarkStore** saves an app-scoped bookmark on Mac or a minimal bookmark on iOS. Only files inside the app's Documents directory may fall back to a stored path. AppModel owns the lifetime of security-scoped access.
- **FileCoordinatorService** coordinates reads and atomic writes. Read failures propagate; unchanged updates do not rewrite the file.
- **FileWatcher** combines dispatch-source notifications, a serial file-presenter queue, and an mtime/size poll. Its mutable state is lock-protected and independent of the main actor. Polling continues after atomic replacement invalidates the original descriptor.
- **MarkdownParser** recognizes level-two/three headings, checkboxes, and metadata tags outside fenced code. It returns line indices and the document's newline convention. Duplicate titles and section headings have distinct identities.
- **TaskStore** retains the displayed document text. Checkbox, rename, and recurrence-menu edits require that snapshot to match the current file, preventing an external deletion from shifting duplicate task identities onto the wrong line. A conflict reloads current data and surfaces a retry message. Adding a new task merges into the latest document.
- **TaskFilter / TaskSort** implement view-only filtering and stable sorting. Today includes overdue open tasks. Search also matches section names.
- **TaskListView / TaskRowView** provide compact sections, search/filter controls, inline editing, metadata, task menus, and persistent category-aware entry.

## Recurrence

A completed task with `@repeat(daily|weekly|monthly)` and a valid completion date becomes eligible after a calendar interval. The store inserts an incomplete copy immediately after it in the same section, advances its due date when present, and marks the original `@repeated(timestamp)`. This is idempotent across reloads and applies to large documents too. It runs on load/foreground, not while the app is closed.

## Platform boundaries

Mac uses native open/save panels and menu commands. iOS uses SwiftUI's file importer. File providers, including iCloud Drive, transport the chosen file between devices; there is no custom CloudKit or notification service.

The sandbox requests user-selected read/write access and app-scoped bookmarks. The privacy manifest declares UserDefaults and file-timestamp use. Unused network, contacts, calendar, and location permissions are disabled.

## Verification and limits

Unit/integration tests exercise parsing, write-back, metadata/indentation preservation, duplicate names, external conflicts, malformed UTF-8, newline conventions, recurrence, bookmarks, and multiple atomic replacements. Mac UI tests use an isolated sample and exercise launch/relaunch, add, rename, filtering, search, and keyboard commands.

Coordinated I/O protects cooperating file clients. Uncoordinated editors or remote file-provider conflicts can still race outside that coordination; this is not a distributed merge engine. Physical-device iCloud sync and minimum-OS validation remain release checks.
