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
            if name == "deftemplate" {
                var cur = node.argList
                guard let nameNode = cur else { return .boolean(false) }
                let nameVal = try eval(&env, nameNode)
                let tname: String
                switch nameVal { case .string(let s): tname = s; case .symbol(let s): tname = s; default: tname = "" }
                cur = nameNode.nextArg
                var slots: [String: Environment.SlotDef] = [:]
                while let n = cur {
                    if n.type == .fcall, let fname = (n.value?.value as? String) {
                        if fname == "slot" || fname == "multislot" {
                            guard let snameNode = n.argList, let sname = (snameNode.value?.value as? String) else { cur = n.nextArg; continue }
                            var defaultType: Environment.SlotDefaultType = .none
                            var defaultStatic: Value? = nil
                            var defaultDynamicExpr: ExpressionNode? = nil
                            var constraints: Environment.SlotConstraints? = nil
                            var opt = snameNode.nextArg
                            while let on = opt {
                                if on.type == .fcall, let oname = (on.value?.value as? String) {
                                    switch oname {
                                    case "default":
                                        if let argHead = on.argList {
                                            defaultType = .static
                                            if fname == "multislot" {
                                                // raccogli tutti gli argomenti statici
                                                var vals: [Value] = []
                                                var a: ExpressionNode? = argHead
                                                while let an = a { if let v = try? eval(&env, an) { vals.append(v) }; a = an.nextArg }
                                                defaultStatic = .multifield(vals)
                                            } else {
                                                // singolo valore
                                                defaultStatic = try? eval(&env, argHead)
                                            }
                                        }
                                    case "default-dynamic":
                                        if let arg = on.argList { defaultType = .dynamic; defaultDynamicExpr = arg }
                                    case "type":
                                        var allowed: Set<Environment.SlotAllowedType> = []
                                        var a = on.argList
                                        while let tn = a { if let tname = tn.value?.value as? String {
                                                let upper = tname.uppercased()
                                                if upper == "INTEGER" { allowed.insert(.integer) }
                                                else if upper == "FLOAT" { allowed.insert(.float) }
                                                else if upper == "NUMBER" { allowed.insert(.number) }
                                                else if upper == "STRING" { allowed.insert(.string) }
                                                else if upper == "SYMBOL" { allowed.insert(.symbol) }
                                                else if upper == "LEXEME" { allowed.insert(.lexeme) }
                                            }
                                            a = tn.nextArg }
                                        constraints = constraints ?? Environment.SlotConstraints()
                                        constraints?.allowed = allowed
                                    case "range":
                                        if let lo = on.argList, let hi = lo.nextArg {
                                            if let lov = try? eval(&env, lo), let hiv = try? eval(&env, hi) {
                                                let lod = numberToDouble(lov)
                                                let hid = numberToDouble(hiv)
                                                if let lo = lod, let hi = hid {
                                                    constraints = constraints ?? Environment.SlotConstraints()
                                                    constraints?.range = lo...hi
                                                }
                                            }
                                        }
                                    default:
                                        break
                                    }
                                }
                                opt = on.nextArg
                            }
                            let sd = Environment.SlotDef(name: sname, isMultifield: (fname == "multislot"), defaultType: defaultType, defaultStatic: defaultStatic, defaultDynamicExpr: defaultDynamicExpr, constraints: constraints)
                            slots[sname] = sd
                        }
                    }
                    cur = n.nextArg
                }
                env.templates[tname] = Environment.Template(name: tname, slots: slots)
                return .symbol(tname)
            }
            if name == "defrule" {
                // defrule parsing: (defrule name <patterns> => <actions...>)
                var cur = node.argList
                guard let nameNode = cur else { return .boolean(false) }
                let nameVal = try eval(&env, nameNode)
                let ruleName: String
                switch nameVal {
                case .string(let s): ruleName = s
                case .symbol(let s): ruleName = s
                default: ruleName = "rule"
                }
                cur = nameNode.nextArg
                var patterns: [Pattern] = []
                var salience = 0
                var tests: [ExpressionNode] = []
                // Collect LHS until '=>' symbol
                while let n = cur {
                    if n.type == .symbol, (n.value?.value as? String) == "=>" { cur = n.nextArg; break }
                    if n.type == .fcall, (n.value?.value as? String) == "declare" {
                        // parse (declare (salience N))
                        var dn = n.argList
                        while let slotNode = dn {
                            if slotNode.type == .fcall, (slotNode.value?.value as? String) == "salience" {
                                if let valNode = slotNode.argList, case .int(let v) = try eval(&env, valNode) { salience = Int(v) }
                            }
                            dn = slotNode.nextArg
                        }
                        cur = n.nextArg
                        continue
                    }
                    if n.type == .fcall, (n.value?.value as? String) == "test" {
                        tests.append(n)
                        cur = n.nextArg
                        continue
                    }
                    if n.type == .fcall, (n.value?.value as? String) == "not" {
                        if let inner = n.argList, let (p, _) = parseSimplePattern(&env, inner) {
                            let np = Pattern(name: p.name, slots: p.slots, negated: true)
                            patterns.append(np)
                        }
                        cur = n.nextArg
                        continue
                    }
                    if n.type == .fcall, (n.value?.value as? String) == "exists" {
                        if let inner = n.argList, let (p, _) = parseSimplePattern(&env, inner) { patterns.append(p) }
                        cur = n.nextArg
                        continue
                    }
                    if n.type == .fcall {
                        if let (p, preds) = parseSimplePattern(&env, n) {
                            patterns.append(p)
                            // Propaga predicati di slot come test esterni per singolo-pattern
                            for pr in preds { tests.append(pr) }
                        }
                    }
                    cur = n.nextArg
                }
                // RHS actions: remaining nodes are expressions
                var rhs: [ExpressionNode] = []
                while let n = cur { rhs.append(n); cur = n.nextArg }
                let rule = Rule(name: ruleName, patterns: patterns, rhs: rhs, salience: salience, tests: tests)
                RuleEngine.addRule(&env, rule)
                return .symbol(ruleName)
            }
            if name == "deffacts" {
                // Special form: non valutare come chiamata normale; salva i fatti
                var cur = node.argList
                guard let nameNode = cur else { return .int(0) }
                let nameVal = try eval(&env, nameNode)
                let dfName: String
                switch nameVal {
                case .string(let s): dfName = s
                case .symbol(let s): dfName = s
                default: dfName = "deffacts"
                }
                cur = nameNode.nextArg
                var list: [[Value]] = []
                while let f = cur {
                    if f.type == .fcall {
                        let fname = (f.value?.value as? String) ?? ""
                        var argsVals: [Value] = [.symbol(fname)]
                        var a = f.argList
                        while let an = a {
                            argsVals.append(try eval(&env, an))
                            a = an.nextArg
                        }
                        list.append(argsVals)
                    }
                    cur = f.nextArg
                }
                env.deffacts[dfName] = list
                return .int(Int64(list.count))
            }
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

    // Parse a simple pattern of form (entity slot val slot val ...)
    // Also collects predicate expressions found in slot values.
    private static func parseSimplePattern(_ env: inout Environment, _ node: ExpressionNode) -> (Pattern, [ExpressionNode])? {
        guard node.type == .fcall else { return nil }
        let pname = (node.value?.value as? String) ?? ""
        var slots: [String: PatternTest] = [:]
        var predicates: [ExpressionNode] = []
        var arg = node.argList
        while let snameNode = arg {
            guard snameNode.type == .symbol, let sname = (snameNode.value?.value as? String) else { break }
            guard let valNode = snameNode.nextArg else { break }
            let test: PatternTest
            switch valNode.type {
            case .integer: test = PatternTest(kind: .constant(try! eval(&env, valNode)))
            case .float: test = PatternTest(kind: .constant(try! eval(&env, valNode)))
            case .string: test = PatternTest(kind: .constant(try! eval(&env, valNode)))
            case .symbol: test = PatternTest(kind: .constant(try! eval(&env, valNode)))
            case .variable: test = PatternTest(kind: .variable((valNode.value?.value as? String) ?? ""))
            case .fcall:
                test = PatternTest(kind: .predicate(valNode))
                predicates.append(valNode)
            default:
                test = PatternTest(kind: .constant(.none))
            }
            slots[sname] = test
            arg = valNode.nextArg
        }
        return (Pattern(name: pname, slots: slots, negated: false), predicates)
    }

    private static func sexpString(_ node: ExpressionNode) -> String {
        switch node.type {
        case .fcall:
            let name = (node.value?.value as? String) ?? ""
            var parts: [String] = ["(", name]
            var arg = node.argList
            while let n = arg { parts.append(" "); parts.append(sexpString(n)); arg = n.nextArg }
            parts.append(")")
            return parts.joined()
        case .integer:
            if let v = node.value?.value as? Int64 { return String(v) }
            return "0"
        case .float:
            if let d = node.value?.value as? Double { return String(d) }
            return "0.0"
        case .string:
            if let s = node.value?.value as? String { return "\"" + s.replacingOccurrences(of: "\"", with: "\\\"") + "\"" }
            return "\"\""
        case .symbol:
            return (node.value?.value as? String) ?? ""
        case .boolean:
            if let b = node.value?.value as? Bool { return b ? "TRUE" : "FALSE" }
            return "FALSE"
        case .variable:
            return "?" + ((node.value?.value as? String) ?? "v")
        case .mfVariable:
            return "$?" + ((node.value?.value as? String) ?? "vs")
        case .gblVariable:
            return "?*" + ((node.value?.value as? String) ?? "g") + "*"
        case .mfGblVariable:
            return "$?*" + ((node.value?.value as? String) ?? "gs") + "*"
        case .instanceName:
            return "[" + ((node.value?.value as? String) ?? "inst") + "]"
        }
    }

    public static func EvaluateExpression(_ env: inout Environment, _ node: ExpressionNode) -> Value {
        return (try? eval(&env, node)) ?? .none
    }
}

// Helper per conversione Value -> Double
private func numberToDouble(_ v: Value) -> Double? {
    switch v {
    case .int(let i): return Double(i)
    case .float(let d): return d
    default: return nil
    }
}
