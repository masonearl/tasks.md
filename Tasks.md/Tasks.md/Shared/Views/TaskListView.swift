import SwiftUI

struct TaskListView: View {
    @ObservedObject var store: TaskStore
    @State private var draftTitle = ""
    @State private var selectedSection = ""
    @State private var editingTaskID: String?
    @State private var repeatTask: TaskItem?
    @State private var filter = TaskFilter.open
    @State private var sort = TaskSort.file
    @State private var search = ""
    @State private var collapsedSections: Set<String> = []
    @State private var showNewCategory = false
    @FocusState private var isComposerFocused: Bool
    @FocusState private var isSearchFocused: Bool

    private var allTasks: [TaskItem] { store.sections.flatMap(\.tasks) }
    private var openCount: Int { allTasks.filter { !$0.isCompleted }.count }
    private var sectionTitles: [String] {
        var titles = store.availableSectionTitles()
        if titles.isEmpty { titles = ["Tasks"] }
        if !selectedSection.isEmpty && !titles.contains(selectedSection) { titles.append(selectedSection) }
        return titles
    }

    var body: some View {
        VStack(spacing: 0) {
            controls
            Divider()
            List {
                ForEach(visibleSections) { section in
                    Section {
                        if !collapsedSections.contains(section.id) {
                            ForEach(visibleTasks(in: section)) { task in
                                TaskRowView(
                                    task: task,
                                    isEditing: editingTaskID == task.id,
                                    onToggle: { store.toggle(task: task) },
                                    onBeginEditing: { editingTaskID = task.id },
                                    onRename: { title in
                                        if store.updateTitle(task: task, newTitle: title) { editingTaskID = nil }
                                    },
                                    onCancelEditing: { editingTaskID = nil },
                                    onRepeat: { repeatTask = task }
                                )
                                .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 12))
                            }
                        }
                    } header: {
                        Button {
                            if !collapsedSections.insert(section.id).inserted { collapsedSections.remove(section.id) }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: collapsedSections.contains(section.id) ? "chevron.right" : "chevron.down")
                                    .font(.system(size: 9, weight: .semibold))
                                    .frame(width: 10)
                                Text(section.title.isEmpty ? "Tasks" : section.title)
                                    .fontWeight(.semibold)
                                Text("\(visibleTasks(in: section).count)").monospacedDigit().foregroundStyle(.tertiary)
                                Spacer()
                            }
                            .font(.caption)
                            .contentShape(Rectangle())
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(collapsedSections.contains(section.id) ? "Expand" : "Collapse") \(section.title)")
                    }
                }
            }
            .listStyle(.inset)
            .environment(\.defaultMinListRowHeight, 32)
            .overlay {
                if visibleSections.isEmpty { emptyState }
            }
            Divider()
            addComposer
        }
        .onAppear { selectedSection = sectionTitles.first ?? "Tasks" }
        .onReceive(NotificationCenter.default.publisher(for: .focusAddComposer)) { _ in isComposerFocused = true }
        .onReceive(NotificationCenter.default.publisher(for: .focusTaskSearch)) { _ in isSearchFocused = true }
        .sheet(isPresented: $showNewCategory) {
            NewCategorySheet { selectedSection = $0 }
#if os(macOS)
                .frame(width: 360, height: 180)
#endif
        }
        .confirmationDialog("Repeat Task", isPresented: Binding(
            get: { repeatTask != nil }, set: { if !$0 { repeatTask = nil } }
        ), titleVisibility: .visible) {
            Button("Daily") { setRepeat("daily") }
            Button("Weekly") { setRepeat("weekly") }
            Button("Monthly") { setRepeat("monthly") }
            if repeatTask?.tags.custom["repeat"] != nil {
                Button("Remove Repeat", role: .destructive) {
                    if let task = repeatTask { store.removeRepeatTag(task: task) }
                    repeatTask = nil
                }
            }
            Button("Cancel", role: .cancel) { repeatTask = nil }
        }
    }

    private var controls: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search tasks or categories", text: $search)
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                    .accessibilityIdentifier("taskSearchField")
                if !search.isEmpty {
                    Button("Clear search", systemImage: "xmark.circle.fill") { search = "" }
                        .labelStyle(.iconOnly).buttonStyle(.plain).foregroundStyle(.secondary)
                }
                Menu {
                    Picker("Sort tasks", selection: $sort) {
                        ForEach(TaskSort.allCases) { Text($0.rawValue).tag($0) }
                    }
                } label: { Image(systemName: "arrow.up.arrow.down") }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Sort tasks: \(sort.rawValue)")
                .accessibilityLabel("Sort tasks")
            }
            HStack(spacing: 12) {
                Picker("Show tasks", selection: $filter) {
                    ForEach(TaskFilter.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .accessibilityIdentifier("taskFilter")
                Text("\(openCount) open")
                    .font(.caption).foregroundStyle(.secondary).monospacedDigit().fixedSize()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: search.isEmpty ? "checkmark.circle" : "magnifyingglass")
                .font(.system(size: 26, weight: .light)).foregroundStyle(.secondary)
            Text(search.isEmpty ? emptyTitle : "No matching tasks").font(.headline)
            Text(search.isEmpty ? emptyDescription : "Try a different title or category.")
                .font(.callout).foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyTitle: String {
        switch filter {
        case .open: return allTasks.isEmpty ? "Start with one task" : "All caught up"
        case .today: return "Nothing due today"
        case .completed: return "No completed tasks yet"
        case .all: return "Start with one task"
        }
    }
    private var emptyDescription: String {
        switch filter {
        case .today: return "Tasks due today and overdue appear here."
        case .completed: return "Check off a task to see it here."
        default: return "Add a task below whenever you're ready."
        }
    }

    private var visibleSections: [TaskSection] { store.sections.filter { !visibleTasks(in: $0).isEmpty } }
    private func visibleTasks(in section: TaskSection) -> [TaskItem] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return sort.sorted(section.tasks.filter {
            filter.includes($0) && (query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) || section.title.localizedCaseInsensitiveContains(query))
        })
    }

    private var addComposer: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let error = store.lastErrorMessage {
                HStack(alignment: .top) {
                    Label(error, systemImage: "exclamationmark.triangle").font(.caption).foregroundStyle(.red)
                    Spacer(minLength: 0)
                    Button("Dismiss error", systemImage: "xmark") { store.dismissError() }
                        .labelStyle(.iconOnly).buttonStyle(.plain)
                }
                .accessibilityIdentifier("taskErrorMessage")
            }
            HStack(spacing: 8) {
                Image(systemName: "plus.circle").foregroundStyle(.secondary)
                TextField("Add a task…", text: $draftTitle)
                    .textFieldStyle(.plain)
                    .focused($isComposerFocused)
                    .accessibilityIdentifier("inlineAddTaskField")
                    .onSubmit(submitInlineTask)
                Button("Add", action: submitInlineTask)
                    .buttonStyle(.borderedProminent)
                    .disabled(draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("inlineAddTaskButton")
            }
            HStack(spacing: 6) {
                Picker("Add to", selection: $selectedSection) {
                    ForEach(sectionTitles, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .fixedSize()
                .accessibilityIdentifier("addTaskCategory")
                Button("New category…") { showNewCategory = true }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
                Spacer(minLength: 0)
#if os(macOS)
                Text("⌘N to add · ⌘F to find").foregroundStyle(.tertiary)
#endif
            }
            .font(.caption)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func submitInlineTask() {
        let title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        if store.addTask(title: title, inSectionTitle: selectedSection) {
            draftTitle = ""
            search = ""
            filter = .open
            collapsedSections.removeAll()
            isComposerFocused = true
        }
    }
    private func setRepeat(_ type: String) {
        if let task = repeatTask { store.addRepeatTag(task: task, repeatType: type) }
        repeatTask = nil
    }
}
