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
    // Join spec precompilata per livello (in ordine di join)
    public let joinSpecs: [[JoinKeyPartC]]
    // Test distribuiti per livello (min level in cui sono valutabili)
    public let testsByLevel: [Int: [ExpressionNode]]
    public let joinOrder: [Int]
    // Exists nodes (unari) nel piano dei pattern
    public let existsNodes: [ExistsNode]
}

public struct ReteNetwork {
    public var alpha: AlphaIndex = AlphaIndex()
    public var rules: [String: CompiledRule] = [:]
    public var beta: [String: BetaMemory] = [:]
    // Memorie beta per livello di join: ruleName -> (levelIndex -> BetaMemory)
    public var betaLevels: [String: [Int: BetaMemory]] = [:]
    // Config di rete
    public struct ReteConfig { public var enableHeuristicOrder: Bool = false; public var heuristicWhitelist: Set<String> = [] }
    public var config: ReteConfig = ReteConfig()
    public init() {}
}

public struct JoinKeyPartC: Codable { public let slot: String; public let varName: String?; public let constValue: Value? }

public enum ReteCompiler {
    public static func compile(_ env: Environment, _ rule: Rule) -> CompiledRule {
        let cps = rule.patterns.map { CompiledPattern(template: $0.name, original: $0) }
        let useHeur = env.rete.config.enableHeuristicOrder || env.rete.config.heuristicWhitelist.contains(rule.name)
        let order: [Int] = useHeur ? heuristicOrder(rule.patterns) : Array(0..<cps.count)
        // Precompute bound levels for variables
        let (joinSpecs, varLevel) = precomputeJoinSpecs(rule.patterns, order: order)
        // Distribuisci tests per livello
        let (testsByLevel, terminalTests) = distributeTests(rule.tests, varLevel: varLevel, patternCount: order.count)
        let filter: FilterNode? = terminalTests.isEmpty ? nil : FilterNode(id: 0, tests: terminalTests)
        // Exists nodes scaffold (solo unari, mappati su posizioni nell'ordine di join)
        var existsNodes: [ExistsNode] = []
        for (idx, pidx) in order.enumerated() {
            if rule.patterns[pidx].exists {
                existsNodes.append(ExistsNode(id: idx, patternIndex: pidx))
            }
        }
        return CompiledRule(name: rule.name, patterns: cps, salience: rule.salience, tests: rule.tests, filterNode: filter, joinSpecs: joinSpecs, testsByLevel: testsByLevel, joinOrder: order, existsNodes: existsNodes)
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

    private static func precomputeJoinSpecs(_ pats: [Pattern], order: [Int]) -> ([[JoinKeyPartC]], [String: Int]) {
        var joinSpecs: [[JoinKeyPartC]] = []
        var bound: Set<String> = []
        var varLevel: [String: Int] = [:]
        for (lvl, pidx) in order.enumerated() {
            let p = pats[pidx]
            var parts: [JoinKeyPartC] = []
            for (slot, t) in p.slots {
                switch t.kind {
                case .variable(let v):
                    if bound.contains(v) {
                        parts.append(JoinKeyPartC(slot: slot, varName: v, constValue: nil))
                    } else {
                        if !p.exists { varLevel[v] = varLevel[v] ?? lvl }
                    }
                case .constant(let v):
                    parts.append(JoinKeyPartC(slot: slot, varName: nil, constValue: v))
                case .predicate:
                    break
                }
            }
            // Aggiorna bound con variabili introdotte in questo livello (solo CE positivi non-exists)
            if !p.negated && !p.exists {
                for (_, t) in p.slots { if case .variable(let v) = t.kind { bound.insert(v) } }
            }
            joinSpecs.append(parts.sorted(by: { $0.slot < $1.slot }))
        }
        return (joinSpecs, varLevel)
    }

    private static func distributeTests(_ tests: [ExpressionNode], varLevel: [String:Int], patternCount: Int) -> ([Int: [ExpressionNode]], [ExpressionNode]) {
        var map: [Int: [ExpressionNode]] = [:]
        var terminal: [ExpressionNode] = []
        for t in tests {
            let vars = freeVars(t)
            let minLvl = vars.map { varLevel[$0] ?? (patternCount) }.max() ?? 0
            if minLvl >= patternCount { terminal.append(t) }
            else { map[minLvl, default: []].append(t) }
        }
        return (map, terminal)
    }

    private static func freeVars(_ node: ExpressionNode?) -> Set<String> {
        var res: Set<String> = []
        func walk(_ n: ExpressionNode?) {
            guard let n = n else { return }
            switch n.type {
            case .variable, .mfVariable:
                if let s = n.value?.value as? String { res.insert(s) }
            default: break
            }
            walk(n.argList); walk(n.nextArg)
        }
        walk(node)
        return res
    }
}
