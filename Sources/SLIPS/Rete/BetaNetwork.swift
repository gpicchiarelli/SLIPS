import Foundation

// MARK: - Rete: Beta token/memory (fase 1, scaffold)

public struct BetaToken {
    public var bindings: [String: Value]
    public var usedFacts: Set<Int>
    public init(bindings: [String: Value] = [:], usedFacts: Set<Int> = []) {
        self.bindings = bindings
        self.usedFacts = usedFacts
    }
}

public final class BetaMemory {
    public var tokens: [BetaToken] = []
    // Alias per rapida verifica di presenza (chiave hashable stabile)
    public var keyIndex: Set<UInt64> = []
    // Indice hash opzionale per futuri join hashing (bucketed per hash)
    public var hashBuckets: [UInt: [Int]] = [:] // hash -> indices in tokens
    public init() {}
}

public struct JoinPlan {
    public let patterns: [CompiledPattern]
    public init(patterns: [CompiledPattern]) { self.patterns = patterns }
}
