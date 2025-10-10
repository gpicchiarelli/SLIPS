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
    public init(id: Int) { self.id = id }
}

