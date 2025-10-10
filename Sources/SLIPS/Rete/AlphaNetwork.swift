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
    public static func compile(_ rule: Rule) -> CompiledRule {
        let cps = rule.patterns.map { CompiledPattern(template: $0.name, original: $0) }
        let order = Array(0..<cps.count)
        let filter: FilterNode? = rule.tests.isEmpty ? nil : FilterNode(id: 0, tests: rule.tests)
        return CompiledRule(name: rule.name, patterns: cps, salience: rule.salience, tests: rule.tests, filterNode: filter, joinOrder: order)
    }
}
