import Foundation
import Darwin

/// Watches a tasks.md file for external edits (Cursor, other editors, iCloud).
///
/// Strategy (bookmark-aware, low-churn):
/// 1. `DispatchSource` write/rename/delete events when a descriptor can be opened
/// 2. `NSFilePresenter` for coordinated / iCloud-aware change callbacks
/// 3. Short mtime+size poll as a safety net when FSEvents-style signals are flaky
///
/// Notifications are debounced so mid-save keystrokes do not thrash reloads.
/// Callers should keep security-scoped access alive for the watched URL.
final class FileWatcher: NSObject, NSFilePresenter, @unchecked Sendable {
    nonisolated let presentedItemURL: URL?
    nonisolated let presentedItemOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "tasks.md.FileWatcher"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    private let onChange: @Sendable () -> Void
    private let debounceInterval: TimeInterval
    private let pollInterval: TimeInterval

    private var fileDescriptor: Int32 = -1
    private var source: DispatchSourceFileSystemObject?
    private var pollTimer: DispatchSourceTimer?
    private var debounceWorkItem: DispatchWorkItem?
    private var lastSignature: String?
    private let lock = NSLock()
    private var isStopped = false

    init(
        url: URL,
        debounceInterval: TimeInterval = 0.35,
        pollInterval: TimeInterval = 1.5,
        onChange: @escaping @Sendable () -> Void
    ) {
        self.presentedItemURL = url
        self.debounceInterval = debounceInterval
        self.pollInterval = pollInterval
        self.onChange = onChange
        super.init()
        self.lastSignature = Self.signature(for: url)
        startDispatchSource(for: url)
        startPolling(for: url)
        NSFileCoordinator.addFilePresenter(self)
    }

    deinit {
        stop()
    }

    func stop() {
        lock.lock()
        defer { lock.unlock() }
        guard !isStopped else { return }
        isStopped = true

        debounceWorkItem?.cancel()
        debounceWorkItem = nil

        pollTimer?.setEventHandler {}
        pollTimer?.cancel()
        pollTimer = nil

        source?.setEventHandler {}
        source?.cancel()
        source = nil

        if fileDescriptor >= 0 {
            close(fileDescriptor)
            fileDescriptor = -1
        }

        NSFileCoordinator.removeFilePresenter(self)
    }

    // MARK: - NSFilePresenter

    nonisolated func presentedItemDidChange() {
        scheduleChangeCheck(reason: "presenter")
    }

    nonisolated func presentedItemDidMove(to newURL: URL) {
        scheduleChangeCheck(reason: "moved")
    }

    nonisolated func accommodatePresentedItemDeletion(completionHandler: @escaping (Error?) -> Void) {
        scheduleChangeCheck(reason: "deleted")
        completionHandler(nil)
    }

    // MARK: - Internals

    private func startDispatchSource(for url: URL) {
        let path = url.path
        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else {
            print("⚠️ FileWatcher: could not open descriptor for \(path); relying on poll + presenter")
            return
        }
        fileDescriptor = fd

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete, .extend, .attrib, .link],
            queue: DispatchQueue.global(qos: .utility)
        )
        source.setEventHandler { [weak self] in
            self?.scheduleChangeCheck(reason: "dispatch-source")
            // After rename/delete the descriptor often goes stale; rebuild on next poll.
        }
        source.setCancelHandler { [weak self] in
            guard let self else { return }
            if self.fileDescriptor >= 0 {
                close(self.fileDescriptor)
                self.fileDescriptor = -1
            }
        }
        source.resume()
        self.source = source
    }

    private func startPolling(for _: URL) {
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
        timer.schedule(deadline: .now() + pollInterval, repeating: pollInterval, leeway: .milliseconds(250))
        timer.setEventHandler { [weak self] in
            self?.scheduleChangeCheck(reason: "poll")
        }
        timer.resume()
        pollTimer = timer
    }

    private func scheduleChangeCheck(reason: String) {
        lock.lock()
        guard !isStopped else {
            lock.unlock()
            return
        }
        debounceWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.evaluateAndNotify(reason: reason)
        }
        debounceWorkItem = work
        lock.unlock()
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + debounceInterval, execute: work)
    }

    private func evaluateAndNotify(reason: String) {
        lock.lock()
        guard !isStopped, let url = presentedItemURL else {
            lock.unlock()
            return
        }
        let signature = Self.signature(for: url)
        let changed = signature != lastSignature
        if changed {
            lastSignature = signature
        }
        lock.unlock()

        guard changed else { return }
        print("👀 FileWatcher: change detected (\(reason))")
        onChange()
    }

    /// mtime + size is enough to detect Cursor/iCloud writes without reading the whole file.
    nonisolated static func signature(for url: URL) -> String? {
        let values = try? url.resourceValues(forKeys: [
            .contentModificationDateKey,
            .fileSizeKey,
            .isRegularFileKey
        ])
        guard let values, values.isRegularFile != false else { return nil }
        let mtime = values.contentModificationDate?.timeIntervalSince1970 ?? 0
        let size = values.fileSize ?? -1
        return "\(mtime)|\(size)"
    }
}
