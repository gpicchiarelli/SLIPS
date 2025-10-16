// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

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
    /// Modulo a cui appartiene la regola (FASE 3 - Module-aware agenda)
    /// Ref: agenda.c in CLIPS con focus stack
    public var moduleName: String? = nil
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

    public func contains(_ a: Activation) -> Bool {
        return queue.contains { existing in
            existing.priority == a.priority &&
            existing.ruleName == a.ruleName &&
            existing.bindings == a.bindings &&
            existing.factIDs == a.factIDs &&
            existing.moduleName == a.moduleName
        }
    }

    public mutating func clear() { queue.removeAll(keepingCapacity: false) }

    public mutating func setStrategy(_ s: AgendaStrategy) {
        strategy = s
        resort()
    }

    public mutating func removeByFactID(_ id: Int) {
        queue.removeAll { $0.factIDs.contains(id) }
    }

    public mutating func removeByRuleName(_ name: String) {
        queue.removeAll { $0.ruleName == name }
    }
    
    /// Filtra attivazioni per modulo (FASE 3 - Module-aware agenda)
    /// Ref: agenda.c - GetFocus/GetAgendaChanged
    public func filterByModule(_ moduleName: String) -> [Activation] {
        return queue.filter { $0.moduleName == moduleName }
    }
    
    /// Ritorna attivazioni ordinate per focus stack
    /// Il modulo in cima al focus stack ha priorità assoluta
    /// Ref: agenda.c - focus stack management
    public func sortedByFocusStack(_ focusStack: [String]) -> [Activation] {
        guard !focusStack.isEmpty else { return queue }
        
        var sorted = queue
        sorted.sort { lhs, rhs in
            // Prima priorità: modulo nel focus stack
            let lhsFocusIndex = focusStack.firstIndex(where: { $0 == lhs.moduleName })
            let rhsFocusIndex = focusStack.firstIndex(where: { $0 == rhs.moduleName })
            
            switch (lhsFocusIndex, rhsFocusIndex) {
            case (.some(let li), .some(let ri)):
                // Entrambi in focus: priorità a quello più in alto nello stack (indice minore)
                if li != ri { return li < ri }
                // Stesso livello focus: applica strategia normale
                fallthrough
            case (.some, .none):
                // Solo lhs in focus: ha priorità
                return true
            case (.none, .some):
                // Solo rhs in focus: ha priorità
                return false
            case (.none, .none):
                // Nessuno in focus: strategia normale
                break
            }
            
            // Strategia normale
            if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
            if lhs.seq != rhs.seq {
                return strategy == .depth ? lhs.seq > rhs.seq : lhs.seq < rhs.seq
            }
            return lhs.ruleName < rhs.ruleName
        }
        
        return sorted
    }
    
    /// Applica ordinamento per focus stack (modifica la queue interna)
    /// Ref: agenda.c - focus stack sorting in RunCommand
    public mutating func applyFocusStackSorting(_ focusStack: [String]) {
        guard !focusStack.isEmpty else { return }
        queue = sortedByFocusStack(focusStack)
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
