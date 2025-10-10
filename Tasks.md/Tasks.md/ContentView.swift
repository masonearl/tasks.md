//
//  ContentView.swift
//  Tasks.md
//
//  Created by Mason Earl on 10/9/25.
//

import SwiftUI

#if os(iOS)
import UIKit
final class PickerDataSource: NSObject, UIPickerViewDataSource {
    let items: [String]
    init(items: [String]) { self.items = items }
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { items.count }
}
final class PickerDelegate: NSObject, UIPickerViewDelegate {
    let items: [String]
    let onSelect: (String) -> Void
    init(items: [String], onSelect: @escaping (String) -> Void) { self.items = items; self.onSelect = onSelect }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? { items[row] }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) { onSelect(items[row]) }
}
#endif

struct ContentView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSettings = false
    @State private var showNewTask = false

    var body: some View {
        NavigationSplitView {
            sidebar
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) { EmptyView() }
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
                        Button(action: { showNewTask = true }) {
                            Label("Add Task", systemImage: "plus")
                                .labelStyle(.iconOnly)
                        }
                        .help("Add Task")
                    }
                }
#if os(macOS)
                ToolbarItem {
                    if appModel.selectedTasksFileUrl != nil {
                        Button(action: { appModel.loadFromDisk() }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                                .labelStyle(.iconOnly)
                        }
                        .help("Refresh from file")
                    }
                }
#endif
                ToolbarItem {
                    Button(action: { showSettings = true }) {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
        } detail: {
            content
        }
#if os(macOS)
        .navigationTitle(appModel.selectedTasksFileUrl?.lastPathComponent ?? "tasks.md")
#endif
        .onAppear(perform: maybePromptForFile)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { appModel.loadFromDisk() }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(onChoose: { presentPicker() })
                .environmentObject(appModel)
        }
        .sheet(isPresented: $showNewTask) {
            NewTaskSheet(store: appModel.store)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFilePicker)) { _ in
            presentPicker()
        }
        .onReceive(NotificationCenter.default.publisher(for: .addNewTask)) { _ in
            if appModel.selectedTasksFileUrl != nil {
                showNewTask = true
            }
        }
