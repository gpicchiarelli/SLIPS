// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import Foundation

// MARK: - Rete: Alpha Index e strutture compilate (fase 1)

public struct AlphaIndex {
    public var byTemplate: [String: Set<Int>] = [:]
    public init() {}
    public mutating func add(_ fact: Environment.FactRec) {
        var set = byTemplate[fact.name] ?? Set<Int>()
        set.insert(fact.id)
        byTemplate[fact.name] = set
    }
    public mutating func remove(_ fact: Environment.FactRec) {
        guard var set = byTemplate[fact.name] else { return }
        set.remove(fact.id)
        if set.isEmpty { byTemplate.removeValue(forKey: fact.name) } else { byTemplate[fact.name] = set }
    }
    public func ids(for template: String) -> [Int] { Array(byTemplate[template] ?? []) }
}

public struct CompiledPattern {
    public let template: String
    // Conserviamo la rappresentazione logica originale; il matcher del RuleEngine verrà usato.
    public let original: Pattern
}

public struct CompiledRule {
    public let name: String
    public let patterns: [CompiledPattern]
    public let salience: Int
    // LHS predicate CE (es. (test ...)) estratti come nodi filtro post-join
    public let tests: [ExpressionNode]
    public let filterNode: FilterNode?
    public let joinOrder: [Int]
}

public struct ReteNetwork {
    public var alpha: AlphaIndex = AlphaIndex()
    public var rules: [String: CompiledRule] = [:]
    public var beta: [String: BetaMemory] = [:]
    // Memorie beta per livello di join: ruleName -> (levelIndex -> BetaMemory)
    public var betaLevels: [String: [Int: BetaMemory]] = [:]
    public init() {}
}

public enum ReteCompiler {
    // Flag opzionale: riordina i pattern per aumentare la selettività (euristica)
    nonisolated(unsafe) public static var enableHeuristicOrder: Bool = false
    public static func compile(_ rule: Rule) -> CompiledRule {
        let cps = rule.patterns.map { CompiledPattern(template: $0.name, original: $0) }
        let order: [Int]
        if enableHeuristicOrder {
            order = heuristicOrder(rule.patterns)
        } else {
            order = Array(0..<cps.count)
        }
        let filter: FilterNode? = rule.tests.isEmpty ? nil : FilterNode(id: 0, tests: rule.tests)
        return CompiledRule(name: rule.name, patterns: cps, salience: rule.salience, tests: rule.tests, filterNode: filter, joinOrder: order)
    }
    // Euristica: prima pattern più selettivi (più costanti), poi greedy massimizzando variabili condivise con già scelti
    private static func heuristicOrder(_ pats: [Pattern]) -> [Int] {
        let n = pats.count
        guard n > 1 else { return Array(0..<n) }
        // Conteggio occorrenze variabili sull'intera LHS
        var varFreq: [String: Int] = [:]
        for p in pats { for (_, t) in p.slots { if case .variable(let v) = t.kind { varFreq[v, default: 0] += 1 } } }
        func constCount(_ p: Pattern) -> Int {
            var c = 0
            for (_, t) in p.slots { if case .constant = t.kind { c += 1 } }
            return c
        }
        // Seed: pattern con più costanti, tie-break con somma frequenze var del pattern
        func varScore(_ p: Pattern) -> Int {
            var s = 0
            for (_, t) in p.slots { if case .variable(let v) = t.kind { s += (varFreq[v] ?? 0) } }
            return s
        }
        var remaining = Set(0..<n)
        let seed = remaining.max { (i, j) in
            let ci = constCount(pats[i]); let cj = constCount(pats[j])
            if ci != cj { return ci < cj }
            return varScore(pats[i]) < varScore(pats[j])
        }!
        var order: [Int] = [seed]
        remaining.remove(seed)
        var bound: Set<String> = []
        for (_, t) in pats[seed].slots { if case .variable(let v) = t.kind { bound.insert(v) } }
        while !remaining.isEmpty {
            let next = remaining.max { (i, j) in
                func shared(_ idx: Int) -> Int {
                    var c = 0
                    for (_, t) in pats[idx].slots { if case .variable(let v) = t.kind, bound.contains(v) { c += 1 } }
                    return c
                }
                let si = shared(i), sj = shared(j)
                if si != sj { return si < sj }
                let ci = constCount(pats[i]), cj = constCount(pats[j])
                if ci != cj { return ci < cj }
                return varScore(pats[i]) < varScore(pats[j])
            }!
            order.append(next)
            remaining.remove(next)
            for (_, t) in pats[next].slots { if case .variable(let v) = t.kind { bound.insert(v) } }
        }
        return order
    }
}
