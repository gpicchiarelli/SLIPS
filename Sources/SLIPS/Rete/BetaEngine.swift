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
    // Verifica match per CE negato: controlla solo vincoli su variabili già bound e costanti; non introduce binding.
    private static func matchesNegativeLite(_ env: inout Environment, pattern: Pattern, fact: Environment.FactRec, current: [String: Value]) -> Bool {
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
    // Aggiorna BetaMemory in modo incrementale: aggiunge token derivati dall'anchor fact
    // Ritorna i token aggiunti (nuovi) per consentire attivazioni incrementali
    public static func updateOnAssert(_ env: inout Environment, ruleName: String, compiled: CompiledRule, facts: [Environment.FactRec], anchor: Environment.FactRec) -> [BetaToken] {
        let inc = computeIncremental(&env, compiled: compiled, facts: facts, anchor: anchor)
        let mem = env.rete.beta[ruleName] ?? BetaMemory()
        var keys: Set<UInt64> = mem.keyIndex.isEmpty ? Set(mem.tokens.map(tokenKeyHash64)) : mem.keyIndex
        var toks = mem.tokens
        var added: [BetaToken] = []
        for m in inc {
            let bt = BetaToken(bindings: m.bindings, usedFacts: m.usedFacts)
            let kh = tokenKeyHash64(bt)
            if !keys.contains(kh) {
                keys.insert(kh)
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
        let newMem = BetaMemory(); newMem.tokens = toks; newMem.keyIndex = Set(toks.map(tokenKeyHash64))
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
    // Hash stabile 64-bit per BetaToken (bindings+facts) per dedup
    public static func tokenKeyHash64(_ t: BetaToken) -> UInt64 {
        var h = fnv64Init()
        for (k, v) in t.bindings.sorted(by: { $0.key < $1.key }) {
            let ks = hashString(k); var x = ks; for _ in 0..<8 { fnv64Combine(&h, UInt8(truncatingIfNeeded: x)); x >>= 8 }
            let hv = hashValue(v); var y = hv; for _ in 0..<8 { fnv64Combine(&h, UInt8(truncatingIfNeeded: y)); y >>= 8 }
        }
        for fid in t.usedFacts.sorted() {
            var z: UInt64 = UInt64(fid)
            for _ in 0..<8 { fnv64Combine(&h, UInt8(truncatingIfNeeded: z)); z >>= 8 }
        }
        return h
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
    private struct JoinKeyPart { let slot: String; let varName: String?; let constValue: Value? }
    private static func buildJoinKeySpec(for pattern: Pattern, boundVarNames: Set<String>) -> [JoinKeyPart] {
        var parts: [JoinKeyPart] = []
        for (slot, t) in pattern.slots {
            switch t.kind {
            case .variable(let vname):
                if boundVarNames.contains(vname) { parts.append(JoinKeyPart(slot: slot, varName: vname, constValue: nil)) }
            case .constant(let v):
                parts.append(JoinKeyPart(slot: slot, varName: nil, constValue: v))
            case .predicate:
                break
            }
        }
        return parts.sorted(by: { $0.slot < $1.slot })
    }
    private static func makeKeyFromBindings(_ bindings: [String: Value], spec: [JoinKeyPart]) -> String? {
        var parts: [String] = []
        for p in spec {
            if let vn = p.varName {
                guard let val = bindings[vn] else { return nil }
                parts.append("\(p.slot)=\(val)")
            } else if let cv = p.constValue {
                parts.append("\(p.slot)=\(cv)")
            }
        }
        return parts.joined(separator: "|")
    }
    private static func makeKeyFromFact(_ fact: Environment.FactRec, spec: [JoinKeyPart]) -> String? {
        var parts: [String] = []
        for p in spec {
            if p.varName != nil {
                guard let v = fact.slots[p.slot] else { return nil }
                parts.append("\(p.slot)=\(v)")
            } else if let cv = p.constValue {
                parts.append("\(p.slot)=\(cv)")
            }
        }
        return parts.joined(separator: "|")
    }
    // Hash numerico per le stesse chiavi (FNV-1a 64-bit)
    @inline(__always) private static func fnv64Init() -> UInt64 { 1469598103934665603 }
    @inline(__always) private static func fnv64Combine(_ h: inout UInt64, _ byte: UInt8) { h ^= UInt64(byte); h &*= 1099511628211 }
    private static func hashString(_ s: String) -> UInt64 {
        var h = fnv64Init()
        for b in s.utf8 { fnv64Combine(&h, b) }
        return h
    }
    private static func hashValue(_ v: Value) -> UInt64 {
        var h = fnv64Init()
        func mixTag(_ t: UInt8) { fnv64Combine(&h, t) }
        switch v {
        case .int(let i): mixTag(1); var x = UInt64(bitPattern: Int64(i)); for _ in 0..<8 { fnv64Combine(&h, UInt8(truncatingIfNeeded: x)); x >>= 8 }
        case .float(let d): mixTag(2); var bits = d.bitPattern; for _ in 0..<8 { fnv64Combine(&h, UInt8(truncatingIfNeeded: bits)); bits >>= 8 }
        case .string(let s): mixTag(3); let hs = hashString(s); var x = hs; for _ in 0..<8 { fnv64Combine(&h, UInt8(truncatingIfNeeded: x)); x >>= 8 }
        case .symbol(let s): mixTag(4); let hs = hashString(s); var x = hs; for _ in 0..<8 { fnv64Combine(&h, UInt8(truncatingIfNeeded: x)); x >>= 8 }
        case .boolean(let b): mixTag(5); fnv64Combine(&h, b ? 1 : 0)
        case .multifield(let arr): mixTag(6); for e in arr { let hv = hashValue(e); var x = hv; for _ in 0..<8 { fnv64Combine(&h, UInt8(truncatingIfNeeded: x)); x >>= 8 } }
        case .none: mixTag(0)
        }
        return h
    }
    private static func hashFromBindings(_ bindings: [String: Value], spec: [JoinKeyPart]) -> UInt {
        var h = fnv64Init()
        for p in spec {
            // slot name
            let hs = hashString(p.slot); var x = hs; for _ in 0..<8 { fnv64Combine(&h, UInt8(truncatingIfNeeded: x)); x >>= 8 }
            if let vn = p.varName, let val = bindings[vn] {
                let hv = hashValue(val); var y = hv; for _ in 0..<8 { fnv64Combine(&h, UInt8(truncatingIfNeeded: y)); y >>= 8 }
            } else if let cv = p.constValue {
                let hv = hashValue(cv); var y = hv; for _ in 0..<8 { fnv64Combine(&h, UInt8(truncatingIfNeeded: y)); y >>= 8 }
            }
        }
        return UInt(truncatingIfNeeded: h)
    }
    private static func hashFromFact(_ fact: Environment.FactRec, spec: [JoinKeyPart]) -> UInt {
        var h = fnv64Init()
        for p in spec {
            let hs = hashString(p.slot); var x = hs; for _ in 0..<8 { fnv64Combine(&h, UInt8(truncatingIfNeeded: x)); x >>= 8 }
            if let _ = p.varName, let val = fact.slots[p.slot] {
                let hv = hashValue(val); var y = hv; for _ in 0..<8 { fnv64Combine(&h, UInt8(truncatingIfNeeded: y)); y >>= 8 }
            } else if let cv = p.constValue {
                let hv = hashValue(cv); var y = hv; for _ in 0..<8 { fnv64Combine(&h, UInt8(truncatingIfNeeded: y)); y >>= 8 }
            }
        }
        return UInt(truncatingIfNeeded: h)
    }
    private static func factPassesConstants(_ fact: Environment.FactRec, pattern: Pattern) -> Bool {
        for (slot, t) in pattern.slots {
            if case .constant(let c) = t.kind {
                if fact.slots[slot] != c { return false }
            }
        }
        return true
    }
    // Costruisce l'elenco di costanti (e valori di variabili già bound) per interrogare l'AlphaIndex.
    private static func alphaConstants(_ pattern: Pattern, current: [String: Value]? = nil) -> [(String, Value)] {
        var out: [(String, Value)] = []
        for (slot, t) in pattern.slots {
            switch t.kind {
            case .constant(let v): out.append((slot, v))
            case .variable(let name):
                if let cur = current, let v = cur[name] { out.append((slot, v)) }
            case .predicate:
                break
            }
        }
        return out
    }
    // Recupera candidati usando l'AlphaIndex dato un pattern e (opzionalmente) i binding correnti.
    private static func alphaCandidates(_ env: Environment, available: Set<Int>?, pattern: Pattern, current: [String: Value]? = nil) -> [Environment.FactRec] {
        let constants = alphaConstants(pattern, current: current)
        let ids = env.rete.alpha.ids(for: pattern.name, constants: constants)
        if ids.isEmpty { return [] }
        if let avail = available {
            var res: [Environment.FactRec] = []
            for id in ids where avail.contains(id) { if let f = env.facts[id] { res.append(f) } }
            return res
        } else {
            var res: [Environment.FactRec] = []
            for id in ids { if let f = env.facts[id] { res.append(f) } }
            return res
        }
    }

    // Propagazione per livelli: ricostruisce tutte le memorie di livello per la regola, ritorna i nuovi token terminali
    @discardableResult
    public static func updateGraphOnAssert(_ env: inout Environment, ruleName: String, compiled: CompiledRule, facts: [Environment.FactRec]) -> [BetaToken] {
        // Assicurati che esista un grafo per la regola (utile per introspezione/watch)
        if env.rete.graphs[ruleName] == nil { env.rete.graphs[ruleName] = ReteGraphBuilder.build(ruleName: ruleName, compiled: compiled) }
        // Compute all levels
        let levels = computeLevels(&env, compiled: compiled, facts: facts, ruleName: ruleName)
        // Previous last-level keys
        let prevLevels = env.rete.betaLevels[ruleName] ?? [:]
        // Individua l'ultimo livello precedente (può includere livello filtro)
        let prevLast = (prevLevels.keys.max().flatMap { prevLevels[$0]?.tokens }) ?? []
        let prevSet = Set(prevLast.map(tokenKeyHash64))
        // Store new levels and compute added
        var store: [Int: BetaMemory] = [:]
        for (idx, toks) in levels.enumerated() {
            let mem = BetaMemory(); mem.tokens = toks; mem.keyIndex = Set(toks.map(tokenKeyHash64))
            var buckets: [UInt: [Int]] = [:]
            for (i, t) in toks.enumerated() { buckets[hashForToken(t), default: []].append(i) }
            mem.hashBuckets = buckets
            store[idx] = mem
        }
        env.rete.betaLevels[ruleName] = store
        // Update terminal beta snapshot as convenience
        // Snapshot terminale (post filtro se presente)
        let termMem = BetaMemory(); termMem.tokens = levels.last ?? []; termMem.keyIndex = Set((levels.last ?? []).map(tokenKeyHash64))
        var tb: [UInt: [Int]] = [:]
        for (i, t) in (levels.last ?? []).enumerated() { tb[hashForToken(t), default: []].append(i) }
        termMem.hashBuckets = tb
        env.rete.beta[ruleName] = termMem
        // Added tokens on terminal level
        var added: [BetaToken] = []
        for t in levels.last ?? [] { let kh = tokenKeyHash64(t); if !prevSet.contains(kh) { added.append(t) } }
        return added
    }

    public static func updateGraphOnRetract(_ env: inout Environment, ruleName: String, factID: Int) {
        guard let compiled = env.rete.rules[ruleName] else { return }
        // Recompute levels from facts without the retracted fact
        let facts = Array(env.facts.values)
        // Preferisci delta se memorie presenti, altrimenti ricostruisci
        if env.rete.betaLevels[ruleName] != nil {
            updateGraphOnRetractDelta(&env, ruleName: ruleName, factID: factID)
        } else {
            _ = updateGraphOnAssert(&env, ruleName: ruleName, compiled: compiled, facts: facts)
        }
    }

    private static func computeLevels(_ env: inout Environment, compiled: CompiledRule, facts: [Environment.FactRec], ruleName: String? = nil) -> [[BetaToken]] {
        let patterns = compiled.patterns.map { $0.original }
        guard !patterns.isEmpty else { return [] }
        var levels: [[BetaToken]] = []
        var current: [BetaToken] = [BetaToken(bindings: [:], usedFacts: [])]
        let availableIDs: Set<Int> = Set(facts.map { $0.id })
        for pidx in compiled.joinOrder {
            let t0 = env.watchReteProfile ? CFAbsoluteTimeGetCurrent() : 0
            let pat = patterns[pidx]
            var next: [BetaToken] = []
            let leftCount = current.count
            var factsConstOK = Set<Int>()
            var factsMatchedKey = 0
            var usedLeftSet = Set<String>()
            // CE negato: mantieni i token invariati se nessun fatto compatibile esiste
            if pat.negated {
                for tok in current {
                    var any = false
                    let constOkFacts = alphaCandidates(env, available: availableIDs, pattern: pat)
                    for f in constOkFacts {
                        if matchesNegativeLite(&env, pattern: pat, fact: f, current: tok.bindings) { any = true; break }
                    }
                    if !any { next.append(tok); usedLeftSet.insert(keyForToken(tok)) }
                }
            } else if pat.exists {
                // CE exists: propaga il token invariato se esiste almeno un fatto compatibile
                // Ottimizzazione: se ci sono chiavi di join definite, usa bucket su fatti
                let spec = (levels.count < compiled.joinSpecs.count) ? compiled.joinSpecs[levels.count].map { JoinKeyPart(slot: $0.slot, varName: $0.varName, constValue: $0.constValue) } : buildJoinKeySpec(for: pat, boundVarNames: boundVarNames(for: compiled, upTo: levels.count))
                if spec.isEmpty {
                    for tok in current {
                        var any = false
                        let constOkFacts = alphaCandidates(env, available: availableIDs, pattern: pat)
                        for f in constOkFacts {
                            if matchesNegativeLite(&env, pattern: pat, fact: f, current: tok.bindings) { any = true; break }
                        }
                        if any { next.append(tok); usedLeftSet.insert(keyForToken(tok)) }
                    }
                } else {
                    var fBucket: [UInt: [Environment.FactRec]] = [:]
                    let constOkFacts = alphaCandidates(env, available: availableIDs, pattern: pat)
                    for f in constOkFacts {
                        let hf = hashFromFact(f, spec: spec)
                        fBucket[hf, default: []].append(f)
                    }
                    for tok in current {
                        let hk = hashFromBindings(tok.bindings, spec: spec)
                        if let cand = fBucket[hk] {
                            var any = false
                            for f in cand { if matchesNegativeLite(&env, pattern: pat, fact: f, current: tok.bindings) { any = true; break } }
                            if any { next.append(tok); usedLeftSet.insert(keyForToken(tok)) }
                            factsMatchedKey += cand.count
                        }
                    }
                }
            } else {
            // Hash-join preparation (usa spec precompilata se disponibile)
            let spec = (levels.count < compiled.joinSpecs.count) ? compiled.joinSpecs[levels.count].map { JoinKeyPart(slot: $0.slot, varName: $0.varName, constValue: $0.constValue) } : buildJoinKeySpec(for: pat, boundVarNames: boundVarNames(for: compiled, upTo: levels.count))
            if !spec.isEmpty {
                // Build bucket from left tokens
                var bucket: [UInt: [BetaToken]] = [:]
                for tok: BetaToken in current {
                    let hk = hashFromBindings(tok.bindings, spec: spec)
                    bucket[hk, default: []].append(tok)
                }
                // Iterate facts filtered by template and constants
                let constOkFacts = alphaCandidates(env, available: availableIDs, pattern: pat)
                for f in constOkFacts {
                    factsConstOK.insert(f.id)
                    let hf = hashFromFact(f, spec: spec)
                    guard let lefts = bucket[hf] else { continue }
                    factsMatchedKey += 1
                    for tok in lefts where !tok.usedFacts.contains(f.id) {
                        if var b = RuleEngine.match(env: &env, pattern: pat, fact: f, current: tok.bindings) {
                            var ok = true
                            for (k,v) in tok.bindings { if let nb = b[k], nb != v { ok = false; break } }
                            if !ok { continue }
                            for (k,v) in tok.bindings { b[k] = v }
                            var used = tok.usedFacts; used.insert(f.id)
                            next.append(BetaToken(bindings: b, usedFacts: used))
                            usedLeftSet.insert(keyForToken(tok))
                        }
                    }
                }
            } else {
                // Fallback nested loops
                for tok in current {
                    let constOkFacts = alphaCandidates(env, available: availableIDs, pattern: pat)
                    for f in constOkFacts where !tok.usedFacts.contains(f.id) {
                        factsConstOK.insert(f.id)
                        if var b = RuleEngine.match(env: &env, pattern: pat, fact: f, current: tok.bindings) {
                            var ok = true
                            for (k,v) in tok.bindings { if let nb = b[k], nb != v { ok = false; break } }
                            if !ok { continue }
                            for (k,v) in tok.bindings { b[k] = v }
                            var used = tok.usedFacts; used.insert(f.id)
                            next.append(BetaToken(bindings: b, usedFacts: used))
                            usedLeftSet.insert(keyForToken(tok))
                        }
                    }
                }
                // In assenza di bucket, consideriamo factsMatchedKey = fatti che passano le costanti
                factsMatchedKey = factsConstOK.count
            }
            }
            // Applica eventuali test intermedi per questo livello
            if let tl = compiled.testsByLevel[levels.count] {
                next = next.filter { RuleEngine.applyTests(&env, tests: tl, with: $0.bindings) }
            }
            // Dedup per livello
            var seen = Set<UInt64>()
            var uniq: [BetaToken] = []
            for t in next {
                let kh = tokenKeyHash64(t)
                if !seen.contains(kh) { seen.insert(kh); uniq.append(t) }
            }
            levels.append(uniq)
            current = uniq
            if current.isEmpty { break }
            if env.watchReteProfile {
                let lvlIdx = levels.count - 1
                let ms = Int((CFAbsoluteTimeGetCurrent() - t0) * 1000)
                if let rn = ruleName {
                    Router.Writeln(&env, "RETE time \(rn)/L\(lvlIdx) \(ms)ms")
                    Router.Writeln(&env, "RETE stats \(rn)/L\(lvlIdx) left=\(leftCount) facts=\(factsConstOK.count) factsKey=\(factsMatchedKey) leftUsed=\(usedLeftSet.count) out=\(uniq.count)")
                } else {
                    Router.Writeln(&env, "RETE time L\(lvlIdx) \(ms)ms")
                    Router.Writeln(&env, "RETE stats L\(lvlIdx) left=\(leftCount) facts=\(factsConstOK.count) factsKey=\(factsMatchedKey) leftUsed=\(usedLeftSet.count) out=\(uniq.count)")
                }
            }
            // timing stampato sopra con stats
        }
        // Nodo filtro post-join: applica predicate CE (test ...)
        if let filter = compiled.filterNode, !filter.tests.isEmpty, !current.isEmpty {
            let t0 = env.watchReteProfile ? CFAbsoluteTimeGetCurrent() : 0
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
            if env.watchReteProfile {
                let ms = Int((CFAbsoluteTimeGetCurrent() - t0) * 1000)
                if let rn = ruleName {
                    Router.Writeln(&env, "RETE time \(rn)/L\(levels.count-1) (filter) \(ms)ms")
                    Router.Writeln(&env, "RETE stats \(rn)/L\(levels.count-1) (filter) out=\(uniq.count)")
                } else {
                    Router.Writeln(&env, "RETE time L\(levels.count-1) (filter) \(ms)ms")
                    Router.Writeln(&env, "RETE stats L\(levels.count-1) (filter) out=\(uniq.count)")
                }
            }
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
                let mem = BetaMemory(); mem.tokens = toks; mem.keyIndex = Set(toks.map(tokenKeyHash64))
                var buckets: [UInt: [Int]] = [:]
                for (i, t) in toks.enumerated() { buckets[hashForToken(t), default: []].append(i) }
                mem.hashBuckets = buckets
                store[idx] = mem
            }
            env.rete.betaLevels[ruleName] = store
            // Terminal snapshot
            let term = levels.last ?? []
            let termMem = BetaMemory(); termMem.tokens = term; termMem.keyIndex = Set(term.map(tokenKeyHash64))
            var tb: [UInt: [Int]] = [:]
            for (i, t) in term.enumerated() { tb[hashForToken(t), default: []].append(i) }
            termMem.hashBuckets = tb
            env.rete.beta[ruleName] = termMem
        }
    }

    private static func addIfNew(_ mem: BetaMemory, _ tok: BetaToken) -> Bool {
        let k = tokenKeyHash64(tok)
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
        if env.rete.graphs[ruleName] == nil { env.rete.graphs[ruleName] = ReteGraphBuilder.build(ruleName: ruleName, compiled: compiled) }
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
                if pat.exists {
                    // Per exists: se l'anchor soddisfa i vincoli con il binding corrente, propaga lt invariato
                    if matchesNegativeLite(&env, pattern: pat, fact: anchor, current: lt.bindings) {
                        let tok = lt
                        if let tl = compiled.testsByLevel[pos], !RuleEngine.applyTests(&env, tests: tl, with: tok.bindings) { continue }
                        let wasNew: Bool
                        if let mem = levels[pos] { wasNew = addIfNew(mem, tok) } else { let mem = BetaMemory(); wasNew = addIfNew(mem, tok); levels[pos] = mem }
                        if wasNew, env.watchRete { Router.Writeln(&env, "RETE + \(ruleName)/L\(pos) \(describeToken(tok))") }
                        if compiled.filterNode == nil && pos == (compiled.joinOrder.count - 1) && wasNew { terminalAdded.append(tok) }
                        currentNew.append(tok)
                    }
                } else {
                    if var b = RuleEngine.match(env: &env, pattern: pat, fact: anchor, current: lt.bindings) {
                        // merge bindings
                        var ok = true
                        for (k,v) in lt.bindings { if let nb = b[k], nb != v { ok = false; break } }
                        if !ok { continue }
                        for (k,v) in lt.bindings { b[k] = v }
                        var used = lt.usedFacts; used.insert(anchor.id)
                        let tok = BetaToken(bindings: b, usedFacts: used)
                        if let tl = compiled.testsByLevel[pos], !RuleEngine.applyTests(&env, tests: tl, with: tok.bindings) { continue }
                        let wasNew: Bool
                        if let mem = levels[pos] { wasNew = addIfNew(mem, tok) } else { let mem = BetaMemory(); wasNew = addIfNew(mem, tok); levels[pos] = mem }
                        if wasNew, env.watchRete { Router.Writeln(&env, "RETE + \(ruleName)/L\(pos) \(describeToken(tok))") }
                        if compiled.filterNode == nil && pos == (compiled.joinOrder.count - 1) && wasNew { terminalAdded.append(tok) }
                        currentNew.append(tok)
                    }
                }
            }

            // Propaga avanti sui livelli successivi
            if currentNew.isEmpty { continue }
            var nextTokens = currentNew
            var k = pos + 1
            while k < compiled.joinOrder.count && !nextTokens.isEmpty {
                let levelStart = env.watchReteProfile ? CFAbsoluteTimeGetCurrent() : 0
                let p2 = patterns[compiled.joinOrder[k]]
                var produced: [BetaToken] = []
                // Gestione negato in propagazione: se p2.negated, propaga invariato solo se nessun fatto compatibile esiste
                let boundNames2 = boundVarNames(for: compiled, upTo: k)
                let spec2 = buildJoinKeySpec(for: p2, boundVarNames: boundNames2)
                if p2.negated {
                    // Ottimizzazione: prefiltra per costanti e usa bucket hash sulle chiavi di join
                    let constOkFacts = alphaCandidates(env, available: Set(facts.map { $0.id }), pattern: p2)
                    if spec2.isEmpty {
                        // Nessun vincolo su variabili bound: il risultato dipende solo dall'esistenza di almeno un fatto compatibile
                        if constOkFacts.isEmpty {
                            for t in nextTokens {
                                let wasNew: Bool
                                if let mem = levels[k] { wasNew = addIfNew(mem, t) }
                                else { let mem = BetaMemory(); wasNew = addIfNew(mem, t); levels[k] = mem }
                                if wasNew { produced.append(t) }
                                if compiled.filterNode == nil && k == (compiled.joinOrder.count - 1) && wasNew { terminalAdded.append(t) }
                            }
                        } // else: esiste almeno un fatto => nessun token passa il not
                    } else {
                        var fBuckets: [UInt: [Environment.FactRec]] = [:]
                        for f in constOkFacts {
                            let hf = hashFromFact(f, spec: spec2)
                            fBuckets[hf, default: []].append(f)
                        }
                        for t in nextTokens {
                            let hk = hashFromBindings(t.bindings, spec: spec2)
                            let cand = fBuckets[hk] ?? []
                            var any = false
                            if !cand.isEmpty {
                                for f in cand {
                                    if matchesNegativeLite(&env, pattern: p2, fact: f, current: t.bindings) { any = true; break }
                                }
                            }
                            if !any {
                                let wasNew: Bool
                                if let mem = levels[k] { wasNew = addIfNew(mem, t) }
                                else { let mem = BetaMemory(); wasNew = addIfNew(mem, t); levels[k] = mem }
                                if wasNew { produced.append(t) }
                                if compiled.filterNode == nil && k == (compiled.joinOrder.count - 1) && wasNew { terminalAdded.append(t) }
                            }
                        }
                    }
                } else if p2.exists {
                    // Propaga il token invariato se esiste almeno un fatto compatibile coi binding
                    // Usa bucket su fatti per efficienza
                    var fBucket: [UInt: [Environment.FactRec]] = [:]
                    let constOkFacts = alphaCandidates(env, available: Set(facts.map { $0.id }), pattern: p2)
                    for f in constOkFacts {
                        let hf = hashFromFact(f, spec: spec2)
                        fBucket[hf, default: []].append(f)
                    }
                    for t in nextTokens {
                        let hk = hashFromBindings(t.bindings, spec: spec2)
                        guard let cand = fBucket[hk] else { continue }
                        var any = false
                        for f in cand { if matchesNegativeLite(&env, pattern: p2, fact: f, current: t.bindings) { any = true; break } }
                        if any {
                            let wasNew: Bool
                            if let mem = levels[k] { wasNew = addIfNew(mem, t) }
                            else { let mem = BetaMemory(); wasNew = addIfNew(mem, t); levels[k] = mem }
                            if wasNew { produced.append(t) }
                            if compiled.filterNode == nil && k == (compiled.joinOrder.count - 1) && wasNew { terminalAdded.append(t) }
                        }
                    }
                } else if !spec2.isEmpty {
                    var bucket: [UInt: [BetaToken]] = [:]
                    for t in nextTokens {
                        let hk = hashFromBindings(t.bindings, spec: spec2)
                        bucket[hk, default: []].append(t)
                    }
                    for f in facts where f.name == p2.name && factPassesConstants(f, pattern: p2) {
                        let hf = hashFromFact(f, spec: spec2)
                        guard let lefts = bucket[hf] else { continue }
                        for t in lefts where !t.usedFacts.contains(f.id) {
                            if var b = RuleEngine.match(env: &env, pattern: p2, fact: f, current: t.bindings) {
                                var ok = true
                                for (kk,vv) in t.bindings { if let nb = b[kk], nb != vv { ok = false; break } }
                                if !ok { continue }
                                for (kk,vv) in t.bindings { b[kk] = vv }
                                var used = t.usedFacts; used.insert(f.id)
                                let nt = BetaToken(bindings: b, usedFacts: used)
                                if let tl = compiled.testsByLevel[k], !RuleEngine.applyTests(&env, tests: tl, with: nt.bindings) { continue }
                                let wasNew: Bool
                                if let mem = levels[k] { wasNew = addIfNew(mem, nt) }
                                else { let mem = BetaMemory(); wasNew = addIfNew(mem, nt); levels[k] = mem }
                                if wasNew, env.watchRete { Router.Writeln(&env, "RETE + \(ruleName)/L\(k) \(describeToken(nt))") }
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
                                if let tl = compiled.testsByLevel[k], !RuleEngine.applyTests(&env, tests: tl, with: nt.bindings) { continue }
                                let wasNew: Bool
                                if let mem = levels[k] { wasNew = addIfNew(mem, nt) }
                                else { let mem = BetaMemory(); wasNew = addIfNew(mem, nt); levels[k] = mem }
                                if wasNew, env.watchRete { Router.Writeln(&env, "RETE + \(ruleName)/L\(k) \(describeToken(nt))") }
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
                if env.watchReteProfile {
                    let ms = Int((CFAbsoluteTimeGetCurrent() - levelStart) * 1000)
                    Router.Writeln(&env, "RETE time \(ruleName)/L\(k-1) \(ms)ms")
                }
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
                            if env.watchRete { Router.Writeln(&env, "RETE + \(ruleName)/L\(terminalLevel) \(describeToken(t))") }
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
        let termMem = BetaMemory(); termMem.tokens = termTokens; termMem.keyIndex = Set(termTokens.map(tokenKeyHash64))
        env.rete.beta[ruleName] = termMem

        // Se il join-check è attivo, verifica consistenza contro ricostruzione completa
        if env.experimentalJoinCheck {
            // Per la verifica completa usa tutti i fatti correnti dell'environment
            let allFacts = Array(env.facts.values)
            let recomputed = computeLevels(&env, compiled: compiled, facts: allFacts)
            let termIdx2 = terminalLevelIndex(compiled)
            let full = (termIdx2 < recomputed.count) ? recomputed[termIdx2] : (recomputed.last ?? [])
            let curSet = Set((levels[termIdx]?.tokens ?? []).map(tokenKeyHash64))
            let fullSet = Set(full.map(tokenKeyHash64))
            if curSet != fullSet {
                // Allinea livelli e snapshot a ricostruzione completa
                if env.watchRete { Router.Writeln(&env, "RETE sync full recompute for \(ruleName)") }
                var store: [Int: BetaMemory] = [:]
                for (idx, toks) in recomputed.enumerated() {
                    let mem = BetaMemory(); mem.tokens = toks; mem.keyIndex = Set(toks.map(tokenKeyHash64))
                    var buckets: [UInt: [Int]] = [:]
                    for (i, t) in toks.enumerated() { buckets[hashForToken(t), default: []].append(i) }
                    mem.hashBuckets = buckets
                    store[idx] = mem
                }
                env.rete.betaLevels[ruleName] = store
                let termMem2 = BetaMemory(); termMem2.tokens = full; termMem2.keyIndex = Set(full.map(tokenKeyHash64))
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
        // 1) Rimuovi dai livelli i token che includono il factID
        for (idx, mem) in levels {
            let before = mem.tokens.count
            let kept = mem.tokens.filter { !$0.usedFacts.contains(factID) }
            mem.tokens = kept
            mem.keyIndex = Set(kept.map(tokenKeyHash64))
            // rebuild hash buckets
            var buckets: [UInt: [Int]] = [:]
            for (i, t) in kept.enumerated() { buckets[hashForToken(t), default: []].append(i) }
            mem.hashBuckets = buckets
            let removed = before - kept.count
            if removed > 0, env.watchRete { Router.Writeln(&env, "RETE - L\(idx) removed \(removed)") }
            levels[idx] = mem
        }
        // 2) Propagazione parziale per EXISTS: ricalcola solo i livelli EXISTS e successivi
        guard let compiled = env.rete.rules[ruleName] else { env.rete.betaLevels[ruleName] = levels; return }
        let patterns = compiled.patterns.map { $0.original }
        let facts = Array(env.facts.values)
        var recomputeFrom: Int? = nil
        if !levels.isEmpty {
            for k in 0..<compiled.joinOrder.count {
                let pat = patterns[compiled.joinOrder[k]]
                if !pat.exists { continue }
                // left tokens sono i token del livello precedente (o token vuoto se k==0)
                let leftTokens: [BetaToken] = (k == 0) ? [BetaToken(bindings: [:], usedFacts: [])] : (levels[k - 1]?.tokens ?? [])
                var next: [BetaToken] = []
                let spec = buildJoinKeySpec(for: pat, boundVarNames: boundVarNames(for: compiled, upTo: k))
                if spec.isEmpty {
                    for t in leftTokens {
                        var any = false
                        for f in facts where f.name == pat.name {
                            if matchesNegativeLite(&env, pattern: pat, fact: f, current: t.bindings) { any = true; break }
                        }
                        if any { next.append(t) }
                    }
                } else {
                    var fBucket: [UInt: [Environment.FactRec]] = [:]
                    for f in facts where f.name == pat.name && factPassesConstants(f, pattern: pat) {
                        let hf = hashFromFact(f, spec: spec)
                        fBucket[hf, default: []].append(f)
                    }
                    for t in leftTokens {
                        let hk = hashFromBindings(t.bindings, spec: spec)
                        if let cand = fBucket[hk] {
                            var any = false
                            for f in cand { if matchesNegativeLite(&env, pattern: pat, fact: f, current: t.bindings) { any = true; break } }
                            if any { next.append(t) }
                        }
                    }
                }
                // Dedup
                var seen = Set<UInt64>()
                var uniq: [BetaToken] = []
                for t in next { let kh = tokenKeyHash64(t); if !seen.contains(kh) { seen.insert(kh); uniq.append(t) } }
                let cur = levels[k]?.tokens ?? []
                // Se i token differiscono, aggiorna e segna il livello per recompute in avanti
                let curSet = Set(cur.map(tokenKeyHash64))
                let newSet = Set(uniq.map(tokenKeyHash64))
                if curSet != newSet {
                    let mem = levels[k] ?? BetaMemory()
                    mem.tokens = uniq
                    mem.keyIndex = Set(uniq.map(tokenKeyHash64))
                    var buckets: [UInt: [Int]] = [:]
                    for (i, t) in uniq.enumerated() { buckets[hashForToken(t), default: []].append(i) }
                    mem.hashBuckets = buckets
                    levels[k] = mem
                    if recomputeFrom == nil || k < recomputeFrom! { recomputeFrom = k }
                }
            }
        }
        // 3) Se necessario, ricalcola i livelli successivi a partire da recomputeFrom
        if let start = recomputeFrom {
            var k = start + 1
            while k < compiled.joinOrder.count {
                let p = patterns[compiled.joinOrder[k]]
                let leftTokens = (k == 0) ? [BetaToken(bindings: [:], usedFacts: [])] : (levels[k - 1]?.tokens ?? [])
                var next: [BetaToken] = []
                if p.negated {
                    for t in leftTokens {
                        var any = false
                        for f in facts where f.name == p.name {
                            if matchesNegativeLite(&env, pattern: p, fact: f, current: t.bindings) { any = true; break }
                        }
                        if !any { next.append(t) }
                    }
                } else if p.exists {
                    let spec = buildJoinKeySpec(for: p, boundVarNames: boundVarNames(for: compiled, upTo: k))
                    if spec.isEmpty {
                        for t in leftTokens {
                            var any = false
                            for f in facts where f.name == p.name {
                                if matchesNegativeLite(&env, pattern: p, fact: f, current: t.bindings) { any = true; break }
                            }
                            if any { next.append(t) }
                        }
                    } else {
                        var fBucket: [UInt: [Environment.FactRec]] = [:]
                        for f in facts where f.name == p.name && factPassesConstants(f, pattern: p) {
                            let hf = hashFromFact(f, spec: buildJoinKeySpec(for: p, boundVarNames: boundVarNames(for: compiled, upTo: k)))
                            fBucket[hf, default: []].append(f)
                        }
                        for t in leftTokens {
                            let hk = hashFromBindings(t.bindings, spec: buildJoinKeySpec(for: p, boundVarNames: boundVarNames(for: compiled, upTo: k)))
                            if let cand = fBucket[hk] {
                                var any = false
                                for f in cand { if matchesNegativeLite(&env, pattern: p, fact: f, current: t.bindings) { any = true; break } }
                                if any { next.append(t) }
                            }
                        }
                    }
                } else {
                    // positivo: join
                    let spec = buildJoinKeySpec(for: p, boundVarNames: boundVarNames(for: compiled, upTo: k))
                    if !spec.isEmpty {
                        var bucket: [UInt: [BetaToken]] = [:]
                        for t in leftTokens {
                            let hk = hashFromBindings(t.bindings, spec: spec)
                            bucket[hk, default: []].append(t)
                        }
                        let constOkFacts = alphaCandidates(env, available: Set(facts.map { $0.id }), pattern: p)
                        for f in constOkFacts {
                            let hf = hashFromFact(f, spec: spec)
                            guard let lefts = bucket[hf] else { continue }
                            for t in lefts where !t.usedFacts.contains(f.id) {
                                if var b = RuleEngine.match(env: &env, pattern: p, fact: f, current: t.bindings) {
                                    var ok = true
                                    for (kk,vv) in t.bindings { if let nb = b[kk], nb != vv { ok = false; break } }
                                    if !ok { continue }
                                    for (kk,vv) in t.bindings { b[kk] = vv }
                                    var used = t.usedFacts; used.insert(f.id)
                                    next.append(BetaToken(bindings: b, usedFacts: used))
                                }
                            }
                        }
                    } else {
                        let constOkFacts = alphaCandidates(env, available: Set(facts.map { $0.id }), pattern: p)
                        for t in leftTokens {
                            for f in constOkFacts where !t.usedFacts.contains(f.id) {
                                if var b = RuleEngine.match(env: &env, pattern: p, fact: f, current: t.bindings) {
                                    var ok = true
                                    for (kk,vv) in t.bindings { if let nb = b[kk], nb != vv { ok = false; break } }
                                    if !ok { continue }
                                    for (kk,vv) in t.bindings { b[kk] = vv }
                                    var used = t.usedFacts; used.insert(f.id)
                                    next.append(BetaToken(bindings: b, usedFacts: used))
                                }
                            }
                        }
                    }
                }
                // Applica eventuali test per livello
                if let tl = compiled.testsByLevel[k] {
                    next = next.filter { RuleEngine.applyTests(&env, tests: tl, with: $0.bindings) }
                }
                // Dedup
                var seen = Set<UInt64>()
                var uniq: [BetaToken] = []
                for t in next { let kh = tokenKeyHash64(t); if !seen.contains(kh) { seen.insert(kh); uniq.append(t) } }
                let mem = levels[k] ?? BetaMemory()
                mem.tokens = uniq
                mem.keyIndex = Set(uniq.map(tokenKeyHash64))
                var buckets: [UInt: [Int]] = [:]
                for (i, t) in uniq.enumerated() { buckets[hashForToken(t), default: []].append(i) }
                mem.hashBuckets = buckets
                levels[k] = mem
                k += 1
            }
            // Nodo filtro terminale, se presente
            if let filter = compiled.filterNode, !filter.tests.isEmpty {
                let lastIdx = compiled.joinOrder.count - 1
                let src = levels[lastIdx]?.tokens ?? []
                var out: [BetaToken] = []
                for t in src { if RuleEngine.applyTests(&env, tests: filter.tests, with: t.bindings) { out.append(t) } }
                let termIdx = terminalLevelIndex(compiled)
                let mem = levels[termIdx] ?? BetaMemory()
                mem.tokens = out
                mem.keyIndex = Set(out.map(tokenKeyHash64))
                var buckets: [UInt: [Int]] = [:]
                for (i, t) in out.enumerated() { buckets[hashForToken(t), default: []].append(i) }
                mem.hashBuckets = buckets
                levels[termIdx] = mem
            }
        }
        env.rete.betaLevels[ruleName] = levels
        // 4) Aggiorna snapshot terminale
        if let maxIdx = levels.keys.max(), let mem = levels[maxIdx] {
            let termMem = BetaMemory(); termMem.tokens = mem.tokens; termMem.keyIndex = mem.keyIndex; termMem.hashBuckets = mem.hashBuckets
            env.rete.beta[ruleName] = termMem
        } else {
            env.rete.beta[ruleName] = BetaMemory()
        }
    }
}
