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
    
    // MARK: - NetworkRetract
    
    /// Primary routine for processing retraction of a fact through the join network
    /// Port FEDELE di NetworkRetract (retract.c linee 90-121)
    /// Viene chiamato per ogni patternMatch che usa il fatto retratto
    public static func NetworkRetract(
        _ theEnv: inout Environment,
        _ factID: Int
    ) {
        if theEnv.watchRete {
            print("[RETE] NetworkRetract: processing retract for fact \(factID)")
        }
        
        // ✅ CRITICO: Trova tutti i PartialMatch che usano questo fatto
        // Ref: retract.c:690 - NetworkRetract viene chiamato con patternMatch list dal fatto
        // Nel nostro caso, cerchiamo in tutte le beta memory (leftMemory e rightMemory) di tutti i join nodes
        // perché i PartialMatch possono essere creati in vari punti della rete
        var matchesToRetract: [PartialMatch] = []
        
        // Cerca in tutti i join nodes, sia leftMemory che rightMemory
        for join in theEnv.rete.joinNodes {
            // Cerca in rightMemory
            if let rightMem = join.rightMemory {
                for i in 0..<rightMem.size {
                    var pm = rightMem.beta[i]
                    while let currentPM = pm {
                        let nextPM = currentPM.nextInMemory
                        
                        // Verifica se questo PartialMatch usa il fatto retratto
                        for j in 0..<Int(currentPM.bcount) {
                            if let alphaMatch = currentPM.binds[j].theMatch,
                               let entity = alphaMatch.matchingItem as? FactPatternEntity {
                                if entity.factID == factID {
                                    matchesToRetract.append(currentPM)
                                    break
                                }
                            }
                        }
                        
                        pm = nextPM
                    }
                }
            }
            
            // Cerca in leftMemory
            if let leftMem = join.leftMemory {
                for i in 0..<leftMem.size {
                    var pm = leftMem.beta[i]
                    while let currentPM = pm {
                        let nextPM = currentPM.nextInMemory
                        
                        // Verifica se questo PartialMatch usa il fatto retratto
                        for j in 0..<Int(currentPM.bcount) {
                            if let alphaMatch = currentPM.binds[j].theMatch,
                               let entity = alphaMatch.matchingItem as? FactPatternEntity {
                                if entity.factID == factID {
                                    matchesToRetract.append(currentPM)
                                    break
                                }
                            }
                        }
                        
                        pm = nextPM
                    }
                }
            }
        }
        
        if theEnv.watchRete {
            print("[RETE] NetworkRetract: found \(matchesToRetract.count) PartialMatch(es) using fact \(factID)")
            for (i, pm) in matchesToRetract.enumerated() {
                print("  PM[\(i)]: bcount=\(pm.bcount), hash=\(pm.hashValue), owner=\(pm.owner != nil ? "\(type(of: pm.owner!))" : "nil")")
                print("    deleting=\(pm.deleting), children=\(pm.children != nil ? "present" : "nil")")
                for j in 0..<Int(pm.bcount) {
                    if let alphaMatch = pm.binds[j].theMatch,
                       let entity = alphaMatch.matchingItem as? FactPatternEntity {
                        print("    binds[\(j)]: factID=\(entity.factID)")
                    }
                }
            }
        }
        
        // Propaga retract per ogni PartialMatch trovato
        // Ref: retract.c:96-120 - itera attraverso patternMatch e chiama PosEntryRetractAlpha/NegEntryRetractAlpha
        for (index, alphaMatch) in matchesToRetract.enumerated() {
            // Verifica se è già stato processato o se è deleting
            if alphaMatch.deleting {
                if theEnv.watchRete {
                    print("[RETE] NetworkRetract: PM[\(index)] already deleting, skipping")
                }
                continue
            }
            
            if theEnv.watchRete {
                print("[RETE] NetworkRetract: processing PM[\(index)]")
            }
            
            alphaMatch.deleting = true
            
            // ✅ CRITICO: Se questo PartialMatch è in un join terminale, rimuovi attivazione direttamente
            // Trova il join node che possiede questo PartialMatch
            if let joinOwner = alphaMatch.owner as? JoinNodeClass,
               let production = joinOwner.ruleToActivate {
                // Estrai fact IDs dal PartialMatch
                var factIDs: Set<Int> = []
                for i in 0..<Int(alphaMatch.bcount) {
                    if let alphaMatch = alphaMatch.binds[i].theMatch,
                       let entity = alphaMatch.matchingItem as? FactPatternEntity {
                        factIDs.insert(entity.factID)
                    }
                }
                
                // ✅ USA marker per trovare e rimuovere l'attivazione specifica
                let factIDsKey = Array(factIDs).sorted().map { String($0) }.joined(separator: ",")
                let activationKey = "\(production.ruleName):\(factIDsKey)"
                if let _ = theEnv.activationToPartialMatch[activationKey] {
                    theEnv.agendaQueue.removeByFactID(factIDs.first ?? -1)
                    theEnv.activationToPartialMatch.removeValue(forKey: activationKey)
                    
                    if theEnv.watchRete {
                        print("[RETE] NetworkRetract: removed terminal activation for '\(production.ruleName)' using marker")
                    }
                } else {
                    // Fallback
                    for fid in factIDs {
                        theEnv.agendaQueue.removeByFactID(fid)
                    }
                    if theEnv.watchRete {
                        print("[RETE] NetworkRetract: removed terminal activation for '\(production.ruleName)' (fallback)")
                    }
                }
            }
            
            // Propaga attraverso children (beta matches)
            if let children = alphaMatch.children {
                if theEnv.watchRete {
                    print("[RETE] NetworkRetract: PM[\(index)] has children, calling PosEntryRetractAlpha")
                    var childCount = 0
                    var child: PartialMatch? = children
                    while let currentChild = child {
                        childCount += 1
                        child = currentChild.nextLeftChild ?? currentChild.nextRightChild
                    }
                    print("  Children count: \(childCount)")
                }
                PosEntryRetractAlpha(&theEnv, alphaMatch, NETWORK_RETRACT)
            } else {
                if theEnv.watchRete {
                    print("[RETE] NetworkRetract: PM[\(index)] has NO children")
                }
            }
            
            // Gestione NOT/EXISTS (blockList)
            if alphaMatch.blockList != nil {
                // TODO: Implementare NegEntryRetractAlpha
                // Per ora, gestiamo solo positivi
            }
        }
        
        // Pulisci il tracking (se presente)
        theEnv.factPartialMatches.removeValue(forKey: factID)
    }
    
    /// Propaga retract attraverso join nodes per partial match positivo
    /// Port FEDELE di PosEntryRetractAlpha (retract.c linee 126-162)
    private static func PosEntryRetractAlpha(
        _ theEnv: inout Environment,
        _ alphaMatch: PartialMatch,
        _ operation: Int
    ) {
        if theEnv.watchRete {
            print("[RETE] PosEntryRetractAlpha: starting with alphaMatch (bcount=\(alphaMatch.bcount))")
        }
        var betaMatch = alphaMatch.children
        var betaIndex = 0
        
        while let currentBeta = betaMatch {
            if theEnv.watchRete {
                print("[RETE] PosEntryRetractAlpha: processing betaMatch[\(betaIndex)] (bcount=\(currentBeta.bcount), owner=\(currentBeta.owner != nil ? "\(type(of: currentBeta.owner!))" : "nil"))")
            }
            
            guard let joinPtr = currentBeta.owner as? JoinNodeClass else {
                if theEnv.watchRete {
                    print("[RETE] PosEntryRetractAlpha: betaMatch[\(betaIndex)] owner is not JoinNodeClass, skipping")
                }
                betaMatch = currentBeta.nextLeftChild ?? currentBeta.nextRightChild
                betaIndex += 1
                continue
            }
            
            if theEnv.watchRete {
                print("  Join level=\(joinPtr.level), ruleToActivate=\(joinPtr.ruleToActivate?.ruleName ?? "nil")")
            }
            
            // Propaga retract ai children
            if currentBeta.children != nil {
                PosEntryRetractBeta(&theEnv, currentBeta, currentBeta.children!, operation)
            }
            
            // Gestione NOT/EXISTS (blockList)
            if currentBeta.blockList != nil {
                // TODO: Implementare NegEntryRetractAlpha
                // Per ora, gestiamo solo positivi
            }
            
            // Rimuovi attivazione se questo è un terminal join
            // Ref: retract.c:147-149 - RemoveActivation se marker != NULL
            if let production = joinPtr.ruleToActivate {
                // Estrai fact IDs dal PartialMatch
                var factIDs: Set<Int> = []
                for i in 0..<Int(currentBeta.bcount) {
                    if let alphaMatch = currentBeta.binds[i].theMatch,
                       let entity = alphaMatch.matchingItem as? FactPatternEntity {
                        factIDs.insert(entity.factID)
                    }
                }
                
                // ✅ USA marker per trovare e rimuovere l'attivazione specifica
                // Ref: retract.c:147-149 - RemoveActivation(theEnv, (struct activation *) betaMatch->marker, true, true)
                let factIDsKey = Array(factIDs).sorted().map { String($0) }.joined(separator: ",")
                let activationKey = "\(production.ruleName):\(factIDsKey)"
                
                if theEnv.watchRete {
                    print("    Trying to remove activation with key: '\(activationKey)'")
                    print("    Available keys in activationToPartialMatch:")
                    for key in theEnv.activationToPartialMatch.keys.sorted() {
                        print("      - \(key)")
                    }
                    print("    Agenda before removal: \(theEnv.agendaQueue.queue.count) activations")
                    for (i, act) in theEnv.agendaQueue.queue.enumerated() {
                        print("      Act[\(i)]: rule='\(act.ruleName)', factIDs=\(act.factIDs)")
                    }
                }
                
                if let _ = theEnv.activationToPartialMatch[activationKey] {
                    // Rimuovi attivazione usando factIDs
                    let beforeCount = theEnv.agendaQueue.queue.count
                    for fid in factIDs {
                        theEnv.agendaQueue.removeByFactID(fid)
                    }
                    let afterCount = theEnv.agendaQueue.queue.count
                    theEnv.activationToPartialMatch.removeValue(forKey: activationKey)
                    
                    if theEnv.watchRete {
                        print("    ✅ Removed activation using marker: \(beforeCount) -> \(afterCount) activations")
                    }
                } else {
                    // Fallback: rimuovi tutte le attivazioni che usano questi fatti
                    let beforeCount = theEnv.agendaQueue.queue.count
                    for fid in factIDs {
                        theEnv.agendaQueue.removeByFactID(fid)
                    }
                    let afterCount = theEnv.agendaQueue.queue.count
                    
                    if theEnv.watchRete {
                        print("    ⚠️  Marker not found, using fallback: \(beforeCount) -> \(afterCount) activations")
                    }
                }
            }
            
            // Salva next prima di unlink
            let tempMatch = currentBeta.nextRightChild ?? currentBeta.nextLeftChild
            
            if theEnv.watchRete {
                print("  Removing betaMatch[\(betaIndex)] from beta memory (rhsMemory=\(currentBeta.rhsMemory))")
            }
            
            // Rimuovi dalla beta memory
            if currentBeta.rhsMemory {
                ReteUtil.RemoveFromRightMemory(joinPtr, currentBeta)
            } else {
                ReteUtil.RemoveFromLeftMemory(joinPtr, currentBeta)
            }
            
            betaMatch = tempMatch
            betaIndex += 1
        }
        
        if theEnv.watchRete {
            print("[RETE] PosEntryRetractAlpha: completed, processed \(betaIndex) beta matches")
        }
    }
    
    /// Propaga retract attraverso join nodes per partial match beta
    /// Port FEDELE di PosEntryRetractBeta (retract.c linee 194-256)
    private static func PosEntryRetractBeta(
        _ theEnv: inout Environment,
        _ parentPM: PartialMatch,
        _ childPM: PartialMatch?,
        _ operation: Int
    ) {
        var currentChild = childPM
        
        while let child = currentChild {
            guard let joinPtr = child.owner as? JoinNodeClass else {
                currentChild = child.nextLeftChild ?? child.nextRightChild
                continue
            }
            
            // Propaga ricorsivamente
            if child.children != nil {
                PosEntryRetractBeta(&theEnv, child, child.children!, operation)
            }
            
            // Gestione NOT/EXISTS
            if child.blockList != nil {
                // TODO: Implementare NegEntryRetractBeta
            }
            
            // Rimuovi attivazione se terminal
            // Ref: retract.c:284-286 - RemoveActivation se marker != NULL
            if let production = joinPtr.ruleToActivate {
                // Estrai fact IDs dal PartialMatch
                var factIDs: Set<Int> = []
                for i in 0..<Int(child.bcount) {
                    if let alphaMatch = child.binds[i].theMatch,
                       let entity = alphaMatch.matchingItem as? FactPatternEntity {
                        factIDs.insert(entity.factID)
                    }
                }
                
                // ✅ USA marker per trovare e rimuovere l'attivazione specifica
                let factIDsKey = Array(factIDs).sorted().map { String($0) }.joined(separator: ",")
                let activationKey = "\(production.ruleName):\(factIDsKey)"
                if let _ = theEnv.activationToPartialMatch[activationKey] {
                    theEnv.agendaQueue.removeByFactID(factIDs.first ?? -1)
                    theEnv.activationToPartialMatch.removeValue(forKey: activationKey)
                    
                    if theEnv.watchRete {
                        print("[RETE] PosEntryRetractBeta: removed activation for '\(production.ruleName)' using marker")
                    }
                } else {
                    // Fallback
                    for fid in factIDs {
                        theEnv.agendaQueue.removeByFactID(fid)
                    }
                    if theEnv.watchRete {
                        print("[RETE] PosEntryRetractBeta: removed activation(s) for '\(production.ruleName)' (fallback)")
                    }
                }
            }
            
            // Salva next
            let tempChild = child.nextLeftChild ?? child.nextRightChild
            
            // Rimuovi dalla beta memory
            if child.rhsMemory {
                ReteUtil.RemoveFromRightMemory(joinPtr, child)
            } else {
                ReteUtil.RemoveFromLeftMemory(joinPtr, child)
            }
            
            currentChild = tempChild
        }
    }
    
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
    
    /// PPDrive: propaga partial match attraverso nextLinks del join
    /// Port FEDELE di PPDrive (drive.c:902-971)
    /// NOTA: PPDrive propaga ai nextLinks, non gestisce direttamente il join passato.
    /// Se il join passato è terminale, dovrebbe essere gestito da NetworkAssertLeft/Right prima di chiamare PPDrive.
    public static func PPDrive(
        _ theEnv: inout Environment,
        _ lhsBinds: PartialMatch,
        _ rhsBinds: PartialMatch?,  // NULL per EXISTS
        _ join: JoinNodeClass,
        _ operation: Int
    ) {
        // Ref: drive.c linea 917-918
        // Nel C, PPDrive fa return se listOfJoins == NULL
        // IMPORTANTE: PPDrive NON dovrebbe gestire il caso terminale direttamente,
        // perché NetworkAssertLeft/Right vengono chiamati PRIMA e gestiscono già quel caso.
        // Se arriviamo qui con un join terminale, significa che è stato chiamato da
        // NetworkAssertLeft/Right che NON ha gestito il caso terminale (non dovrebbe succedere),
        // oppure è stato chiamato direttamente da EmptyDrive per EXISTS/NOT.
        guard let firstLink = join.nextLinks.first?.link else {
            // ✅ ATTENZIONE: Se il join è terminale, NetworkAssertLeft/Right dovrebbero
            // aver già gestito questo caso e fatto return. Se arriviamo qui, potrebbe
            // essere un errore o un caso speciale (EXISTS/NOT chiamato direttamente).
            // Per sicurezza, gestiamo il caso ma solo se non è già stato gestito.
            // 
            // Tuttavia, per evitare duplicazioni, NON creiamo attivazioni qui se
            // NetworkAssertLeft/Right sono già stati chiamati. Lasciamo che gestiscano
            // loro il caso terminale.
            //
            // REF: Nel codice C, PPDrive semplicemente fa return se nextLinks è NULL.
            // Il caso terminale viene gestito da NetworkAssertLeft/Right PRIMA di chiamare PPDrive.
            if theEnv.watchRete {
                if join.ruleToActivate != nil {
                    print("[RETE] PPDrive: WARNING - join is TERMINAL but no nextLinks (should have been handled by NetworkAssertLeft/Right)")
                }
            }
            return
        }
        
        var listOfJoins: JoinLink? = firstLink
        
        while let currentLink = listOfJoins {
            guard let targetJoin = currentLink.join else {
                listOfJoins = currentLink.next
                continue
            }
            
            // Merge lhs e rhs (se rhs è NULL, usa solo lhs)
            // Ref: drive.c linea 931
            let linker = rhsBinds != nil ? mergePartialMatches(lhsBinds, rhsBinds!) : lhsBinds.copy()
            
            // Calcola hash usando BetaMemoryHashValue
            // Ref: drive.c linee 937-950
            var hashValue: UInt = 0
            if currentLink.enterDirection == LHS {
                hashValue = BetaMemoryHashValue(&theEnv, targetJoin.leftHash, linker, nil, targetJoin)
            } else {
                hashValue = BetaMemoryHashValue(&theEnv, targetJoin.rightHash, linker, nil, targetJoin)
            }
            linker.hashValue = hashValue
            
            // UpdateBetaPMLinks: aggiungi a beta memory PRIMA di propagare
            // Ref: drive.c linea 956, reteutil.c linee 209-295
            // CRITICO: Collega parent-child relationships come in CLIPS C
            if currentLink.enterDirection == LHS {
                if ReteUtil.AddToLeftMemory(targetJoin, linker) {
                    // Collega linker come child di lhsBinds
                    linker.leftParent = lhsBinds
                    if lhsBinds.children == nil {
                        lhsBinds.children = linker
                    } else {
                        linker.nextLeftChild = lhsBinds.children
                        lhsBinds.children?.prevLeftChild = linker
                        lhsBinds.children = linker
                    }
                    NetworkAssertLeft(&theEnv, linker, targetJoin, operation)
                }
            } else {
                if ReteUtil.AddToRightMemory(targetJoin, linker) {
                    // Collega linker come child di rhsBinds (se presente)
                    if let rhsParent = rhsBinds {
                        linker.rightParent = rhsParent
                        if rhsParent.children == nil {
                            rhsParent.children = linker
                        } else {
                            linker.nextRightChild = rhsParent.children
                            rhsParent.children?.prevRightChild = linker
                            rhsParent.children = linker
                        }
                    }
                    NetworkAssertRight(&theEnv, linker, targetJoin, operation)
                }
            }
            
            listOfJoins = currentLink.next
        }
    }
    
    /// EPMDrive: propaga token vuoti attraverso nextLinks del join
    /// Port FEDELE di EPMDrive (drive.c:974-999)
    public static func EPMDrive(
        _ theEnv: inout Environment,
        _ parent: PartialMatch,
        _ join: JoinNodeClass,
        _ operation: Int
    ) {
        guard let firstLink = join.nextLinks.first?.link else { return }
        var listOfJoins: JoinLink? = firstLink
        
        while let currentLink = listOfJoins {
            // Crea linker vuoto (CreateEmptyPartialMatch)
            let linker = CreateEmptyPartialMatch()
            
            // UpdateBetaPMLinks - collega parent
            // Per ora semplificato
            linker.hashValue = 0
            
            if let targetJoin = currentLink.join {
                if theEnv.watchRete {
                    print("[RETE] EPMDrive: propagating empty token to join level \(targetJoin.level) via \(currentLink.enterDirection)")
                }
                
                // Propaga secondo la direzione
                if currentLink.enterDirection == LHS {
                    NetworkAssertLeft(&theEnv, linker, targetJoin, operation)
                } else {
                    NetworkAssertRight(&theEnv, linker, targetJoin, operation)
                }
            }
            
            listOfJoins = currentLink.next
        }
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
        
        if theEnv.watchRete {
            let leftCount = join.leftMemory?.count ?? 0
            print("[RETE] NetworkAssertRight: leftMemory size=\(leftCount), hash=\(rhsBinds.hashValue)")
            if lhsBinds != nil {
                print("[RETE] NetworkAssertRight: found matches in bucket")
            } else {
                print("[RETE] NetworkAssertRight: NO matches in bucket")
            }
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
            // Ref: drive.c linee 229-257
            var joinExpr = EvaluateJoinExpression(&theEnv, join.networkTest, join, currentLHS, rhsBinds)
            
            // Secondary network test
            // Ref: drive.c linee 259-265
            if joinExpr, let secondaryTest = join.secondaryNetworkTest {
                joinExpr = EvaluateJoinExpression(&theEnv, secondaryTest, join, currentLHS, rhsBinds)
            }
            
            if !joinExpr {
                lhsBinds = nextBind
                continue
            }
            
            // JOIN RIUSCITO: propaga attraverso PPDrive (come in C linee 292)
            // Ref: drive.c linee 274-292
            if join.patternIsExists {
                // EXISTS: AddBlockedLink e propaga senza merge (linee 276-280)
                // TODO: Implementare AddBlockedLink
                PPDrive(&theEnv, currentLHS, nil, join, operation)
                lhsBinds = nextBind
                continue
            } else {
                // Normal join: usa PPDrive con merge (linea 292)
                PPDrive(&theEnv, currentLHS, rhsBinds, join, operation)
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
        // ✅ CRITICO: Se è l'ultimo join (ha ruleToActivate), crea attivazione direttamente
        // Ref: drive.c linee 351-355, agenda.c:187 - binds->marker = newActivation
        if let production = join.ruleToActivate {
            if theEnv.watchRete {
                print("[RETE] NetworkAssertLeft: TERMINAL join, creating activation for '\(production.ruleName)'")
            }
            let token = partialMatchToBetaToken(lhsBinds, env: theEnv, ruleName: production.ruleName)
            
            // ✅ CRITICO: Imposta marker sul PartialMatch PRIMA di creare attivazione
            // Questo permette a NetworkRetract di trovare l'attivazione associata
            // In CLIPS C, il marker viene impostato in AddActivation (agenda.c:187)
            // Per ora, tracciamo tramite activationToPartialMatch usando factIDs come key
            let factIDsKey = Array(token.usedFacts).sorted().map { String($0) }.joined(separator: ",")
            let activationKey = "\(production.ruleName):\(factIDsKey)"
            theEnv.activationToPartialMatch[activationKey] = lhsBinds
            
            production.activate(token: token, env: &theEnv)
            return
        }
        
        // ✅ Gestione EXISTS: propaga direttamente senza join
        // Ref: drive.c:276-280, 510-518
        if join.patternIsExists {
            // AddBlockedLink(lhsBinds, rhsBinds) - TODO
            PPDrive(&theEnv, lhsBinds, nil, join, operation)
            return
        }
        
        if theEnv.watchRete {
            print("[RETE] NetworkAssertLeft: entering join at level \(join.level), leftMemory size=\(join.leftMemory?.count ?? 0)")
        }
        
        // Aggiungi a leftMemory
        let added = ReteUtil.AddToLeftMemory(join, lhsBinds)
        if !added { return }
        
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
                
                if theEnv.watchRete {
                    print("[RETE] NetworkAssertLeft: compatible match found")
                }
                
                // Propaga attraverso PPDrive (come in C)
                // Ref: drive.c linea 503
                PPDrive(&theEnv, lhsBinds, currentRHS, join, operation)
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
            print("[RETE] EmptyDrive: nextLinks.count=\(join.nextLinks.count), ruleToActivate=\(join.ruleToActivate?.ruleName ?? "nil")")
        }
        
        // ✅ FEDELE A CLIPS C (drive.c:1075-1106)
        var existsParent: PartialMatch? = nil
        
        // Handle negated first pattern
        if join.patternIsNegated && !join.patternIsExists {
            // NOT semplice (non EXISTS): verifica se il pattern matcha COMPLETAMENTE
            // Ref: drive.c:1075-1090
            // Se networkTest/secondaryNetworkTest passano, il pattern matcha -> blocca
            // Se falliscono, il pattern NON matcha -> NOT è vera, non bloccare
            
            // Evalua network test per verificare se il pattern matcha completamente
            // Ref: drive.c linee 1026-1047
            let networkTestPasses = EvaluateJoinExpression(&theEnv, join.networkTest, join, nil, rhsBinds)
            
            // Secondary network test
            // Ref: drive.c linee 1049-1069
            let secondaryTestPasses = EvaluateJoinExpression(&theEnv, join.secondaryNetworkTest, join, nil, rhsBinds)
            
            // Se entrambi i test passano, il pattern matcha completamente -> blocca
            if networkTestPasses && secondaryTestPasses {
                if join.leftMemory == nil {
                    join.leftMemory = BetaMemoryHash(initialSize: 17)
                }
                if join.leftMemory?.beta[0] == nil {
                    let parent = CreateEmptyPartialMatch()
                    parent.hashValue = 0
                    join.leftMemory?.beta[0] = parent
                }
                
                guard let notParent = join.leftMemory?.beta[0] else { return }
                if notParent.marker != nil { return }
                
                // AddBlockedLink per indicare che NOT è falsa (pattern matcha)
                ReteUtil.AddBlockedLink(notParent, rhsBinds)
                
                // PosEntryRetractBeta: retract children se esistono
                if notParent.children != nil {
                    // TODO: Implementare PosEntryRetractBeta completo
                    // Per ora, semplicemente non propagare
                }
                
                if theEnv.watchRete {
                    print("[RETE] EmptyDrive: NOT first pattern, pattern MATCHES, blocked and return")
                }
                return  // ✅ NOT falsa (pattern matcha), NON propaga!
            } else {
                // Pattern NON matcha completamente -> NOT è vera, continua a propagare
                if theEnv.watchRete {
                    print("[RETE] EmptyDrive: NOT first pattern, pattern DOES NOT MATCH completely, continuing propagation")
                }
                // NON fare return, continua a propagare (NOT è vera)
            }
        } else {
            // Pattern normale o EXISTS: valuta network test normalmente
            // Ref: drive.c linee 1026-1047
            if !EvaluateJoinExpression(&theEnv, join.networkTest, join, nil, rhsBinds) {
                return
            }
            
            // Secondary network test
            // Ref: drive.c linee 1049-1069
            if !EvaluateJoinExpression(&theEnv, join.secondaryNetworkTest, join, nil, rhsBinds) {
                return
            }
        }
        
        // Handle EXISTS (secondo NOT del NOT(NOT))
        if join.patternIsExists {
            // Ref: drive.c:1100-1106
            if join.leftMemory == nil {
                join.leftMemory = BetaMemoryHash(initialSize: 17)
            }
            if join.leftMemory?.beta[0] == nil {
                let parent = CreateEmptyPartialMatch()
                parent.hashValue = 0
                join.leftMemory?.beta[0] = parent
            }
            
            guard let parent = join.leftMemory?.beta[0] else { return }
            existsParent = parent
            
            if parent.marker != nil {
                // Già soddisfatto, non propagare di nuovo
                if theEnv.watchRete {
                    print("[RETE] EmptyDrive: EXISTS already satisfied, skipping")
                }
                return
            }
            
            // AddBlockedLink per indicare che EXISTS è soddisfatto
            ReteUtil.AddBlockedLink(parent, rhsBinds)
            
            if theEnv.watchRete {
                print("[RETE] EmptyDrive: EXISTS pattern, blocked but CONTINUE")
            }
            // ✅ NON fa return! Continua a propagare (solo la prima volta)
        }
        
        // Propaga attraverso nextLinks
        var listOfJoins = join.nextLinks.first?.link
        
        if theEnv.watchRete {
            print("[RETE] EmptyDrive: join level \(join.level) has \(join.nextLinks.count) nextLinks")
        }
        
        if listOfJoins == nil {
            // ✅ FEDELE AL C: EmptyDrive fa semplicemente return se non ci sono nextLinks
            // Ref: drive.c:1113 - if (listOfJoins == NULL) return;
            // Questo significa che EmptyDrive NON gestisce direttamente il caso terminale.
            // Se un firstJoin è terminale, probabilmente significa che la regola ha un solo pattern,
            // quindi rhsBinds contiene già tutti i fatti necessari, ma in questo caso
            // dovremmo chiamare direttamente NetworkAssertLeft invece di EmptyDrive.
            // 
            // Tuttavia, nella nostra implementazione, abbiamo casi dove un join può essere
            // sia firstJoin che terminale (per regole con 2+ pattern dove il secondo pattern
            // è l'ultimo). In questo caso, dobbiamo combinare leftMemory (pattern precedente)
            // con rhsBinds (pattern corrente) per creare l'attivazione corretta.
            //
            // NOTA: Questa è una differenza rispetto al C, ma necessaria per gestire correttamente
            // le attivazioni con tutti i factIDs necessari per il retract.
            
            if theEnv.watchRete {
                print("[RETE] EmptyDrive: no nextLinks (FEDELE AL C: dovrebbe fare return)")
                print("[RETE] EmptyDrive: ruleToActivate=\(join.ruleToActivate?.ruleName ?? "nil")")
                print("[RETE] EmptyDrive: ATTENZIONE - gestione custom per firstJoin terminale")
            }
            
            // ✅ GESTIONE CUSTOM: Se è terminal (ruleToActivate), crea attivazione
            // Questo NON è equivalente al C, ma necessario per il nostro caso d'uso
            if let production = join.ruleToActivate {
                if theEnv.watchRete {
                    print("[RETE] EmptyDrive: CREATING ACTIVATION for rule '\(production.ruleName)'")
                    print("[RETE] EmptyDrive: rhsBinds bcount=\(rhsBinds.bcount)")
                    for i in 0..<Int(rhsBinds.bcount) {
                        if let alphaMatch = rhsBinds.binds[i].theMatch,
                           let entity = alphaMatch.matchingItem as? FactPatternEntity {
                            print("  rhsBinds binds[\(i)]: factID=\(entity.factID)")
                        }
                    }
                    print("  leftMemory count: \(join.leftMemory?.count ?? 0)")
                }
                
                // ✅ CRITICO: Per un firstJoin terminale, dobbiamo combinare leftMemory e rhsBinds
                // Il leftMemory contiene i token del pattern precedente (se presente)
                // Ref: drive.c - quando firstJoin è terminale, AddActivation riceve un PartialMatch combinato
                var combinedPM: PartialMatch
                if let leftMem = join.leftMemory, leftMem.count > 0 {
                    // C'è un leftMemory: dobbiamo combinare il primo token con rhsBinds
                    // Per un firstJoin, il leftMemory dovrebbe contenere un solo token (dal ROOT)
                    var leftToken: PartialMatch? = nil
                    for i in 0..<leftMem.size {
                        if let pm = leftMem.beta[i] {
                            leftToken = pm
                            break  // Prendi il primo token
                        }
                    }
                    
                    if let left = leftToken {
                        if theEnv.watchRete {
                            print("  Found leftMemory token with bcount=\(left.bcount)")
                        }
                        // Combina left e rhsBinds
                        combinedPM = mergePartialMatches(left, rhsBinds)
                        if theEnv.watchRete {
                            print("  Combined PM bcount=\(combinedPM.bcount)")
                        }
                    } else {
                        // Nessun token nel leftMemory, usa solo rhsBinds
                        combinedPM = rhsBinds
                        if theEnv.watchRete {
                            print("  No leftMemory token found, using only rhsBinds")
                        }
                    }
                } else {
                    // Nessun leftMemory, usa solo rhsBinds
                    combinedPM = rhsBinds
                    if theEnv.watchRete {
                        print("  No leftMemory, using only rhsBinds")
                    }
                }
                
                // Per EXISTS, crea token vuoto (senza binding di fatti)
                // Ref: drive.c linee 1128-1129 - EXISTS genera empty partial match
                let token: BetaToken
                if join.patternIsExists {
                    // Token vuoto per EXISTS (no bindings, no usedFacts)
                    token = BetaToken(bindings: [:], usedFacts: [])
                } else {
                    // Pattern normale: usa combinedPM
                    token = partialMatchToBetaToken(
                        combinedPM,
                        env: theEnv,
                        ruleName: production.ruleName
                    )
                    if theEnv.watchRete {
                        print("  Token created with factIDs: \(token.usedFacts.sorted())")
                    }
                }
                
                // ✅ CRITICO: Imposta marker sul PartialMatch PRIMA di creare attivazione
                // (come in NetworkAssertLeft sopra)
                let factIDsKey = Array(token.usedFacts).sorted().map { String($0) }.joined(separator: ",")
                let activationKey = "\(production.ruleName):\(factIDsKey)"
                if join.patternIsExists {
                    // Per EXISTS, usa existsParent se disponibile, altrimenti combinedPM
                    if let parent = existsParent {
                        theEnv.activationToPartialMatch[activationKey] = parent
                    } else {
                        theEnv.activationToPartialMatch[activationKey] = combinedPM
                    }
                } else {
                    theEnv.activationToPartialMatch[activationKey] = combinedPM
                }
                
                if theEnv.watchRete {
                    print("  Activation key: '\(activationKey)'")
                }
                
                production.activate(token: token, env: &theEnv)
            } else {
                if theEnv.watchRete {
                    print("[RETE] EmptyDrive: ERROR - no nextLinks AND no ruleToActivate!")
                }
            }
            return
        }
        
        while let currentLink = listOfJoins {
            guard let targetJoin = currentLink.join else {
                listOfJoins = currentLink.next
                continue
            }
            
            // Crea linker (nuovo partial match)
            // Ref: drive.c linee 1128-1136
            let linker: PartialMatch
            if join.patternIsExists {
                linker = CreateEmptyPartialMatch()
            } else {
                linker = rhsBinds.copy()
            }
            
            // Calcola hash usando BetaMemoryHashValue
            // Ref: drive.c linee 1142-1155
            var hashValue: UInt = 0
            if currentLink.enterDirection == LHS {
                hashValue = BetaMemoryHashValue(&theEnv, targetJoin.leftHash, linker, nil, targetJoin)
            } else {
                hashValue = BetaMemoryHashValue(&theEnv, targetJoin.rightHash, linker, nil, targetJoin)
            }
            linker.hashValue = hashValue
            
            // UpdateBetaPMLinks: aggiungi a beta memory PRIMA di propagare
            // Ref: drive.c linea 1162-1164
            if join.patternIsExists, let parent = existsParent {
                // Per EXISTS, usa existsParent come leftParent
                if currentLink.enterDirection == LHS {
                    if ReteUtil.AddToLeftMemory(targetJoin, linker) {
                        // Collega linker a existsParent
                        linker.leftParent = parent
                        if parent.children == nil {
                            parent.children = linker
                        } else {
                            linker.nextLeftChild = parent.children
                            parent.children?.prevLeftChild = linker
                            parent.children = linker
                        }
                        NetworkAssertLeft(&theEnv, linker, targetJoin, operation)
                    }
                } else {
                    if ReteUtil.AddToRightMemory(targetJoin, linker) {
                        NetworkAssertRight(&theEnv, linker, targetJoin, operation)
                    }
                }
            } else {
                // Pattern normale: collega linker come child di rhsBinds
                // Ref: reteutil.c linee 267-287 - UpdateBetaPMLinks collega parent-child
                if currentLink.enterDirection == LHS {
                    if ReteUtil.AddToLeftMemory(targetJoin, linker) {
                        // Collega linker come child di rhsBinds (rightParent)
                        linker.rightParent = rhsBinds
                        if rhsBinds.children == nil {
                            rhsBinds.children = linker
                        } else {
                            linker.nextRightChild = rhsBinds.children
                            rhsBinds.children?.prevRightChild = linker
                            rhsBinds.children = linker
                        }
                        NetworkAssertLeft(&theEnv, linker, targetJoin, operation)
                    }
                } else {
                    if ReteUtil.AddToRightMemory(targetJoin, linker) {
                        // Collega linker come child di rhsBinds (rightParent)
                        linker.rightParent = rhsBinds
                        if rhsBinds.children == nil {
                            rhsBinds.children = linker
                        } else {
                            linker.nextRightChild = rhsBinds.children
                            rhsBinds.children?.prevRightChild = linker
                            rhsBinds.children = linker
                        }
                        NetworkAssertRight(&theEnv, linker, targetJoin, operation)
                    }
                }
            }
            
            listOfJoins = currentLink.next
        }
    }
    
    // MARK: - Helper Functions
    
    /// Estrae binding da PartialMatch usando il join context
    /// (ref: GlobalLHSBinds/GlobalRHSBinds in CLIPS C)
    private static func extractBindingsFromPartialMatch(
        _ pm: PartialMatch,
        _ join: JoinNodeClass,
        _ theEnv: Environment
    ) -> [String: Value] {
        var bindings: [String: Value] = [:]
        
        // Tenta di ottenere la regola dal join per avere i pattern
        var rule: Rule? = nil
        if let production = join.ruleToActivate {
            rule = theEnv.rules.first { $0.name == production.ruleName || $0.displayName == production.ruleName }
        }
        
        // Estrai binding da ogni pattern nel partial match
        for i in 0..<Int(pm.bcount) {
            guard let alphaMatch = pm.binds[i].theMatch,
                  let entity = alphaMatch.matchingItem as? FactPatternEntity else {
                continue
            }
            
            let fact = entity.fact
            
            // Prova a usare il pattern dalla regola se disponibile
            if let rule = rule, i < rule.patterns.count {
                let pattern = rule.patterns[i]
                let factBindings = Propagation.extractBindings(fact: fact, pattern: pattern)
                bindings.merge(factBindings) { _, new in new }
            }
            // Altrimenti, usa il pattern del rightInput se è il primo pattern
            else if i == 0, let rightAlpha = join.rightInput {
                let factBindings = Propagation.extractBindings(fact: fact, pattern: rightAlpha.pattern)
                bindings.merge(factBindings) { _, new in new }
            }
            // Fallback: estrai da fact slots direttamente (meno preciso)
            else {
                for (slotName, value) in fact.slots {
                    bindings[slotName] = value
                }
            }
        }
        
        return bindings
    }
    
    /// Valuta join expression con binding da LHS e RHS
    /// Port FEDELE di EvaluateJoinExpression (drive.c linee 590-729)
    private static func EvaluateJoinExpression(
        _ theEnv: inout Environment,
        _ joinExpr: ExpressionNode?,
        _ join: JoinNodeClass,
        _ lhsBinds: PartialMatch?,
        _ rhsBinds: PartialMatch?
    ) -> Bool {
        guard let joinExpr = joinExpr else { return true }
        
        // Estrai binding da LHS e RHS
        var combinedBindings: [String: Value] = [:]
        if let lhsBinds = lhsBinds {
            let lhsBindings = extractBindingsFromPartialMatch(lhsBinds, join, theEnv)
            combinedBindings.merge(lhsBindings) { _, new in new }
        }
        if let rhsBinds = rhsBinds {
            let rhsBindings = extractBindingsFromPartialMatch(rhsBinds, join, theEnv)
            combinedBindings.merge(rhsBindings) { _, new in new }
        }
        
        // Salva binding esistenti
        let oldBindings = theEnv.localBindings
        
        // Imposta binding per evaluation
        theEnv.localBindings = combinedBindings
        
        // Valuta expression
        let result = evaluateReteTest(&theEnv, joinExpr)
        
        // Ripristina binding
        theEnv.localBindings = oldBindings
        
        switch result {
        case .boolean(let b): return b
        case .int(let i): return i != 0
        default: return false
        }
    }
    
    /// Calcola hash value per beta memory usando hash expression
    /// Port FEDELE di BetaMemoryHashValue (drive.c linee 768-891)
    public static func BetaMemoryHashValue(
        _ theEnv: inout Environment,
        _ hashExpr: ExpressionNode?,
        _ lbinds: PartialMatch?,
        _ rbinds: PartialMatch?,
        _ join: JoinNodeClass
    ) -> UInt {
        // Se hashExpr è nil, usa joinKeys come fallback (calcolo hash basato su variabili di join)
        guard let hashExpr = hashExpr else {
            // Fallback: calcola hash usando joinKeys
            var bindings: [String: Value] = [:]
            if let lbinds = lbinds {
                bindings.merge(extractBindingsFromPartialMatch(lbinds, join, theEnv)) { _, new in new }
            }
            if let rbinds = rbinds {
                bindings.merge(extractBindingsFromPartialMatch(rbinds, join, theEnv)) { _, new in new }
            }
            
            // Calcola hash basato su joinKeys
            var hasher = Hasher()
            for key in join.joinKeys.sorted() {
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
            return UInt(bitPattern: hasher.finalize())
        }
        
        // Estrai binding da LHS e RHS
        var combinedBindings: [String: Value] = [:]
        if let lbinds = lbinds {
            let lhsBindings = extractBindingsFromPartialMatch(lbinds, join, theEnv)
            combinedBindings.merge(lhsBindings) { _, new in new }
        }
        if let rbinds = rbinds {
            let rhsBindings = extractBindingsFromPartialMatch(rbinds, join, theEnv)
            combinedBindings.merge(rhsBindings) { _, new in new }
        }
        
        // Salva binding esistenti
        let oldBindings = theEnv.localBindings
        
        // Imposta binding per evaluation
        theEnv.localBindings = combinedBindings
        
        var hashValue: UInt = 0
        var multiplier: UInt = 1
        
        // Valuta ogni espressione nella lista hash
        var currentExpr: ExpressionNode? = hashExpr
        while let expr = currentExpr {
            let result = evaluateReteTest(&theEnv, expr)
            
            // Calcola hash basato sul tipo (come in C linee 838-868)
            switch result {
            case .int(let i):
                hashValue += UInt(i) * multiplier
            case .float(let f):
                hashValue += UInt(f.bitPattern) * multiplier
            case .string(let s), .symbol(let s):
                var hasher = Hasher()
                hasher.combine(s)
                hashValue += UInt(bitPattern: hasher.finalize()) * multiplier
            case .boolean(let b):
                hashValue += (b ? 1 : 0) * multiplier
            default:
                break
            }
            
            // Multiplier come in C (linea 875): multiplier = multiplier * 509
            multiplier = multiplier * 509
            
            currentExpr = expr.nextArg
        }
        
        // Ripristina binding
        theEnv.localBindings = oldBindings
        
        return hashValue
    }
    
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
        
        // 2. Valuta join.networkTest se presente
        if let networkTest = join.networkTest {
            let exprResult = EvaluateJoinExpression(&theEnv, networkTest, join, lhs, rhs)
            if !exprResult {
                if theEnv.watchRete {
                    print("[RETE] isCompatible: FAIL - network test failed")
                }
                return false
            }
        }
        
        // 3. Valuta secondary network test se presente
        if let secondaryTest = join.secondaryNetworkTest {
            let exprResult = EvaluateJoinExpression(&theEnv, secondaryTest, join, lhs, rhs)
            if !exprResult {
                if theEnv.watchRete {
                    print("[RETE] isCompatible: FAIL - secondary network test failed")
                }
                return false
            }
        }
        
        return true
    }
    
    /// Converte PartialMatch in BetaToken (bridge tra C-style e Swift-style)
    private static func partialMatchToBetaToken(
        _ pm: PartialMatch,
        env: Environment,
        ruleName: String?
    ) -> BetaToken {
        if let ruleName = ruleName,
           let rule = env.rules.first(where: { $0.name == ruleName || $0.displayName == ruleName }) {
            let bindings = PartialMatchBridge.extractBindings(from: pm, rule: rule, env: env)
            return PartialMatchBridge.createBetaToken(from: pm, bindings: bindings)
        }
        
        // Fallback: binding per nome slot (meno preciso ma evita crash)
        var fallbackBindings: [String: Value] = [:]
        var usedFacts: Set<Int> = []
        for i in 0..<Int(pm.bcount) {
            if let alphaMatch = pm.binds[i].theMatch,
               let entity = alphaMatch.matchingItem {
                usedFacts.insert(entity.factID)
                if let factEntity = entity as? FactPatternEntity {
                    for (slotName, value) in factEntity.fact.slots {
                        fallbackBindings[slotName] = value
                    }
                }
            }
        }
        return BetaToken(bindings: fallbackBindings, usedFacts: usedFacts)
    }
}
