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

extension BetaEngine {
    // Aggiorna BetaMemory in modo incrementale: aggiunge token derivati dall'anchor fact
    // Ritorna i token aggiunti (nuovi) per consentire attivazioni incrementali
    public static func updateOnAssert(_ env: inout Environment, ruleName: String, compiled: CompiledRule, facts: [Environment.FactRec], anchor: Environment.FactRec) -> [BetaToken] {
        let inc = computeIncremental(&env, compiled: compiled, facts: facts, anchor: anchor)
        let mem = env.rete.beta[ruleName] ?? BetaMemory()
        var keys = Set(mem.tokens.map(keyForToken))
        var toks = mem.tokens
        var added: [BetaToken] = []
        for m in inc {
            let k = keyForMatch(m)
            if !keys.contains(k) {
                keys.insert(k)
                let bt = BetaToken(bindings: m.bindings, usedFacts: m.usedFacts)
                toks.append(bt)
                added.append(bt)
            }
        }
        let newMem = BetaMemory(); newMem.tokens = toks
        env.rete.beta[ruleName] = newMem
        return added
    }

    public static func updateOnRetract(_ env: inout Environment, ruleName: String, factID: Int) {
        guard let mem = env.rete.beta[ruleName] else { return }
        let toks = mem.tokens.filter { !$0.usedFacts.contains(factID) }
        let newMem = BetaMemory(); newMem.tokens = toks
        env.rete.beta[ruleName] = newMem
    }

    // Calcolo incrementale: ancora su un pattern che matcha l'anchor
    private static func computeIncremental(_ env: inout Environment, compiled: CompiledRule, facts: [Environment.FactRec], anchor: Environment.FactRec) -> [RuleEngine.PartialMatch] {
        let patterns = compiled.patterns.map { $0.original }
        guard !patterns.isEmpty else { return [] }
        var results: [RuleEngine.PartialMatch] = []
        for (idx, pat) in patterns.enumerated() where !pat.negated && pat.name == anchor.name {
            if let b0 = RuleEngine.match(env: &env, pattern: pat, fact: anchor, current: [:]) {
                let used0: Set<Int> = [anchor.id]
                func backtrack(_ pidx: Int, _ current: [String: Value], _ used: Set<Int>) {
                    if pidx == patterns.count {
                        if RuleEngine.applyTests(&env, tests: compiled.tests, with: current) {
                            results.append(RuleEngine.PartialMatch(bindings: current, usedFacts: used))
                        }
                        return
                    }
                    if pidx == idx { backtrack(pidx + 1, current, used); return }
                    let p = patterns[pidx]
                    if p.negated {
                        // usa la stessa semantica del motore principale
                        var any = false
                        for f in facts where f.name == p.name {
                            if let _ = RuleEngine.match(env: &env, pattern: p, fact: f, current: current) { any = true; break }
                        }
                        if any { return } else { backtrack(pidx + 1, current, used) }
                    } else {
                        for f in facts where f.name == p.name && !used.contains(f.id) {
                            if var nb = RuleEngine.match(env: &env, pattern: p, fact: f, current: current) {
                                var ok = true
                                for (k,v) in current { if let nv = nb[k], nv != v { ok = false; break } }
                                if !ok { continue }
                                for (k,v) in current { nb[k] = v }
                                var newUsed = used; newUsed.insert(f.id)
                                backtrack(pidx + 1, nb, newUsed)
                            }
                        }
                    }
                }
                backtrack(0, b0, used0)
            }
        }
        return results
    }

    private static func keyForMatch(_ t: RuleEngine.PartialMatch) -> String {
        let b = t.bindings.sorted(by: { $0.key < $1.key }).map { "\($0.key)=\($0.value)" }.joined(separator: ",")
        let f = t.usedFacts.sorted().map { String($0) }.joined(separator: ",")
        return b + "|" + f
    }
    private static func keyForToken(_ t: BetaToken) -> String {
        let b = t.bindings.sorted(by: { $0.key < $1.key }).map { "\($0.key)=\($0.value)" }.joined(separator: ",")
        let f = t.usedFacts.sorted().map { String($0) }.joined(separator: ",")
        return b + "|" + f
    }
}
