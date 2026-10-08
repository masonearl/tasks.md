#if os(macOS)
import Foundation
import AppKit
import UniformTypeIdentifiers

enum TasksFilePicker {
    private static var markdownTypes: [UTType] {
        var types: [UTType] = [.plainText]
        if let md = UTType(filenameExtension: "md") { types.append(md) }
        return types
    }

    static func pick(completion: @escaping (URL) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.allowedContentTypes = markdownTypes
        panel.title = "Select tasks.md"
        panel.message = "Choose a markdown file to use as your task list. You can also create a new file."
        panel.prompt = "Open"
        panel.begin { response in
            guard response == .OK, let url = panel.urls.first else { return }
            completion(url)
        }
    }

    static func createNew(completion: @escaping (Result<URL, Error>) -> Void) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.allowedContentTypes = markdownTypes
        panel.nameFieldStringValue = "tasks.md"
        panel.title = "Create tasks.md"
        panel.message = "Choose where to save a new markdown task list."
        panel.prompt = "Create"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                if !FileManager.default.fileExists(atPath: url.path) {
                    try DefaultTasksFile.starterMarkdown.write(to: url, atomically: true, encoding: .utf8)
                }
                completion(.success(url))
            } catch { completion(.failure(error)) }
        }
    }
}

#else
import Foundation
enum TasksFilePicker {
    static func pick(completion: @escaping (URL) -> Void) {
        // No-op on non-macOS builds
    }

    static func createNew(completion: @escaping (Result<URL, Error>) -> Void) {
        // No-op on non-macOS builds
    }
}
#endif
