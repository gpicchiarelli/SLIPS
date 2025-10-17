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
                
                for joinNode in alphaNode.rightJoinListeners {
                    joinNode.activateFromRight(fact: fact, env: &env)
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
        
        // 3. Gestione speciale per regole EXISTS
        // Quando l'ultimo fatto di un template viene retratto, rimuovi attivazioni EXISTS per quel template
        // Ref: drive.c retract logic per EXISTS
        // Verifica se l'alpha per questo template è ora vuota
        for (ruleName, production) in env.rete.productionNodes {
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
    private static func extractBindings(
        fact: Environment.FactRec,
        pattern: Pattern
    ) -> [String: Value] {
        var bindings: [String: Value] = [:]
        
        for (slot, test) in pattern.slots {
            guard let value = fact.slots[slot] else { continue }
            
            switch test.kind {
            case .variable(let name), .mfVariable(let name):
                bindings[name] = value
            default:
                break
            }
        }
        
        return bindings
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

