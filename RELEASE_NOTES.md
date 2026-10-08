# 1.1 — build 4

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

- macOS unit/integration tests and UI tests for launch, relaunch, adding, renaming, search, filters, and keyboard shortcuts.
- iOS simulator build and launch.
- Universal Mac Release archive (Apple silicon and Intel), development-signed, version 1.1/build 4; signature and sandbox entitlements verified.

## Distribution status

This source update and local archive do not publish an App Store release. Before submission: exercise iCloud Drive on physical devices and minimum supported OS versions, verify screenshots/metadata, and create a distribution-signed App Store upload. The local development build is for review on the development Mac, not general public distribution.
