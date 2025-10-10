import Foundation

public enum AgendaStrategy: String, Codable {
    case depth
    case breadth
    case lex
}

public struct Activation: Codable, Equatable {
    public var priority: Int
    public var ruleName: String
    public var bindings: [String: Value]?
    public var factIDs: Set<Int> = []
    public var seq: Int = 0
}

public struct Agenda: Codable, Equatable {
    public private(set) var queue: [Activation] = []
    public var strategy: AgendaStrategy = .depth
    private var nextSeq: Int = 1

    public init() {}

    public mutating func add(_ a: Activation) {
        var aVar = a
        aVar.seq = nextSeq
        nextSeq &+= 1
        queue.append(aVar)
        resort()
    }

    public mutating func next() -> Activation? {
        return queue.isEmpty ? nil : queue.removeFirst()
    }

    public var isEmpty: Bool { queue.isEmpty }

    public func contains(_ a: Activation) -> Bool { queue.contains(a) }

    public mutating func clear() { queue.removeAll(keepingCapacity: false) }

    public mutating func setStrategy(_ s: AgendaStrategy) {
        strategy = s
        resort()
    }

    public mutating func removeByFactID(_ id: Int) {
        queue.removeAll { $0.factIDs.contains(id) }
    }

    private mutating func resort() {
        switch strategy {
        case .depth:
            queue.sort { lhs, rhs in
                if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
                // LIFO per pari priorità
                if lhs.seq != rhs.seq { return lhs.seq > rhs.seq }
                return lhs.ruleName < rhs.ruleName
            }
        case .breadth:
            queue.sort { lhs, rhs in
                if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
                // FIFO per pari priorità
                if lhs.seq != rhs.seq { return lhs.seq < rhs.seq }
                return lhs.ruleName < rhs.ruleName
            }
        case .lex:
            queue.sort { lhs, rhs in
                if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
                if lhs.ruleName != rhs.ruleName { return lhs.ruleName < rhs.ruleName }
                // fallback a FIFO
                if lhs.seq != rhs.seq { return lhs.seq < rhs.seq }
                return false
            }
        }
    }
}
