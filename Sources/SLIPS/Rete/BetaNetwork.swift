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
    // Alias per rapida verifica di presenza (chiave = bindings|facts)
    public var keyIndex: Set<String> = []
    public init() {}
}

public struct JoinPlan {
    public let patterns: [CompiledPattern]
    public init(patterns: [CompiledPattern]) { self.patterns = patterns }
}
