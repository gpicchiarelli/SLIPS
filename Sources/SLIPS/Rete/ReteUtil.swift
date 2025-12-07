// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import Foundation

// MARK: - RETE Utilities (Port fedele da reteutil.c)
// Riferimenti C:
// - GetLeftBetaMemory (reteutil.c linee 1068-1080)
// - GetRightBetaMemory (reteutil.c linee 1082-1095)
// - CreateEmptyPartialMatch (reteutil.c linee 160-177)
// - ResizeBetaMemory (reteutil.c)

public enum ReteUtil {
    
    /// Recupera lista di partial match da left beta memory con hash lookup O(1)
    /// Port FEDELE di GetLeftBetaMemory (reteutil.c linee 1068-1080)
    public static func GetLeftBetaMemory(
        _ theJoin: JoinNodeClass,
        hashValue: UInt
    ) -> PartialMatch? {
        guard let leftMemory = theJoin.leftMemory else { return nil }
        
        let betaLocation = Int(hashValue % UInt(leftMemory.size))
        return leftMemory.beta[betaLocation]
    }
    
    /// Recupera lista di partial match da right beta memory con hash lookup O(1)
    /// Port FEDELE di GetRightBetaMemory (reteutil.c linee 1082-1095)
    public static func GetRightBetaMemory(
        _ theJoin: JoinNodeClass,
        hashValue: UInt
    ) -> PartialMatch? {
        guard let rightMemory = theJoin.rightMemory else { return nil }
        
        let betaLocation = Int(hashValue % UInt(rightMemory.size))
        return rightMemory.beta[betaLocation]
    }
    
    /// Pulisce left memory
    /// Port di ReturnLeftMemory (reteutil.c linee 1097-1109)
    public static func ReturnLeftMemory(_ theJoin: JoinNodeClass) {
        guard let leftMem = theJoin.leftMemory else { return }
        leftMem.flush()
        theJoin.leftMemory = nil
    }
    
    /// Pulisce right memory  
    /// Port di ReturnRightMemory (reteutil.c linee 1111-1124)
    public static func ReturnRightMemory(_ theJoin: JoinNodeClass) {
        guard let rightMem = theJoin.rightMemory else { return }
        rightMem.flush()
        theJoin.rightMemory = nil
    }
    
    /// Verifica se beta memory non è vuota
    /// Port di BetaMemoryNotEmpty (reteutil.c)
    public static func BetaMemoryNotEmpty(_ theJoin: JoinNodeClass) -> Bool {
        if let leftMem = theJoin.leftMemory, !leftMem.isEmpty {
            return true
        }
        if let rightMem = theJoin.rightMemory, !rightMem.isEmpty {
            return true
        }
        return false
    }
    
    /// Aggiunge partial match a left memory
    /// (ref: UpdateBetaPMLinks in reteutil.c linee 209-261)
    @discardableResult
    public static func AddToLeftMemory(
        _ theJoin: JoinNodeClass,
        _ match: PartialMatch
    ) -> Bool {
        if theJoin.leftMemory == nil {
            theJoin.leftMemory = BetaMemoryHash(initialSize: 17)
        }
        
        // ✅ CRITICO: Imposta owner e rhsMemory flag (come in CLIPS C linea 219, 261)
        match.owner = theJoin
        match.rhsMemory = false
        
        let inserted = theJoin.leftMemory?.addMatch(match) ?? false
        if inserted { theJoin.memoryLeftAdds += 1 }
        return inserted
    }
    
    /// Aggiunge partial match a right memory
    /// (ref: UpdateBetaPMLinks in reteutil.c linee 209-261)
    @discardableResult
    public static func AddToRightMemory(
        _ theJoin: JoinNodeClass,
        _ match: PartialMatch
    ) -> Bool {
        if theJoin.rightMemory == nil {
            theJoin.rightMemory = BetaMemoryHash(initialSize: 17)
        }
        
        // ✅ CRITICO: Imposta owner e rhsMemory flag (come in CLIPS C linea 224, 261)
        match.owner = theJoin
        match.rhsMemory = true
        
        let inserted = theJoin.rightMemory?.addMatch(match) ?? false
        if inserted { theJoin.memoryRightAdds += 1 }
        return inserted
    }
    
    /// Rimuove partial match da left memory
    public static func RemoveFromLeftMemory(
        _ theJoin: JoinNodeClass,
        _ match: PartialMatch
    ) {
        theJoin.leftMemory?.removeMatch(match)
        theJoin.memoryLeftDeletes += 1
    }
    
    /// Rimuove partial match da right memory
    public static func RemoveFromRightMemory(
        _ theJoin: JoinNodeClass,
        _ match: PartialMatch
    ) {
        theJoin.rightMemory?.removeMatch(match)
        theJoin.memoryRightDeletes += 1
    }
    
    /// Aggiunge link di blocking tra partial match (per NOT/EXISTS)
    /// Port FEDELE di AddBlockedLink (reteutil.c linee 304-313)
    public static func AddBlockedLink(
        _ thePM: PartialMatch,
        _ rhsBinds: PartialMatch
    ) {
        // Imposta marker per indicare che è blocked
        // In C: thePM->marker = rhsBinds (void* cast)
        thePM.marker = rhsBinds
        
        // Aggiungi alla blockList di rhsBinds
        thePM.nextBlocked = rhsBinds.blockList
        if let prevBlocked = rhsBinds.blockList {
            prevBlocked.prevBlocked = thePM
        }
        rhsBinds.blockList = thePM
    }
    
    /// Rimuove link di blocking
    /// Port FEDELE di RemoveBlockedLink (reteutil.c linee 322-341)
    public static func RemoveBlockedLink(_ thePM: PartialMatch) {
        guard let blocker = thePM.marker as? PartialMatch else { return }
        
        if thePM.prevBlocked == nil {
            blocker.blockList = thePM.nextBlocked
        } else {
            thePM.prevBlocked?.nextBlocked = thePM.nextBlocked
        }
        
        if let next = thePM.nextBlocked {
            next.prevBlocked = thePM.prevBlocked
        }
        
        thePM.nextBlocked = nil
        thePM.prevBlocked = nil
        thePM.marker = nil
    }
}
