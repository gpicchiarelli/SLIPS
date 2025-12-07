// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import Foundation

// MARK: - Bridge tra PartialMatch (C-style) e BetaToken (Swift-style)
// Durante la transizione, manteniamo entrambe le rappresentazioni

/// Adapter per fatto che implementa PatternEntity
public final class FactPatternEntity: PatternEntity {
    public let factID: Int
    public let fact: Environment.FactRec
    
    public init(_ fact: Environment.FactRec) {
        self.factID = fact.id
        self.fact = fact
    }
}

public enum PartialMatchBridge {
    
    /// Crea PartialMatch da BetaToken (Swift → C)
    /// Ref: CreateAlphaMatch in factmch.c - crea partialMatch e lo aggiunge a theFact->list
    public static func createPartialMatch(
        from token: BetaToken,
        env: inout Environment
    ) -> PartialMatch {
        let pm = PartialMatch()
        pm.initializeLinks()
        pm.betaMemory = true
        pm.busy = false
        // Ref: Tracking memoria per PartialMatch (CLIPS usa genalloc)
        MemoryTracking.trackPartialMatch(&env, pm)
        
        // Converti usedFacts in GenericMatch array
        let factIDs = Array(token.usedFacts).sorted()
        pm.bcount = UInt16(factIDs.count)
        
        var binds: [GenericMatch] = []
        for factID in factIDs {
            var gm = GenericMatch()
            
            // Crea AlphaMatch per il fatto
            if let fact = env.facts[factID] {
                let alphaMatch = AlphaMatch()
                let entity = FactPatternEntity(fact)
                alphaMatch.matchingItem = entity
                gm.theMatch = alphaMatch
                // Ref: Tracking memoria per AlphaMatch (CLIPS usa genalloc)
                MemoryTracking.trackAlphaMatch(&env, alphaMatch)
                
                // ✅ CRITICO: Aggiungi questo PartialMatch alla lista del fatto
                // Ref: factmch.c:576-580 - aggiunge patternMatch a theFact->list
                // Questo permette a NetworkRetract di trovare tutti i PartialMatch associati
                if env.factPartialMatches[factID] == nil {
                    env.factPartialMatches[factID] = []
                }
                env.factPartialMatches[factID]?.append(pm)
            }
            
            binds.append(gm)
        }
        pm.binds = binds
        
        // Calcola hash value basato sui fact IDs
        var hasher = Hasher()
        for factID in factIDs {
            hasher.combine(factID)
        }
        pm.hashValue = UInt(bitPattern: hasher.finalize())
        
        return pm
    }
    
    /// Crea BetaToken da PartialMatch (C → Swift)
    public static func createBetaToken(
        from pm: PartialMatch,
        bindings: [String: Value]
    ) -> BetaToken {
        var usedFacts: Set<Int> = []
        
        // Estrai fact IDs dai binds
        for i in 0..<Int(pm.bcount) {
            if let alphaMatch = pm.binds[i].theMatch,
               let entity = alphaMatch.matchingItem {
                usedFacts.insert(entity.factID)
            }
        }
        
        return BetaToken(bindings: bindings, usedFacts: usedFacts)
    }
    
    /// Estrae bindings da PartialMatch (richiede context della regola per nomi variabili)
    public static func extractBindings(
        from pm: PartialMatch,
        rule: Rule,
        env: Environment
    ) -> [String: Value] {
        var bindings: [String: Value] = [:]
        
        // Per ogni pattern nella regola, estrai binding dal corrispondente fact
        for (patternIndex, pattern) in rule.patterns.enumerated() {
            guard patternIndex < Int(pm.bcount) else { break }
            
            if let alphaMatch = pm.binds[patternIndex].theMatch,
               let entity = alphaMatch.matchingItem as? FactPatternEntity {
                let fact = entity.fact
                
                // Estrai variabili dal pattern
                for (slot, test) in pattern.slots {
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
        
        return bindings
    }
}

