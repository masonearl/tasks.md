import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var selectedTasksFileUrl: URL?
    @Published var store = TaskStore()
    @Published var fileErrorMessage: String?

    let bookmarks = BookmarkStore()
    private let fileCoordinator = FileCoordinatorService()
    private var watcher: FileWatcher?
    private var securityScopedURL: URL?
    private var didStartSecurityAccess = false
    private var lastLoadedSignature: String?

    init() {
#if DEBUG
        // UI tests use their own document and never touch the user's selected file.
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") || ProcessInfo.processInfo.arguments.contains("--store-screenshots") {
            let isStoreCapture = ProcessInfo.processInfo.arguments.contains("--store-screenshots")
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(isStoreCapture ? "Store Capture/Documents/My Tasks.md" : "Tasks UI Preview.md")
            let sample = """
            # Tasks

            ## Today
            - [ ] Review the Mac update @priority(high) @due(2020-01-01)
            - [ ] Plan the next release @repeat(weekly)
            - [x] Choose a tasks file

            ## Work
            - [ ] Polish the task list @priority(medium)
            - [ ] Share release notes

            ## Personal
            - [ ] Plan the weekend
            """
            do {
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try (isStoreCapture ? Self.storeScreenshotMarkdown : sample).write(to: url, atomically: true, encoding: .utf8)
                setSelectedFile(url, remember: false)
            } catch { fileErrorMessage = error.localizedDescription }
            return
        }
#endif
        if let url = bookmarks.resolveBookmark() {
            setSelectedFile(url)
        } else {
            ensureDefaultFile()
        }
    }

#if DEBUG
    private static var storeScreenshotMarkdown: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        let tomorrow = formatter.string(from: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
        return """
        # My Tasks

        ## Today
        - [ ] Review the project proposal @priority(high) @due(\(today))
        - [ ] Send the design feedback @due(\(today))
        - [ ] Plan tomorrow's focus @priority(medium)

        ## Work
        - [ ] Draft October release notes @due(\(tomorrow))
        - [ ] Weekly team review @repeat(weekly)
        - [x] Publish the launch checklist

        ## Personal
        - [ ] Book a weekend hike
        - [ ] Read 20 pages @repeat(daily)
        """
    }
#endif

    func ensureDefaultFile() {
        guard selectedTasksFileUrl == nil else { return }
        do {
            setSelectedFile(try DefaultTasksFile.ensureOnDisk())
        } catch {
            fileErrorMessage = "Couldn't create a tasks file: \(error.localizedDescription)"
        }
    }

    func setSelectedFile(_ url: URL, remember: Bool = true) {
        let accessed = url.startAccessingSecurityScopedResource()
        do {
            let text = try fileCoordinator.read(url: url)
            watcher?.stop()
            if didStartSecurityAccess { securityScopedURL?.stopAccessingSecurityScopedResource() }
            securityScopedURL = url
            didStartSecurityAccess = accessed
            selectedTasksFileUrl = url
            store.bind(to: url)
            store.load(from: text)
            if remember { bookmarks.saveBookmark(for: url) }
            fileErrorMessage = nil
            store.processRepeatingTasks()
            lastLoadedSignature = FileWatcher.signature(for: url)
            watcher = FileWatcher(url: url) { [weak self] in
                Task { @MainActor [weak self] in self?.handleExternalFileChange() }
            }
        } catch {
            if accessed { url.stopAccessingSecurityScopedResource() }
            fileErrorMessage = "Couldn't open \(url.lastPathComponent): \(error.localizedDescription)"
        }
    }

    func loadFromDisk() {
        guard let url = selectedTasksFileUrl else { return }
        do {
            store.load(from: try fileCoordinator.read(url: url))
            store.processRepeatingTasks()
            lastLoadedSignature = FileWatcher.signature(for: url)
            fileErrorMessage = nil
        } catch {
            fileErrorMessage = "Couldn't read \(url.lastPathComponent). Choose the file again or retry. \(error.localizedDescription)"
        }
    }

    func retryFile() {
        if selectedTasksFileUrl != nil { loadFromDisk() }
        else if let url = bookmarks.resolveBookmark() { setSelectedFile(url) }
        else { ensureDefaultFile() }
    }

    func reloadOnForeground() { loadFromDisk() }

    private func handleExternalFileChange() {
        guard let url = selectedTasksFileUrl else { return }
        let signature = FileWatcher.signature(for: url)
        if signature != nil && signature == lastLoadedSignature { return }
        loadFromDisk()
    }
}

enum NewTasksFileName {
    static func make(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HHmmss"
        return "Tasks \(formatter.string(from: date)).md"
    }
}

enum DefaultTasksFile {
    static let fileName = "My Tasks.md"
    static let starterMarkdown = """
    # Tasks

    ## Today
    - [ ] Check off this task
    - [ ] Add a task with the field at the bottom
    """

    static func documentsURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    static func ensureOnDisk() throws -> URL {
        let destinationUrl = documentsURL()
        try FileManager.default.createDirectory(at: destinationUrl.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard !FileManager.default.fileExists(atPath: destinationUrl.path) else {
            return destinationUrl
        }

        if let sampleUrl = Bundle.main.url(forResource: "sample_tasks", withExtension: "md") {
            do {
                try FileManager.default.copyItem(at: sampleUrl, to: destinationUrl)
                return destinationUrl
            } catch {
                print("Could not copy bundled sample: \(error)")
            }
        }

        try starterMarkdown.write(to: destinationUrl, atomically: true, encoding: .utf8)
        return destinationUrl
    }
}
