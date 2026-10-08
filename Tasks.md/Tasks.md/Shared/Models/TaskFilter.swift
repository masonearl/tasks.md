import Foundation

enum TaskFilter: String, CaseIterable, Identifiable {
    case open = "Open", today = "Today", all = "All", completed = "Done"
    var id: String { rawValue }

    func includes(_ task: TaskItem, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        switch self {
        case .open: return !task.isCompleted
        case .completed: return task.isCompleted
        case .all: return true
        case .today:
            guard !task.isCompleted, let due = task.tags.dueDate,
                  let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else { return false }
            return due < tomorrow
        }
    }
}

enum TaskSort: String, CaseIterable, Identifiable {
    case file = "File order", due = "Due date", priority = "Priority"
    var id: String { rawValue }

    func sorted(_ tasks: [TaskItem]) -> [TaskItem] {
        guard self != .file else { return tasks }
        return tasks.enumerated().sorted { left, right in
            if self == .due {
                let a = left.element.tags.dueDate ?? .distantFuture
                let b = right.element.tags.dueDate ?? .distantFuture
                if a != b { return a < b }
            } else {
                let order: [TaskItem.Priority: Int] = [.high: 0, .medium: 1, .low: 2]
                let a = left.element.tags.priority.flatMap { order[$0] } ?? 3
                let b = right.element.tags.priority.flatMap { order[$0] } ?? 3
                if a != b { return a < b }
            }
            return left.offset < right.offset
        }.map(\.element)
    }
}
