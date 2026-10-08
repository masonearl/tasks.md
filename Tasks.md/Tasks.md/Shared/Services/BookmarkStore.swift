import Foundation

final class BookmarkStore {
    private let defaults: UserDefaults
    private let bookmarkKey = "tasksFileBookmark"
    private let pathKey = "tasksFilePath"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func saveBookmark(for url: URL) {
        let wasAccessing = url.startAccessingSecurityScopedResource()
        defer { if wasAccessing { url.stopAccessingSecurityScopedResource() } }

        do {
            #if os(macOS)
            let data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            #else
            let data = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            #endif
            defaults.set(data, forKey: bookmarkKey)
            defaults.set(url.path, forKey: pathKey)
        } catch {
            defaults.removeObject(forKey: bookmarkKey)
            defaults.set(url.path, forKey: pathKey)
        }
    }

    func resolveBookmark() -> URL? {
        if let data = defaults.data(forKey: bookmarkKey) {
            var isStale = false
            do {
                #if os(macOS)
                let url = try URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                #else
                let url = try URL(resolvingBookmarkData: data, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &isStale)
                #endif
                if isStale { saveBookmark(for: url) }
                return url
            } catch {
                // Fall through to the container path, if we still have one.
            }
        }

        guard let path = defaults.string(forKey: pathKey) else { return nil }
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: url.path), isInsideAppContainer(url) else {
            return nil
        }
        return url
    }

    private func isInsideAppContainer(_ url: URL) -> Bool {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .standardizedFileURL.path
        return url.standardizedFileURL.path.hasPrefix(documents + "/")
    }
}
