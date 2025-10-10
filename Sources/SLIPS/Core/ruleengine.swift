// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import Foundation

// MARK: - Semplified Rule Engine (RETE skeleton)

public struct PatternTest: Codable {
    public enum Kind: Codable { case constant(Value), variable(String), predicate(ExpressionNode) }
    public let kind: Kind
}

public struct Pattern: Codable {
    public let name: String
    public let slots: [String: PatternTest]
    public let negated: Bool
}

public struct Rule: Codable {
    public let name: String
    public let patterns: [Pattern]
    public let rhs: [ExpressionNode]
    public let salience: Int
    public let tests: [ExpressionNode]
}

public enum RuleEngine {
    public static func addRule(_ env: inout Environment, _ rule: Rule) {
        env.rules.append(rule)
        let cr = ReteCompiler.compile(rule)
        env.rete.rules[rule.name] = cr
    }

    public static func onAssert(_ env: inout Environment, _ fact: Environment.FactRec) {
        // Revaluta regole contro i fatti ancorando sul fatto nuovo
        env.rete.alpha.add(fact)
        let facts = Array(env.facts.values)
        for rule in env.rules {
            let hasNeg = rule.patterns.contains { $0.negated }
            // Usa indice alpha per limitare i candidati ai soli template della regola
            let usedTemplates = Set(rule.patterns.map { $0.name })
            var candidateFacts: [Environment.FactRec] = []
            for t in usedTemplates {
                for id in env.rete.alpha.ids(for: t) {
                    if let f = env.facts[id] { candidateFacts.append(f) }
                }
            }
            let pool = candidateFacts.isEmpty ? facts : candidateFacts
            // Calcolo naive solo se necessario (negati o join-check), altrimenti delega all'infrastruttura RETE
            var matches: [PartialMatch] = []
            let supportRete = !hasNeg && (env.rete.rules[rule.name] != nil)
            let needNaive = hasNeg || env.experimentalJoinCheck || !supportRete
            if needNaive {
                if hasNeg || env.experimentalJoinCheck {
                    // Per il confronto di stabilità calcola i match completi
                    matches = generateMatches(env: &env, patterns: rule.patterns, tests: rule.tests, facts: pool)
                } else {
                    // Altrimenti usa la versione ancorata per performance
                    matches = generateMatchesAnchored(env: &env, patterns: rule.patterns, tests: rule.tests, facts: pool, anchor: fact)
                }
            }

            // Confronto + aggiornamento BetaMemory in modalità sperimentale
            if let cr = env.rete.rules[rule.name], supportRete && (env.experimentalJoinCheck || env.experimentalJoinActivate || env.joinActivateWhitelist.contains(rule.name)) {
                // Aggiorna per delta e raccogli token terminali aggiunti
                let added = BetaEngine.updateGraphOnAssertDelta(&env, ruleName: rule.name, compiled: cr, facts: pool, anchor: fact)
                if let mem = env.rete.beta[rule.name] {
                    let jList = mem.tokens.map { PartialMatch(bindings: $0.bindings, usedFacts: $0.usedFacts) }
                    if env.experimentalJoinCheck {
                        let eq = equivalentMatchesStatic(matches, jList)
                        if !eq {
                            if env.watchRules {
                                Router.WriteString(&env, Router.STDERR, "[JOIN-CHECK] Divergenza regola \(rule.name)\n")
                                logMatchDiff(&env, lhs: matches, rhs: jList)
                            }
                            env.joinStableRules.remove(rule.name)
                        } else {
                            env.joinStableRules.insert(rule.name)
                        }
                    }
                }
                let useReteActivation = env.experimentalJoinActivate || (env.joinActivateWhitelist.contains(rule.name) && env.joinStableRules.contains(rule.name))
                if useReteActivation {
                    for t in added {
                        var act = Activation(priority: rule.salience, ruleName: rule.name, bindings: t.bindings)
                        act.factIDs = t.usedFacts
                        if !env.agendaQueue.contains(act) {
                            env.agendaQueue.add(act)
                            if env.watchRules { Router.Writeln(&env, "==> Activation \(rule.name)") }
                        }
                    }
                } else if needNaive {
                    // Usa matcher naive per attivazioni
                    for m in matches {
                        var act = Activation(priority: rule.salience, ruleName: rule.name, bindings: m.bindings)
                        act.factIDs = m.usedFacts
                        if !env.agendaQueue.contains(act) {
                            env.agendaQueue.add(act)
                            if env.watchRules {
                                Router.Writeln(&env, "==> Activation \(rule.name)")
                                Router.WriteString(&env, "t", "ACT \(rule.name)\n")
                            }
                        }
                    }
                }
                // Per coerenza con join-check, riallinea la memoria terminale con una ricostruzione completa
                if env.experimentalJoinCheck {
                    let allFacts = Array(env.facts.values)
                    _ = BetaEngine.updateGraphOnAssert(&env, ruleName: rule.name, compiled: cr, facts: allFacts)
                }
            } else {
                // Percorso standard: solo naive
                if matches.isEmpty {
                    matches = hasNeg
                        ? generateMatches(env: &env, patterns: rule.patterns, tests: rule.tests, facts: pool)
                        : generateMatchesAnchored(env: &env, patterns: rule.patterns, tests: rule.tests, facts: pool, anchor: fact)
                }
                for m in matches {
                    var act = Activation(priority: rule.salience, ruleName: rule.name, bindings: m.bindings)
                    act.factIDs = m.usedFacts
                    if !env.agendaQueue.contains(act) {
                        env.agendaQueue.add(act)
                        if env.watchRules {
                            Router.Writeln(&env, "==> Activation \(rule.name)")
                            Router.WriteString(&env, "t", "ACT \(rule.name)\n")
                        }
                    }
                }
            }
        }
    }

