import Foundation

public struct TaskSection: Identifiable, Hashable, Codable {
    public let id: String
    public var title: String
    public var path: [String]
    public var tasks: [TaskItem]

    public init(title: String, path: [String], tasks: [TaskItem]) {
        self.id = (path + [title]).joined(separator: "/")
        self.title = title
        self.path = path
        self.tasks = tasks
    }
}


