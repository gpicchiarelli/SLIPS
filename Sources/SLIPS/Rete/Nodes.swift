// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import Foundation

// MARK: - Nodi RETE Espliciti (Fase 1)
// Traduzione fedele da pattern.h, network.h, reteutil.h (CLIPS 6.4.2)
// Riferimenti C:
// - struct patternNodeHeader (pattern.h) → ReteNode protocol
// - struct joinNode (network.h) → JoinNodeClass
// - struct betaMemory (implicito) → BetaMemoryNode

/// Protocollo base per tutti i nodi della rete RETE
/// (ref: struct patternNodeHeader in pattern.h)
public protocol ReteNode: AnyObject {
    var id: UUID { get }
    var level: Int { get }
    func activate(token: BetaToken, env: inout Environment)
}

// MARK: - Alpha Network Nodes

/// Nodo alpha per pattern matching su singolo template
/// Memorizza fatti che matchano il pattern e propaga ai join successori
/// (ref: struct patternNodeHeader con alpha memory in pattern.h)
public final class AlphaNodeClass: ReteNode {
    public let id: UUID
    public let level: Int
    public let pattern: Pattern
    /// Memoria alpha: IDs di fatti che matchano questo pattern
    public var memory: Set<Int> = []
    /// Nodi successori nella catena principale (per primo pattern)
    public var successors: [ReteNode] = []
    /// Join nodes che usano questo alpha come rightInput
    /// Quando un fatto viene aggiunto, questi join vengono notificati
    public var rightJoinListeners: [JoinNodeClass] = []
    
    public init(pattern: Pattern, level: Int = 0) {
        self.id = UUID()
        self.level = level
        self.pattern = pattern
    }
    
    /// Attiva propagazione token ai successori
    /// (ref: NetworkAssert flow in drive.c)
    public func activate(token: BetaToken, env: inout Environment) {
        if env.watchRete {
            print("[RETE] AlphaNode activate: pattern=\(pattern.name), successors=\(successors.count)")
        }
        for successor in successors {
            successor.activate(token: token, env: &env)
        }
    }
}

// MARK: - Beta Network Nodes

/// Nodo join per combinare pattern (left × right)
/// Port FEDELE di struct joinNode (network.h linee 108-136)
/// (ref: struct joinNode in network.h, PerformJoin in drive.c)
public final class JoinNodeClass: ReteNode {
    public let id: UUID
    public let level: Int
    
    // NUOVE STRUTTURE - Port fedele da network.h
    
    /// Flags (bitfield in C)
    public var firstJoin: Bool = false
    public var logicalJoin: Bool = false
    public var joinFromTheRight: Bool = false
    public var patternIsNegated: Bool = false
    public var patternIsExists: Bool = false
    public var initialize: Bool = true
    public var marked: Bool = false
    public var rhsType: UInt8 = 0
    public var depth: UInt16 = 0
    
    /// Beta memories (DUE separate come in CLIPS!)
    /// Port di: struct betaMemory *leftMemory / *rightMemory
    public var leftMemory: BetaMemoryHash? = nil
    public var rightMemory: BetaMemoryHash? = nil
    
    /// Network tests
    /// Port di: Expression *networkTest / *secondaryNetworkTest
    public var networkTest: ExpressionNode? = nil
    public var secondaryNetworkTest: ExpressionNode? = nil
    
    /// Hash expressions (per calcolo hash value)
    /// Port di: Expression *leftHash / *rightHash
    public var leftHash: ExpressionNode? = nil
    public var rightHash: ExpressionNode? = nil
    
    /// Right side entry structure (per pattern nodes)
    /// Port di: void *rightSideEntryStructure
    public var rightSideEntryStructure: AnyObject? = nil
    
    /// Collegamenti successori (nextLinks in C)
    /// Port di: struct joinLink *nextLinks
    public var nextLinks: [JoinLink] = []
    
    /// Last level join (predecessore)
    /// Port di: struct joinNode *lastLevel
    public var lastLevel: JoinNodeClass? = nil
    
    /// Right match node (per join from right)
    /// Port di: struct joinNode *rightMatchNode
    public var rightMatchNode: JoinNodeClass? = nil
    
    /// Regola da attivare (production terminal)
    /// Port di: Defrule *ruleToActivate
    public var ruleToActivate: ProductionNode? = nil
    
