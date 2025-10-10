import Foundation

final class BookmarkStore {
    private let defaults: UserDefaults
    private let bookmarkKey = "tasksFileBookmark"
    private let pathKey = "tasksFilePath"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func saveBookmark(for url: URL) {
        print("🔍 Saving bookmark for: \(url.path)")
        
        // For iCloud files, just log that we detected one
        if url.path.contains("com~apple~CloudDocs") {
            print("📱 iCloud file detected at: \(url.path)")
        }
        
        // Make sure we have security-scoped access before creating bookmark
        let wasAccessing = url.startAccessingSecurityScopedResource()
        defer { if wasAccessing { url.stopAccessingSecurityScopedResource() } }
        
        do {
            #if os(macOS)
            let data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            #else
            // On iOS, we need .minimalBookmark for files picked from document picker
            let data = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            #endif
            defaults.set(data, forKey: bookmarkKey)
            defaults.set(url.path, forKey: pathKey)
            print("✅ Bookmark saved successfully")
        } catch {
            print("❌ Failed to save bookmark: \(error)")
            // Fallback: just save the path without bookmark
            print("🔄 Fallback: saving path only")
            defaults.set(url.path, forKey: pathKey)
        }
    }

    func resolveBookmark() -> URL? {
        print("🔍 Attempting to resolve bookmark...")
        if let data = defaults.data(forKey: bookmarkKey) {
            print("📁 Found bookmark data")
            var isStale = false
            do {
                #if os(macOS)
                let url = try URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                #else
                let url = try URL(resolvingBookmarkData: data, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &isStale)
                #endif
                print("✅ Resolved bookmark to: \(url.path)")
                if isStale { saveBookmark(for: url) }
                // Start accessing the security-scoped resource
                let _ = url.startAccessingSecurityScopedResource()
                return url
            } catch {
                print("❌ Failed to resolve bookmark: \(error)")
                // fall through to path fallback below
            }
        } else {
            print("📁 No bookmark data found")
        }
        print("❌ No valid file found")
        return nil
    }
}