    // Esecuzione join semplice (fase 1): solo pattern positivi, stesso comportamento del backtracking
    private static func computeMatchesJoin(env: inout Environment, compiled: CompiledRule, facts: [Environment.FactRec]) -> [PartialMatch] {
        let patterns = compiled.patterns.map { $0.original }
        guard !patterns.isEmpty else { return [] }
        var tokens: [PartialMatch] = [PartialMatch(bindings: [:], usedFacts: [])]
        for pat in patterns {
            var next: [PartialMatch] = []
            for tok in tokens {
                for f in facts where f.name == pat.name && !tok.usedFacts.contains(f.id) {
                    if var b = match(env: &env, pattern: pat, fact: f, current: tok.bindings) {
                        var ok = true
                        for (k,v) in tok.bindings { if let nb = b[k], nb != v { ok = false; break } }
                        if !ok { continue }
                        for (k,v) in tok.bindings { b[k] = v }
                        var used = tok.usedFacts; used.insert(f.id)
                        next.append(PartialMatch(bindings: b, usedFacts: used))
                    }
                }
            }
            tokens = next
            if tokens.isEmpty { break }
        }
        // Applica tests LHS (inclusi predicati propagati)
        tokens = tokens.filter { applyTests(&env, tests: compiled.tests, with: $0.bindings) }
        return tokens
    }

    public static func run(_ env: inout Environment, limit: Int?) -> Int {
        var fired = 0
        let max = limit ?? Int.max
        while fired < max, let act = env.agendaQueue.next() {
            // find rule
            guard let rule = env.rules.first(where: { $0.name == act.ruleName }) else { continue }
            let oldBindings = env.localBindings
            if let b = act.bindings { for (k,v) in b { env.localBindings[k] = v } }
            if env.watchRules {
                Router.Writeln(&env, "FIRE \(rule.name)")
                Router.WriteString(&env, "t", "FIRE \(rule.name)\n")
            }
            for exp in rule.rhs { _ = Evaluator.EvaluateExpression(&env, exp) }
            env.localBindings = oldBindings
            fired += 1
        }
        return fired
    }

    public static func rebuildAgenda(_ env: inout Environment) {
        env.agendaQueue.clear()
        let facts = Array(env.facts.values)
        for rule in env.rules {
            let matches = generateMatches(env: &env, patterns: rule.patterns, tests: rule.tests, facts: facts)
            for m in matches {
                var act = Activation(priority: rule.salience, ruleName: rule.name, bindings: m.bindings)
                act.factIDs = m.usedFacts
                if !env.agendaQueue.contains(act) { env.agendaQueue.add(act) }
            }
        }
    }

