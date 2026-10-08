# 1.2 — build 5

## What's new

- A cleaner Mac interface with compact rows, collapsible categories, and always-visible task entry.
- Search tasks and categories, filter open/today/completed tasks, and sort by due date or priority.
- See due dates, overdue tasks, priorities, and repeat schedules at a glance.
- Choose a category as you add tasks. Use Command-N to add, Command-F to search, and Command-O to open a file.

## Fixes

- Reliable Mac launch/relaunch and first-launch task entry.
- Correct editing when multiple tasks have the same name.
- Clear file access and save errors, with protection for edits made in other apps.
- Daily, weekly, and monthly recurring tasks stay in their category and generate only once per completed occurrence.
- Preserve markdown tags, indentation, and Windows line endings; exclude tasks inside fenced code examples.
- Restore file bookmarks without leaking security-scoped access.

## Validation

- 25 macOS unit/integration tests and four Mac UI tests passed, covering launch, relaunch, adding, renaming, search, filters, keyboard shortcuts, and file watching.
- UI checks passed on iPhone 18 Pro, iPhone 18 Pro Max, and iPad Pro 13-inch (M5) simulators, including task entry, completion, search, and filters.
- Version 1.2/build 5 Release archives created for universal Mac (Apple silicon and Intel) and iOS. Both were exported with automatic App Store distribution signing, uploaded successfully, and processed by Apple.
- Fresh screenshots captured from the app for Mac, both iPhone display sizes, and iPad 13-inch. Store copy and review notes now describe the implemented features accurately.
- Physical-device iCloud Drive sync and minimum-OS checks were not performed in this release pass.

## Distribution status

Both platforms were submitted on October 8, 2026 and confirmed **Waiting for Review**. Both use version **1.2 (5)** and automatic release after approval. This is submission confirmation, not App Store approval.

- macOS submission: `3567dd67-22d6-4586-a23d-d373c6feb561`, submitted at 2:22 PM MDT. The updated build addresses the previous Add Task rejection.
- iOS submission: `db28436a-6eb1-497e-ae22-72d0e6db7a1d`, submitted at 2:23 PM MDT.
- App Store Connect app: `6753879372`; bundle: `buildmase.app.Tasks-md`.

Local archives, uploaded screenshot files, and review confirmations are retained under the ignored `output/app-store/` directory. The repeatable screenshot fixture is Debug-only (`--store-screenshots`) and does not modify the user's task file.

The release moved from 1.1 to 1.2 because Apple's existing iOS 1.1 build train was already closed, despite the public listing being labeled 1.0.
