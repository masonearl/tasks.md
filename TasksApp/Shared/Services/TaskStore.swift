import Foundation

@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var sections: [TaskSection] = []

    func load(from text: String) {
        let parsed = MarkdownParser.parse(text)
        self.sections = parsed.sections
    }
}


