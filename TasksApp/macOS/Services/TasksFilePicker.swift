import Foundation
import AppKit
import UniformTypeIdentifiers

enum TasksFilePicker {
    static func pick(completion: @escaping (URL) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        var types: [UTType] = [.plainText]
        if let md = UTType(filenameExtension: "md") { types.append(md) }
        panel.allowedContentTypes = types
        panel.title = "Select tasks.md"
        panel.message = "Pick your markdown tasks file stored in iCloud Drive."
        panel.begin { response in
            guard response == .OK, let url = panel.urls.first else { return }
            completion(url)
        }
    }
}


