import Foundation

final class ClosureSleeve: NSObject {
    private let closure: (Any?) -> Void
    init(_ closure: @escaping (Any?) -> Void) { self.closure = closure }
    @objc func invoke(_ sender: Any?) { closure(sender) }

    // Convenience for assigning to NSControl targets
    convenience init(action: @escaping () -> Void) {
        self.init { _ in action() }
    }
}

extension NSObjectProtocol where Self: NSControl {
    func setAction(_ sleeve: ClosureSleeve) {
        self.target = sleeve
        self.action = #selector(ClosureSleeve.invoke(_:))
        objc_setAssociatedObject(self, "closureSleeve", sleeve, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}