    static func match(env: inout Environment, pattern: Pattern, fact: Environment.FactRec, current: [String: Value]) -> [String: Value]? {
        guard pattern.name == fact.name else { return nil }
        var bindings: [String: Value] = [:]
        // Per stabilità: prima variabili, poi costanti, infine predicate
        let entries = pattern.slots.map { ($0.key, $0.value) }
        let varEntries = entries.filter { if case .variable = $0.1.kind { return true } else { return false } }
        let constEntries = entries.filter { if case .constant = $0.1.kind { return true } else { return false } }
        let predEntries = entries.filter { if case .predicate = $0.1.kind { return true } else { return false } }
        // variabili
        for (slot, test) in varEntries {
            guard let fval = fact.slots[slot] else { return nil }
            if case .variable(let name) = test.kind {
                if let existing = bindings[name] ?? current[name], existing != fval { return nil }
                bindings[name] = fval
            }
        }
        // costanti
        for (slot, test) in constEntries {
            guard let fval = fact.slots[slot] else { return nil }
            if case .constant(let v) = test.kind { if v != fval { return nil } }
        }
        // predicati
        for (_, test) in predEntries {
            if case .predicate(let exprNode) = test.kind {
                let old = env.localBindings
                for (k,v) in current { env.localBindings[k] = v }
                for (k,v) in bindings { env.localBindings[k] = v }
                let exprToEval: ExpressionNode
                if exprNode.type == .fcall, (exprNode.value?.value as? String) == "test", let a = exprNode.argList {
                    exprToEval = a
                } else {
                    exprToEval = exprNode
                }
                let res = Evaluator.EvaluateExpression(&env, exprToEval)
                env.localBindings = old
                switch res {
                case .boolean(let b): if !b { return nil }
                case .int(let i): if i == 0 { return nil }
                default: return nil
                }
            }
        }
        return bindings
    }

    // Matching per CE negato: ignora variabili non ancora bound
    private static func matchesNegative(env: inout Environment, pattern: Pattern, fact: Environment.FactRec, current: [String: Value]) -> Bool {
        guard pattern.name == fact.name else { return false }
        for (slot, test) in pattern.slots {
            guard let fval = fact.slots[slot] else { return false }
            switch test.kind {
            case .constant(let v):
                if v != fval { return false }
            case .variable(let name):
                if let existing = current[name] { if existing != fval { return false } }
                // se non bound: wildcard, nessun vincolo
            case .predicate(let exprNode):
                let old = env.localBindings
                for (k,v) in current { env.localBindings[k] = v }
                let exprToEval: ExpressionNode
                if exprNode.type == .fcall, (exprNode.value?.value as? String) == "test", let a = exprNode.argList {
                    exprToEval = a
                } else {
                    exprToEval = exprNode
                }
                let res = Evaluator.EvaluateExpression(&env, exprToEval)
                env.localBindings = old
                switch res {
                case .boolean(let b): if !b { return false }
                case .int(let i): if i == 0 { return false }
                default: return false
                }
            }
        }
        return true
    }

    public struct PartialMatch { let bindings: [String: Value]; let usedFacts: Set<Int> }

    private static func generateMatches(env: inout Environment, patterns: [Pattern], tests: [ExpressionNode], facts: [Environment.FactRec]) -> [PartialMatch] {
        guard !patterns.isEmpty else { return [] }
        var results: [PartialMatch] = []
        func backtrack(_ idx: Int, _ current: [String: Value], _ used: Set<Int>) {
            if idx == patterns.count {
                // Apply tests
                if applyTests(&env, tests: tests, with: current) {
                    results.append(PartialMatch(bindings: current, usedFacts: used))
                }
                return
            }
            let pat = patterns[idx]
            if pat.negated {
                // Fail if any fact matches with current binding (ignore new variables)
                var any = false
                for f in facts where f.name == pat.name {
                    if matchesNegative(env: &env, pattern: pat, fact: f, current: current) { any = true; break }
                }
                if any { return } else { backtrack(idx + 1, current, used) }
            } else {
                for f in facts where f.name == pat.name && !used.contains(f.id) {
                    if var b = match(env: &env, pattern: pat, fact: f, current: current) {
                        // verifica consistenza
                        var ok = true
                        for (k,v) in current { if let nb = b[k], nb != v { ok = false; break } }
                        if !ok { continue }
                        for (k,v) in current { b[k] = v }
                        var newUsed = used; newUsed.insert(f.id)
                        backtrack(idx + 1, b, newUsed)
                    }
                }
            }
        }
        backtrack(0, [:], Set<Int>())
        return results
    }

