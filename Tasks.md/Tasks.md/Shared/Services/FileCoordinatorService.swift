import Foundation

final class FileCoordinatorService {
    private let coordinator = NSFileCoordinator(filePresenter: nil)

    func read(url: URL) throws -> String {
        var result: String = ""
        var coordError: NSError?
        var innerError: Error?
        coordinator.coordinate(readingItemAt: url, options: .withoutChanges, error: &coordError) { readUrl in
            do {
                result = try String(contentsOf: readUrl, encoding: .utf8)
            } catch {
                innerError = error
            }
        }
        if let innerError { throw innerError }
        if let coordError { throw coordError }
        return result
    }

    func write(url: URL, update: (String) -> String) throws {
        var coordError: NSError?
        var innerError: Error?
        coordinator.coordinate(writingItemAt: url, options: .forMerging, error: &coordError) { writeUrl in
            do {
                let current = (try? String(contentsOf: writeUrl, encoding: .utf8)) ?? ""
                let next = update(current)
                try next.write(to: writeUrl, atomically: true, encoding: .utf8)
            } catch {
                innerError = error
            }
        }
        if let innerError { throw innerError }
        if let coordError { throw coordError }
    }
}