#if os(iOS)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
#endif
    }

    @ViewBuilder
    private var sidebar: some View {
#if os(macOS)
        // macOS sidebar shows file info and navigation
        if let url = appModel.selectedTasksFileUrl {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current File")
                        .font(.headline)
                    Text(url.lastPathComponent)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Categories")
                        .font(.headline)
                    ForEach(appModel.store.availableSectionTitles(), id: \.self) { section in
                        Button(section) {
                            // Could add section filtering here later
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.primary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            VStack(spacing: 12) {
                Text("Select your tasks.md file to begin")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button("Choose tasks.md…") { presentPicker() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
#else
        // iOS sidebar shows tasks
        if let _ = appModel.selectedTasksFileUrl {
            TaskListView(store: appModel.store)
        } else {
            VStack(spacing: 12) {
                Text("Select your tasks.md file to begin")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button("Choose tasks.md…") { presentPicker() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
#endif
    }

    @ViewBuilder
    private var content: some View {
#if os(macOS)
        // macOS main content shows tasks
        if let _ = appModel.selectedTasksFileUrl {
            TaskListView(store: appModel.store)
        } else {
            VStack(spacing: 12) {
                Text("No file selected")
                Button(action: presentPicker) {
                    Label("Choose tasks.md…", systemImage: "folder")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
#else
        // iOS detail view shows file info
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
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
#endif
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
        TasksFilePicker.pick { url in 
            print("📁 Picker returned: \(url.path)")
            appModel.setSelectedFile(url) 
        }
#else
        // Present iOS picker via sheet
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        scene?.windows.first?.rootViewController?.present(UIHostingController(rootView: MarkdownDocumentPicker { url in
            print("📁 iOS Picker returned: \(url.path)")
            appModel.setSelectedFile(url)
            scene?.windows.first?.rootViewController?.dismiss(animated: true)
        }), animated: true)
#endif
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

struct NewTaskSheet: View {
    @ObservedObject var store: TaskStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var taskTitle = ""
    @State private var selectedSection = ""
    @FocusState private var isTitleFocused: Bool
    @State private var showNewCategorySheet = false
    
    var availableSections: [String] {
        let sections = store.availableSectionTitles()
        return sections.isEmpty ? ["Tasks"] : sections
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("Add New Task")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("Choose a category and enter your task")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                .padding(.bottom, 32)
                
                VStack(spacing: 20) {
                    // Category Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Category", systemImage: "folder")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Menu {
                            ForEach(availableSections, id: \.self) { section in
                                Button(section) {
                                    selectedSection = section
                                }
                            }
                            
                            Divider()
                            
                            Button("Create New Category...") {
                                showNewCategorySheet = true
                            }
                        } label: {
                            HStack {
                                Text(selectedSection.isEmpty ? "Select Category" : selectedSection)
                                    .foregroundStyle(selectedSection.isEmpty ? .secondary : .primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            #if os(macOS)
                            .background(Color(NSColor.controlBackgroundColor))
                            #else
                            .background(Color(UIColor.secondarySystemBackground))
                            #endif
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                    // Task Input
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Task", systemImage: "checkmark.circle")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        TextField("What needs to be done?", text: $taskTitle, axis: .vertical)
                            .focused($isTitleFocused)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            #if os(macOS)
                            .background(Color(NSColor.controlBackgroundColor))
                            #else
                            .background(Color(UIColor.secondarySystemBackground))
                            #endif
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .lineLimit(2...4)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                
                // Bottom buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    #if os(macOS)
                    .background(Color(NSColor.controlColor))
                    #else
                    .background(Color(UIColor.systemGray5))
                    #endif
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Button("Add Task") {
                        addTask()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    #if os(macOS)
                    .background(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color(NSColor.disabledControlTextColor) : Color.accentColor)
                    #else
                    .background(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color(UIColor.systemGray3) : Color.accentColor)
                    #endif
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            #if os(macOS)
            .background(Color(NSColor.windowBackgroundColor))
            #else
            .background(Color(UIColor.systemBackground))
            #endif
        }
        .onAppear {
            selectedSection = availableSections.first ?? "Tasks"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTitleFocused = true
            }
        }
        .sheet(isPresented: $showNewCategorySheet) {
            NewCategorySheet { newCategory in
                selectedSection = newCategory
            }
        }
    }
    
    private func addTask() {
        let trimmedTitle = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        store.addTask(title: trimmedTitle, inSectionTitle: selectedSection)
        dismiss()
    }
}

struct NewCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    let onCategoryCreated: (String) -> Void
    
    @State private var categoryName = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("Create New Category")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Add a new section to organize your tasks")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 12) {
                    Label("Category Name", systemImage: "folder.badge.plus")
                        .font(.headline)
                    
                    TextField("e.g., Work Tasks, Personal, etc.", text: $categoryName)
                        .focused($isFocused)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        #if os(macOS)
                        .background(Color(NSColor.controlBackgroundColor))
                        #else
                        .background(Color(UIColor.secondarySystemBackground))
                        #endif
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    #if os(macOS)
                    .background(Color(NSColor.controlColor))
                    #else
                    .background(Color(UIColor.systemGray5))
                    #endif
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Button("Create") {
                        createCategory()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    #if os(macOS)
                    .background(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color(NSColor.disabledControlTextColor) : Color.accentColor)
                    #else
                    .background(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color(UIColor.systemGray3) : Color.accentColor)
                    #endif
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(24)
            #if os(macOS)
            .background(Color(NSColor.windowBackgroundColor))
            #else
            .background(Color(UIColor.systemBackground))
            #endif
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
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
