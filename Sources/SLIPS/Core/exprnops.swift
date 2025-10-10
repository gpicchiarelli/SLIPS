import Foundation

// MARK: - Operazioni sulle espressioni (subset di exprnops.h)

public enum ExprOps {
    public static func ExpressionSize(_ e: ExpressionNode?) -> UInt64 {
        guard let e else { return 0 }
        var count: UInt64 = 0
        func walk(_ n: ExpressionNode?) {
            guard let n else { return }
            count += 1
            walk(n.argList)
            walk(n.nextArg)
        }
        walk(e)
        return count
    }

    public static func CountArguments(_ e: ExpressionNode?) -> UInt16 {
        var c: UInt16 = 0
        var cur = e
        while cur != nil { c &+= 1; cur = cur?.nextArg }
        return c
    }

    public static func CopyExpression(_ e: ExpressionNode?) -> ExpressionNode? {
        guard let e else { return nil }
        let n = ExpressionNode(type: e.type, value: e.value)
        n.argList = CopyExpression(e.argList)
        n.nextArg = CopyExpression(e.nextArg)
        return n
    }

    public static func IdenticalExpression(_ a: ExpressionNode?, _ b: ExpressionNode?) -> Bool {
        if a === b { return true }
        guard let a, let b else { return a == nil && b == nil }
        if a.type != b.type { return false }
        let av = a.value?.value
        let bv = b.value?.value
        switch (av, bv) {
        case let (ai as Int64, bi as Int64) where ai == bi: break
        case let (ad as Double, bd as Double) where ad == bd: break
        case let (asv as String, bsv as String) where asv == bsv: break
        case let (ab as Bool, bb as Bool) where ab == bb: break
        case (nil, nil): break
        default: return false
        }
        return IdenticalExpression(a.argList, b.argList) && IdenticalExpression(a.nextArg, b.nextArg)
    }

    public static func AppendExpressions(_ a: ExpressionNode?, _ b: ExpressionNode?) -> ExpressionNode? {
        guard let a else { return b }
        var last = a
        while last.nextArg != nil { last = last.nextArg! }
        last.nextArg = b
        return a
    }
}

