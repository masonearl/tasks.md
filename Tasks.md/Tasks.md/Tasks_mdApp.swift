//
//  Tasks_mdApp.swift
//  Tasks.md
//
//  Created by Mason Earl on 10/9/25.
//

import SwiftUI

#if os(macOS)
import AppKit

final class TasksAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async {
            Self.ensureVisibleWindow()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            Self.ensureVisibleWindow()
        }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    static func ensureVisibleWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.canBecomeMain && !$0.isSheet }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
#endif

@main
struct Tasks_mdApp: App {
#if os(macOS)
    @NSApplicationDelegateAdaptor(TasksAppDelegate.self) private var appDelegate
#endif
    @StateObject private var appModel = AppModel()
    @State private var showAbout = false
    @State private var showNewTask = false

    init() {
        UserDefaults.standard.set(true, forKey: "ApplePersistenceIgnoreState")
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appModel)
#if os(macOS)
                .frame(minWidth: 520, minHeight: 400)
#endif
                .sheet(isPresented: $showAbout) {
                    AboutView()
                }
                .sheet(isPresented: $showNewTask) {
                    NewTaskSheet(store: appModel.store)
#if os(macOS)
                        .frame(minWidth: 440, idealWidth: 460, minHeight: 260)
#endif
                }
                .onReceive(NotificationCenter.default.publisher(for: .addNewTask)) { _ in
                    presentAddTask()
                }
        }
#if os(macOS)
        .defaultSize(width: 720, height: 600)
        .commands { macCommands }
#endif
    }

    private func presentAddTask() {
        if appModel.selectedTasksFileUrl == nil {
            appModel.ensureDefaultFile()
        }
#if os(macOS)
        TasksAppDelegate.ensureVisibleWindow()
#endif
        NotificationCenter.default.post(name: .focusAddComposer, object: nil)
    }

#if os(macOS)
    @CommandsBuilder
    private var macCommands: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About tasks.md") {
                showAbout = true
            }
        }
        CommandGroup(replacing: .newItem) {
            Button("Add New Task") {
                presentAddTask()
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("Add Task in Category…") {
                if appModel.selectedTasksFileUrl == nil {
                    appModel.ensureDefaultFile()
                }
                TasksAppDelegate.ensureVisibleWindow()
                showNewTask = true
            }

            Button("Choose tasks.md File...") {
                NotificationCenter.default.post(name: .openFilePicker, object: nil)
            }
            .keyboardShortcut("o", modifiers: .command)
        }
        CommandGroup(after: .textEditing) {
            Button("Find Tasks") {
                NotificationCenter.default.post(name: .focusTaskSearch, object: nil)
            }
            .keyboardShortcut("f", modifiers: .command)
        }
        CommandGroup(replacing: .help) {
            Button("tasks.md Help") {
                if let url = URL(string: "https://github.com/masonearl/tasks.md") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
#endif
}

extension Notification.Name {
    static let openFilePicker = Notification.Name("openFilePicker")
    static let addNewTask = Notification.Name("addNewTask")
    static let focusTaskSearch = Notification.Name("focusTaskSearch")
    static let focusAddComposer = Notification.Name("focusAddComposer")
}
