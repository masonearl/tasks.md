# Quick start

1. Open `Tasks.md/Tasks.md.xcodeproj` in Xcode 26 or newer.
2. Select the **Tasks.md** scheme and **My Mac** or an iPhone simulator.
3. Choose your signing team if prompted, then Run.
4. The app opens a sample markdown file. Type a task at the bottom, choose a category, and press Return.
5. Use the folder button to open your own file. Put it in iCloud Drive and select the same file on another device for provider-managed sync.

On Mac, **⌘N** focuses task entry, **⌘F** focuses search, and **⌘O** opens a file. Click a task title to rename it. The task menu offers repeat settings. Today includes tasks due today and overdue tasks.

To verify external edits, open the selected file in a text editor, add `- [ ] Added externally`, and save. The app should update within a few seconds. Toggle that task in the app and verify that only its checkbox and completion tag change in the file.

See [README.md](README.md) for build/test commands and [FEATURES.md](FEATURES.md) for implemented features and next priorities. Reminder notifications are not implemented.
