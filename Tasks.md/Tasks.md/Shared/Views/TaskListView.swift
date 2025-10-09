import SwiftUI

struct TaskListView: View {
    @ObservedObject var store: TaskStore

    var body: some View {
        Group {
            if store.sections.flatMap({ $0.tasks }).isEmpty {
                VStack(spacing: 8) {
                    Text("No tasks found in your markdown file")
                        .foregroundStyle(.secondary)
                    Text("Use '- [ ] Task title' under '## Section' headings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(store.sections) { section in
                        Section(section.title.isEmpty ? "Tasks" : section.title) {
                            ForEach(section.tasks) { task in
                                TaskRowView(task: task, store: store)
                            }
                        }
                    }
                }
            }
        }
    }

    private func priorityColor(_ p: TaskItem.Priority) -> Color {
        switch p {
        case .high: return .red
        case .medium: return .orange
        case .low: return .yellow
        }
    }
}


