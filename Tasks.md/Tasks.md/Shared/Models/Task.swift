import Foundation

public struct TaskItem: Identifiable, Hashable, Codable {
    public struct Tags: Hashable, Codable {
        public var priority: Priority?
        public var dueDate: Date?
        public var remindAt: Date?
        public var completedAt: Date?
        public var custom: [String: String] = [:]
    }

    public enum Priority: String, Codable, CaseIterable { case high, medium, low }

    public let id: String
    public var title: String
    public var isCompleted: Bool
    public var sectionPath: [String]
    public var tags: Tags

    public init(id: String, title: String, isCompleted: Bool, sectionPath: [String], tags: Tags) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.sectionPath = sectionPath
        self.tags = tags
    }
}


