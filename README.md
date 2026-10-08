# Tasks.md

A native SwiftUI app for Mac and iPhone. Your markdown file is the database: check off, rename, or add tasks in the app, and edit the same file in any text editor.

[App Store](https://apps.apple.com/us/app/tasks-md/id6753879372) · [Source](https://github.com/masonearl/tasks.md) · Bundle ID `buildmase.app.Tasks-md`

This update targets **1.2, build 5**. Repository build numbers do not indicate App Store publication.

## This update

- A compact, single-column Mac window with a persistent add-task field and category picker.
- Search task titles and categories; switch between Open, Today (including overdue), All, and Done.
- Collapse sections and sort within them by file order, due date, or priority. Sorting leaves the markdown order unchanged.
- Due-date labels, priority flags, recurrence labels, and accessible task action menus.
- **⌘N** focuses task entry; **⌘F** focuses search; **⌘O** opens a file. Return adds or saves a task; Escape cancels a title edit.
- Visible errors with retry/choose-file actions. Failed file selection keeps the current document open.
- Safe edits of duplicate task names, preservation of tags and indentation, and support for LF/CRLF files. Fenced code examples are excluded from tasks.
- Daily/weekly/monthly repeats create one successor per completed occurrence in the same section, using calendar intervals.

## Files and sync

On first launch, the app creates `My Tasks.md` in its Documents folder. Choose a different file using the folder button or Settings. A security-scoped bookmark remembers that choice.

Store the file in iCloud Drive or another file provider, then choose it on each device. The provider handles transport; the app watches local changes using file events, `NSFilePresenter`, and a short file-signature poll. There is no app account or custom CloudKit database.

Edits read the latest document inside coordinated file access. If the file changed since a task was displayed, that task edit stops and the app loads the latest version for retry. An unreadable file is never treated as an empty document.

## Markdown

```markdown
# Tasks

## Work
- [ ] Review the release @priority(high) @due(2026-10-12)
- [x] Draft release notes @completed(2026-10-08T17:00:00Z)

## Habits
- [ ] Weekly review @repeat(weekly)
```

Sections use `##` or `###`. Tasks use `- [ ]`, `- [x]`, or `- [X]`. Dates support `YYYY-MM-DD` or ISO 8601 timestamps, with or without fractional seconds. Recognized tags include `priority`, `due`, `remind`, `repeat`, and `completed`; other tags are retained during title edits.

Recurring tasks are processed when the file loads or the app becomes active. The completed occurrence receives an `@repeated(...)` marker after its successor is created, preventing duplicate generation on subsequent reloads. This is not a background scheduler. `@remind(...)` is parsed but does not schedule notifications.

## Build and verify

- Deployment targets: **macOS 15.6+ / iOS 18.6+**.
- Use **Xcode 26+** for the project's Swift concurrency settings; this update was verified with Xcode 27.
- Open `Tasks.md/Tasks.md.xcodeproj`, select the **Tasks.md** scheme, and choose **My Mac** or an iPhone simulator.
- Select your signing team when needed. The checked-in team is `3FXGJUET7Y`.

```sh
xcodebuild -project Tasks.md/Tasks.md.xcodeproj -scheme Tasks.md \
  -destination 'platform=macOS' -parallel-testing-enabled NO test

xcodebuild -project Tasks.md/Tasks.md.xcodeproj -scheme Tasks.md \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

Mac UI tests use a disposable sample document via the Debug-only `--ui-testing` launch argument and do not change the remembered file. Tests cover launch/relaunch, adding, searching, completion filters, renaming, shortcuts, parsing, duplicate edits, external conflicts, unreadable files, recurrence, and repeated atomic file replacements.

## Project

- `Tasks.md/Tasks.md/Shared/`: models, file services, and task views.
- `Tasks.md/Tasks.md/ContentView.swift`: shared app navigation and settings, plus the iOS file importer.
- `Tasks.md/Tasks.md/macOS/`: native open/save panels.
- `Tasks.md/Tasks.mdTests/`, `Tasks.md/Tasks.mdUITests/`: regression and interaction tests.

See [FEATURES.md](FEATURES.md) for next priorities and [ARCHITECTURE.md](ARCHITECTURE.md) for implementation details. No accounts, subscription, analytics, or network service is required.
