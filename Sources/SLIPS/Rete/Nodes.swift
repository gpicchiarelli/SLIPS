// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import Foundation

/// Strutture dei nodi della RETE ispirate ai corrispettivi in CLIPS.
public struct AlphaNode: Codable, Equatable {
    public var id: Int
    public init(id: Int) { self.id = id }
}

public struct BetaNode: Codable, Equatable {
    public var id: Int
    public init(id: Int) { self.id = id }
}

public struct JoinNode: Codable, Equatable {
    public var id: Int
    public var patternIndex: Int
    public init(id: Int, patternIndex: Int) { self.id = id; self.patternIndex = patternIndex }
}

/// Nodo filtro post-join per predicate CE (es. (test ...)).
/// Valuta le espressioni rispetto ai binding del token corrente e decide la propagazione.
public struct FilterNode: Codable {
    public var id: Int
    public var tests: [ExpressionNode]
    public init(id: Int, tests: [ExpressionNode]) { self.id = id; self.tests = tests }
}

/// Nodo "exists" unario: verifica l'esistenza di almeno un fatto compatibile
/// con i vincoli sui binding correnti, senza introdurre nuovi binding.
public struct ExistsNode: Codable, Equatable {
    public var id: Int
    public var patternIndex: Int
    public init(id: Int, patternIndex: Int) { self.id = id; self.patternIndex = patternIndex }
}
