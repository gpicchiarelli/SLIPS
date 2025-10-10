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
        // Applica nodo filtro post-join se presente (equivalente a applyTests)
        if let _ = compiled.filterNode, !compiled.tests.isEmpty {
            tokens = tokens.filter { RuleEngine.applyTests(&env, tests: compiled.tests, with: $0.bindings) }
        }
        return tokens
    }
}

extension BetaEngine {
    // Aggiorna BetaMemory in modo incrementale: aggiunge token derivati dall'anchor fact
    // Ritorna i token aggiunti (nuovi) per consentire attivazioni incrementali
    public static func updateOnAssert(_ env: inout Environment, ruleName: String, compiled: CompiledRule, facts: [Environment.FactRec], anchor: Environment.FactRec) -> [BetaToken] {
        let inc = computeIncremental(&env, compiled: compiled, facts: facts, anchor: anchor)
        let mem = env.rete.beta[ruleName] ?? BetaMemory()
        var keys = mem.keyIndex.isEmpty ? Set(mem.tokens.map(keyForToken)) : mem.keyIndex
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
        let newMem = BetaMemory(); newMem.tokens = toks; newMem.keyIndex = keys
        env.rete.beta[ruleName] = newMem
        return added
    }

    public static func updateOnRetract(_ env: inout Environment, ruleName: String, factID: Int) {
        guard let mem = env.rete.beta[ruleName] else { return }
        let toks = mem.tokens.filter { !$0.usedFacts.contains(factID) }
        let newMem = BetaMemory(); newMem.tokens = toks; newMem.keyIndex = Set(toks.map(keyForToken))
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
                        // Applica filtro post-join se definito
                        if let _ = compiled.filterNode {
                            if RuleEngine.applyTests(&env, tests: compiled.tests, with: current) {
                                results.append(RuleEngine.PartialMatch(bindings: current, usedFacts: used))
                            }
                        } else {
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

    // Propagazione per livelli: ricostruisce tutte le memorie di livello per la regola, ritorna i nuovi token terminali
    @discardableResult
    public static func updateGraphOnAssert(_ env: inout Environment, ruleName: String, compiled: CompiledRule, facts: [Environment.FactRec]) -> [BetaToken] {
        // Compute all levels
        let levels = computeLevels(&env, compiled: compiled, facts: facts)
        // Previous last-level keys
        let prevLevels = env.rete.betaLevels[ruleName] ?? [:]
        // Individua l'ultimo livello precedente (può includere livello filtro)
        let prevLast = (prevLevels.keys.max().flatMap { prevLevels[$0]?.tokens }) ?? []
        var prevSet = Set(prevLast.map(keyForToken))
        // Store new levels and compute added
        var store: [Int: BetaMemory] = [:]
        for (idx, toks) in levels.enumerated() {
            let mem = BetaMemory(); mem.tokens = toks; mem.keyIndex = Set(toks.map(keyForToken))
            store[idx] = mem
        }
        env.rete.betaLevels[ruleName] = store
        // Update terminal beta snapshot as convenience
        // Snapshot terminale (post filtro se presente)
        let termMem = BetaMemory(); termMem.tokens = levels.last ?? []; termMem.keyIndex = Set((levels.last ?? []).map(keyForToken))
        env.rete.beta[ruleName] = termMem
        // Added tokens on terminal level
        var added: [BetaToken] = []
        for t in levels.last ?? [] {
            let k = keyForToken(t)
            if !prevSet.contains(k) { added.append(t) }
        }
        return added
    }

    public static func updateGraphOnRetract(_ env: inout Environment, ruleName: String, factID: Int) {
        guard let compiled = env.rete.rules[ruleName] else { return }
        // Recompute levels from facts without the retracted fact
        let facts = Array(env.facts.values)
        _ = updateGraphOnAssert(&env, ruleName: ruleName, compiled: compiled, facts: facts)
    }

    private static func computeLevels(_ env: inout Environment, compiled: CompiledRule, facts: [Environment.FactRec]) -> [[BetaToken]] {
        let patterns = compiled.patterns.map { $0.original }
        guard !patterns.isEmpty else { return [] }
        var levels: [[BetaToken]] = []
        var current: [BetaToken] = [BetaToken(bindings: [:], usedFacts: [])]
        for pidx in compiled.joinOrder {
            let pat = patterns[pidx]
            var next: [BetaToken] = []
            for tok in current {
                for f in facts where f.name == pat.name && !tok.usedFacts.contains(f.id) {
                    if var b = RuleEngine.match(env: &env, pattern: pat, fact: f, current: tok.bindings) {
                        var ok = true
                        for (k,v) in tok.bindings { if let nb = b[k], nb != v { ok = false; break } }
                        if !ok { continue }
                        for (k,v) in tok.bindings { b[k] = v }
                        var used = tok.usedFacts; used.insert(f.id)
                        next.append(BetaToken(bindings: b, usedFacts: used))
                    }
                }
            }
            // Dedup per livello
            var seen = Set<String>()
            var uniq: [BetaToken] = []
            for t in next {
                let k = keyForToken(t)
                if !seen.contains(k) { seen.insert(k); uniq.append(t) }
            }
            levels.append(uniq)
            current = uniq
            if current.isEmpty { break }
        }
        // Nodo filtro post-join: applica predicate CE (test ...)
        if let filter = compiled.filterNode, !filter.tests.isEmpty, !current.isEmpty {
            var filtered: [BetaToken] = []
            for t in current {
                if RuleEngine.applyTests(&env, tests: filter.tests, with: t.bindings) {
                    filtered.append(t)
                }
            }
            // Dedup dopo filtro (per sicurezza)
            var seen = Set<String>()
            var uniq: [BetaToken] = []
            for t in filtered {
                let k = keyForToken(t)
                if !seen.contains(k) { seen.insert(k); uniq.append(t) }
            }
            levels.append(uniq)
        }
        return levels
    }
}

// MARK: - Delta propagation (add/remove) per memorie di livello
extension BetaEngine {
    private static func terminalLevelIndex(_ compiled: CompiledRule) -> Int {
        return compiled.filterNode == nil ? (compiled.joinOrder.count - 1) : compiled.joinOrder.count
    }

    private static func ensureLevelMemories(_ env: inout Environment, ruleName: String, compiled: CompiledRule, facts: [Environment.FactRec]) {
        // Se non ci sono livelli, crea tutti i livelli corrente (senza filtro) per bootstrap.
        if env.rete.betaLevels[ruleName] == nil {
            let levels = computeLevels(&env, compiled: compiled, facts: facts)
            var store: [Int: BetaMemory] = [:]
            for (idx, toks) in levels.enumerated() {
                let mem = BetaMemory(); mem.tokens = toks; mem.keyIndex = Set(toks.map(keyForToken))
                store[idx] = mem
            }
            env.rete.betaLevels[ruleName] = store
            // Terminal snapshot
            let term = levels.last ?? []
            let termMem = BetaMemory(); termMem.tokens = term; termMem.keyIndex = Set(term.map(keyForToken))
            env.rete.beta[ruleName] = termMem
        }
    }

    private static func addIfNew(_ mem: BetaMemory, _ tok: BetaToken) -> Bool {
        let k = keyForToken(tok)
        if mem.keyIndex.contains(k) { return false }
        mem.keyIndex.insert(k)
        mem.tokens.append(tok)
        return true
    }

    // Aggiorna le memorie per livello propagando solo i delta derivati dal fatto anchor.
    // Ritorna i token aggiunti al livello terminale (post filtro se presente).
    @discardableResult
    public static func updateGraphOnAssertDelta(_ env: inout Environment, ruleName: String, compiled: CompiledRule, facts: [Environment.FactRec], anchor: Environment.FactRec) -> [BetaToken] {
        ensureLevelMemories(&env, ruleName: ruleName, compiled: compiled, facts: facts)
        guard var levels = env.rete.betaLevels[ruleName] else { return [] }
        let patterns = compiled.patterns.map { $0.original }

        var terminalAdded: [BetaToken] = []
        // Per ciascuna posizione in cui il pattern corrisponde all'anchor
        for (pos, pidx) in compiled.joinOrder.enumerated() {
            let pat = patterns[pidx]
            if pat.negated || pat.name != anchor.name { continue }

            let leftTokens: [BetaToken]
            if pos == 0 { leftTokens = [BetaToken(bindings: [:], usedFacts: [])] }
            else { leftTokens = levels[pos - 1]?.tokens ?? [] }

            if leftTokens.isEmpty { continue }

            var currentNew: [BetaToken] = []
            for lt in leftTokens {
                if var b = RuleEngine.match(env: &env, pattern: pat, fact: anchor, current: lt.bindings) {
                    // merge bindings
                    var ok = true
                    for (k,v) in lt.bindings { if let nb = b[k], nb != v { ok = false; break } }
                    if !ok { continue }
                    for (k,v) in lt.bindings { b[k] = v }
                    var used = lt.usedFacts; used.insert(anchor.id)
                    let tok = BetaToken(bindings: b, usedFacts: used)
                    let wasNew: Bool
                    if let mem = levels[pos] { wasNew = addIfNew(mem, tok) } else { let mem = BetaMemory(); wasNew = addIfNew(mem, tok); levels[pos] = mem }
                    // Se questo è già l'ultimo livello pattern ed è nuovo, conteggia come aggiunto al terminale (assenza di filtro)
                    if compiled.filterNode == nil && pos == (compiled.joinOrder.count - 1) && wasNew {
                        terminalAdded.append(tok)
                    }
                    currentNew.append(tok)
                }
            }

            // Propaga avanti sui livelli successivi
            if currentNew.isEmpty { continue }
            var nextTokens = currentNew
            var k = pos + 1
            while k < compiled.joinOrder.count && !nextTokens.isEmpty {
                let p2 = patterns[compiled.joinOrder[k]]
                var produced: [BetaToken] = []
                for t in nextTokens {
                    for f in facts where f.name == p2.name && !t.usedFacts.contains(f.id) {
                        if var b = RuleEngine.match(env: &env, pattern: p2, fact: f, current: t.bindings) {
                            var ok = true
                            for (kk,vv) in t.bindings { if let nb = b[kk], nb != vv { ok = false; break } }
                            if !ok { continue }
                            for (kk,vv) in t.bindings { b[kk] = vv }
                            var used = t.usedFacts; used.insert(f.id)
                            let nt = BetaToken(bindings: b, usedFacts: used)
                            let wasNew: Bool
                            if let mem = levels[k] { wasNew = addIfNew(mem, nt) }
                            else { let mem = BetaMemory(); wasNew = addIfNew(mem, nt); levels[k] = mem }
                            if wasNew { produced.append(nt) }
                            if compiled.filterNode == nil && k == (compiled.joinOrder.count - 1) && wasNew {
                                terminalAdded.append(nt)
                            }
                        }
                    }
                }
                nextTokens = produced
                k += 1
            }

            // Nodo filtro terminale
            let lastPatternLevel = compiled.joinOrder.count - 1
            let terminalLevel = terminalLevelIndex(compiled)
            var terminalCandidates: [BetaToken]
            if compiled.filterNode != nil {
                // Se abbiamo finito con livelli pattern e ci sono nuovi token in ultimo livello
                if pos <= lastPatternLevel {
                    // raccogli i delta arrivati fino al livello finale pattern
                    terminalCandidates = nextTokens
                } else { terminalCandidates = currentNew }
                // Applica filtro e aggiungi a livello terminale
                var mem = levels[terminalLevel]
                if mem == nil { mem = BetaMemory(); levels[terminalLevel] = mem }
                for t in terminalCandidates {
                    if RuleEngine.applyTests(&env, tests: compiled.tests, with: t.bindings) {
                        if addIfNew(mem!, t) { terminalAdded.append(t) }
                    }
                }
            } else {
                // Terminale è l'ultimo livello di pattern; 'terminalAdded' è stato popolato durante l'inserimento sui livelli
            }
        }

        // Persisti livelli aggiornati e snapshot terminale
        env.rete.betaLevels[ruleName] = levels
        let termIdx = terminalLevelIndex(compiled)
        let termTokens = levels[termIdx]?.tokens ?? (levels[compiled.joinOrder.count - 1]?.tokens ?? [])
        let termMem = BetaMemory(); termMem.tokens = termTokens; termMem.keyIndex = Set(termTokens.map(keyForToken))
        env.rete.beta[ruleName] = termMem
        return terminalAdded
    }

    // Rimozione delta: elimina dai livelli tutti i token che includono il factID.
    public static func updateGraphOnRetractDelta(_ env: inout Environment, ruleName: String, factID: Int) {
        guard var levels = env.rete.betaLevels[ruleName] else { return }
        for (idx, mem) in levels {
            let kept = mem.tokens.filter { !$0.usedFacts.contains(factID) }
            mem.tokens = kept
            mem.keyIndex = Set(kept.map(keyForToken))
            levels[idx] = mem
        }
        env.rete.betaLevels[ruleName] = levels
        // Aggiorna snapshot terminale
        if let maxIdx = levels.keys.max(), let mem = levels[maxIdx] {
            let termMem = BetaMemory(); termMem.tokens = mem.tokens; termMem.keyIndex = mem.keyIndex
            env.rete.beta[ruleName] = termMem
        } else {
            env.rete.beta[ruleName] = BetaMemory()
        }
    }
}
