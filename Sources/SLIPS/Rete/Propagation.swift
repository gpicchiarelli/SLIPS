// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import Foundation

// MARK: - Propagation Engine (Fase 1, Task 1.3)
// Traduzione fedele da drive.c, factmngr.c (CLIPS 6.4.2)
// Riferimenti C:
// - NetworkAssert (drive.c) → propagateAssert
// - NetworkRetract (drive.c) → propagateRetract
// - DriveRetractions (drive.c) → propagazione retract

/// Gestisce la propagazione di assert/retract attraverso la rete RETE
/// (ref: drive.c in CLIPS)
public enum Propagation {
    
    // MARK: - Assert Propagation
    
    /// Propaga assert di un fatto attraverso la rete
    /// (ref: NetworkAssert in drive.c)
    public static func propagateAssert(
        fact: Environment.FactRec,
        env: inout Environment
    ) {
        if env.watchRete {
            print("[RETE Assert] Propagating fact \(fact.id): (\(fact.name) \(factSlotsToString(fact)))")
        }
        
        let startTime = env.watchReteProfile ? Date() : nil
        var alphaMatches = 0
        var tokensGenerated = 0
        
        // 1. Trova alpha nodes che matchano il fatto
        let matchingAlphaNodes = findMatchingAlphaNodes(fact: fact, env: env)
        alphaMatches = matchingAlphaNodes.count
        
        if env.watchRete {
            print("[RETE Assert]   Matched \(alphaMatches) alpha node(s)")
        }
        
        // 2. Per ogni alpha node, aggiungi fatto alla memoria e propaga
        for alphaNode in matchingAlphaNodes {
            // Aggiungi fact alla memoria alpha
            alphaNode.memory.insert(fact.id)
            
            if env.watchRete {
                print("[RETE Assert]   Alpha '\(alphaNode.pattern.name)': memory size = \(alphaNode.memory.count)")
            }
            
            // 3. Genera token iniziale per questo fatto
            let initialBindings = extractBindings(fact: fact, pattern: alphaNode.pattern)
            let initialToken = BetaToken(
                bindings: initialBindings,
                usedFacts: [fact.id]
            )
            
            tokensGenerated += 1
            
            // 4a. Propaga token attraverso i successori diretti (per root pattern)
            alphaNode.activate(token: initialToken, env: &env)
            
            // 4b. Notifica join nodes che usano questo alpha come rightInput
            // Questo gestisce il caso in cui l'alpha non è il primo pattern
            if !alphaNode.rightJoinListeners.isEmpty {
                if env.watchRete {
                    print("[RETE Assert]   Alpha '\(alphaNode.pattern.name)': notifying \(alphaNode.rightJoinListeners.count) right join listeners")
                }
                
                for weakJoinNode in alphaNode.rightJoinListeners {
                    if let joinNode = weakJoinNode.node {
                        joinNode.activateFromRight(fact: fact, env: &env)
                    }
                }
            }
        }
        
        if let start = startTime, env.watchReteProfile {
            let elapsed = Date().timeIntervalSince(start)
            print("[RETE Profile] Assert propagation: \(alphaMatches) alphas, \(tokensGenerated) tokens in \(elapsed * 1000)ms")
        }
    }
    
    // MARK: - Retract Propagation
    
