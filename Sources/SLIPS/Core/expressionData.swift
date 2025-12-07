import Foundation

// MARK: - Dati ambiente per espressioni (EXPRESSION_DATA)

public final class ExpressionDataSwift {
    public final class HashNode {
        public var exp: ExpressionNode
        public var count: UInt = 1
        public var next: HashNode? = nil
        public var hashval: UInt = 0
        public init(exp: ExpressionNode, hashval: UInt) { self.exp = exp; self.hashval = hashval }
    }

    public var sequenceOpMode: Bool = false
    public var hashTable: [UInt: HashNode] = [:]
    public static let EXPRESSION_HASH_SIZE: UInt = 503
    public init() {}
}

public enum ExpressionEnv {
    public static let EXPRESSION_DATA = 45

    public static func InitExpressionData(_ env: inout Environment) {
        if Envrnmnt.GetEnvironmentData(env, EXPRESSION_DATA) as ExpressionDataSwift? == nil {
            Envrnmnt.SetEnvironmentData(&env, EXPRESSION_DATA, ExpressionDataSwift())
        }
        // In CLIPS vengono impostati puntatori funzione; qui verifichiamo i built-in minimi
        Functions.registerBuiltins(&env)
    }

    // Hashing espressioni (ispirato a expressn.c)
    private static func hash(_ exp: ExpressionNode?) -> UInt {
        guard let exp else { return 0 }
        var tally: UInt64 = 269 // PRIME_THREE
        func h(_ e: ExpressionNode?) {
            guard let e else { return }
            if let al = e.argList { h(al); tally &+= 257 * tally } // PRIME_ONE
            var cur: ExpressionNode? = e
            while let n = cur {
                tally &+= UInt64(n.type.rawValue) * 263 // PRIME_TWO
                // value mix
                if let v = n.value?.value as? Int64 { tally &+= UInt64(bitPattern: v) }
                else if let d = n.value?.value as? Double { tally &+= d.bitPattern }
                else if let s = n.value?.value as? String { tally &+= UInt64(s.hashValue) }
                else if let b = n.value?.value as? Bool { tally &+= b ? 1 : 0 }
                cur = n.nextArg
            }
        }
        h(exp)
        return UInt(tally % UInt64(ExpressionDataSwift.EXPRESSION_HASH_SIZE))
    }

    public static func AddHashedExpression(_ env: inout Environment, _ exp: ExpressionNode?) -> ExpressionNode? {
        guard let exp else { return nil }
        let data = ensure(&env)
        let hv = hash(exp)
        var node = data.hashTable[hv]
        while let n = node {
            if ExprOps.IdenticalExpression(n.exp, exp) {
                n.count &+= 1
                return n.exp
            }
            node = n.next
        }
        let hn = ExpressionDataSwift.HashNode(exp: ExprOps.CopyExpression(exp)!, hashval: hv)
        hn.next = data.hashTable[hv]
        data.hashTable[hv] = hn
        // Ref: Tracking memoria per ExpressionNode (CLIPS usa genalloc)
        // Track solo la prima volta (count = 1), non quando viene riusato
        if hn.count == 1 {
            MemoryTracking.trackExpressionNode(&env, hn.exp)
        }
        return hn.exp
    }

    public static func RemoveHashedExpression(_ env: inout Environment, _ exp: ExpressionNode?) {
        guard let exp else { return }
        let data = ensure(&env)
        let hv = hash(exp)
        var node = data.hashTable[hv]
        var prev: ExpressionDataSwift.HashNode? = nil
        while let n = node {
            if ExprOps.IdenticalExpression(n.exp, exp) {
                if n.count > 1 { n.count &-= 1; return }
                // remove
                if prev == nil { data.hashTable[hv] = n.next } else { prev?.next = n.next }
                return
            }
            prev = node
            node = n.next
        }
    }

    @discardableResult
    public static func SetSequenceOperatorRecognition(_ env: inout Environment, _ value: Bool) -> Bool {
        let data = ensure(&env)
        let old = data.sequenceOpMode
        data.sequenceOpMode = value
        return old
    }

    public static func GetSequenceOperatorRecognition(_ env: Environment) -> Bool {
        let data: ExpressionDataSwift? = Envrnmnt.GetEnvironmentData(env, EXPRESSION_DATA)
        return data?.sequenceOpMode ?? false
    }

    @discardableResult
    private static func ensure(_ env: inout Environment) -> ExpressionDataSwift {
        if let d: ExpressionDataSwift = Envrnmnt.GetEnvironmentData(env, EXPRESSION_DATA) { return d }
        let d = ExpressionDataSwift()
        Envrnmnt.SetEnvironmentData(&env, EXPRESSION_DATA, d)
        return d
    }
}
