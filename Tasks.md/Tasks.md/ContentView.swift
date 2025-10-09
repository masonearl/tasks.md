//
//  ContentView.swift
//  Tasks.md
//
//  Created by Mason Earl on 10/9/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var items: [Item]
    @State private var showSettings = false

    var body: some View {
        NavigationSplitView {
            sidebar
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EmptyView()
                }
#endif
                ToolbarItem {
                    Button(action: presentPicker) {
                        Label("Choose tasks.md…", systemImage: "folder")
                            .labelStyle(.iconOnly)
                    }
                    .help("Choose tasks.md…")
                }
                ToolbarItem {
                    if appModel.selectedTasksFileUrl != nil {
                        Button(action: { addNewTaskPrompt() }) {
                            Label("Add Task", systemImage: "plus")
                                .labelStyle(.iconOnly)
                        }
                        .help("Add Task")
                    }
                }
                ToolbarItem {
                    Button(action: { showSettings = true }) {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
        } detail: {
            content
        }
        .onAppear(perform: maybePromptForFile)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { appModel.loadFromDisk() }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(onChoose: { presentPicker() })
                .environmentObject(appModel)
        }
    }

    @ViewBuilder
    private var sidebar: some View {
        if appModel.selectedTasksFileUrl == nil {
            VStack(spacing: 12) {
                Text("Select your tasks.md file to begin")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button("Choose tasks.md…") { presentPicker() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            TaskListView(store: appModel.store)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let url = appModel.selectedTasksFileUrl {
            VStack(spacing: 8) {
                Text("File: \(url.lastPathComponent)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
        } else {
            VStack(spacing: 12) {
                Text("No file selected")
                Button(action: presentPicker) {
                    Label("Choose tasks.md…", systemImage: "folder")
                        .labelStyle(.iconOnly)
                }
                Button(action: presentPicker) {
                    Label("Choose tasks.md…", systemImage: "folder")
                        .labelStyle(.iconOnly)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func maybePromptForFile() {
        guard appModel.selectedTasksFileUrl == nil else { return }
#if os(macOS)
        // Only auto-prompt if we have never stored a bookmark path
        if UserDefaults.standard.string(forKey: "tasksFilePath") == nil && appModel.selectedTasksFileUrl == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                presentPicker()
            }
        }
#endif
    }

    private func presentPicker() {
#if os(macOS)
        TasksFilePicker.pick { url in appModel.setSelectedFile(url) }
#else
        // Present iOS picker via sheet
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        scene?.windows.first?.rootViewController?.present(UIHostingController(rootView: MarkdownDocumentPicker { url in
            appModel.setSelectedFile(url)
            scene?.windows.first?.rootViewController?.dismiss(animated: true)
        }), animated: true)
#endif
    }

    private func addNewTaskPrompt() {
#if os(iOS)
        let sections = appModel.store.availableSectionTitles()
        let alert = UIAlertController(title: "New Task", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Task title" }
        if !sections.isEmpty {
            alert.addTextField { field in
                field.placeholder = "Section"
                field.text = sections.first
            }
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { _ in
            let title = alert.textFields?.first?.text ?? ""
            if sections.isEmpty {
                appModel.store.addTask(title: title)
            } else {
                let section = alert.textFields?.count ?? 0 > 1 ? (alert.textFields?[1].text ?? sections.first!) : sections.first!
                appModel.store.addTask(title: title, inSectionTitle: section)
            }
        }))
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.keyWindow?.rootViewController?.present(alert, animated: true)
#else
        let sections = appModel.store.availableSectionTitles()
        let panel = NSPanel(contentRect: .init(x: 0, y: 0, width: 420, height: 160), styleMask: [.titled], backing: .buffered, defer: false)
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 8
        let titleField = NSTextField(string: "")
        titleField.placeholderString = "Task title"
        stack.addArrangedSubview(titleField)
        var popup: NSPopUpButton?
        if !sections.isEmpty {
            let p = NSPopUpButton(frame: .zero, pullsDown: false)
            p.addItems(withTitles: sections)
            stack.addArrangedSubview(p)
            popup = p
        }
        let buttons = NSStackView()
        buttons.orientation = .horizontal
        buttons.spacing = 8
        let addBtn = NSButton(title: "Add", target: nil, action: nil)
        let cancelBtn = NSButton(title: "Cancel", target: nil, action: nil)
        buttons.addArrangedSubview(addBtn)
        buttons.addArrangedSubview(cancelBtn)
        stack.addArrangedSubview(buttons)
        panel.contentView = stack
        let app = NSApplication.shared
        app.mainWindow?.beginSheet(panel) { _ in }
        addBtn.action = #selector(NSApplication.orderFrontStandardAboutPanel(_:))
        addBtn.target = ClosureSleeve { [weak appModel] in
            guard let appModel else { return }
            let title = titleField.stringValue
            if let popup = popup { appModel.store.addTask(title: title, inSectionTitle: popup.titleOfSelectedItem ?? sections.first ?? "Tasks") }
            else { appModel.store.addTask(title: title) }
            app?.mainWindow?.endSheet(panel)
        }
        cancelBtn.action = #selector(NSApplication.orderFrontStandardAboutPanel(_:))
        cancelBtn.target = ClosureSleeve { _ in app?.mainWindow?.endSheet(panel) }
#endif
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }

    private func clearAll() {
        withAnimation {
            for item in items { modelContext.delete(item) }
        }
    }
}

private struct SettingsSheet: View {
    @EnvironmentObject private var appModel: AppModel
    let onChoose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.title2)
            HStack {
                Text("Selected file:")
                Text(appModel.selectedTasksFileUrl?.path ?? "None")
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            HStack {
                Button(action: onChoose) {
                    Label("Choose tasks.md…", systemImage: "folder")
                        .labelStyle(.iconOnly)
                }
                Spacer()
            }
            Spacer()
        }
        .padding()
        .frame(minWidth: 420, minHeight: 220)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
