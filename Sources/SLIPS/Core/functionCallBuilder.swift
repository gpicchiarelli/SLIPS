import Foundation

// MARK: - FunctionCallBuilder minimale

public final class FunctionCallBuilderSwift {
    public var env: Environment
    public var args: [Value] = []
    public init(_ env: Environment) { self.env = env }

    public func append(_ v: Value) { args.append(v) }
    public func appendInteger(_ i: Int64) { args.append(.int(i)) }
    public func appendFloat(_ d: Double) { args.append(.float(d)) }
    public func appendString(_ s: String) { args.append(.string(s)) }
    public func appendSymbol(_ s: String) { args.append(.symbol(s)) }

    public func call(_ name: String) throws -> Value {
        guard let fn = Functions.find(env, name) else { throw EvalError.unknownFunction(name) }
        var e = env
        return try fn.impl(&e, args)
    }
}
