// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import Foundation

// MARK: - Rete: Alpha Index e strutture compilate (fase 1)

public struct AlphaIndex {
    public var byTemplate: [String: Set<Int>] = [:]
    // Indici per (template -> slot -> value -> {factIDs})
    public struct ValueKey: Hashable, Codable {
        public let v: Value
        public init(_ v: Value) { self.v = v }
        public static func == (lhs: ValueKey, rhs: ValueKey) -> Bool { lhs.v == rhs.v }
        public func hash(into hasher: inout Hasher) {
            switch v {
            case .int(let i): hasher.combine(1); hasher.combine(i)
            case .float(let d): hasher.combine(2); hasher.combine(d.bitPattern)
            case .string(let s): hasher.combine(3); hasher.combine(s)
            case .symbol(let s): hasher.combine(4); hasher.combine(s)
            case .boolean(let b): hasher.combine(5); hasher.combine(b)
            case .multifield(let arr):
                hasher.combine(6); hasher.combine(arr.count)
                for e in arr { ValueKey(e).hash(into: &hasher) }
            case .none: hasher.combine(0)
            }
        }
    }
    public var bySlotConst: [String: [String: [ValueKey: Set<Int>]]] = [:]
    public init() {}
    public mutating func add(_ fact: Environment.FactRec) {
        var set = byTemplate[fact.name] ?? Set<Int>()
        set.insert(fact.id)
        byTemplate[fact.name] = set
        var slotMap = bySlotConst[fact.name] ?? [:]
        for (slot, val) in fact.slots {
            var valMap = slotMap[slot] ?? [:]
            var ids = valMap[ValueKey(val)] ?? Set<Int>()
            ids.insert(fact.id)
            valMap[ValueKey(val)] = ids
            slotMap[slot] = valMap
        }
        bySlotConst[fact.name] = slotMap
    }
    public mutating func remove(_ fact: Environment.FactRec) {
        guard var set = byTemplate[fact.name] else { return }
        set.remove(fact.id)
        if set.isEmpty { byTemplate.removeValue(forKey: fact.name) } else { byTemplate[fact.name] = set }
        if var slotMap = bySlotConst[fact.name] {
            for (slot, val) in fact.slots {
                if var valMap = slotMap[slot] {
                    if var ids = valMap[ValueKey(val)] {
                        ids.remove(fact.id)
                        if ids.isEmpty { valMap.removeValue(forKey: ValueKey(val)) } else { valMap[ValueKey(val)] = ids }
                        slotMap[slot] = valMap
                    }
                }
            }
            bySlotConst[fact.name] = slotMap
        }
    }
    public func ids(for template: String) -> [Int] { Array(byTemplate[template] ?? []) }
    public func ids(for template: String, constants: [(String, Value)]) -> [Int] {
        guard !constants.isEmpty else { return ids(for: template) }
        guard let slotMap = bySlotConst[template] else { return [] }
        var acc: Set<Int>? = nil
        for (slot, val) in constants {
            guard let vmap = slotMap[slot], let ids = vmap[ValueKey(val)] else { return [] }
            if let cur = acc { acc = cur.intersection(ids) } else { acc = ids }
            if acc?.isEmpty ?? true { return [] }
        }
        return Array(acc ?? [])
    }
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
    // Sistema RETE esplicito (unico percorso, come in CLIPS C)
    // Ref: pattern.h (alpha nodes), network.h (join nodes, beta memory)
    
    /// Alpha nodes: pattern matching su singoli template
    /// Ref: struct patternNodeHeader in pattern.h
    public var alphaNodes: [String: AlphaNodeClass] = [:]
    
    /// Production nodes: regole compilate
    /// Ref: struct defrule *ruleToActivate in network.h joinNode
    public var productionNodes: [String: ProductionNode] = [:]
    
    /// Alpha index (per ricerca rapida fatti per template)
    /// Ref: factmngr.c - hash table per template lookups
    public var alpha: AlphaIndex = AlphaIndex()
    
    public init() {}
    
    // WRAPPER TEMPORANEO: per compatibilità con test che usano env.rete.beta
    // Nel sistema esplicito, le beta memories sono nei JoinNode, non centralizzate
    // Questo wrapper legge dalle memorie dei join nodes
    public var beta: [String: BetaMemory] {
        get {
            var result: [String: BetaMemory] = [:]
            for (ruleName, productionNode) in productionNodes {
                // Trova l'ultimo join/beta memory prima del production node
                // Per ora, crea una beta memory vuota come placeholder
                result[ruleName] = BetaMemory()
            }
            return result
        }
    }
}

public struct JoinKeyPartC: Codable { public let slot: String; public let varName: String?; public let constValue: Value? }

public enum ReteCompiler {
    public static func compile(_ env: Environment, _ rule: Rule) -> CompiledRule {
        let cps = rule.patterns.map { CompiledPattern(template: $0.name, original: $0) }
        // Usa ordine naturale dei pattern (come in CLIPS C di default)
        let order: [Int] = Array(0..<cps.count)
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
                case .mfVariable(let v):
                    if bound.contains(v) {
                        parts.append(JoinKeyPartC(slot: slot, varName: v, constValue: nil))
                    } else {
                        if !p.exists { varLevel[v] = varLevel[v] ?? lvl }
                    }
                case .sequence(let arr):
                    var allConst = true
                    for it in arr {
                        switch it.kind {
                        case .constant: break
                        default: allConst = false
                        }
                    }
                    if allConst {
                        let consts = arr.compactMap { it -> Value? in if case .constant(let v) = it.kind { return v } else { return nil } }
                        parts.append(JoinKeyPartC(slot: slot, varName: nil, constValue: .multifield(consts)))
                    } else {
                        for it in arr {
                            switch it.kind {
                            case .variable(let v), .mfVariable(let v):
                                if bound.contains(v) { parts.append(JoinKeyPartC(slot: slot, varName: v, constValue: nil)) }
                            default: break
                            }
                        }
                    }
                case .constant(let v):
                    parts.append(JoinKeyPartC(slot: slot, varName: nil, constValue: v))
                case .predicate:
                    break
                }
            }
            // Aggiorna bound con variabili introdotte in questo livello (solo CE positivi non-exists)
            if !p.negated && !p.exists {
                for (_, t) in p.slots {
                    switch t.kind {
                    case .variable(let v): bound.insert(v)
                    case .mfVariable(let v): bound.insert(v)
                    default: break
                    }
                }
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
