import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let isEditing: Bool
    var onToggle: () -> Void
    var onBeginEditing: () -> Void
    var onRename: (String) -> Void
    var onCancelEditing: () -> Void
    var onRepeat: () -> Void

    @State private var draftTitle = ""
    @FocusState private var titleFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(task.isCompleted ? Color.accentColor : Color.secondary)
                    .frame(width: 24, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(task.isCompleted ? "Mark incomplete" : "Mark complete"): \(task.title)")

            VStack(alignment: .leading, spacing: 3) {
                if isEditing {
                    TextField("Task title", text: $draftTitle)
                        .textFieldStyle(.plain)
                        .focused($titleFocused)
                        .onSubmit(commit)
#if os(macOS)
                        .onExitCommand { onCancelEditing() }
#endif
                        .accessibilityIdentifier("editTaskTitleField")
                } else {
                    Button(action: onBeginEditing) {
                        Text(task.title)
                            .strikethrough(task.isCompleted)
                            .foregroundStyle(task.isCompleted ? .secondary : .primary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Edit task")
                }
                if task.tags.dueDate != nil || task.tags.custom["repeat"] != nil {
                    HStack(spacing: 10) {
                        if let due = task.tags.dueDate {
                            Label(dueLabel(due), systemImage: "calendar")
                                .foregroundStyle(isOverdue(due) ? Color.red : Color.secondary)
                        }
                        if let frequency = task.tags.custom["repeat"] {
                            Label(frequency.capitalized, systemImage: "repeat").foregroundStyle(.secondary)
                        }
                    }
                    .font(.caption2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let priority = task.tags.priority {
                Image(systemName: "flag.fill")
                    .font(.caption)
                    .foregroundStyle(priorityColor(priority))
                    .help("\(priority.rawValue.capitalized) priority")
                    .accessibilityLabel("\(priority.rawValue.capitalized) priority")
            }
            Menu {
                Button("Rename", action: onBeginEditing)
                Button("Repeat…", action: onRepeat)
                Button(task.isCompleted ? "Mark Incomplete" : "Mark Complete", action: onToggle)
            } label: { Image(systemName: "ellipsis") }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .frame(width: 24, height: 28)
            .accessibilityLabel("Options for \(task.title)")
        }
        .padding(.vertical, 3)
        .contextMenu {
            Button("Rename", action: onBeginEditing)
            Button("Repeat…", action: onRepeat)
        }
        .onChange(of: isEditing) { _, editing in
            if editing {
                draftTitle = task.title
                titleFocused = true
            } else { titleFocused = false }
        }
        .onChange(of: titleFocused) { _, focused in
            if isEditing && !focused { commit() }
        }
    }

    private func commit() {
        let trimmed = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == task.title { onCancelEditing() }
        else { onRename(trimmed) }
    }
    private func isOverdue(_ date: Date) -> Bool {
        !task.isCompleted && date < Calendar.current.startOfDay(for: Date())
    }
    private func dueLabel(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInTomorrow(date) { return "Tomorrow" }
        let label = date.formatted(.dateTime.month(.abbreviated).day())
        return isOverdue(date) ? "Overdue · \(label)" : label
    }
    private func priorityColor(_ priority: TaskItem.Priority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}
