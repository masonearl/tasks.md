import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    @ObservedObject var store: TaskStore

    @State private var draftTitle: String
    @FocusState private var isFocused: Bool

    init(task: TaskItem, store: TaskStore) {
        self.task = task
        self.store = store
        _draftTitle = State(initialValue: task.title)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Button(action: { store.toggle(task: task) }) {
                Image(systemName: task.isCompleted ? "checkmark.square" : "square")
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                if #available(iOS 16.0, macOS 13.0, *) {
                    TextField("Task title", text: $draftTitle, axis: .vertical)
                        .lineLimit(1...6)
                        .focused($isFocused)
                        .textFieldStyle(.plain)
                        .onSubmit(commit)
                        .onChange(of: isFocused) { focused in if !focused { commit() } }
                        .toolbar {
                            #if os(iOS)
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") { isFocused = false }
                            }
                            #endif
                        }
                } else {
                    TextField("Task title", text: $draftTitle)
                        .focused($isFocused)
                        .textFieldStyle(.plain)
                        .onSubmit(commit)
                        .onChange(of: isFocused) { focused in if !focused { commit() } }
                }

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

    private func commit() {
        let trimmed = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != task.title, !trimmed.isEmpty else { return }
        store.updateTitle(task: task, newTitle: trimmed)
    }

    private func priorityColor(_ p: TaskItem.Priority) -> Color {
        switch p {
        case .high: return .red
        case .medium: return .orange
        case .low: return .yellow
        }
    }
}