    private static func generateMatchesAnchored(env: inout Environment, patterns: [Pattern], tests: [ExpressionNode], facts: [Environment.FactRec], anchor: Environment.FactRec) -> [PartialMatch] {
        guard !patterns.isEmpty else { return [] }
        var results: [PartialMatch] = []
        for (idx, pat) in patterns.enumerated() where !pat.negated && pat.name == anchor.name {
            if let b = match(env: &env, pattern: pat, fact: anchor, current: [:]) {
                let used: Set<Int> = [anchor.id]
                func backtrack(_ pidx: Int, _ current: [String: Value], _ used: Set<Int>) {
                    if pidx == patterns.count {
                        if applyTests(&env, tests: tests, with: current) {
                            results.append(PartialMatch(bindings: current, usedFacts: used))
                        }
                        return
                    }
                    if pidx == idx { backtrack(pidx + 1, current, used); return }
                    let p = patterns[pidx]
                    if p.negated {
                        var any = false
                        for f in facts where f.name == p.name {
                            if matchesNegative(env: &env, pattern: p, fact: f, current: current) { any = true; break }
                        }
                        if any { return } else { backtrack(pidx + 1, current, used) }
                    } else {
                        for f in facts where f.name == p.name && !used.contains(f.id) {
                            if var nb = match(env: &env, pattern: p, fact: f, current: current) {
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
                backtrack(0, b, used)
            }
        }
        return results
    }

    static func applyTests(_ env: inout Environment, tests: [ExpressionNode], with binding: [String: Value]) -> Bool {
        let old = env.localBindings
        for (k,v) in binding { env.localBindings[k] = v }
        var okAll = true
        for tnode in tests {
            if tnode.type == .fcall, (tnode.value?.value as? String) == "test" {
                if let arg = tnode.argList, case .boolean(let b) = (try? Evaluator.eval(&env, arg)) { if !b { okAll = false; break } }
                else if let arg = tnode.argList, case .int(let i) = (try? Evaluator.eval(&env, arg)) { if i == 0 { okAll = false; break } }
                else { okAll = false; break }
            } else {
                if case .boolean(let b) = (try? Evaluator.eval(&env, tnode)) { if !b { okAll = false; break } }
                else if case .int(let i) = (try? Evaluator.eval(&env, tnode)) { if i == 0 { okAll = false; break } }
                else { okAll = false; break }
            }
        }
        env.localBindings = old
        return okAll
    }

    // Helper: confronto insiemi di match (bindings + usedFacts)
    private static func equivalentMatchesStatic(_ lhs: [PartialMatch], _ rhs: [PartialMatch]) -> Bool {
        func key(_ m: PartialMatch) -> String {
            let b = m.bindings.sorted(by: { $0.key < $1.key }).map { "\($0.key)=\($0.value)" }.joined(separator: ",")
            let f = m.usedFacts.sorted().map { String($0) }.joined(separator: ",")
            return b + "|" + f
        }
        let ls = Set(lhs.map(key))
        let rs = Set(rhs.map(key))
        return ls == rs
    }

    private static func logMatchDiff(_ env: inout Environment, lhs: [PartialMatch], rhs: [PartialMatch]) {
        func key(_ m: PartialMatch) -> String {
            let b = m.bindings.sorted(by: { $0.key < $1.key }).map { "\($0.key)=\($0.value)" }.joined(separator: ",")
            let f = m.usedFacts.sorted().map { String($0) }.joined(separator: ",")
            return b + "|" + f
        }
        func describe(_ m: PartialMatch) -> String {
            let b = m.bindings.sorted(by: { $0.key < $1.key }).map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            let f = m.usedFacts.sorted().map { String($0) }.joined(separator: ",")
            return "{bindings: [" + b + "], facts: [" + f + "]}"
        }
        let lset = Dictionary(uniqueKeysWithValues: lhs.map { (key($0), $0) })
        let rset = Dictionary(uniqueKeysWithValues: rhs.map { (key($0), $0) })
        var onlyL: [PartialMatch] = []
        var onlyR: [PartialMatch] = []
        for (k,v) in lset { if rset[k] == nil { onlyL.append(v) } }
        for (k,v) in rset { if lset[k] == nil { onlyR.append(v) } }
        let maxPrint = 10
        if !onlyL.isEmpty {
            Router.WriteString(&env, Router.STDERR, "  LHS-only (\(onlyL.count)):\n")
            for i in 0..<min(maxPrint, onlyL.count) {
                Router.WriteString(&env, Router.STDERR, "    ")
                Router.WriteString(&env, Router.STDERR, describe(onlyL[i]))
                Router.WriteString(&env, Router.STDERR, "\n")
            }
        }
        if !onlyR.isEmpty {
            Router.WriteString(&env, Router.STDERR, "  JOIN-only (\(onlyR.count)):\n")
            for i in 0..<min(maxPrint, onlyR.count) {
                Router.WriteString(&env, Router.STDERR, "    ")
                Router.WriteString(&env, Router.STDERR, describe(onlyR[i]))
                Router.WriteString(&env, Router.STDERR, "\n")
            }
        }
    }
}
