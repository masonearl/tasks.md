import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedTasksFileUrl: URL? {
        didSet { }
    }
    @Published var store = TaskStore()

    private let bookmarks = BookmarkStore()
    private let fileCoordinator = FileCoordinatorService()
    #if os(macOS)
    private var watcher: FileWatcher?
    #endif

    init() {
        if let url = bookmarks.resolveBookmark() {
            selectedTasksFileUrl = url
            loadFromDisk()
            startWatching()
            store.bind(to: url)
        }
    }

    func setSelectedFile(_ url: URL) {
        selectedTasksFileUrl = url
        bookmarks.saveBookmark(for: url)
        loadFromDisk()
        startWatching()
        store.bind(to: url)
    }

    func loadFromDisk() {
        guard let url = selectedTasksFileUrl else { return }
        _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }
        do {
            let text = try fileCoordinator.read(url: url)
            store.load(from: text)
            store.bind(to: url)
        } catch {
        }
    }

    #if os(macOS)
    private func startWatching() {
        guard let url = selectedTasksFileUrl else { return }
        watcher = FileWatcher(url: url) { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self?.loadFromDisk()
            }
        }
    }
    #else
    private func startWatching() { }
    #endif
}


