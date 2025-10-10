import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    @ObservedObject var store: TaskStore

    @State private var draftTitle: String
    @FocusState private var isFocused: Bool
    @State private var showRepeatSheet = false

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
                        .onChange(of: isFocused) { _, focused in if !focused { commit() } }
                } else {
                    TextField("Task title", text: $draftTitle)
                        .focused($isFocused)
                        .textFieldStyle(.plain)
                        .onSubmit(commit)
                        .onChange(of: isFocused) { _, focused in if !focused { commit() } }
                }

                HStack(spacing: 8) {
                    if let p = task.tags.priority {
                        Text(p.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(priorityColor(p).opacity(0.15))
                            .foregroundStyle(priorityColor(p))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    
                    if task.tags.custom["repeat"] != nil {
                        Text("Repeat")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .foregroundStyle(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            // Repeat button on the far right
            Button(action: showRepeatOptions) {
                Image(systemName: "repeat")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
#if os(iOS)
            .actionSheet(isPresented: $showRepeatSheet) {
                ActionSheet(
                    title: Text("Repeat Task"),
                    buttons: [
                        .default(Text("Daily")) { addRepeatTag("daily") },
                        .default(Text("Weekly")) { addRepeatTag("weekly") },
                        .default(Text("Monthly")) { addRepeatTag("monthly") },
                        task.tags.custom["repeat"] != nil ? 
                            .destructive(Text("Remove Repeat")) { removeRepeatTag() } : nil,
                        .cancel()
                    ].compactMap { $0 }
                )
            }
#else
            .popover(isPresented: $showRepeatSheet) {
                VStack(spacing: 12) {
                    Text("Repeat Task")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Button("Daily") {
                        addRepeatTag("daily")
                        showRepeatSheet = false
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Weekly") {
                        addRepeatTag("weekly")
                        showRepeatSheet = false
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Monthly") {
                        addRepeatTag("monthly")
                        showRepeatSheet = false
                    }
                    .buttonStyle(.bordered)
                    
                    if task.tags.custom["repeat"] != nil {
                        Button("Remove Repeat") {
                            removeRepeatTag()
                            showRepeatSheet = false
                        }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.red)
                    }
                    
                    Button("Cancel") {
                        showRepeatSheet = false
                    }
                    .buttonStyle(.bordered)
                    .padding(.bottom, 8)
                }
                .padding()
                .frame(width: 200)
            }
#endif
        }
    }

    private func commit() {
        let trimmed = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != task.title, !trimmed.isEmpty else { return }
        store.updateTitle(task: task, newTitle: trimmed)
    }
    
    private func addRepeatTag(_ repeatType: String) {
        let trimmed = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            store.updateTitle(task: task, newTitle: trimmed)
        }
        store.addRepeatTag(task: task, repeatType: repeatType)
    }
    
    private func removeRepeatTag() {
        let trimmed = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            store.updateTitle(task: task, newTitle: trimmed)
        }
        store.removeRepeatTag(task: task)
    }
    
    private func showRepeatOptions() {
        showRepeatSheet = true
    }

    private func priorityColor(_ p: TaskItem.Priority) -> Color {
        switch p {
        case .high: return .red
        case .medium: return .orange
        case .low: return .yellow
        }
    }
}


