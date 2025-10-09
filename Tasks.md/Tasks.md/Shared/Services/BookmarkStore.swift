import Foundation

final class BookmarkStore {
    private let defaults: UserDefaults
    private let bookmarkKey = "tasksFileBookmark"
    private let pathKey = "tasksFilePath"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func saveBookmark(for url: URL) {
        do {
            #if os(macOS)
            let data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            #else
            let data = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
            #endif
            defaults.set(data, forKey: bookmarkKey)
            defaults.set(url.path, forKey: pathKey)
        } catch {
        }
    }

    func resolveBookmark() -> URL? {
        if let data = defaults.data(forKey: bookmarkKey) {
            var isStale = false
            do {
                #if os(macOS)
                let url = try URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                #else
                let url = try URL(resolvingBookmarkData: data, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale)
                #endif
                if isStale { saveBookmark(for: url) }
                return url
            } catch {
                // fall through to path fallback below
            }
        }
        // Fallback to saved path when no valid bookmark is available
        if let path = defaults.string(forKey: pathKey) {
            let fallback = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: fallback.path) { return fallback }
        }
        return nil
    }
}