    /// Statistics (per profiling)
    public var memoryLeftAdds: Int64 = 0
    public var memoryRightAdds: Int64 = 0
    public var memoryLeftDeletes: Int64 = 0
    public var memoryRightDeletes: Int64 = 0
    public var memoryCompares: Int64 = 0
    
    // BACKWARD COMPATIBILITY (da rimuovere gradualmente)
    public let leftInput: ReteNode?
    public let rightInput: AlphaNodeClass?
    public let joinKeys: Set<String>
    public let tests: [ExpressionNode]
    public var successors: [ReteNode] = []
    
    public init(
        left: ReteNode? = nil,
        right: AlphaNodeClass? = nil,
        keys: Set<String> = [],
        tests: [ExpressionNode] = [],
        level: Int = 0
    ) {
        self.id = UUID()
        self.level = level
        self.leftInput = left
        self.rightInput = right
        self.joinKeys = keys
        self.tests = tests
        
        // Inizializza beta memories
        self.leftMemory = BetaMemoryHash(initialSize: 17)
        self.rightMemory = BetaMemoryHash(initialSize: 17)
    }
    
    /// Attiva join: combina token con fatti dalla memoria alpha
    /// (ref: PerformJoin in drive.c, NetworkAssertLeft in drive.c)
    public func activate(token: BetaToken, env: inout Environment) {
        if env.watchRete {
            let memCount = rightInput?.memory.count ?? 0
            print("[RETE] JoinNode activate (from LEFT): level=\(level), rightAlpha=\(memCount) facts")
        }
        
        // ✅ CRITICO: Aggiungi token alla leftMemory (ref: NetworkAssertLeft in drive.c)
        // Quando un token arriva dal lato SINISTRO (da BetaMemory predecessore),
        // va salvato nella leftMemory per futuri join con fatti dal lato destro
        let pm = PartialMatchBridge.createPartialMatch(from: token, env: env)
        
        // ✅ CRITICO: Ricalcola hash usando joinKeys
        // Ref: drive.c:940 - hashValue = BetaMemoryHashValue(..., join->leftHash, ...)
        // L'hash deve basarsi sulle variabili COMUNI (joinKeys) non su tutti i fact IDs
        // SEMPLIFICAZIONE: Se joinKeys è vuoto, usa hash 0 (tutti nello stesso bucket)
        var hasher = Hasher()
        for key in joinKeys.sorted() {
            if let value = token.bindings[key] {
                switch value {
                case .int(let i): hasher.combine(i)
                case .float(let f): hasher.combine(f)
                case .string(let s), .symbol(let s): hasher.combine(s)
                case .boolean(let b): hasher.combine(b)
                default: break
                }
            }
        }
        pm.hashValue = joinKeys.isEmpty ? 0 : UInt(bitPattern: hasher.finalize())
        
        ReteUtil.AddToLeftMemory(self, pm)
        if env.watchRete {
            print("[RETE] JoinNode: added token to leftMemory (size=\(leftMemory?.count ?? 0), hash=\(pm.hashValue))")
        }
        
        let startTime = env.watchReteProfile ? Date() : nil
        var joinCount = 0
        
        // Join con tutti i fatti nella memoria alpha destra
        guard let rightAlpha = rightInput else { return }
        
        for factID in rightAlpha.memory {
            guard let fact = env.facts[factID] else { continue }
            guard !token.usedFacts.contains(factID) else { continue } // Evita cicli
            
            // Tenta join verificando join keys e test
            if let newToken = attemptJoin(
                leftToken: token,
                rightFact: fact,
                env: &env
            ) {
                joinCount += 1
                // Propaga nuovo token ai successori
                for successor in successors {
                    successor.activate(token: newToken, env: &env)
                }
            }
        }
        
        if let start = startTime, env.watchReteProfile {
            let elapsed = Date().timeIntervalSince(start)
            print("[RETE Profile] JoinNode level \(level): \(joinCount) joins in \(elapsed * 1000)ms")
        }
    }
    
