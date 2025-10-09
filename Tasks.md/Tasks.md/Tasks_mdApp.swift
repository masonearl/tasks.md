//
//  Tasks_mdApp.swift
//  Tasks.md
//
//  Created by Mason Earl on 10/9/25.
//

import SwiftUI
import SwiftData

@main
struct Tasks_mdApp: App {
    @StateObject private var appModel = AppModel()
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appModel)
        }
        .modelContainer(sharedModelContainer)
    }
}
