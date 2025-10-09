import SwiftUI

@main
struct TasksAppApp: App {
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appModel)
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
        }

        Settings {
            PreferencesView()
                .environmentObject(appModel)
        }
    }
}

final class AppModel: ObservableObject {
    @Published var selectedTasksFileUrl: URL? {
        didSet { handleSelectedFileChanged() }
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
        } else {
            // First launch: prompt for file selection
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                TasksFilePicker.pick { url in
                    self?.setSelectedFile(url)
                }
            }
        }
    }

    func setSelectedFile(_ url: URL) {
        selectedTasksFileUrl = url
        bookmarks.saveBookmark(for: url)
        loadFromDisk()
        startWatching()
    }

    private func handleSelectedFileChanged() {
        // reload views as needed
    }

    func loadFromDisk() {
        guard let url = selectedTasksFileUrl else { return }
        _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }
        do {
            let text = try fileCoordinator.read(url: url)
            store.load(from: text)
        } catch {
            // ignore for now
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


