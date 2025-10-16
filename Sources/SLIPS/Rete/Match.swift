// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import Foundation

// MARK: - Match Structures (Port fedele da match.h)
// Riferimenti C:
// - struct partialMatch (match.h linee 74-98)
// - struct alphaMatch (match.h linee 103-109)
// - struct multifieldMarker (match.h linee 117-128)

/// Partial match nella rete RETE
/// Port fedele di struct partialMatch (match.h)
public final class PartialMatch {
    // Flags (bitfield in C)
    public var betaMemory: Bool = false
    public var busy: Bool = false
    public var rhsMemory: Bool = false
    public var deleting: Bool = false
    
    // Count e hash
    public var bcount: UInt16 = 0  // Numero di pattern matchati
    public var hashValue: UInt = 0  // Hash value per bucket lookup
    
    // Owner e markers
    public var owner: AnyObject? = nil  // Join node o pattern node owner
    public var marker: MultifieldMarker? = nil
    public var dependents: AnyObject? = nil  // Logical dependencies
    
    // Memory chain (linked list in bucket)
    public var nextInMemory: PartialMatch? = nil
    public var prevInMemory: PartialMatch? = nil
    
    // Parent-child relationships
    public var children: PartialMatch? = nil
    public var rightParent: PartialMatch? = nil
    public var nextRightChild: PartialMatch? = nil
    public var prevRightChild: PartialMatch? = nil
    public var leftParent: PartialMatch? = nil
    public var nextLeftChild: PartialMatch? = nil
    public var prevLeftChild: PartialMatch? = nil
    
    // Blocking (per NOT CE)
    public var blockList: PartialMatch? = nil
    public var nextBlocked: PartialMatch? = nil
    public var prevBlocked: PartialMatch? = nil
    
    // Bindings (array di GenericMatch)
    // In C: GenericMatch binds[1] (flexible array)
    public var binds: [GenericMatch] = []
    
    public init() {}
}

/// Generic match (union in C)
/// Port fedele di struct genericMatch (match.h linee 62-69)
public struct GenericMatch {
    // Union { void *theValue; AlphaMatch *theMatch; }
    public var theValue: AnyObject? = nil
    public var theMatch: AlphaMatch? = nil
    
    public init() {}
}

/// Alpha match per pattern nodes
/// Port fedele di struct alphaMatch (match.h linee 103-109)
public final class AlphaMatch {
    public var matchingItem: PatternEntity? = nil  // Fact o instance
    public var markers: MultifieldMarker? = nil
    public var next: AlphaMatch? = nil
    public var bucket: UInt = 0
    
    public init() {}
}

/// Pattern entity (placeholder - da espandere)
public protocol PatternEntity: AnyObject {
    var factID: Int { get }
}

/// Multifield marker per $? variables
/// Port fedele di struct multifieldMarker (match.h linee 117-128)
public final class MultifieldMarker {
    public var whichField: UInt16 = 0
    public var whichSlot: AnyObject? = nil  // Union in C
    public var whichSlotNumber: UInt16 = 0
    public var startPosition: Int = 0
    public var range: Int = 0
    public var next: MultifieldMarker? = nil
    
    public init() {}
}

// MARK: - Join Link Structure

/// Link per successori di un join node
/// Port fedele di struct joinLink (network.h linee 100-106)
public final class JoinLink {
    /// Direzione di entrata ('l' = left, 'r' = right)
    /// Port di: char enterDirection
    public var enterDirection: Character = "l"
    
    /// Join node successore
    /// Port di: struct joinNode *join
    public var join: JoinNodeClass? = nil
    
    /// Link successivo nella lista
    /// Port di: struct joinLink *next
    public var next: JoinLink? = nil
    
    /// ID per binary save (non usato per ora)
    /// Port di: unsigned long bsaveID
    public var bsaveID: UInt = 0
    
    public init() {}
}

// MARK: - Helper Extensions

extension PartialMatch {
    /// Inizializza tutti i link a nil (InitializePMLinks in reteutil.c linee 182-199)
    public func initializeLinks() {
        nextInMemory = nil
        prevInMemory = nil
        nextRightChild = nil
        prevRightChild = nil
        nextLeftChild = nil
        prevLeftChild = nil
        children = nil
        rightParent = nil
        leftParent = nil
        blockList = nil
        nextBlocked = nil
        prevBlocked = nil
        marker = nil
        dependents = nil
    }
    
    /// Crea copia del partial match (CopyPartialMatch in reteutil.c linee 134-155)
    public func copy() -> PartialMatch {
        let linker = PartialMatch()
        linker.initializeLinks()
        linker.betaMemory = true
        linker.busy = false
        linker.rhsMemory = false
        linker.deleting = false
        linker.bcount = self.bcount
        linker.hashValue = self.hashValue  // CRITICO: Mantieni hash originale!
        
        // Copia bindings
        linker.binds = self.binds.map { gm in
            var copy = GenericMatch()
            copy.theValue = gm.theValue
            copy.theMatch = gm.theMatch
            return copy
        }
        
        return linker
    }
}

/// Crea empty partial match (CreateEmptyPartialMatch in reteutil.c linee 160-177)
public func CreateEmptyPartialMatch() -> PartialMatch {
    let linker = PartialMatch()
    linker.initializeLinks()
    linker.betaMemory = true
    linker.busy = false
    linker.rhsMemory = false
    linker.deleting = false
    linker.bcount = 1
    linker.hashValue = 0
    
    var bind = GenericMatch()
    bind.theValue = nil
    linker.binds = [bind]
    
    return linker
}

