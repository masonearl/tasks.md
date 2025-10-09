import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appModel: AppModel
    @StateObject private var store = TaskStore()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tasks.md App")
                .font(.title)

            if let url = appModel.selectedTasksFileUrl {
                Text("File: \(url.lastPathComponent)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Divider()
                TaskListView(store: appModel.store)
            } else {
                VStack(spacing: 12) {
                    Text("Select your tasks.md file to begin")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Button("Choose tasks.md…") {
                        TasksFilePicker.pick { url in
                            appModel.setSelectedFile(url)
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(minWidth: 720, minHeight: 480)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppModel())
}


