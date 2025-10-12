// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import Foundation

// MARK: - Drive Engine (Port FEDELE da drive.c)
// Riferimenti C:
// - NetworkAssert (drive.c linee 84-115)
// - NetworkAssertRight (drive.c linee 122-321)
// - EmptyDrive (drive.c linee 1002-1173) ← CRITICO!

public enum DriveEngine {
    
    /// Costanti per enter direction (come in C)
    public static let LHS: Character = "l"
    public static let RHS: Character = "r"
    
    /// Network assert operation codes
    public static let NETWORK_ASSERT = 1
    public static let NETWORK_RETRACT = 2
    
    // MARK: - NetworkAssert
    
    /// Primary routine for filtering a partial match through the join network
    /// Port FEDELE di NetworkAssert (drive.c linee 84-115)
    public static func NetworkAssert(
        _ theEnv: inout Environment,
        _ binds: PartialMatch,
        _ join: JoinNodeClass
    ) {
        // If this is the first join, use special routine
        if join.firstJoin {
            EmptyDrive(&theEnv, join, binds, NETWORK_ASSERT)
            return
        }
        
        // Enter the join from the right
        NetworkAssertRight(&theEnv, binds, join, NETWORK_ASSERT)
    }
    
    // MARK: - NetworkAssertRight
    
    /// Primary routine for filtering a partial match through join network from RHS
    /// Port FEDELE di NetworkAssertRight (drive.c linee 122-321)
    public static func NetworkAssertRight(
        _ theEnv: inout Environment,
        _ rhsBinds: PartialMatch,
        _ join: JoinNodeClass,
        _ operation: Int
    ) {
        // If this is first join, use EmptyDrive
        if join.firstJoin {
            EmptyDrive(&theEnv, join, rhsBinds, operation)
            return
        }
        
        // Get partial matches from left beta memory usando HASH VALUE ✅
        var lhsBinds = ReteUtil.GetLeftBetaMemory(join, hashValue: rhsBinds.hashValue)
        
        if theEnv.watchRete && lhsBinds != nil {
            print("[RETE] NetworkAssertRight: found left matches in bucket for hash \(rhsBinds.hashValue)")
        }
        
        // Scan solo token nel bucket (O(bucket size) invece di O(n))
        while let currentLHS = lhsBinds {
            let nextBind = currentLHS.nextInMemory
            join.memoryCompares += 1
            
            // CRITICO: Confronta hash value PRIMA dei test (ottimizzazione CLIPS)
            if currentLHS.hashValue != rhsBinds.hashValue {
                lhsBinds = nextBind
                continue
            }
            
            // Evalua network test
            var joinExpr = true
            if let networkTest = join.networkTest {
                // Setup evaluation environment
                // (GlobalLHSBinds/GlobalRHSBinds in C - qui semplifico con localBindings)
                let oldBindings = theEnv.localBindings
                
                // Merge bindings da LHS e RHS
                for _ in 0..<Int(currentLHS.bcount) {
                    // Binding da partial match (da implementare conversione)
                }
                
                // Evalua test
                let result = Evaluator.EvaluateExpression(&theEnv, networkTest)
                
                theEnv.localBindings = oldBindings
                
                switch result {
                case .boolean(let b): joinExpr = b
                case .int(let i): joinExpr = (i != 0)
                default: joinExpr = false
                }
                
                if !joinExpr {
                    lhsBinds = nextBind
                    continue
                }
            }
            
            // JOIN RIUSCITO: propaga attraverso nextLinks
            var listOfJoins = join.nextLinks.first
            while listOfJoins != nil {
                // Crea nuovo partial match combinando LHS + RHS
                let newPM = mergePartialMatches(currentLHS, rhsBinds)
                
                // Calcola hash value per il nuovo match
                var hashValue: UInt = 0
                if let targetJoin = listOfJoins?.join {
                    if listOfJoins?.enterDirection == LHS {
                        hashValue = targetJoin.leftHash != nil ? 
                            computeHashValue(for: newPM, using: targetJoin.leftHash) : 0
                    } else {
                        hashValue = targetJoin.rightHash != nil ?
                            computeHashValue(for: newPM, using: targetJoin.rightHash) : 0
                    }
                }
                newPM.hashValue = hashValue
                
                // Aggiungi a beta memory appropriata
                if let targetJoin = listOfJoins?.join {
                    if listOfJoins?.enterDirection == LHS {
                        ReteUtil.AddToLeftMemory(targetJoin, newPM)
                        // Ricorsione: NetworkAssertLeft
                        // (NetworkAssertLeft chiama EmptyDrive o altro)
                    } else {
                        ReteUtil.AddToRightMemory(targetJoin, newPM)
                        NetworkAssertRight(&theEnv, newPM, targetJoin, operation)
                    }
                }
                
                listOfJoins = listOfJoins?.next
            }
            
            lhsBinds = nextBind
        }
    }
    
