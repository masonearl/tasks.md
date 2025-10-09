import Foundation

final class FileCoordinatorService {
    private let coordinator = NSFileCoordinator(filePresenter: nil)

    func read(url: URL) throws -> String {
        var result: String = ""
        var error: NSError?
        coordinator.coordinate(readingItemAt: url, options: .withoutChanges, error: &error) { readUrl in
            do {
                result = try String(contentsOf: readUrl, encoding: .utf8)
            } catch {
                error = error as NSError
            }
        }
        if let error { throw error }
        return result
    }

    func write(url: URL, update: (String) -> String) throws {
        var writeError: NSError?
        coordinator.coordinate(writingItemAt: url, options: .forMerging, error: &writeError) { writeUrl in
            do {
                let current = (try? String(contentsOf: writeUrl, encoding: .utf8)) ?? ""
                let next = update(current)
                try next.write(to: writeUrl, atomically: true, encoding: .utf8)
            } catch {
                writeError = error as NSError
            }
        }
        if let writeError { throw writeError }
    }
}


