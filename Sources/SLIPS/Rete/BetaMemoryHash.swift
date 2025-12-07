// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import Foundation

// MARK: - Beta Memory Hash Table (Port fedele da network.h e reteutil.c)
// Riferimenti C:
// - struct betaMemory (network.h linee 92-98)
// - GetLeftBetaMemory/GetRightBetaMemory (reteutil.c linee 1068-1095)
// - ResizeBetaMemory (reteutil.c)

/// Beta memory con hash table vera (come in CLIPS)
/// Port fedele di struct betaMemory (network.h)
public final class BetaMemoryHash {
    /// Dimensione hash table (numero di bucket)
    /// Inizia con INITIAL_BETA_HASH_SIZE (17) e cresce dinamicamente
    public var size: Int
    
    /// Numero di partial match memorizzati
    public var count: Int = 0
    
    /// Array di bucket - ogni bucket è una linked list di PartialMatch
    /// Port di: struct partialMatch **beta
    public var beta: [PartialMatch?]
    
    /// Array di puntatori all'ultimo elemento di ogni bucket
    /// Port di: struct partialMatch **last
    public var last: [PartialMatch?]
    
    /// Inizializza beta memory con dimensione iniziale
    /// (ref: INITIAL_BETA_HASH_SIZE = 17 in network.h linea 90)
    public init(initialSize: Int = 17) {
        self.size = initialSize
        self.beta = Array(repeating: nil, count: initialSize)
        self.last = Array(repeating: nil, count: initialSize)
    }
    
    /// Cleanup method per prevenire memory leaks
    deinit {
        flush()
    }
    
    /// Ottiene la lista di partial match in un bucket specifico
    /// Port fedele di GetLeftBetaMemory (reteutil.c linee 1071-1080)
    public func getMatches(hashValue: UInt) -> PartialMatch? {
        let betaLocation = Int(hashValue % UInt(size))
        return beta[betaLocation]
    }
    
    /// Aggiunge un partial match alla memoria
    /// (ref: AddToken in beta memory - logica inferita da AddBlockedLink e simili)
    @discardableResult
    public func addMatch(_ match: PartialMatch) -> Bool {
        let betaLocation = Int(match.hashValue % UInt(size))
        
        // Deduplica: evita di conservare token identici nello stesso bucket
        var cursor = beta[betaLocation]
        while let existing = cursor {
            if BetaMemoryHash.matchesAreEquivalent(existing, match) {
                return false
            }
            cursor = existing.nextInMemory
        }
        
        // Inserisci in testa alla lista del bucket
        match.nextInMemory = beta[betaLocation]
        match.prevInMemory = nil
        
        if let current = beta[betaLocation] {
            current.prevInMemory = match
        } else {
            // Primo elemento nel bucket, imposta anche last
            last[betaLocation] = match
        }
        
        beta[betaLocation] = match
        count += 1
        
        // Resize se necessario (load factor > 2)
        if count > size * 2 {
            resize()
        }
        return true
    }
    
    /// Rimuove un partial match dalla memoria
    /// (ref: RemovePartialMatch logica in reteutil.c)
    public func removeMatch(_ match: PartialMatch) {
        let betaLocation = Int(match.hashValue % UInt(size))
        
        // Rimuovi dalla linked list
        if let prev = match.prevInMemory {
            prev.nextInMemory = match.nextInMemory
        } else {
            // Era in testa
            beta[betaLocation] = match.nextInMemory
        }
        
        if let next = match.nextInMemory {
            next.prevInMemory = match.prevInMemory
        } else {
            // Era in coda
            last[betaLocation] = match.prevInMemory
        }
        
        count -= 1
    }
    
    /// Confronta due partial match verificando che rappresentino la stessa combinazione di fatti.
    private static func matchesAreEquivalent(_ lhs: PartialMatch, _ rhs: PartialMatch) -> Bool {
        if lhs.hashValue != rhs.hashValue { return false }
        if lhs.bcount != rhs.bcount { return false }
        let leftIDs = collectFactIDs(from: lhs)
        let rightIDs = collectFactIDs(from: rhs)
        return leftIDs == rightIDs
    }
    
    private static func collectFactIDs(from match: PartialMatch) -> [Int] {
        var ids: [Int] = []
        appendFactIDs(from: match, into: &ids)
        ids.sort()
        return ids
    }
    
    private static func appendFactIDs(from match: PartialMatch, into ids: inout [Int]) {
        for bind in match.binds {
            if let entity = bind.theMatch?.matchingItem as? FactPatternEntity {
                ids.append(entity.factID)
            } else if let nested = bind.theValue as? PartialMatch {
                appendFactIDs(from: nested, into: &ids)
            }
        }
    }
    
    /// Resize della hash table quando load factor troppo alto
    /// Port di ResizeBetaMemory (reteutil.c - logica inferita)
    private func resize() {
        let newSize = nextPrime(size * 2)
        let oldBeta = beta
        
        // Crea nuova tabella
        size = newSize
        beta = Array(repeating: nil, count: newSize)
        last = Array(repeating: nil, count: newSize)
        count = 0
        
        // Rehash tutti gli elementi
        for bucket in oldBeta {
            var current = bucket
            while let match = current {
                let next = match.nextInMemory
                match.nextInMemory = nil
                match.prevInMemory = nil
                addMatch(match)
                current = next
            }
        }
    }
    
    /// Trova il prossimo numero primo (per dimensioni hash table)
    private func nextPrime(_ n: Int) -> Int {
        // Sequenza primi usati in CLIPS: 17, 37, 67, 131, 257, 521, 1031...
        let primes = [17, 37, 67, 131, 257, 521, 1031, 2053, 4099, 8209, 16411, 32771, 65537]
        for p in primes where p > n {
            return p
        }
        return n * 2 + 1  // Fallback
    }
    
    /// Pulisce tutti i match dalla memoria
    /// Port di FlushBetaMemory (reteutil.c linee 1157-1186)
    public func flush() {
        for i in 0..<size {
            var current = beta[i]
            while let match = current {
                let next = match.nextInMemory
                // In C: DestroyAlphaBetaMemory - qui solo unlink
                match.nextInMemory = nil
                match.prevInMemory = nil
                current = next
            }
            beta[i] = nil
            last[i] = nil
        }
        count = 0
    }
    
    /// Verifica se la memoria è vuota
    /// Port di BetaMemoryNotEmpty (reteutil.c)
    public var isEmpty: Bool {
        return count == 0
    }
}

// MARK: - Utility Functions

/// Calcola hash value per un partial match basato sui binding
/// (ref: ComputeRightHashValue in reteutil.c se presente, altrimenti logica inferita)
public func computeHashValue(
    for match: PartialMatch,
    using expression: ExpressionNode?
) -> UInt {
    // Se c'è hash expression, evalua quella
    // Altrimenti, hash basato sui fact IDs nei binds
    
    var hasher = Hasher()
    
    for i in 0..<Int(match.bcount) {
        if let value = match.binds[i].theValue {
            // Hash del valore (fact ID o altro)
            hasher.combine(ObjectIdentifier(value))
        }
    }
    
    return UInt(bitPattern: hasher.finalize())
}
