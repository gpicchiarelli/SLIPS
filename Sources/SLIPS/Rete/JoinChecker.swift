// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import Foundation

/// Confronta il risultato della RETE con un matcher naive (backtracking sui fatti)
/// per verificare la stabilità di una regola quando `set-join-check` è attivo.
enum JoinChecker {
    /// Ricostruisce i token naive e li confronta con quelli presenti nella beta memory RETE.
    /// Aggiorna `env.joinStableRules` in base all'esito e ritorna `true` se i risultati coincidono.
    static func recomputeStability(for rule: Rule, env: inout Environment) -> Bool {
        let canonicalName = rule.name
        let reteTokens = env.rete.beta[canonicalName]?.tokens ?? []
        let naiveTokens = naiveMatches(for: rule, env: &env)
        
        let stable = tokenMultiset(reteTokens) == tokenMultiset(naiveTokens)
        if stable {
            env.joinStableRules.insert(canonicalName)
        } else {
            env.joinStableRules.remove(canonicalName)
            logDivergence(rule: rule, reteTokens: reteTokens, naiveTokens: naiveTokens, env: &env)
        }
        return stable
    }
    
    /// Genera i token naive ripercorrendo la LHS con un semplice backtracking sui fatti disponibili.
    private static func naiveMatches(
        for rule: Rule,
        env: inout Environment
    ) -> [BetaToken] {
        var tokens: [BetaToken] = []
        let patterns = rule.patterns
        
        func dfs(
            index: Int,
            bindings: [String: Value],
            usedFacts: Set<Int>
        ) {
            if index >= patterns.count {
                guard evaluateRuleTests(rule.tests, bindings: bindings, env: &env) else { return }
                tokens.append(BetaToken(bindings: bindings, usedFacts: usedFacts))
                return
            }
            
            let pattern = patterns[index]
            
            if pattern.negated {
                if !hasMatchingFact(for: pattern, env: &env, bindings: bindings, usedFacts: usedFacts) {
                    dfs(index: index + 1, bindings: bindings, usedFacts: usedFacts)
                }
                return
            }
            
            let candidates = candidateFacts(for: pattern, env: env)
            var matchedAny = false
            
            for fact in candidates {
                if usedFacts.contains(fact.id) { continue }
                guard let nextBindings = matchFact(pattern: pattern, fact: fact, bindings: bindings, env: &env) else {
                    continue
                }
                matchedAny = true
                var newUsed = usedFacts
                newUsed.insert(fact.id)
                dfs(index: index + 1, bindings: nextBindings, usedFacts: newUsed)
            }
            
            if pattern.exists && !matchedAny {
                // EXISTS fallisce se non c'è alcun match
                return
            }
        }
        
        if patterns.isEmpty {
            if evaluateRuleTests(rule.tests, bindings: [:], env: &env) {
                tokens.append(BetaToken(bindings: [:], usedFacts: Set<Int>()))
            }
            return tokens
        }
        
        dfs(index: 0, bindings: [:], usedFacts: Set<Int>())
        return tokens
    }
    
    /// Verifica se esiste almeno un fatto compatibile con il pattern (usato per NOT).
    private static func hasMatchingFact(
        for pattern: Pattern,
        env: inout Environment,
        bindings: [String: Value],
        usedFacts: Set<Int>
    ) -> Bool {
        let candidates = candidateFacts(for: pattern, env: env)
        for fact in candidates {
            if usedFacts.contains(fact.id) { continue }
            if matchFact(pattern: pattern, fact: fact, bindings: bindings, env: &env) != nil {
                return true
            }
        }
        return false
    }
    
    /// Ritorna i fatti candidati per un pattern (usa l'indice alpha se disponibile).
    private static func candidateFacts(
        for pattern: Pattern,
        env: Environment
    ) -> [Environment.FactRec] {
        let ids = env.rete.alpha.ids(for: pattern.name)
        if !ids.isEmpty {
            return ids.compactMap { env.facts[$0] }
        }
        return env.facts.values.filter { $0.name == pattern.name }
    }
    
    /// Verifica se un fatto soddisfa il pattern con i binding correnti e ritorna i binding aggiornati.
    private static func matchFact(
        pattern: Pattern,
        fact: Environment.FactRec,
        bindings: [String: Value],
        env: inout Environment
    ) -> [String: Value]? {
        guard fact.name == pattern.name else { return nil }
        
        // Verifica costanti prima di estrarre i binding
        for (slot, test) in pattern.slots {
            if case .constant(let expected) = test.kind {
                guard let actual = fact.slots[slot], actual == expected else { return nil }
            }
        }
        
        // Estrai binding variabili usando la stessa logica della propagazione RETE
        let factBindings = Propagation.extractBindings(fact: fact, pattern: pattern)
        var merged = bindings
        for (key, value) in factBindings {
            if let existing = merged[key], existing != value {
                return nil
            }
            merged[key] = value
        }
        
        // Valuta eventuali predicate test presenti nello slot
        for (slot, test) in pattern.slots {
            guard case .predicate(let exprNode) = test.kind else { continue }
            let oldBindings = env.localBindings
            var evalBindings = merged
            if let slotValue = fact.slots[slot] {
                evalBindings[slot] = slotValue
            }
            env.localBindings = evalBindings
            let result = evaluateReteTest(&env, exprNode)
            env.localBindings = oldBindings
            
            switch result {
            case .boolean(let b) where b:
                continue
            case .int(let i) where i != 0:
                continue
            default:
                return nil
            }
        }
        
        return merged
    }
    
    /// Valuta i test terminali (CE `(test ...)`) con i binding attuali.
    private static func evaluateRuleTests(
        _ tests: [ExpressionNode],
        bindings: [String: Value],
        env: inout Environment
    ) -> Bool {
        if tests.isEmpty { return true }
        let oldBindings = env.localBindings
        env.localBindings = bindings
        defer { env.localBindings = oldBindings }
        
        for test in tests {
            let result = evaluateReteTest(&env, test)
            switch result {
            case .boolean(let b) where b:
                continue
            case .int(let i) where i != 0:
                continue
            default:
                return false
            }
        }
        return true
    }
    
    /// Costruisce un multiset di token usando l'hash deterministico.
    private static func tokenMultiset(_ tokens: [BetaToken]) -> [UInt: Int] {
        var counts: [UInt: Int] = [:]
        for token in tokens {
            let key = tokenKeyHash64(token)
            counts[key, default: 0] += 1
        }
        return counts
    }
    
    private static func logDivergence(
        rule: Rule,
        reteTokens: [BetaToken],
        naiveTokens: [BetaToken],
        env: inout Environment
    ) {
        Router.Writeln(
            &env,
            "[join-check] Divergenza per regola \(rule.displayName): rete=\(reteTokens.count) naive=\(naiveTokens.count)"
        )
    }
}
