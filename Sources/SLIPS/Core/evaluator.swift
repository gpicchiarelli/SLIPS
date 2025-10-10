import Foundation

// MARK: - Valutazione delle espressioni

public enum EvalError: Error, CustomStringConvertible {
    case unknownFunction(String)
    case invalidExpression
    case runtime(String)
    public var description: String {
        switch self {
        case .unknownFunction(let n): return "Funzione sconosciuta: \(n)"
        case .invalidExpression: return "Espressione non valida"
        case .runtime(let s): return s
        }
    }
}

public enum Evaluator {
    public static func eval(_ env: inout Environment, _ node: ExpressionNode) throws -> Value {
        switch node.type {
        case .integer:
            if let v = node.value?.value as? Int64 { return .int(v) }
            if let i = node.value?.value as? Int { return .int(Int64(i)) }
            return .int(0)
        case .float:
            if let d = node.value?.value as? Double { return .float(d) }
            if let f = node.value?.value as? Float { return .float(Double(f)) }
            return .float(0)
        case .string:
            return .string((node.value?.value as? String) ?? "")
        case .symbol:
            return .symbol((node.value?.value as? String) ?? "")
        case .boolean:
            return .boolean((node.value?.value as? Bool) ?? false)
        case .fcall:
            let name = (node.value?.value as? String) ?? ""
            // Special handling for bind to access variable tokens
            if name == "bind" {
                // first arg is variable token node
                guard let varNode = node.argList else { return .none }
                let rest = varNode.nextArg
                switch varNode.type {
                case .variable:
                    let varName = (varNode.value?.value as? String) ?? ""
                    // bind single value (eval first of rest)
                    if let first = rest, let val = try? eval(&env, first) {
                        env.localBindings[varName] = val
                        return val
                    }
                case .mfVariable:
                    let varName = (varNode.value?.value as? String) ?? ""
                    // bind to multifield of evaluated rest args
                    var vals: [Value] = []
                    var cur = rest
                    while let n = cur { if let v = try? eval(&env, n) { vals.append(v) }; cur = n.nextArg }
                    let mf: Value = .multifield(vals)
                    env.localBindings[varName] = mf
                    return mf
                case .gblVariable:
                    let varName = (varNode.value?.value as? String) ?? ""
                    if let first = rest, let val = try? eval(&env, first) {
                        env.globalBindings[varName] = val
                        return val
                    }
                case .mfGblVariable:
                    let varName = (varNode.value?.value as? String) ?? ""
                    var vals: [Value] = []
                    var cur = rest
                    while let n = cur { if let v = try? eval(&env, n) { vals.append(v) }; cur = n.nextArg }
                    let mf: Value = .multifield(vals)
                    env.globalBindings[varName] = mf
                    return mf
                case .symbol, .string:
                    let varName = (varNode.value?.value as? String) ?? ""
                    // single vs multi based on arity
                    if let first = rest, rest?.nextArg == nil, let val = try? eval(&env, first) {
                        env.localBindings[varName] = val
                        return val
                    } else {
                        var vals: [Value] = []
                        var cur = rest
                        while let n = cur { if let v = try? eval(&env, n) { vals.append(v) }; cur = n.nextArg }
                        let mf: Value = .multifield(vals)
                        env.localBindings[varName] = mf
                        return mf
                    }
                default: break
                }
                return .none
            }
            guard let def = Functions.find(env, name) else {
                throw EvalError.unknownFunction(name)
            }
            var argsVals: [Value] = []
            var arg = node.argList
            while let n = arg {
                // Sequence expansion for multifield variables
                if (n.type == .mfVariable || n.type == .mfGblVariable) {
                    let varName = (n.value?.value as? String) ?? ""
                    let bound = (n.type == .mfVariable ? env.localBindings[varName] : env.globalBindings[varName])
                    if case .multifield(let arr)? = bound { argsVals.append(contentsOf: arr) }
                    else if let b = bound { argsVals.append(b) }
                } else if let v = try? eval(&env, n) {
                    argsVals.append(v)
                } else {
                    argsVals.append(.none)
                }
                arg = n.nextArg
            }
            do { return try def.impl(&env, argsVals) } catch { throw EvalError.runtime(String(describing: error)) }
        case .variable:
            let name = (node.value?.value as? String) ?? ""
            return env.localBindings[name] ?? env.globalBindings[name] ?? .none
        case .mfVariable:
            let name = (node.value?.value as? String) ?? ""
            return env.localBindings[name] ?? .none
        case .gblVariable:
            let name = (node.value?.value as? String) ?? ""
            return env.globalBindings[name] ?? .none
        case .mfGblVariable:
            let name = (node.value?.value as? String) ?? ""
            return env.globalBindings[name] ?? .none
        case .instanceName:
            return .symbol((node.value?.value as? String) ?? "")
        }
    }

    public static func EvaluateExpression(_ env: inout Environment, _ node: ExpressionNode) -> Value {
        return (try? eval(&env, node)) ?? .none
    }
}
