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
/// Esegue join tra token beta (left) e fatti alpha (right)
/// (ref: struct joinNode in network.h, PerformJoin in drive.c)
public final class JoinNodeClass: ReteNode {
    public let id: UUID
    public let level: Int
    /// Input sinistro: nodo beta precedente
    public let leftInput: ReteNode
    /// Input destro: alpha node con fatti candidati
    public let rightInput: AlphaNodeClass
    /// Variabili di join (vincoli di consistenza tra left e right)
    public let joinKeys: Set<String>
    /// Test constraints addizionali da valutare dopo join
    public let tests: [ExpressionNode]
    /// Nodi successori nella catena
    public var successors: [ReteNode] = []
    
    public init(
        left: ReteNode,
        right: AlphaNodeClass,
        keys: Set<String>,
        tests: [ExpressionNode],
        level: Int
    ) {
        self.id = UUID()
        self.level = level
        self.leftInput = left
        self.rightInput = right
        self.joinKeys = keys
        self.tests = tests
    }
    
    /// Attiva join: combina token con fatti dalla memoria alpha
    /// (ref: PerformJoin in drive.c)
    public func activate(token: BetaToken, env: inout Environment) {
        if env.watchRete {
            print("[RETE] JoinNode activate: level=\(level), rightAlpha=\(rightInput.memory.count) facts")
        }
        
        let startTime = env.watchReteProfile ? Date() : nil
        var joinCount = 0
        
        // Join con tutti i fatti nella memoria alpha destra
        for factID in rightInput.memory {
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
        guard rightFact.name == rightInput.pattern.name else {
            return nil
        }
        
        var newBindings = leftToken.bindings
        
        // Verifica consistenza join keys e estrai nuovi binding
        for (slot, test) in rightInput.pattern.slots {
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
    /// Fa join del fatto con tutti i token nella memoria beta sinistra
    /// (ref: PosEntryDrive in drive.c - right-side activation)
    public func activateFromRight(fact: Environment.FactRec, env: inout Environment) {
        // Ottieni token dalla memoria beta del left input
        let leftTokens = getLeftTokens(env: env)
        
        // Per ogni token sinistro, tenta join con il fatto destro
        for leftToken in leftTokens {
            if leftToken.usedFacts.contains(fact.id) {
                continue
            }
            
            if let newToken = attemptJoin(
                leftToken: leftToken,
                rightFact: fact,
                env: &env
            ) {
                // Propaga nuovo token ai successori
                for successor in successors {
                    successor.activate(token: newToken, env: &env)
                }
            }
        }
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
        let hash = BetaEngine.tokenKeyHash64(token)
        
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
public final class ExistsNodeClass: ReteNode {
    public let id: UUID
    public let level: Int
    public let pattern: Pattern
    /// Alpha node per trovare fatti candidati
    public let alphaNode: AlphaNodeClass
    public var successors: [ReteNode] = []
    
    public init(
        pattern: Pattern,
        alphaNode: AlphaNodeClass,
        level: Int
    ) {
        self.id = UUID()
        self.level = level
        self.pattern = pattern
        self.alphaNode = alphaNode
    }
    
    /// Attiva: propaga token se EXISTS condition è vera
    /// (ref: EvaluateSecondaryNetworkTest in drive.c)
    public func activate(token: BetaToken, env: inout Environment) {
        if env.watchRete {
            print("[RETE] ExistsNode activate: level=\(level), checking \(alphaNode.memory.count) facts")
        }
        
        // Cerca almeno un fatto che matcha
        var foundMatch = false
        
        for factID in alphaNode.memory {
            guard let fact = env.facts[factID] else { continue }
            
            // Per EXISTS unario senza vincoli, basta che esista un fatto del template
            if pattern.slots.isEmpty {
                foundMatch = true
                break
            }
            
            // Altrimenti verifica match con binding
            if matchesPattern(fact: fact, bindings: token.bindings, env: &env) {
                foundMatch = true
                break
            }
        }
        
        // Propaga solo se EXISTS trovato
        if foundMatch {
            for successor in successors {
                successor.activate(token: token, env: &env)
            }
        }
    }
    
    private func matchesPattern(
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
                break
            }
        }
        
        return true
    }
}

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
        var activation = Activation(
            priority: salience,
            ruleName: ruleName,
            bindings: token.bindings
        )
        activation.factIDs = token.usedFacts
        
        // Aggiungi solo se non già presente (deduplica)
        if !env.agendaQueue.contains(activation) {
            env.agendaQueue.add(activation)
            
            if env.watchRules {
                print("==> Activation \(ruleName) : salience \(salience)")
            }
            if env.watchRete {
                print("[RETE] ProductionNode: created activation for \(ruleName)")
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
