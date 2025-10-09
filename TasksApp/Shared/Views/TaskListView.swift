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
                                HStack {
                                    Image(systemName: task.isCompleted ? "checkmark.square" : "square")
                                    Text(task.title)
                                    Spacer()
                                    if let p = task.tags.priority {
                                        Text(p.rawValue.capitalized)
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(priorityColor(p).opacity(0.15))
                                            .foregroundStyle(priorityColor(p))
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                }
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

//#Preview { TaskListView(store: TaskStore()) }