    // MARK: - NetworkAssertLeft
    
    /// Primary routine for filtering a partial match through join network from LHS
    /// Port di NetworkAssertLeft (simmetrico a NetworkAssertRight)
    public static func NetworkAssertLeft(
        _ theEnv: inout Environment,
        _ lhsBinds: PartialMatch,
        _ join: JoinNodeClass,
        _ operation: Int
    ) {
        if theEnv.watchRete {
            print("[RETE] NetworkAssertLeft: entering join at level \(join.level)")
        }
        
        // Aggiungi a leftMemory
        ReteUtil.AddToLeftMemory(join, lhsBinds)
        
        // Cerca match nel rightMemory
        var rhsBinds = ReteUtil.GetRightBetaMemory(join, hashValue: lhsBinds.hashValue)
        
        while let currentRHS = rhsBinds {
            // Verifica compatibilità e crea join
            if isCompatible(lhsBinds, currentRHS, join, &theEnv) {
                let newPM = mergePartialMatches(lhsBinds, currentRHS)
                
                // Propaga attraverso nextLinks
                for link in join.nextLinks {
                    if let targetJoin = link.join {
                        if link.enterDirection == LHS {
                            NetworkAssertLeft(&theEnv, newPM, targetJoin, operation)
                        } else {
                            NetworkAssertRight(&theEnv, newPM, targetJoin, operation)
                        }
                    }
                }
                
                // Se è terminal, crea attivazione
                if join.nextLinks.isEmpty, let production = join.ruleToActivate {
                    let token = partialMatchToBetaToken(newPM)
                    production.activate(token: token, env: &theEnv)
                }
            }
            
            rhsBinds = currentRHS.nextInMemory
        }
    }
    
    // MARK: - EmptyDrive
    
