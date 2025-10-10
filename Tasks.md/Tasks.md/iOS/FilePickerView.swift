// This file is iOS-only; guard it so mac builds don't compile UIKit types
#if os(iOS)
import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct MarkdownDocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        var types: [UTType] = [.plainText]
        if let md = UTType(filenameExtension: "md") { types.append(md) }
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: types)
        controller.allowsMultipleSelection = false
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        private let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            // Start accessing security-scoped resource immediately
            let didStart = url.startAccessingSecurityScopedResource()
            print("🔐 Started accessing security-scoped resource: \(didStart)")
            onPick(url)
        }
    }
}
#endif


