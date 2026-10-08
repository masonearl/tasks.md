# Features and next priorities

This describes the current code, not the App Store's publication status.

## Included in 1.2, build 5

- Native Mac and iPhone task lists over a user-selected markdown file.
- First-launch sample, open/create file actions, remembered file access, external-edit watching, foreground and manual reload.
- Compact rows, collapsible sections, title/category search, and Open / Today / All / Done filters.
- File-order, due-date, and priority sorting within sections without rearranging the file.
- Inline add with category selection and category creation; inline rename and checkbox completion.
- Mac keyboard shortcuts for add, find, and open.
- Visible priority, due/overdue, and repeat metadata.
- Daily, weekly, and monthly recurrence without regenerating the same completed occurrence twice.
- Visible read/write failures, stale-edit detection, safe duplicate-title edits, and preservation of surrounding markdown.
- Fenced-code exclusion and LF/CRLF support.
- Sandboxed file access, privacy manifest, and no account requirement.

## Recommended next work

1. **Task details:** an expandable editor for due date, priority, and repeat options. These currently live in markdown tags; repeat also has a task menu.
2. **Undo:** restore a just-completed or renamed task with native undo support while preserving external changes.
3. **Reminders:** local notifications for `@remind(...)`, permission handling, and rescheduling when another editor changes the file. No reminders are scheduled today.
4. **File switching:** recent files and clearer file-provider/offline status.
5. **Device coverage:** exercise iCloud Drive on physical Mac/iPhone devices and verify on the minimum supported OS versions. Version 1.2 screenshots and distribution uploads are complete; see `RELEASE_NOTES.md` for submission status.

## Later possibilities

- Widgets, App Shortcuts/Siri, menu bar entry, and an Apple Watch companion.
- Saved filters, free-form tag filtering, drag reorder, and subtasks.
- Recurrence postponement, custom intervals, and history views.

Accounts, collaboration servers, analytics, and a custom cloud database are outside this update.
