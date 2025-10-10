// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

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
    public static func keyForToken(_ t: BetaToken) -> String {
        let b = t.bindings.sorted(by: { $0.key < $1.key }).map { "\($0.key)=\($0.value)" }.joined(separator: ",")
        let f = t.usedFacts.sorted().map { String($0) }.joined(separator: ",")
        return b + "|" + f
    }
    private static func hashForToken(_ t: BetaToken) -> UInt {
        return UInt(bitPattern: keyForToken(t).hashValue)
    }
    private static func describeToken(_ t: BetaToken) -> String {
        let b = t.bindings.sorted(by: { $0.key < $1.key }).map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        let f = t.usedFacts.sorted().map { String($0) }.joined(separator: ",")
        return "{" + b + " | [" + f + "]}"
    }

    // MARK: - Hash-Join helpers
    private static func boundVarNames(for compiled: CompiledRule, upTo level: Int) -> Set<String> {
        if level <= 0 { return [] }
        var names: Set<String> = []
        let patterns = compiled.patterns.map { $0.original }
        for li in 0..<level {
            let p = patterns[compiled.joinOrder[li]]
            for (_, t) in p.slots {
                if case .variable(let vname) = t.kind { names.insert(vname) }
            }
        }
        return names
    }
    private static func joinKeySlots(for pattern: Pattern, boundVarNames: Set<String>) -> [String] {
        var slots: [String] = []
        for (slot, t) in pattern.slots {
            if case .variable(let vname) = t.kind, boundVarNames.contains(vname) {
                slots.append(slot)
            }
        }
        return slots.sorted()
    }
    private static func makeKeyFromBindings(_ bindings: [String: Value], pattern: Pattern, keySlots: [String]) -> String? {
        var parts: [String] = []
        for s in keySlots {
            guard let t = pattern.slots[s] else { return nil }
            guard case .variable(let vname) = t.kind, let val = bindings[vname] else { return nil }
            parts.append("\(s)=\(val)")
        }
        return parts.joined(separator: "|")
    }
    private static func makeKeyFromFact(_ fact: Environment.FactRec, pattern: Pattern, keySlots: [String]) -> String? {
        var parts: [String] = []
        for s in keySlots {
            guard let v = fact.slots[s] else { return nil }
            parts.append("\(s)=\(v)")
        }
        return parts.joined(separator: "|")
    }
    private static func factPassesConstants(_ fact: Environment.FactRec, pattern: Pattern) -> Bool {
        for (slot, t) in pattern.slots {
            if case .constant(let c) = t.kind {
                if fact.slots[slot] != c { return false }
            }
        }
        return true
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
            var buckets: [UInt: [Int]] = [:]
            for (i, t) in toks.enumerated() { buckets[hashForToken(t), default: []].append(i) }
            mem.hashBuckets = buckets
            store[idx] = mem
        }
        env.rete.betaLevels[ruleName] = store
        // Update terminal beta snapshot as convenience
        // Snapshot terminale (post filtro se presente)
        let termMem = BetaMemory(); termMem.tokens = levels.last ?? []; termMem.keyIndex = Set((levels.last ?? []).map(keyForToken))
        var tb: [UInt: [Int]] = [:]
        for (i, t) in (levels.last ?? []).enumerated() { tb[hashForToken(t), default: []].append(i) }
        termMem.hashBuckets = tb
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
            // Hash-join preparation
            let boundNames = boundVarNames(for: compiled, upTo: levels.count)
            let keySlots = joinKeySlots(for: pat, boundVarNames: boundNames)
            if !keySlots.isEmpty {
                // Build bucket from left tokens
                var bucket: [String: [BetaToken]] = [:]
                for tok in current {
                    guard let k = makeKeyFromBindings(tok.bindings, pattern: pat, keySlots: keySlots) else { continue }
                    bucket[k, default: []].append(tok)
                }
                // Iterate facts filtered by template and constants
                for f in facts where f.name == pat.name && factPassesConstants(f, pattern: pat) {
                    guard let fk = makeKeyFromFact(f, pattern: pat, keySlots: keySlots), let lefts = bucket[fk] else { continue }
                    for tok in lefts where !tok.usedFacts.contains(f.id) {
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
            } else {
                // Fallback nested loops
                for tok in current {
                    for f in facts where f.name == pat.name && !tok.usedFacts.contains(f.id) && factPassesConstants(f, pattern: pat) {
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
                var buckets: [UInt: [Int]] = [:]
                for (i, t) in toks.enumerated() { buckets[hashForToken(t), default: []].append(i) }
                mem.hashBuckets = buckets
                store[idx] = mem
            }
            env.rete.betaLevels[ruleName] = store
            // Terminal snapshot
            let term = levels.last ?? []
            let termMem = BetaMemory(); termMem.tokens = term; termMem.keyIndex = Set(term.map(keyForToken))
            var tb: [UInt: [Int]] = [:]
            for (i, t) in term.enumerated() { tb[hashForToken(t), default: []].append(i) }
            termMem.hashBuckets = tb
            env.rete.beta[ruleName] = termMem
        }
    }

    private static func addIfNew(_ mem: BetaMemory, _ tok: BetaToken) -> Bool {
        let k = keyForToken(tok)
        if mem.keyIndex.contains(k) { return false }
        mem.keyIndex.insert(k)
        mem.tokens.append(tok)
        let idx = mem.tokens.count - 1
        mem.hashBuckets[hashForToken(tok), default: []].append(idx)
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
                    if wasNew, env.watchRete {
                        Router.Writeln(&env, "RETE + L\(pos) \(describeToken(tok))")
                    }
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
                // Hash-join with current delta tokens
                let boundNames2 = boundVarNames(for: compiled, upTo: k)
                let keySlots2 = joinKeySlots(for: p2, boundVarNames: boundNames2)
                if !keySlots2.isEmpty {
                    var bucket: [String: [BetaToken]] = [:]
                    for t in nextTokens {
                        if let kkey = makeKeyFromBindings(t.bindings, pattern: p2, keySlots: keySlots2) {
                            bucket[kkey, default: []].append(t)
                        }
                    }
                    for f in facts where f.name == p2.name && factPassesConstants(f, pattern: p2) {
                        guard let fk = makeKeyFromFact(f, pattern: p2, keySlots: keySlots2), let lefts = bucket[fk] else { continue }
                        for t in lefts where !t.usedFacts.contains(f.id) {
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
                                if wasNew, env.watchRete { Router.Writeln(&env, "RETE + L\(k) \(describeToken(nt))") }
                                if wasNew { produced.append(nt) }
                                if compiled.filterNode == nil && k == (compiled.joinOrder.count - 1) && wasNew {
                                    terminalAdded.append(nt)
                                }
                            }
                        }
                    }
                } else {
                    for t in nextTokens {
                        for f in facts where f.name == p2.name && !t.usedFacts.contains(f.id) && factPassesConstants(f, pattern: p2) {
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
                                if wasNew, env.watchRete { Router.Writeln(&env, "RETE + L\(k) \(describeToken(nt))") }
                                if wasNew { produced.append(nt) }
                                if compiled.filterNode == nil && k == (compiled.joinOrder.count - 1) && wasNew {
                                    terminalAdded.append(nt)
                                }
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
                        if addIfNew(mem!, t) {
                            terminalAdded.append(t)
                            if env.watchRete { Router.Writeln(&env, "RETE + L\(terminalLevel) \(describeToken(t))") }
                        }
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

        // Se il join-check è attivo, verifica consistenza contro ricostruzione completa
        if env.experimentalJoinCheck {
            // Per la verifica completa usa tutti i fatti correnti dell'environment
            let allFacts = Array(env.facts.values)
            let recomputed = computeLevels(&env, compiled: compiled, facts: allFacts)
            let termIdx2 = terminalLevelIndex(compiled)
            let full = (termIdx2 < recomputed.count) ? recomputed[termIdx2] : (recomputed.last ?? [])
            let curSet = Set((levels[termIdx]?.tokens ?? []).map(keyForToken))
            let fullSet = Set(full.map(keyForToken))
            if curSet != fullSet {
                // Allinea livelli e snapshot a ricostruzione completa
                if env.watchRete { Router.Writeln(&env, "RETE sync full recompute for \(ruleName)") }
                var store: [Int: BetaMemory] = [:]
                for (idx, toks) in recomputed.enumerated() {
                    let mem = BetaMemory(); mem.tokens = toks; mem.keyIndex = Set(toks.map(keyForToken))
                    var buckets: [UInt: [Int]] = [:]
                    for (i, t) in toks.enumerated() { buckets[hashForToken(t), default: []].append(i) }
                    mem.hashBuckets = buckets
                    store[idx] = mem
                }
                env.rete.betaLevels[ruleName] = store
                let termMem2 = BetaMemory(); termMem2.tokens = full; termMem2.keyIndex = Set(full.map(keyForToken))
                var tb: [UInt: [Int]] = [:]
                for (i, t) in full.enumerated() { tb[hashForToken(t), default: []].append(i) }
                termMem2.hashBuckets = tb
                env.rete.beta[ruleName] = termMem2
            }
        }
        return terminalAdded
    }

    // Rimozione delta: elimina dai livelli tutti i token che includono il factID.
    public static func updateGraphOnRetractDelta(_ env: inout Environment, ruleName: String, factID: Int) {
        guard var levels = env.rete.betaLevels[ruleName] else { return }
        for (idx, mem) in levels {
            let before = mem.tokens.count
            let kept = mem.tokens.filter { !$0.usedFacts.contains(factID) }
            mem.tokens = kept
            mem.keyIndex = Set(kept.map(keyForToken))
            // rebuild hash buckets
            var buckets: [UInt: [Int]] = [:]
            for (i, t) in kept.enumerated() { buckets[hashForToken(t), default: []].append(i) }
            mem.hashBuckets = buckets
            let removed = before - kept.count
            if removed > 0, env.watchRete { Router.Writeln(&env, "RETE - L\(idx) removed \(removed)") }
            levels[idx] = mem
        }
        env.rete.betaLevels[ruleName] = levels
        // Aggiorna snapshot terminale
        if let maxIdx = levels.keys.max(), let mem = levels[maxIdx] {
            let termMem = BetaMemory(); termMem.tokens = mem.tokens; termMem.keyIndex = mem.keyIndex; termMem.hashBuckets = mem.hashBuckets
            env.rete.beta[ruleName] = termMem
        } else {
            env.rete.beta[ruleName] = BetaMemory()
        }
    }
}
