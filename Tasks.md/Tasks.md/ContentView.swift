//
//  ContentView.swift
//  Tasks.md
//
//  Created by Mason Earl on 10/9/25.
//

import SwiftUI
#if os(iOS)
import UniformTypeIdentifiers
#endif

struct ContentView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSettings = false
#if os(iOS)
    @State private var showFileImporter = false
#endif

    var body: some View {
        NavigationStack {
            Group {
                if appModel.selectedTasksFileUrl != nil {
                    TaskListView(store: appModel.store)
                        .id(appModel.selectedTasksFileUrl)
                } else {
                    ContentUnavailableView {
                        Label("No tasks file", systemImage: "doc.text")
                    } description: {
                        Text("Choose a markdown file or create a new one.")
                    } actions: {
                        Button("Choose tasks.md…") { presentPicker() }
                        Button("Create New File…") { presentCreateFile() }
                    }
                }
            }
            .navigationTitle(appModel.selectedTasksFileUrl?.deletingPathExtension().lastPathComponent ?? "tasks.md")
#if os(macOS)
            .navigationSubtitle(appModel.selectedTasksFileUrl?.deletingLastPathComponent().lastPathComponent ?? "")
#endif
            .toolbar {
                ToolbarItem {
                    Button("Choose tasks.md…", systemImage: "folder", action: presentPicker)
                        .help("Choose tasks.md…")
                }
                ToolbarItem {
                    Button("Add Task", systemImage: "plus", action: presentAddTask)
                        .help("Add Task")
                        .accessibilityIdentifier("addTaskToolbarButton")
                }
                ToolbarItem {
                    Button("Reload file", systemImage: "arrow.clockwise") { appModel.loadFromDisk() }
                        .help("Reload from disk")
                }
                ToolbarItem {
                    Button("Settings", systemImage: "gearshape") { showSettings = true }
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if let error = appModel.fileErrorMessage {
                HStack(alignment: .top, spacing: 8) {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.callout).foregroundStyle(.red)
                    Spacer(minLength: 0)
                    Button("Retry") { appModel.retryFile() }
                    Button("Choose…", action: presentPicker)
                }
                .padding(12)
                .background(.bar)
            }
        }
        .onAppear(perform: maybePromptForFile)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { appModel.reloadOnForeground() }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(
                onChoose: presentPicker,
                onCreate: presentCreateFile
            )
            .environmentObject(appModel)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFilePicker)) { _ in
            presentPicker()
        }
#if os(iOS)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: Self.markdownTypes,
            allowsMultipleSelection: false
        ) { result in
            if case .failure(let error) = result {
                appModel.fileErrorMessage = error.localizedDescription
            }
            if case .success(let urls) = result, let url = urls.first {
                let accessed = url.startAccessingSecurityScopedResource()
                appModel.setSelectedFile(url)
                if accessed {
                    url.stopAccessingSecurityScopedResource()
                }
            }
        }
#endif
    }

#if os(iOS)
    private static var markdownTypes: [UTType] {
        var types: [UTType] = [.plainText]
        if let markdown = UTType(filenameExtension: "md") {
            types.append(markdown)
        }
        return types
    }
#endif

    private func maybePromptForFile() {
        if appModel.selectedTasksFileUrl == nil && appModel.fileErrorMessage == nil {
            appModel.ensureDefaultFile()
        }
    }

    private func presentAddTask() {
        if appModel.selectedTasksFileUrl == nil {
            appModel.ensureDefaultFile()
        }
        NotificationCenter.default.post(name: .focusAddComposer, object: nil)
    }

    private func presentPicker() {
#if os(macOS)
        TasksFilePicker.pick { url in
            appModel.setSelectedFile(url)
        }
#else
        showFileImporter = true
#endif
    }

    private func presentCreateFile() {
#if os(macOS)
        TasksFilePicker.createNew { result in
            switch result {
            case .success(let url): appModel.setSelectedFile(url)
            case .failure(let error): appModel.fileErrorMessage = error.localizedDescription
            }
        }
#else
        let name = NewTasksFileName.make()
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(name)
        do {
            try DefaultTasksFile.starterMarkdown.write(to: url, atomically: true, encoding: .utf8)
            appModel.setSelectedFile(url)
        } catch {
            appModel.fileErrorMessage = error.localizedDescription
        }
#endif
    }
}

