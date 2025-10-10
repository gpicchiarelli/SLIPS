import Foundation

public struct Activation: Codable, Equatable {
    public var priority: Int
    public var ruleName: String
}

public struct Agenda: Codable, Equatable {
    public private(set) var queue: [Activation] = []

    public init() {}

    public mutating func add(_ a: Activation) {
        queue.append(a)
        // TODO: ordinamento per salience come in CLIPS
    }

    public mutating func next() -> Activation? {
        // TODO: considerare strategia di conflitto di CLIPS
        return queue.isEmpty ? nil : queue.removeFirst()
    }

    public var isEmpty: Bool { queue.isEmpty }
}

