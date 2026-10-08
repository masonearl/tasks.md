import Foundation
import XCTest
@testable import Tasks_md

final class FileWatcherTests: XCTestCase {
    func testMultipleAtomicReplacementsAreObserved() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("watch-\(UUID()).md")
        try "## Tasks\n- [ ] Initial".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        let changes = ChangeCounter()
        let watcher = FileWatcher(url: url, debounceInterval: 0.02, pollInterval: 0.1) { changes.increment() }
        defer { watcher.stop() }
        for index in 1...2 {
            try "## Tasks\n- [ ] Replacement \(index)".write(to: url, atomically: true, encoding: .utf8)
            let deadline = Date().addingTimeInterval(3)
            while changes.value < index && Date() < deadline {
                try await Task.sleep(for: .milliseconds(50))
            }
            XCTAssertGreaterThanOrEqual(changes.value, index)
        }
        watcher.stop()
        let stoppedCount = changes.value
        try "## Tasks\n- [ ] After stop".write(to: url, atomically: true, encoding: .utf8)
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertEqual(changes.value, stoppedCount)
    }
}

private nonisolated final class ChangeCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    var value: Int { lock.withLock { count } }
    func increment() { lock.withLock { count += 1 } }
}