    /// Tenta il join di un token beta con un fatto alpha
    /// Verifica consistenza join keys e applica test constraints
    /// (ref: EvaluateJoinExpression in drive.c)
    private func attemptJoin(
        leftToken: BetaToken,
        rightFact: Environment.FactRec,
        env: inout Environment
    ) -> BetaToken? {
        // Verifica che il fatto sia del template giusto
        guard let rightAlpha = rightInput,
              rightFact.name == rightAlpha.pattern.name else {
            return nil
        }
        
        var newBindings = leftToken.bindings
        
        // Verifica consistenza join keys e estrai nuovi binding
        for (slot, test) in rightAlpha.pattern.slots {
            guard let factValue = rightFact.slots[slot] else { continue }
            
            switch test.kind {
            case .constant(let expectedValue):
                // Costante: deve matchare esattamente
                if factValue != expectedValue { return nil }
                
            case .variable(let varName):
                // Variabile: verifica consistenza se già bound
                if joinKeys.contains(varName) {
                    if let existingValue = leftToken.bindings[varName] {
                        if existingValue != factValue { return nil }
                    }
                }
                // Aggiungi/aggiorna binding
                newBindings[varName] = factValue
                
            case .mfVariable(let varName):
                // Multifield variable
                if joinKeys.contains(varName) {
                    if let existingValue = leftToken.bindings[varName] {
                        if existingValue != factValue { return nil }
                    }
                }
                newBindings[varName] = factValue
                
            case .predicate(let exprNode):
                // Predicate test: valuta con binding correnti
                let oldBindings = env.localBindings
                env.localBindings = newBindings
                env.localBindings[slot] = factValue // Binding implicito per slot
                
                let result = Evaluator.EvaluateExpression(&env, exprNode)
                env.localBindings = oldBindings
                
                switch result {
                case .boolean(let b):
                    if !b { return nil }
                case .int(let i):
                    if i == 0 { return nil }
                default:
                    break
                }
                
            case .sequence:
                // Sequence matching (multifield) - implementazione futura Fase 2
                break
            }
        }
        
        // Applica test constraints aggiuntivi
        for test in tests {
            let oldBindings = env.localBindings
            env.localBindings = newBindings
            
            let result = Evaluator.EvaluateExpression(&env, test)
            env.localBindings = oldBindings
            
            switch result {
            case .boolean(let b):
                if !b { return nil }
            case .int(let i):
                if i == 0 { return nil }
            default:
                break
            }
        }
        
        // Join riuscito: crea nuovo token
        var usedFacts = leftToken.usedFacts
        usedFacts.insert(rightFact.id)
        
        return BetaToken(bindings: newBindings, usedFacts: usedFacts)
    }
    
    /// Attiva join quando un nuovo fatto arriva da destra (rightInput)
    /// NUOVO: Usa hash lookup O(1) come in CLIPS C (con fallback durante transizione)
    /// (ref: NetworkAssertRight in drive.c con GetLeftBetaMemory)
    public func activateFromRight(fact: Environment.FactRec, env: inout Environment) {
        // Estrai bindings dal fatto secondo il pattern
        var bindings: [String: Value] = [:]
        if let rightAlpha = rightInput {
            for (slot, test) in rightAlpha.pattern.slots {
                if let value = fact.slots[slot] {
                    switch test.kind {
                    case .variable(let name), .mfVariable(let name):
                        bindings[name] = value
                    default:
                        break
                    }
                }
            }
        }
        
        // Crea PartialMatch dal fatto
        let factToken = BetaToken(bindings: bindings, usedFacts: [fact.id])
        let rhsPM = PartialMatchBridge.createPartialMatch(from: factToken, env: env)
        
        // ✅ CRITICO: Calcola hash usando rightHash expression o joinKeys
        // Ref: drive.c:947 - hashValue = BetaMemoryHashValue(..., join->rightHash, ...)
        var hasher = Hasher()
        for key in joinKeys.sorted() {
            if let value = bindings[key] {
                switch value {
                case .int(let i): hasher.combine(i)
                case .float(let f): hasher.combine(f)
                case .string(let s), .symbol(let s): hasher.combine(s)
                case .boolean(let b): hasher.combine(b)
                default: break
                }
            }
        }
        rhsPM.hashValue = joinKeys.isEmpty ? 0 : UInt(bitPattern: hasher.finalize())
        
        // CRITICO: Aggiungi fatto a rightMemory PRIMA di propagare (come in CLIPS C)
        if !self.firstJoin {
            ReteUtil.AddToRightMemory(self, rhsPM)
            if env.watchRete {
                print("[RETE] JoinNodeClass.activateFromRight: added to rightMemory (level=\(self.level), size=\(self.rightMemory?.count ?? 0), hash=\(rhsPM.hashValue))")
            }
        }
        
        // CRITICO: Usa DriveEngine per tutta la propagazione (Fase 1.5 - CLIPS C)
        if self.firstJoin {
            // First join: usa EmptyDrive
            if env.watchRete {
                print("[RETE] JoinNodeClass.activateFromRight: FIRST JOIN, calling EmptyDrive")
            }
            DriveEngine.EmptyDrive(&env, self, rhsPM, DriveEngine.NETWORK_ASSERT)
        } else {
            // Join successivo: usa NetworkAssertRight
            if env.watchRete {
                print("[RETE] JoinNodeClass.activateFromRight: calling NetworkAssertRight at level \(self.level)")
            }
            DriveEngine.NetworkAssertRight(&env, rhsPM, self, DriveEngine.NETWORK_ASSERT)
        }
    }
    