private struct SettingsSheet: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    let onChoose: () -> Void
    let onCreate: () -> Void

    var body: some View {
#if os(macOS)
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 4) {
                Text("Tasks file")
                    .font(.headline)
                Text(appModel.selectedTasksFileUrl?.path ?? "None")
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
            }

            HStack {
                Button("Choose…") { dismiss(); onChoose() }
                Button("Create New…") { dismiss(); onCreate() }
                Spacer()
            }

            Text("Checking a box writes back to this markdown file. You can also edit it in any text editor.")
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(minWidth: 420, minHeight: 220)
#else
        NavigationStack {
            Form {
                Section("Tasks file") {
                    Text(appModel.selectedTasksFileUrl?.lastPathComponent ?? "None")
                        .foregroundStyle(.secondary)
                    Button("Choose…") { dismiss(); onChoose() }
                    Button("Create New…") { dismiss(); onCreate() }
                }
                Section {
                    Text("Checking a box writes back to this markdown file. You can also edit it in any text editor.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
#endif
    }
}

struct NewTaskSheet: View {
    @ObservedObject var store: TaskStore
    @Environment(\.dismiss) private var dismiss

    @State private var taskTitle = ""
    @State private var selectedSection = ""
    @FocusState private var isTitleFocused: Bool
    @State private var showNewCategorySheet = false
    @State private var errorMessage: String?

    private var canSubmit: Bool {
        !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var availableSections: [String] {
        var sections = store.availableSectionTitles()
        if sections.isEmpty { sections = ["Tasks"] }
        if !selectedSection.isEmpty && !sections.contains(selectedSection) {
            sections.append(selectedSection)
        }
        return sections
    }

    var body: some View {
#if os(macOS)
        macBody
#else
        iosBody
#endif
    }

#if os(macOS)
    private var macBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Task")
                .font(.title2)
                .fontWeight(.semibold)

            TextField("What needs to be done?", text: $taskTitle)
                .textFieldStyle(.roundedBorder)
                .focused($isTitleFocused)
                .accessibilityIdentifier("newTaskTitleField")
                .onSubmit { addTask() }

            Picker("Category", selection: $selectedSection) {
                ForEach(availableSections, id: \.self) { section in
                    Text(section).tag(section)
                }
            }

            Button("Create New Category…") {
                showNewCategorySheet = true
            }
            .buttonStyle(.borderless)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.callout)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Add Task") { addTask() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canSubmit)
                    .accessibilityIdentifier("addTaskSubmitButton")
            }
        }
        .padding(20)
        .onAppear(perform: prepare)
        .sheet(isPresented: $showNewCategorySheet) {
            NewCategorySheet { newCategory in
                selectedSection = newCategory
            }
            .frame(width: 360, height: 180)
        }
    }
#endif

#if !os(macOS)
    private var iosBody: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("What needs to be done?", text: $taskTitle, axis: .vertical)
                        .focused($isTitleFocused)
                        .lineLimit(2...4)
                        .accessibilityIdentifier("newTaskTitleField")
                }
                Section("Category") {
                    Picker("Category", selection: $selectedSection) {
                        ForEach(availableSections, id: \.self) { section in
                            Text(section).tag(section)
                        }
                    }
                    Button("Create New Category…") {
                        showNewCategorySheet = true
                    }
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Task") { addTask() }
                        .disabled(!canSubmit)
                        .accessibilityIdentifier("addTaskSubmitButton")
                }
            }
        }
        .onAppear(perform: prepare)
        .sheet(isPresented: $showNewCategorySheet) {
            NewCategorySheet { newCategory in
                selectedSection = newCategory
            }
        }
    }
#endif

    private func prepare() {
        if selectedSection.isEmpty {
            selectedSection = availableSections.first ?? "Tasks"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isTitleFocused = true
        }
    }

    private func addTask() {
        let trimmedTitle = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        let section = selectedSection.isEmpty ? "Tasks" : selectedSection
        if store.addTask(title: trimmedTitle, inSectionTitle: section) {
            dismiss()
        } else {
            errorMessage = store.lastErrorMessage ?? "Couldn't add the task. Try choosing your tasks.md file again."
        }
    }
}

struct NewCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    let onCategoryCreated: (String) -> Void

    @State private var categoryName = ""
    @FocusState private var isFocused: Bool

    private var canCreate: Bool {
        !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
#if os(macOS)
        VStack(alignment: .leading, spacing: 16) {
            Text("Create New Category")
                .font(.title2)
                .fontWeight(.semibold)
            TextField("e.g. Work, Personal", text: $categoryName)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onSubmit { createCategory() }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Create") { createCategory() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canCreate)
            }
        }
        .padding(20)
        .onAppear { isFocused = true }
#else
        NavigationStack {
            Form {
                TextField("e.g. Work, Personal", text: $categoryName)
                    .focused($isFocused)
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createCategory() }
                        .disabled(!canCreate)
                }
            }
        }
        .onAppear { isFocused = true }
#endif
    }

    private func createCategory() {
        let trimmed = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onCategoryCreated(trimmed)
        dismiss()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppModel())
}
