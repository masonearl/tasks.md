import Foundation

final class FileWatcher: NSObject, NSFilePresenter, @unchecked Sendable {
    nonisolated let presentedItemURL: URL?
    nonisolated let presentedItemOperationQueue: OperationQueue = {
        let q = OperationQueue()
        q.maxConcurrentOperationCount = 1
        return q
    }()

    private let onChange: () -> Void

    init(url: URL, onChange: @escaping () -> Void) {
        self.presentedItemURL = url
        self.onChange = onChange
        super.init()
        NSFileCoordinator.addFilePresenter(self)
    }

    deinit {
        NSFileCoordinator.removeFilePresenter(self)
    }

    nonisolated func presentedItemDidChange() {
        onChange()
    }
}


