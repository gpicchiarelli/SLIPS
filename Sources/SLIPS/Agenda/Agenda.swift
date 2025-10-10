import Foundation

public struct Activation: Codable, Equatable {
    public var priority: Int
    public var ruleName: String
    public var bindings: [String: Value]?
}

public struct Agenda: Codable, Equatable {
    public private(set) var queue: [Activation] = []

    public init() {}

    public mutating func add(_ a: Activation) {
        queue.append(a)
        queue.sort { lhs, rhs in
            if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
            return lhs.ruleName < rhs.ruleName
        }
    }

    public mutating func next() -> Activation? {
        // TODO: considerare strategia di conflitto di CLIPS
        return queue.isEmpty ? nil : queue.removeFirst()
    }

    public var isEmpty: Bool { queue.isEmpty }

    public func contains(_ a: Activation) -> Bool { queue.contains(a) }
}
