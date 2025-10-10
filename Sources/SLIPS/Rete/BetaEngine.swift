import Foundation

// MARK: - Beta Engine (fase 1): esecuzione join step-by-step

public enum BetaEngine {
    // Per ora calcola i match da zero usando l'ordine dei pattern compilati.
    public static func computeMatches(_ env: inout Environment, compiled: CompiledRule, facts: [Environment.FactRec]) -> [RuleEngine.PartialMatch] {
        let patterns = compiled.patterns.map { $0.original }
        guard !patterns.isEmpty else { return [] }
        var tokens: [RuleEngine.PartialMatch] = [RuleEngine.PartialMatch(bindings: [:], usedFacts: [])]
        for pat in patterns {
            var next: [RuleEngine.PartialMatch] = []
            for tok in tokens {
                for f in facts where f.name == pat.name && !tok.usedFacts.contains(f.id) {
                    if var b = RuleEngine.match(env: &env, pattern: pat, fact: f, current: tok.bindings) {
                        var ok = true
                        for (k,v) in tok.bindings { if let nb = b[k], nb != v { ok = false; break } }
                        if !ok { continue }
                        for (k,v) in tok.bindings { b[k] = v }
                        var used = tok.usedFacts; used.insert(f.id)
                        next.append(RuleEngine.PartialMatch(bindings: b, usedFacts: used))
                    }
                }
            }
            tokens = next
            if tokens.isEmpty { break }
        }
        // Tests di LHS
        tokens = tokens.filter { RuleEngine.applyTests(&env, tests: compiled.tests, with: $0.bindings) }
        return tokens
    }
}

