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
    public let tests: [ExpressionNode]
}

public struct ReteNetwork {
    public var alpha: AlphaIndex = AlphaIndex()
    public var rules: [String: CompiledRule] = [:]
    public var beta: [String: BetaMemory] = [:]
    public init() {}
}

public enum ReteCompiler {
    public static func compile(_ rule: Rule) -> CompiledRule {
        let cps = rule.patterns.map { CompiledPattern(template: $0.name, original: $0) }
        return CompiledRule(name: rule.name, patterns: cps, salience: rule.salience, tests: rule.tests)
    }
}
