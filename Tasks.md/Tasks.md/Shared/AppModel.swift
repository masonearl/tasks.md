import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedTasksFileUrl: URL? {
        didSet { }
    }
    @Published var store = TaskStore()

    let bookmarks = BookmarkStore()
    private let fileCoordinator = FileCoordinatorService()
    private var watcher: FileWatcher?
    private var securityScopedURL: URL?
    private var didStartSecurityAccess = false
    private var lastLoadedSignature: String?
    /// Ignore watcher callbacks briefly after our own writes settle via TaskStore.
    private var ignoreExternalChangesUntil: Date = .distantPast

    init() {
        print("🚀 AppModel init - attempting to restore file")
        if let url = bookmarks.resolveBookmark() {
            print("✅ Found saved file: \(url.path)")
            selectedTasksFileUrl = url
            // resolveBookmark already started security-scoped access
            securityScopedURL = url
            didStartSecurityAccess = true
            loadFromDisk()
            startWatching()
            store.bind(to: url)
        } else {
            print("❌ No saved file found - loading sample")
            loadSampleFile()
        }
    }
    
    private func loadSampleFile() {
        // Copy sample file to Documents directory for first-time users
        guard let sampleUrl = Bundle.main.url(forResource: "sample_tasks", withExtension: "md") else {
            print("⚠️ Sample file not found in bundle")
            return
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationUrl = documentsPath.appendingPathComponent("My Tasks.md")
        
        // Only copy if it doesn't already exist
        if !FileManager.default.fileExists(atPath: destinationUrl.path) {
            do {
                try FileManager.default.copyItem(at: sampleUrl, to: destinationUrl)
                print("✅ Copied sample file to: \(destinationUrl.path)")
            } catch {
                print("❌ Failed to copy sample file: \(error)")
                return
            }
        }
        
        // Set this as the selected file
        selectedTasksFileUrl = destinationUrl
        bookmarks.saveBookmark(for: destinationUrl)
        holdSecurityAccess(to: destinationUrl)
        store.bind(to: destinationUrl)
        loadFromDisk()
        startWatching()
        print("✅ Loaded sample file for first launch")
    }

    func setSelectedFile(_ url: URL) {
        print("📁 User selected file: \(url.path)")
        stopWatching()
        releaseSecurityAccess()
        selectedTasksFileUrl = url
        bookmarks.saveBookmark(for: url)
        holdSecurityAccess(to: url)
        store.bind(to: url)
        loadFromDisk()
        startWatching()
    }

    func loadFromDisk() {
        guard let url = selectedTasksFileUrl else { return }
        let nestedAccess = url.startAccessingSecurityScopedResource()
        defer { if nestedAccess { url.stopAccessingSecurityScopedResource() } }
        do {
            let text = try fileCoordinator.read(url: url)
            store.load(from: text)
            lastLoadedSignature = FileWatcher.signature(for: url)
            
            // Only process repeating tasks occasionally to avoid slow loading
            let lastProcessed = UserDefaults.standard.double(forKey: "lastRepeatProcessed")
            let now = Date().timeIntervalSince1970
            let oneHour: TimeInterval = 3600
            
            if now - lastProcessed > oneHour {
                ignoreExternalChanges(for: 1.0)
                store.processRepeatingTasks()
                UserDefaults.standard.set(now, forKey: "lastRepeatProcessed")
                lastLoadedSignature = FileWatcher.signature(for: url)
            }
        } catch {
            print("Error loading file: \(error)")
        }
    }

    /// Called when the scene becomes active; always reloads from disk.
    func reloadOnForeground() {
        loadFromDisk()
    }

    private func handleExternalFileChange() {
        guard Date() >= ignoreExternalChangesUntil else {
            print("👀 Ignoring external change (own write window)")
            return
        }
        guard let url = selectedTasksFileUrl else { return }
        let signature = FileWatcher.signature(for: url)
        if signature != nil, signature == lastLoadedSignature {
            return
        }
        print("🔄 Reloading tasks.md after external edit")
        loadFromDisk()
    }

    private func ignoreExternalChanges(for duration: TimeInterval) {
        ignoreExternalChangesUntil = Date().addingTimeInterval(duration)
    }

    private func startWatching() {
        stopWatching()
        guard let url = selectedTasksFileUrl else { return }
        holdSecurityAccess(to: url)
        lastLoadedSignature = FileWatcher.signature(for: url)
        watcher = FileWatcher(url: url) { [weak self] in
            Task { @MainActor in
                self?.handleExternalFileChange()
            }
        }
        print("👀 Started watching: \(url.path)")
    }

    private func stopWatching() {
        watcher?.stop()
        watcher = nil
    }

    private func holdSecurityAccess(to url: URL) {
        if let previous = securityScopedURL, previous != url {
            if didStartSecurityAccess {
                previous.stopAccessingSecurityScopedResource()
            }
            securityScopedURL = nil
            didStartSecurityAccess = false
        }
        if securityScopedURL == nil {
            didStartSecurityAccess = url.startAccessingSecurityScopedResource()
            securityScopedURL = url
            print("🔐 Security-scoped access for \(url.lastPathComponent): \(didStartSecurityAccess)")
        }
    }

    private func releaseSecurityAccess() {
        guard let url = securityScopedURL else { return }
        if didStartSecurityAccess {
            url.stopAccessingSecurityScopedResource()
        }
        securityScopedURL = nil
        didStartSecurityAccess = false
    }
}