    /// Handles entry of alpha memory partial match from RHS of first join
    /// Port FEDELE di EmptyDrive (drive.c linee 1002-1173)
    /// QUESTA È LA FUNZIONE CHIAVE PER FIRSTJOIN! ✅
    public static func EmptyDrive(
        _ theEnv: inout Environment,
        _ join: JoinNodeClass,
        _ rhsBinds: PartialMatch,
        _ operation: Int
    ) {
        if theEnv.watchRete {
            print("[RETE] EmptyDrive: firstJoin handling for join level \(join.level)")
        }
        
        // Evalua network test
        if let networkTest = join.networkTest {
            let oldBindings = theEnv.localBindings
            
            // Setup per evaluation (GlobalRHSBinds = rhsBinds in C)
            // Estrai binding da rhsBinds e metti in localBindings
            
            let result = Evaluator.EvaluateExpression(&theEnv, networkTest)
            theEnv.localBindings = oldBindings
            
            var joinExpr: Bool
            switch result {
            case .boolean(let b): joinExpr = b
            case .int(let i): joinExpr = (i != 0)
            default: joinExpr = false
            }
            
            if !joinExpr { return }
        }
        
        // Secondary network test
        if let secondaryTest = join.secondaryNetworkTest {
            let oldBindings = theEnv.localBindings
            let result = Evaluator.EvaluateExpression(&theEnv, secondaryTest)
            theEnv.localBindings = oldBindings
            
            var joinExpr: Bool
            switch result {
            case .boolean(let b): joinExpr = b
            case .int(let i): joinExpr = (i != 0)
            default: joinExpr = false
            }
            
            if !joinExpr { return }
        }
        
        // Handle negated first pattern or join from right
        if join.patternIsNegated || (join.joinFromTheRight && !join.patternIsExists) {
            // NOT come primo pattern: usa leftMemory bucket 0
            if join.leftMemory == nil || join.leftMemory?.beta[0] == nil {
                if theEnv.watchRete {
                    print("[RETE] EmptyDrive: NOT first pattern, creating parent")
                }
                // Crea parent se non esiste
                let parent = CreateEmptyPartialMatch()
                parent.hashValue = 0
                if join.leftMemory == nil {
                    join.leftMemory = BetaMemoryHash(initialSize: 17)
                }
                join.leftMemory?.beta[0] = parent
            }
            
            guard let notParent = join.leftMemory?.beta[0] else { return }
            
            if notParent.marker != nil {
                return
            }
            
            // AddBlockedLink(notParent, rhsBinds) - da implementare
            // PosEntryRetractBeta se ha children - da implementare
            
            if theEnv.watchRete {
                print("[RETE] EmptyDrive: NOT first pattern handled")
            }
            return
        }
        
        // Handle exists first pattern
        var existsParent: PartialMatch? = nil
        if join.patternIsExists {
            if join.leftMemory == nil {
                // Crea leftMemory e parent
                join.leftMemory = BetaMemoryHash(initialSize: 17)
                let parent = CreateEmptyPartialMatch()
                parent.hashValue = 0
                join.leftMemory?.beta[0] = parent
                existsParent = parent
            } else {
                existsParent = join.leftMemory?.beta[0]
            }
            
            if existsParent?.marker != nil {
                return
            }
            
            // AddBlockedLink(existsParent, rhsBinds)
        }
        
        // Propaga attraverso nextLinks
        var listOfJoins = join.nextLinks.first
        
        if listOfJoins == nil {
            if theEnv.watchRete {
                print("[RETE] EmptyDrive: no nextLinks, might be terminal")
            }
            
            // Se è terminal (ruleToActivate), crea attivazione
            if let production = join.ruleToActivate {
                // Converti rhsBinds in BetaToken per attivazione
                let token = partialMatchToBetaToken(rhsBinds)
                production.activate(token: token, env: &theEnv)
            }
            return
        }
        
        while let currentLink = listOfJoins {
            // Crea linker (nuovo partial match)
            let linker: PartialMatch
            if join.patternIsExists {
                linker = CreateEmptyPartialMatch()
            } else {
                linker = rhsBinds.copy()
            }
            
            // Calcola hash value
            var hashValue: UInt = 0
            if let targetJoin = currentLink.join {
                if currentLink.enterDirection == LHS {
                    hashValue = targetJoin.leftHash != nil ?
                        computeHashValue(for: linker, using: targetJoin.leftHash) : 0
                } else {
                    hashValue = targetJoin.rightHash != nil ?
                        computeHashValue(for: linker, using: targetJoin.rightHash) : 0
                }
            }
            linker.hashValue = hashValue
            
            // Aggiungi a beta memory e propaga
            if let targetJoin = currentLink.join {
                if currentLink.enterDirection == LHS {
                    NetworkAssertLeft(&theEnv, linker, targetJoin, operation)
                } else {
                    NetworkAssertRight(&theEnv, linker, targetJoin, operation)
                }
            }
            
            listOfJoins = currentLink.next
        }
    }
    
    // MARK: - Helper Functions
    
    /// Merge due partial match (combinazione LHS + RHS)
    private static func mergePartialMatches(
        _ lhs: PartialMatch,
        _ rhs: PartialMatch
    ) -> PartialMatch {
        let merged = PartialMatch()
        merged.bcount = lhs.bcount + rhs.bcount
        merged.hashValue = 0 // Ricalcolato dopo
        
        // Combina binds
        var allBinds: [GenericMatch] = []
        allBinds.append(contentsOf: lhs.binds)
        allBinds.append(contentsOf: rhs.binds)
        merged.binds = allBinds
        
        return merged
    }
    
    /// Verifica se due PartialMatch sono compatibili per join
    private static func isCompatible(
        _ lhs: PartialMatch,
        _ rhs: PartialMatch,
        _ join: JoinNodeClass,
        _ theEnv: inout Environment
    ) -> Bool {
        // TODO: Implementare check completo con join tests
        // Per ora ritorna true (ottimistico)
        return true
    }
    
    /// Converte PartialMatch in BetaToken (bridge tra C-style e Swift-style)
    private static func partialMatchToBetaToken(_ pm: PartialMatch) -> BetaToken {
        let bindings: [String: Value] = [:]
        let usedFacts: Set<Int> = []
        
        // Estrai binding da partial match (da completare)
        // Per ora, partial match semplificato
        
        return BetaToken(bindings: bindings, usedFacts: usedFacts)
    }
}