    /// Propaga retract di un fatto attraverso la rete
    /// (ref: NetworkRetract in drive.c)
    public static func propagateRetract(
        factID: Int,
        factName: String,  // Template name del fatto retratto
        env: inout Environment
    ) {
        if env.watchRete {
            print("[RETE Retract] Retracting fact \(factID)")
        }
        
        let startTime = env.watchReteProfile ? Date() : nil
        var tokensRemoved = 0
        var activationsRemoved = 0
        
        // 1. Rimuovi fatto dalle memorie alpha
        for (_, alphaNode) in env.rete.alphaNodes {
            if alphaNode.memory.contains(factID) {
                alphaNode.memory.remove(factID)
                
                if env.watchRete {
                    print("[RETE Retract]   Removed from alpha '\(alphaNode.pattern.name)'")
                }
            }
        }
        
        // 2. Rimuovi attivazioni dall'agenda che usano questo fatto
        let beforeAgenda = env.agendaQueue.queue.count
        env.agendaQueue.removeByFactID(factID)
        activationsRemoved = beforeAgenda - env.agendaQueue.queue.count
        
        // ✅ Rimuovi token dal beta storage che usano questo fatto
        // Ref: Retract logic in CLIPS C drive.c
        for (ruleName, betaMem) in env.rete.beta {
            let before = betaMem.tokens.count
            env.rete.beta[ruleName]?.tokens.removeAll { token in
                token.usedFacts.contains(factID)
            }
            let removed = before - (env.rete.beta[ruleName]?.tokens.count ?? 0)
            if removed > 0 {
                tokensRemoved += removed
                if env.watchRete {
                    print("[RETE Retract]   Removed \(removed) token(s) from beta[\(ruleName)]")
                }
            }
        }
        
        // 3. Gestione speciale per regole EXISTS
        // Quando l'ultimo fatto di un template viene retratto, rimuovi attivazioni EXISTS per quel template
        // Ref: drive.c retract logic per EXISTS
        // Verifica se l'alpha per questo template è ora vuota
        for (ruleName, _) in env.rete.productionNodes {
            if let rule = env.rules.first(where: { $0.name == ruleName }) {
                // Se la regola ha EXISTS su questo template e l'alpha è vuota, rimuovi attivazione
                for pattern in rule.patterns where pattern.exists && pattern.name == factName {
                    // Verifica se alpha è vuota per questo template
                    if env.rete.alpha.ids(for: pattern.name).isEmpty {
                        // Alpha vuota: EXISTS è falsa, rimuovi attivazione
                        env.agendaQueue.removeByRuleName(ruleName)
                        if env.watchRete {
                            print("[RETE Retract]   Removed EXISTS activation for '\(ruleName)' (alpha empty)")
                        }
                    }
                }
            }
        }
        
        if activationsRemoved > 0 && env.watchRete {
            print("[RETE Retract]   Removed \(activationsRemoved) activation(s) from agenda")
        }
        
        // 4. Per NOT nodes, il retract potrebbe generare NUOVI token
        // (quando un fatto che bloccava un NOT viene rimosso)
        propagateRetractToNotNodes(factID: factID, env: &env)
        
        if let start = startTime, env.watchReteProfile {
            let elapsed = Date().timeIntervalSince(start)
            print("[RETE Profile] Retract propagation: \(tokensRemoved) tokens, \(activationsRemoved) activations in \(elapsed * 1000)ms")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Trova alpha nodes che matchano un fatto
    private static func findMatchingAlphaNodes(
        fact: Environment.FactRec,
        env: Environment
    ) -> [AlphaNodeClass] {
        var matching: [AlphaNodeClass] = []
        
        for (_, alphaNode) in env.rete.alphaNodes {
            // Verifica template name
            if alphaNode.pattern.name != fact.name {
                continue
            }
            
            // Verifica costanti nel pattern
            var matches = true
            for (slot, test) in alphaNode.pattern.slots {
                if case .constant(let expectedValue) = test.kind {
                    if let actualValue = fact.slots[slot] {
                        if actualValue != expectedValue {
                            matches = false
                            break
                        }
                    } else {
                        matches = false
                        break
                    }
                }
            }
            
            if matches {
                matching.append(alphaNode)
            }
        }
        
        return matching
    }
    
    /// Estrae binding da un fatto dato un pattern
    /// Ref: VariablePatternMatch in factrete.c (CLIPS 6.4.2)
    public static func extractBindings(
        fact: Environment.FactRec,
        pattern: Pattern
    ) -> [String: Value] {
        var bindings: [String: Value] = [:]
        
        for (slot, test) in pattern.slots {
            guard let value = fact.slots[slot] else { continue }
            
            switch test.kind {
            case .variable(let name):
                // Single-field variable: bind direttamente
                bindings[name] = value
                
            case .mfVariable(let name):
                // Multifield variable: bind come multifield
                // Se il valore è già multifield, usa quello
                // Altrimenti wrappa in multifield
                if case .multifield = value {
                    bindings[name] = value
                } else {
                    bindings[name] = .multifield([value])
                }
                
            case .sequence(let items):
                // Pattern di sequenza complesso: richiede matching avanzato
                // Ref: VariablePatternMatch in factrete.c
                if case .multifield(let values) = value {
                    // Tenta di matchare la sequenza con backtracking
                    if let seqBindings = matchSequence(items: items, values: values) {
                        bindings.merge(seqBindings) { _, new in new }
                    }
                } else {
                    // Valore singolo: tratta come sequenza di un elemento
                    if let seqBindings = matchSequence(items: items, values: [value]) {
                        bindings.merge(seqBindings) { _, new in new }
                    }
                }
                
            default:
                break
            }
        }
        
        return bindings
    }
    
    /// Match sequenza con backtracking per pattern complessi
    /// Gestisce pattern come: a $?x b $?y c
    /// Ref: VariablePatternMatch in factrete.c (CLIPS 6.4.2)
    private static func matchSequence(
        items: [PatternTest],
        values: [Value]
    ) -> [String: Value]? {
        var bindings: [String: Value] = [:]
        
        // Conta variabili multifield e calcola minimo required
        var mfVarCount = 0
        var minRequired = 0
        for item in items {
            if case .mfVariable = item.kind {
                mfVarCount += 1
            } else {
                minRequired += 1
            }
        }
        
        // Verifica se ci sono abbastanza valori
        guard values.count >= minRequired else {
            return nil
        }
        
        // Algoritmo di backtracking per matchare sequenza
        // Ref: factrete.c:VariablePatternMatch
        return backtrack(
            itemIndex: 0,
            valueIndex: 0,
            items: items,
            values: values,
            bindings: &bindings,
            minRequired: minRequired
        ) ? bindings : nil
    }
    
    /// Backtracking ricorsivo per sequence matching
    /// Ref: factrete.c logic
    private static func backtrack(
        itemIndex: Int,
        valueIndex: Int,
        items: [PatternTest],
        values: [Value],
        bindings: inout [String: Value],
        minRequired: Int
    ) -> Bool {
        // Caso base: tutti gli item processati
        if itemIndex >= items.count {
            // Success se abbiamo consumato tutti i valori
            return valueIndex >= values.count
        }
        
        // Caso base: valori esauriti ma item rimanenti
        if valueIndex >= values.count {
            // Success solo se tutti gli item rimanenti sono mfVariable
            // che possono bindare a lista vuota
            for i in itemIndex..<items.count {
                if case .mfVariable(let name) = items[i].kind {
                    bindings[name] = .multifield([])
                } else {
                    return false
                }
            }
            return true
        }
        
        let currentItem = items[itemIndex]
        
        switch currentItem.kind {
        case .constant(let expectedValue):
            // Costante: deve matchare esattamente
            guard valueIndex < values.count,
                  values[valueIndex] == expectedValue else {
                return false
            }
            return backtrack(
                itemIndex: itemIndex + 1,
                valueIndex: valueIndex + 1,
                items: items,
                values: values,
                bindings: &bindings,
                minRequired: minRequired
            )
            
        case .variable(let name):
            // Variabile single-field: bind un valore
            guard valueIndex < values.count else {
                return false
            }
            let oldBinding = bindings[name]
            bindings[name] = values[valueIndex]
            
            if backtrack(
                itemIndex: itemIndex + 1,
                valueIndex: valueIndex + 1,
                items: items,
                values: values,
                bindings: &bindings,
                minRequired: minRequired
            ) {
                return true
            }
            
            // Backtrack: ripristina binding
            if let old = oldBinding {
                bindings[name] = old
            } else {
                bindings.removeValue(forKey: name)
            }
            return false
            
        case .mfVariable(let name):
            // Variabile multifield: prova tutte le lunghezze possibili
            // Ref: factrete.c - greedy matching con backtracking
            
            // Calcola costanti rimanenti (minimo da lasciare)
            var minToLeave = 0
            for i in (itemIndex + 1)..<items.count {
                if case .mfVariable = items[i].kind {
                    // Altra mfVar, può bindare a 0
                } else {
                    minToLeave += 1
                }
            }
            
            // Massimo che questa mfVar può prendere
            let valuesRemaining = values.count - valueIndex
            let maxCanTake = valuesRemaining - minToLeave
            
            // Prova da lunghezza massima a 0 (greedy first)
            for length in stride(from: maxCanTake, through: 0, by: -1) {
                let oldBinding = bindings[name]
                let taken = Array(values[valueIndex..<(valueIndex + length)])
                bindings[name] = .multifield(taken)
                
                if backtrack(
                    itemIndex: itemIndex + 1,
                    valueIndex: valueIndex + length,
                    items: items,
                    values: values,
                    bindings: &bindings,
                    minRequired: minRequired
                ) {
                    return true
                }
                
                // Backtrack
                if let old = oldBinding {
                    bindings[name] = old
                } else {
                    bindings.removeValue(forKey: name)
                }
            }
            return false
            
        default:
            return false
        }
    }
    
    /// Gestisce propagazione retract per NOT nodes
    /// Un retract può rendere vera una condizione NOT precedentemente falsa
    /// Ref: DriveRetractions in drive.c
    private static func propagateRetractToNotNodes(
        factID: Int,
        env: inout Environment
    ) {
        // TODO: Implementare logica NOT retract secondo drive.c
        // Per ora, la rimozione dalle alpha memories è sufficiente
        // perché i NOT nodes verificano contro alpha memory
        
        if env.watchRete {
            print("[RETE Retract]   NOT node propagation: alpha memories updated")
        }
    }
    
    /// Converte slot di un fatto in stringa per debug
    private static func factSlotsToString(_ fact: Environment.FactRec) -> String {
        let slots = fact.slots.map { "\($0.key) \(valueToString($0.value))" }.joined(separator: " ")
        return slots
    }
    
    /// Converte Value in stringa
    private static func valueToString(_ value: Value) -> String {
        switch value {
        case .int(let i): return "\(i)"
        case .float(let d): return "\(d)"
        case .string(let s): return "\"\(s)\""
        case .symbol(let s): return s
        case .boolean(let b): return b ? "TRUE" : "FALSE"
        case .multifield(let arr): return "(\(arr.map(valueToString).joined(separator: " ")))"
        case .none: return "nil"
        }
    }
}

