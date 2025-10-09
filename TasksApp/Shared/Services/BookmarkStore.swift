import Foundation

final class BookmarkStore {
    private let defaults: UserDefaults
    private let bookmarkKey = "tasksFileBookmark"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func saveBookmark(for url: URL) {
        do {
            let data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            defaults.set(data, forKey: bookmarkKey)
        } catch {
            // Intentionally ignore for now; user can reselect
        }
    }

    func resolveBookmark() -> URL? {
        guard let data = defaults.data(forKey: bookmarkKey) else { return nil }
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            if isStale {
                // attempt to refresh bookmark with a save
                saveBookmark(for: url)
            }
            return url
        } catch {
            return nil
        }
    }
}


