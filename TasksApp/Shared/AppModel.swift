import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedTasksFileUrl: URL? {
        didSet { /* trigger view updates */ }
    }
    @Published var store = TaskStore()

    private let bookmarks = BookmarkStore()
    private let fileCoordinator = FileCoordinatorService()
    private var watcher: FileWatcher?

    init() {
        if let url = bookmarks.resolveBookmark() {
            selectedTasksFileUrl = url
            loadFromDisk()
            startWatching()
        }
    }

    func setSelectedFile(_ url: URL) {
        selectedTasksFileUrl = url
        bookmarks.saveBookmark(for: url)
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
        } catch {
            // swallow; UI remains
        }
    }

    private func startWatching() {
        guard let url = selectedTasksFileUrl else { return }
        watcher = FileWatcher(url: url) { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self?.loadFromDisk()
            }
        }
    }
}


