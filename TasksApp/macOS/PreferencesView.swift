import SwiftUI
import AppKit

struct PreferencesView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        Form {
            Section("Tasks.md File") {
                HStack {
                    Text(appModel.selectedTasksFileUrl?.path ?? "No file selected")
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("Choose…") { chooseFile() }
                }
                .help("Pick your tasks.md file from iCloud Drive for syncing")
            }
        }
        .padding(20)
        .frame(width: 560)
    }

    private func chooseFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.plainText]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.title = "Select tasks.md"
        panel.message = "Pick your markdown tasks file stored in iCloud Drive."
        panel.begin { response in
            guard response == .OK, let url = panel.urls.first else { return }
            appModel.setSelectedFile(url)
        }
    }
}

#Preview {
    PreferencesView()
        .environmentObject(AppModel())
}


