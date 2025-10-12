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
            print("[RETE] NetworkAssertLeft: entering join at level \(join.level), leftMemory size=\(join.leftMemory?.count ?? 0)")
        }
        
        // Aggiungi a leftMemory
        ReteUtil.AddToLeftMemory(join, lhsBinds)
        
        // Cerca match nel rightMemory
        var rhsBinds = ReteUtil.GetRightBetaMemory(join, hashValue: lhsBinds.hashValue)
        
        if theEnv.watchRete {
            let rhsCount = join.rightMemory?.count ?? 0
            print("[RETE] NetworkAssertLeft: searching rightMemory (size=\(rhsCount)) for matches with hash=\(lhsBinds.hashValue)")
            
            // DEBUG: Mostra hash dei primi elementi in rightMemory
            if let rightMem = join.rightMemory, rhsCount > 0 {
                for i in 0..<min(3, rightMem.size) {
                    if let pm = rightMem.beta[i] {
                        print("[RETE]   rightMemory[\(i)] hash=\(pm.hashValue)")
                    }
                }
            }
        }
        
        var matchCount = 0
        var compatibleCount = 0
        while let currentRHS = rhsBinds {
            matchCount += 1
            // Verifica compatibilità e crea join
            if isCompatible(lhsBinds, currentRHS, join, &theEnv) {
                compatibleCount += 1
                let newPM = mergePartialMatches(lhsBinds, currentRHS)
                
                if theEnv.watchRete {
                    print("[RETE] NetworkAssertLeft: compatible match found, merged PM has \(newPM.bcount) patterns")
                }
                
                // Propaga attraverso nextLinks
                for link in join.nextLinks {
                    if let targetJoin = link.join {
                        if theEnv.watchRete {
                            print("[RETE] NetworkAssertLeft: propagating to level \(targetJoin.level) via \(link.enterDirection == LHS ? "LHS" : "RHS")")
                        }
                        if link.enterDirection == LHS {
                            NetworkAssertLeft(&theEnv, newPM, targetJoin, operation)
                        } else {
                            NetworkAssertRight(&theEnv, newPM, targetJoin, operation)
                        }
                    }
                }
                
                // Se è terminal, crea attivazione
                if join.nextLinks.isEmpty, let production = join.ruleToActivate {
                    if theEnv.watchRete {
                        print("[RETE] NetworkAssertLeft: TERMINAL - creating activation for '\(production.ruleName)'")
                    }
                    let token = partialMatchToBetaToken(newPM)
                    production.activate(token: token, env: &theEnv)
                }
            }
            
            rhsBinds = currentRHS.nextInMemory
        }
        
        if theEnv.watchRete {
            print("[RETE] NetworkAssertLeft: checked \(matchCount) RHS candidates, \(compatibleCount) compatible")
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
        
        if theEnv.watchRete {
            print("[RETE] EmptyDrive: join level \(join.level) has \(join.nextLinks.count) nextLinks")
        }
        
        if listOfJoins == nil {
            if theEnv.watchRete {
                print("[RETE] EmptyDrive: no nextLinks, checking if terminal")
            }
            
            // Se è terminal (ruleToActivate), crea attivazione
            if let production = join.ruleToActivate {
                if theEnv.watchRete {
                    print("[RETE] EmptyDrive: CREATING ACTIVATION for rule '\(production.ruleName)'")
                }
                // Converti rhsBinds in BetaToken per attivazione
                let token = partialMatchToBetaToken(rhsBinds)
                production.activate(token: token, env: &theEnv)
            } else {
                if theEnv.watchRete {
                    print("[RETE] EmptyDrive: ERROR - no nextLinks AND no ruleToActivate!")
                }
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
            
            // Hash value già calcolato in linker.copy() o CreateEmptyPartialMatch
            // Non sovrascrivere! (In CLIPS C usa leftHash/rightHash functions, qui usiamo hash già presente)
            if theEnv.watchRete {
                print("[RETE] EmptyDrive: linker hash=\(linker.hashValue) for propagation")
            }
            
            // Aggiungi a beta memory e propaga
            if let targetJoin = currentLink.join {
                if theEnv.watchRete {
                    print("[RETE] EmptyDrive: propagating to join level \(targetJoin.level) via \(currentLink.enterDirection == LHS ? "LHS" : "RHS")")
                }
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
        merged.initializeLinks()  // Inizializza i link a nil
        merged.bcount = lhs.bcount + rhs.bcount
        
        // Combina binds
        var allBinds: [GenericMatch] = []
        allBinds.append(contentsOf: lhs.binds)
        allBinds.append(contentsOf: rhs.binds)
        merged.binds = allBinds
        
        // Calcola hash combinato
        var hasher = Hasher()
        for i in 0..<Int(merged.bcount) {
            if let alphaMatch = merged.binds[i].theMatch,
               let entity = alphaMatch.matchingItem {
                hasher.combine(entity.factID)
            }
        }
        merged.hashValue = UInt(bitPattern: hasher.finalize())
        
        return merged
    }
    
    /// Verifica se due PartialMatch sono compatibili per join
    private static func isCompatible(
        _ lhs: PartialMatch,
        _ rhs: PartialMatch,
        _ join: JoinNodeClass,
        _ theEnv: inout Environment
    ) -> Bool {
        // 1. Verifica che non ci siano fact ID duplicati
        // Estrai fact IDs da LHS
        var lhsFactIDs: Set<Int> = []
        for i in 0..<Int(lhs.bcount) {
            if let alphaMatch = lhs.binds[i].theMatch,
               let entity = alphaMatch.matchingItem {
                lhsFactIDs.insert(entity.factID)
            }
        }
        
        // Verifica che RHS non abbia fact duplicati
        var rhsFactIDs: Set<Int> = []
        for i in 0..<Int(rhs.bcount) {
            if let alphaMatch = rhs.binds[i].theMatch,
               let entity = alphaMatch.matchingItem {
                rhsFactIDs.insert(entity.factID)
                if lhsFactIDs.contains(entity.factID) {
                    // Stesso fatto usato due volte - non compatibile
                    if theEnv.watchRete {
                        print("[RETE] isCompatible: FAIL - fact \(entity.factID) appears in both LHS and RHS")
                    }
                    return false
                }
            }
        }
        
        if theEnv.watchRete {
            print("[RETE] isCompatible: OK - LHS facts=\(lhsFactIDs), RHS facts=\(rhsFactIDs)")
        }
        
        // 2. TODO: Applicare join.networkTest se presente
        // Per ora, compatibilità basata solo su fact uniqueness
        
        return true
    }
    
    /// Converte PartialMatch in BetaToken (bridge tra C-style e Swift-style)
    private static func partialMatchToBetaToken(_ pm: PartialMatch) -> BetaToken {
        var bindings: [String: Value] = [:]
        var usedFacts: Set<Int> = []
        
        // Estrai fact IDs da binds[]
        for i in 0..<Int(pm.bcount) {
            if let alphaMatch = pm.binds[i].theMatch,
               let entity = alphaMatch.matchingItem {
                usedFacts.insert(entity.factID)
                
                // Se entity è FactPatternEntity, estrai slot come bindings
                if let factEntity = entity as? FactPatternEntity {
                    let fact = factEntity.fact
                    
                    // Per ogni slot del fatto, crea binding con nome slot
                    // (questo è semplificato - idealmente servirebbe il pattern per nomi variabili)
                    for (slotName, value) in fact.slots {
                        // Usa nome slot come chiave (approssimazione)
                        // In regole reali, il pattern map slotName → varName
                        bindings[slotName] = value
                    }
                }
            }
        }
        
        return BetaToken(bindings: bindings, usedFacts: usedFacts)
    }
}