    /// Converte PartialMatch in BetaToken (bridge temporaneo)
    private func partialMatchToToken(_ pm: PartialMatch, env: Environment) -> BetaToken {
        var bindings: [String: Value] = [:]
        var usedFacts: Set<Int> = []
        
        // Estrai fact IDs
        for i in 0..<Int(pm.bcount) {
            if let alphaMatch = pm.binds[i].theMatch,
               let entity = alphaMatch.matchingItem {
                usedFacts.insert(entity.factID)
                
                // Estrai bindings dal fatto
                if let factEntity = entity as? FactPatternEntity {
                    let fact = factEntity.fact
                    // Serve il pattern per sapere quali variabili estrarre
                    // Per ora usiamo rightInput pattern se disponibile
                    if let rightAlpha = rightInput {
                        for (slot, test) in rightAlpha.pattern.slots {
                            if let value = fact.slots[slot] {
                                switch test.kind {
                                case .variable(let name), .mfVariable(let name):
                                    bindings[name] = value
                                default:
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return BetaToken(bindings: bindings, usedFacts: usedFacts)
    }
    
    /// Ottiene i token dalla memoria beta del left input
    private func getLeftTokens(env: Environment) -> [BetaToken] {
        // Se il leftInput è un BetaMemoryNode, restituisci i suoi token
        if let betaMemory = leftInput as? BetaMemoryNode {
            return betaMemory.memory.tokens
        }
        
        // Altrimenti, naviga ricorsivamente
        // Per ora, ritorna array vuoto se non è direttamente un BetaMemoryNode
        return []
    }
}

/// Nodo memoria beta per persistenza token
/// Memorizza token intermedi e propaga ai successori
/// (ref: beta memory implicito in network.h, BetaMemory class già definita in BetaNetwork.swift)
public final class BetaMemoryNode: ReteNode {
    public let id: UUID
    public let level: Int
    /// Riferimento alla memoria beta condivisa (può essere riutilizzata da altre regole)
    public let memory: BetaMemory
    /// Nodi successori
    public var successors: [ReteNode] = []
    
    public init(level: Int, memory: BetaMemory = BetaMemory()) {
        self.id = UUID()
        self.level = level
        self.memory = memory
    }
    
    /// Attiva: memorizza token se nuovo e propaga
    /// (ref: UpdateBetaMemory in drive.c)
    public func activate(token: BetaToken, env: inout Environment) {
        let hash = tokenKeyHash64(token)
        
        // Deduplica: aggiungi solo se non già presente
        if !memory.keyIndex.contains(hash) {
            memory.keyIndex.insert(hash)
            memory.tokens.append(token)
            
            // Aggiorna hash buckets per join optimization
            let joinHash = computeJoinHash(token)
            memory.hashBuckets[joinHash, default: []].append(memory.tokens.count - 1)
            
            if env.watchRete {
                print("[RETE] BetaMemory level \(level): stored token (total=\(memory.tokens.count))")
            }
            
            // Propaga ai successori
            // NOTA: leftMemory viene popolata da DriveEngine, non qui (Fase 1.5)
            for successor in successors {
                successor.activate(token: token, env: &env)
            }
        }
    }
    
    /// Computa hash per join bucket (basato su variabili comuni)
    private func computeJoinHash(_ token: BetaToken) -> UInt {
        var hasher = Hasher()
        // Hash ordinato deterministico
        for key in token.bindings.keys.sorted() {
            hasher.combine(key)
            if let value = token.bindings[key] {
                hashValue(&hasher, value)
            }
        }
        // Usa bitPattern per gestire valori negativi
        return UInt(bitPattern: hasher.finalize())
    }
    
    private func hashValue(_ hasher: inout Hasher, _ value: Value) {
        switch value {
        case .int(let i): hasher.combine(0); hasher.combine(i)
        case .float(let d): hasher.combine(1); hasher.combine(d)
        case .string(let s): hasher.combine(2); hasher.combine(s)
        case .symbol(let s): hasher.combine(3); hasher.combine(s)
        case .boolean(let b): hasher.combine(4); hasher.combine(b)
        case .multifield(let arr):
            hasher.combine(5); hasher.combine(arr.count)
            for v in arr { hashValue(&hasher, v) }
        case .none: hasher.combine(6)
        }
    }
}

// MARK: - Special Nodes

/// Nodo NOT per conditional elements negativi
/// Propaga token solo se NON esiste fatto matching con il pattern
/// (ref: struct joinNode con negated flag in network.h, EvaluateSecondaryNetworkTest in drive.c)
public final class NotNodeClass: ReteNode {
    public let id: UUID
    public let level: Int
    public let pattern: Pattern
    public let joinKeys: Set<String>
    /// Alpha node per trovare fatti candidati
    public let alphaNode: AlphaNodeClass
    public var successors: [ReteNode] = []
    
    public init(
        pattern: Pattern,
        keys: Set<String>,
        alphaNode: AlphaNodeClass,
        level: Int
    ) {
        self.id = UUID()
        self.level = level
        self.pattern = pattern
        self.joinKeys = keys
        self.alphaNode = alphaNode
    }
    
    /// Attiva: propaga token solo se NOT condition è vera
    /// (ref: EvaluateSecondaryNetworkTest in drive.c)
    public func activate(token: BetaToken, env: inout Environment) {
        if env.watchRete {
            print("[RETE] NotNode activate: level=\(level), checking \(alphaNode.memory.count) facts")
        }
        
        // Cerca fatti che matchano con i binding correnti
        var foundMatch = false
        
        for factID in alphaNode.memory {
            guard let fact = env.facts[factID] else { continue }
            
            // Verifica se il fatto matcha considerando join keys
            if matchesWithBindings(fact: fact, bindings: token.bindings, env: &env) {
                foundMatch = true
                break
            }
        }
        
        // Propaga solo se NON trovato match (NOT condition vera)
        if !foundMatch {
            for successor in successors {
                successor.activate(token: token, env: &env)
            }
        }
    }
    
    /// Verifica se un fatto matcha con i binding correnti
    private func matchesWithBindings(
        fact: Environment.FactRec,
        bindings: [String: Value],
        env: inout Environment
    ) -> Bool {
        guard fact.name == pattern.name else { return false }
        
        for (slot, test) in pattern.slots {
            guard let factValue = fact.slots[slot] else { return false }
            
            switch test.kind {
            case .constant(let v):
                if v != factValue { return false }
            case .variable(let name):
                if let existing = bindings[name], existing != factValue { return false }
            case .mfVariable(let name):
                if let existing = bindings[name], existing != factValue { return false }
            case .predicate(let exprNode):
                let old = env.localBindings
                env.localBindings = bindings
                let res = Evaluator.EvaluateExpression(&env, exprNode)
                env.localBindings = old
                switch res {
                case .boolean(let b):
                    if !b { return false }
                case .int(let i):
                    if i == 0 { return false }
                default:
                    break
                }
            case .sequence:
                // Implementazione futura Fase 2
                break
            }
        }
        
        return true
    }
}

/// Nodo EXISTS per conditional elements esistenziali
/// Propaga token se EXISTS condition è vera (almeno un fatto matcha)
/// (ref: struct joinNode con exists flag in network.h)
// ExistsNodeClass rimosso: EXISTS viene trasformato in NOT(NOT) dal parser
// Ref: rulelhs.c:827-843 in CLIPS C

/// Nodo produzione terminale che genera attivazioni
/// Quando un token completo arriva qui, crea un'attivazione nell'agenda
/// (ref: struct defrule in ruledef.h, AddActivation in agenda.c)
public final class ProductionNode: ReteNode {
    public let id: UUID
    public let level: Int
    public let ruleName: String
    public let rhs: [ExpressionNode]
    public let salience: Int
    
    public init(
        ruleName: String,
        rhs: [ExpressionNode],
        salience: Int,
        level: Int
    ) {
        self.id = UUID()
        self.level = level
        self.ruleName = ruleName
        self.rhs = rhs
        self.salience = salience
    }
    
    /// Attiva: crea attivazione e aggiunge all'agenda
    /// (ref: AddActivation in agenda.c)
    public func activate(token: BetaToken, env: inout Environment) {
        if env.watchRete {
            print("[RETE] ProductionNode.activate called for '\(ruleName)'")
            print("[RETE]   Token bindings: \(token.bindings)")
            print("[RETE]   Token facts: \(token.usedFacts)")
        }
        
        // ✅ CRITICO: Valuta test terminali PRIMA di creare l'attivazione
        // In CLIPS C, i test sono integrati come networkTest nell'ultimo JoinNode
        // o valutati prima di aggiungere all'agenda
        // Ref: EvaluateJoinExpression in drive.c
        if let rule = env.rules.first(where: { $0.name == ruleName || $0.displayName == ruleName }),
           !rule.tests.isEmpty {
            let oldBindings = env.localBindings
            env.localBindings = token.bindings
            
            for testExpr in rule.tests {
                let exprToEval: ExpressionNode
                if testExpr.type == .fcall, (testExpr.value?.value as? String) == "test",
                   let arg = testExpr.argList {
                    exprToEval = arg
                } else {
                    exprToEval = testExpr
                }
                
                let result = try? Evaluator.eval(&env, exprToEval)
                
                switch result {
                case .boolean(let b):
                    if !b {
                        env.localBindings = oldBindings
                        if env.watchRete {
                            print("[RETE] ProductionNode: REJECTED by test (boolean false)")
                        }
                        return  // ← Test fallito, NON creare attivazione
                    }
                case .int(let i):
                    if i == 0 {
                        env.localBindings = oldBindings
                        if env.watchRete {
                            print("[RETE] ProductionNode: REJECTED by test (int 0)")
                        }
                        return
                    }
                default:
                    env.localBindings = oldBindings
                    if env.watchRete {
                        print("[RETE] ProductionNode: REJECTED by test (eval failed)")
                    }
                    return
                }
            }
            
            env.localBindings = oldBindings
        }
        
        var activation = Activation(
            priority: salience,
            ruleName: ruleName,
            bindings: token.bindings
        )
        activation.factIDs = token.usedFacts
        // FASE 3: Assegna modulo e displayName alla attivazione (prendi dalla regola in env)
        if let rule = env.rules.first(where: { $0.name == ruleName || $0.displayName == ruleName }) {
            activation.moduleName = rule.moduleName
            activation.displayName = rule.displayName  // ✅ Per deduplica disjuncts
        }
        
        // Aggiungi solo se non già presente (deduplica)
        let alreadyExists = env.agendaQueue.contains(activation)
        if env.watchRete {
            print("[RETE]   Already in agenda: \(alreadyExists)")
        }
        
        if !alreadyExists {
            env.agendaQueue.add(activation)
            
            if env.watchRules {
                print("==> Activation \(ruleName) : salience \(salience)")
            }
            if env.watchRete {
                print("[RETE] ProductionNode: ADDED activation for \(ruleName)")
            }
        } else {
            if env.watchRete {
                print("[RETE] ProductionNode: SKIPPED duplicate activation for \(ruleName)")
            }
        }
    }
}

// MARK: - Backward Compatibility (struct-based legacy nodes)

/// Nodo filtro post-join per predicate CE (es. (test ...)).
/// Valuta le espressioni rispetto ai binding del token corrente e decide la propagazione.
public struct FilterNode: Codable {
    public var id: Int
    public var tests: [ExpressionNode]
    public init(id: Int, tests: [ExpressionNode]) { self.id = id; self.tests = tests }
}

/// Nodo "exists" unario (struct legacy per backward compatibility)
/// Verifica l'esistenza di almeno un fatto compatibile
/// con i vincoli sui binding correnti, senza introdurre nuovi binding.
public struct ExistsNode: Codable, Equatable {
    public var id: Int
    public var patternIndex: Int
    public init(id: Int, patternIndex: Int) { self.id = id; self.patternIndex = patternIndex }
}
