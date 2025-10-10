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
    #if os(macOS)
    private var watcher: FileWatcher?
    #endif

    init() {
        print("🚀 AppModel init - attempting to restore file")
        if let url = bookmarks.resolveBookmark() {
            print("✅ Found saved file: \(url.path)")
            selectedTasksFileUrl = url
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
        store.bind(to: destinationUrl)
        loadFromDisk()
        startWatching()
        print("✅ Loaded sample file for first launch")
    }

    func setSelectedFile(_ url: URL) {
        print("📁 User selected file: \(url.path)")
        selectedTasksFileUrl = url
        bookmarks.saveBookmark(for: url)
        store.bind(to: url)
        loadFromDisk()
        startWatching()
    }

    func loadFromDisk() {
        guard let url = selectedTasksFileUrl else { return }
        _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }
        do {
            let text = try fileCoordinator.read(url: url)
            store.load(from: text)
            
            // Only process repeating tasks occasionally to avoid slow loading
            let lastProcessed = UserDefaults.standard.double(forKey: "lastRepeatProcessed")
            let now = Date().timeIntervalSince1970
            let oneHour: TimeInterval = 3600
            
            if now - lastProcessed > oneHour {
                store.processRepeatingTasks()
                UserDefaults.standard.set(now, forKey: "lastRepeatProcessed")
            }
        } catch {
            print("Error loading file: \(error)")
        }
    }

    #if os(macOS)
    private func startWatching() {
        guard let url = selectedTasksFileUrl else { return }
        // Disable file watching for better performance on macOS
        // watcher = FileWatcher(url: url) { [weak self] in
        //     DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
        //         self?.loadFromDisk()
        //     }
        // }
    }
    #else
    private func startWatching() { }
    #endif
}


