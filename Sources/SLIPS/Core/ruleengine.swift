import Foundation

// MARK: - Semplified Rule Engine (RETE skeleton)

public struct PatternTest: Codable, Equatable {
    public enum Kind: Codable, Equatable { case constant(Value), variable(String) }
    public let kind: Kind
}

public struct Pattern: Codable, Equatable {
    public let name: String
    public let slots: [String: PatternTest]
}

public struct Rule: Codable {
    public let name: String
    public let patterns: [Pattern]
    public let rhs: [ExpressionNode]
    public let salience: Int
}

public enum RuleEngine {
    public static func addRule(_ env: inout Environment, _ rule: Rule) {
        env.rules.append(rule)
    }

    public static func onAssert(_ env: inout Environment, _ fact: Environment.FactRec) {
        // Revaluta regole contro tutti i fatti per gestire join multi-pattern (naive)
        let facts = Array(env.facts.values)
        for rule in env.rules {
            let matches = generateMatchesAnchored(patterns: rule.patterns, facts: facts, anchor: fact)
            for b in matches {
                let act = Activation(priority: rule.salience, ruleName: rule.name, bindings: b)
                if !env.agendaQueue.contains(act) {
                    env.agendaQueue.add(act)
                    if env.watchRules { Router.Writeln(&env, "==> Activation \(rule.name)") }
                }
            }
        }
    }

    public static func run(_ env: inout Environment, limit: Int?) -> Int {
        var fired = 0
        let max = limit ?? Int.max
        while fired < max, let act = env.agendaQueue.next() {
            // find rule
            guard let rule = env.rules.first(where: { $0.name == act.ruleName }) else { continue }
            let oldBindings = env.localBindings
            if let b = act.bindings { for (k,v) in b { env.localBindings[k] = v } }
            if env.watchRules { Router.Writeln(&env, "FIRE \(rule.name)") }
            for exp in rule.rhs { _ = Evaluator.EvaluateExpression(&env, exp) }
            env.localBindings = oldBindings
            fired += 1
        }
        return fired
    }

    private static func match(pattern: Pattern, fact: Environment.FactRec) -> [String: Value]? {
        guard pattern.name == fact.name else { return nil }
        var bindings: [String: Value] = [:]
        for (slot, test) in pattern.slots {
            guard let fval = fact.slots[slot] else { return nil }
            switch test.kind {
            case .constant(let v):
                if v != fval { return nil }
            case .variable(let name):
                if let existing = bindings[name], existing != fval { return nil }
                bindings[name] = fval
            }
        }
        return bindings
    }

    private static func generateMatches(patterns: [Pattern], facts: [Environment.FactRec]) -> [[String: Value]] {
        guard !patterns.isEmpty else { return [] }
        var results: [[String: Value]] = []
        func backtrack(_ idx: Int, _ current: [String: Value], _ used: Set<Int>) {
            if idx == patterns.count { results.append(current); return }
            let pat = patterns[idx]
            for f in facts where f.name == pat.name && !used.contains(f.id) {
                if var b = match(pattern: pat, fact: f) {
                    var ok = true
                    for (k,v) in current { if let nb = b[k], nb != v { ok = false; break } }
                    if !ok { continue }
                    for (k,v) in current { b[k] = v }
                    var newUsed = used; newUsed.insert(f.id)
                    backtrack(idx + 1, b, newUsed)
                }
            }
        }
        backtrack(0, [:], Set<Int>())
        return results
    }

    private static func generateMatchesAnchored(patterns: [Pattern], facts: [Environment.FactRec], anchor: Environment.FactRec) -> [[String: Value]] {
        guard !patterns.isEmpty else { return [] }
        var results: [[String: Value]] = []
        for (idx, pat) in patterns.enumerated() where pat.name == anchor.name {
            if let b = match(pattern: pat, fact: anchor) {
                var used: Set<Int> = [anchor.id]
                func backtrack(_ pidx: Int, _ current: [String: Value], _ used: Set<Int>) {
                    if pidx == patterns.count { results.append(current); return }
                    if pidx == idx { backtrack(pidx + 1, current, used); return }
                    let p = patterns[pidx]
                    for f in facts where f.name == p.name && !used.contains(f.id) {
                        if var nb = match(pattern: p, fact: f) {
                            var ok = true
                            for (k,v) in current { if let nv = nb[k], nv != v { ok = false; break } }
                            if !ok { continue }
                            for (k,v) in current { nb[k] = v }
                            var newUsed = used; newUsed.insert(f.id)
                            backtrack(pidx + 1, nb, newUsed)
                        }
                    }
                }
                backtrack(0, b, used)
            }
        }
        return results
    }
}
