//
//  Tasks_mdApp.swift
//  Tasks.md
//
//  Created by Mason Earl on 10/9/25.
//

import SwiftUI

@main
struct Tasks_mdApp: App {
    @StateObject private var appModel = AppModel()
    @State private var showAbout = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appModel)
                .sheet(isPresented: $showAbout) {
                    AboutView()
                }
        }
        #if os(macOS)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About tasks.md") {
                    showAbout = true
                }
            }
            CommandGroup(after: .newItem) {
                Button("Choose tasks.md File...") {
                    NotificationCenter.default.post(name: .openFilePicker, object: nil)
                }
                .keyboardShortcut("O", modifiers: .command)
                
                Button("Add New Task") {
                    NotificationCenter.default.post(name: .addNewTask, object: nil)
                }
                .keyboardShortcut("N", modifiers: .command)
                .disabled(appModel.selectedTasksFileUrl == nil)
            }
            CommandGroup(replacing: .help) {
                Button("tasks.md Help") {
                    if let url = URL(string: "https://github.com/masonearl/tasks.md") {
                        #if os(macOS)
                        NSWorkspace.shared.open(url)
                        #endif
                    }
                }
            }
        }
        #endif
    }
}

extension Notification.Name {
    static let openFilePicker = Notification.Name("openFilePicker")
    static let addNewTask = Notification.Name("addNewTask")
}
