import Foundation

// MARK: - Registro funzioni (port minimale di extnfunc)

public final class FunctionDefinitionSwift {
    public let name: String
    public let impl: (inout Environment, [Value]) throws -> Value
    public init(name: String, impl: @escaping (inout Environment, [Value]) throws -> Value) {
        self.name = name
        self.impl = impl
    }
}

public enum Functions {
    public static func registerBuiltins(_ env: inout Environment) {
        if env.functionTable["+"] == nil {
        env.functionTable["+"] = FunctionDefinitionSwift(name: "+", impl: builtin_add)
        }
        env.functionTable["-"] = FunctionDefinitionSwift(name: "-", impl: builtin_sub)
        env.functionTable["*"] = FunctionDefinitionSwift(name: "*", impl: builtin_mul)
        env.functionTable["/"] = FunctionDefinitionSwift(name: "/", impl: builtin_div)
        env.functionTable["="] = FunctionDefinitionSwift(name: "=", impl: builtin_num_eq)
        env.functionTable["<>"] = FunctionDefinitionSwift(name: "<>", impl: builtin_num_neq)
        env.functionTable["<"] = FunctionDefinitionSwift(name: "<", impl: builtin_lt)
        env.functionTable["<="] = FunctionDefinitionSwift(name: "<=", impl: builtin_le)
        env.functionTable[">"] = FunctionDefinitionSwift(name: ">", impl: builtin_gt)
        env.functionTable[">="] = FunctionDefinitionSwift(name: ">=", impl: builtin_ge)
        env.functionTable["eq"] = FunctionDefinitionSwift(name: "eq", impl: builtin_eq)
        env.functionTable["neq"] = FunctionDefinitionSwift(name: "neq", impl: builtin_neq)
        env.functionTable["and"] = FunctionDefinitionSwift(name: "and", impl: builtin_and)
        env.functionTable["or"] = FunctionDefinitionSwift(name: "or", impl: builtin_or)
        env.functionTable["not"] = FunctionDefinitionSwift(name: "not", impl: builtin_not)
        env.functionTable["progn"] = FunctionDefinitionSwift(name: "progn", impl: builtin_progn)
        env.functionTable["printout"] = FunctionDefinitionSwift(name: "printout", impl: builtin_printout)
        env.functionTable["bind"] = FunctionDefinitionSwift(name: "bind", impl: { _, _ in .none })
        env.functionTable["deftemplate"] = FunctionDefinitionSwift(name: "deftemplate", impl: builtin_deftemplate)
        env.functionTable["deffacts"] = FunctionDefinitionSwift(name: "deffacts", impl: builtin_deffacts)
        env.functionTable["assert"] = FunctionDefinitionSwift(name: "assert", impl: builtin_assert)
        env.functionTable["retract"] = FunctionDefinitionSwift(name: "retract", impl: builtin_retract)
        env.functionTable["value"] = FunctionDefinitionSwift(name: "value", impl: builtin_value)
        env.functionTable["facts"] = FunctionDefinitionSwift(name: "facts", impl: builtin_facts)
        env.functionTable["templates"] = FunctionDefinitionSwift(name: "templates", impl: builtin_templates)
        env.functionTable["create$"] = FunctionDefinitionSwift(name: "create$", impl: builtin_create$)
        env.functionTable["watch"] = FunctionDefinitionSwift(name: "watch", impl: builtin_watch)
        env.functionTable["unwatch"] = FunctionDefinitionSwift(name: "unwatch", impl: builtin_unwatch)
        env.functionTable["clear"] = FunctionDefinitionSwift(name: "clear", impl: builtin_clear)
    }

    public static func find(_ env: Environment, _ name: String) -> FunctionDefinitionSwift? {
        return env.functionTable[name]
    }
}

// MARK: - Builtins

private func asDouble(_ v: Value) throws -> Double {
    switch v {
    case .int(let i): return Double(i)
    case .float(let d): return d
    default: throw NSError(domain: "SLIPS", code: 1, userInfo: [NSLocalizedDescriptionKey: "Argomento non numerico: \(v)"])
    }
}

private func widen(_ values: [Value]) -> (isFloat: Bool, doubles: [Double]) {
    var isFloat = false
    var ds: [Double] = []
    for v in values {
        switch v {
        case .float: isFloat = true
        case .int: break
        default: isFloat = true
        }
        ds.append((try? asDouble(v)) ?? 0)
    }
    return (isFloat, ds)
}

private func builtin_add(_ env: inout Environment, _ args: [Value]) throws -> Value {
    let (isFloat, ds) = widen(args)
    let s = ds.reduce(0, +)
    return isFloat ? .float(s) : .int(Int64(s))
}

private func builtin_sub(_ env: inout Environment, _ args: [Value]) throws -> Value {
    if args.isEmpty { return .int(0) }
    let (isFloat, ds) = widen(args)
    let head = ds.first ?? 0
    let tail = ds.dropFirst().reduce(0, +)
    let r = head - tail
    return isFloat ? .float(r) : .int(Int64(r))
}

private func builtin_mul(_ env: inout Environment, _ args: [Value]) throws -> Value {
    let (isFloat, ds) = widen(args)
    let r = ds.reduce(1, *)
    return isFloat ? .float(r) : .int(Int64(r))
}

private func builtin_div(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard !args.isEmpty else { return .int(0) }
    let (_, ds) = widen(args)
    var r = ds.first ?? 0
    for x in ds.dropFirst() { r /= x }
    return .float(r)
}

private func builtin_num_eq(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard let first = try? asDouble(args.first ?? .int(0)) else { return .boolean(true) }
    for a in args.dropFirst() { if (try? asDouble(a)) != first { return .boolean(false) } }
    return .boolean(true)
}

private func builtin_num_neq(_ env: inout Environment, _ args: [Value]) throws -> Value {
    let eq = try builtin_num_eq(&env, args)
    if case .boolean(let b) = eq { return .boolean(!b) }
    return .boolean(false)
}

private func builtin_lt(_ env: inout Environment, _ args: [Value]) throws -> Value {
    var prev: Double? = nil
    for a in args {
        let d = try asDouble(a)
        if let p = prev, !(p < d) { return .boolean(false) }
        prev = d
    }
    return .boolean(true)
}

private func builtin_le(_ env: inout Environment, _ args: [Value]) throws -> Value {
    var prev: Double? = nil
    for a in args {
        let d = try asDouble(a)
        if let p = prev, !(p <= d) { return .boolean(false) }
        prev = d
    }
    return .boolean(true)
}

private func builtin_gt(_ env: inout Environment, _ args: [Value]) throws -> Value {
    var prev: Double? = nil
    for a in args {
        let d = try asDouble(a)
        if let p = prev, !(p > d) { return .boolean(false) }
        prev = d
    }
    return .boolean(true)
}

private func builtin_ge(_ env: inout Environment, _ args: [Value]) throws -> Value {
    var prev: Double? = nil
    for a in args {
        let d = try asDouble(a)
        if let p = prev, !(p >= d) { return .boolean(false) }
        prev = d
    }
    return .boolean(true)
}

private func builtin_eq(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard let first = args.first else { return .boolean(true) }
    let eq = args.dropFirst().allSatisfy { $0 == first }
    return .boolean(eq)
}

private func builtin_neq(_ env: inout Environment, _ args: [Value]) throws -> Value {
    let res = try builtin_eq(&env, args)
    if case .boolean(let b) = res { return .boolean(!b) }
    return .boolean(false)
}

private func builtin_and(_ env: inout Environment, _ args: [Value]) throws -> Value {
    for a in args { if case .boolean(false) = a { return .boolean(false) } }
    return .boolean(true)
}

private func builtin_or(_ env: inout Environment, _ args: [Value]) throws -> Value {
    for a in args { if case .boolean(true) = a { return .boolean(true) } }
    return .boolean(false)
}

private func builtin_not(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard let a = args.first else { return .boolean(true) }
    if case .boolean(let b) = a { return .boolean(!b) }
    return .boolean(false)
}

private func builtin_progn(_ env: inout Environment, _ args: [Value]) throws -> Value {
    return args.last ?? .none
}

private func builtin_printout(_ env: inout Environment, _ args: [Value]) throws -> Value {
    // printout router arg1 arg2 ... ; treat symbol crlf as newline
    var output = ""
    var first = true
    for v in args {
        if first { first = false; continue } // skip router for ora
        switch v {
        case .string(let s): output += s
        case .symbol(let s): output += (s.lowercased() == "crlf") ? "\n" : s
        case .int(let i): output += String(i)
        case .float(let d): output += String(d)
        case .boolean(let b): output += b ? "TRUE" : "FALSE"
        default: output += String(describing: v)
        }
    }
    // usa routers
    Router.WriteString(&env, "t", output)
    return .none
}

// MARK: - Costrutti minimi

private func builtin_deftemplate(_ env: inout Environment, _ args: [Value]) throws -> Value {
    // Gestito dallo special form in evaluator; ritorna simbolo per compatibilità
    guard let name = (args.first?.stringValue) else { return .none }
    return .symbol(name)
}

private func builtin_deffacts(_ env: inout Environment, _ args: [Value]) throws -> Value {
    // Placeholder: no-op, returns count of given facts
    return .int(Int64(args.count))
}

private func builtin_assert(_ env: inout Environment, _ args: [Value]) throws -> Value {
    // (assert factName [slot value]...)
    guard let name = args.first?.stringValue else { return .none }
    var slotMap: [String: Value] = [:]
    var it = args.dropFirst().makeIterator()
    while let key = it.next()?.stringValue, let val = it.next() { slotMap[key] = val }
    let id = env.nextFactId; env.nextFactId += 1
    // Fill missing slots from template defaults
    if let tmpl = env.templates[name] {
        for (_, sd) in tmpl.slots {
            if slotMap[sd.name] == nil {
                switch sd.defaultType {
                case .none:
                    slotMap[sd.name] = Value.none
                case .static:
                    if let v = sd.defaultStatic {
                        if sd.isMultifield {
                            switch v { case .multifield: slotMap[sd.name] = v; default: slotMap[sd.name] = .multifield([v]) }
                        } else { slotMap[sd.name] = v }
                    } else { slotMap[sd.name] = Value.none }
                case .dynamic:
                    if let expr = sd.defaultDynamicExpr {
                        // Valuta expr dinamico tramite fast router/token parser
                        var envCopy = env
                        let router = "***DEFEXP***"
                        let r = RouterEnvData.ensure(&envCopy)
                        r.FastCharGetRouter = router
                        r.FastCharGetString = expr
                        r.FastCharGetIndex = 0
                        var val: Value = .none
                        if let ast = try? ExprTokenParser.parseTop(&envCopy, logicalName: router), let res = try? Evaluator.eval(&envCopy, ast) {
                            val = res
                        }
                        if sd.isMultifield {
                            switch val { case .multifield: slotMap[sd.name] = val; default: slotMap[sd.name] = .multifield([val]) }
                        } else { slotMap[sd.name] = val }
                    } else { slotMap[sd.name] = Value.none }
                }
            } else if sd.isMultifield, let existing = slotMap[sd.name] {
                // Normalize single to multifield when required
                if case .multifield = existing { /* ok */ } else { slotMap[sd.name] = .multifield([existing]) }
            }
        }
    }

    env.facts[id] = Environment.FactRec(id: id, name: name, slots: slotMap)
    RuleEngine.onAssert(&env, env.facts[id]!)
    if env.watchFacts {
        Router.WriteString(&env, Router.STDOUT, "==> (")
        Router.WriteString(&env, Router.STDOUT, name)
        for (k,v) in slotMap {
            Router.WriteString(&env, Router.STDOUT, " ")
            Router.WriteString(&env, Router.STDOUT, k)
            Router.WriteString(&env, Router.STDOUT, " ")
            PrintUtil.PrintAtom(&env, Router.STDOUT, v)
        }
        Router.Writeln(&env, ")")
    }
    return .int(Int64(id))
}

private func builtin_retract(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard let id = args.first?.intValue else { return .none }
    if let fact = env.facts.removeValue(forKey: Int(id)) {
        if env.watchFacts {
            Router.WriteString(&env, Router.STDOUT, "<== (")
            Router.WriteString(&env, Router.STDOUT, fact.name)
            for (k,v) in fact.slots {
                Router.WriteString(&env, Router.STDOUT, " ")
                Router.WriteString(&env, Router.STDOUT, k)
                Router.WriteString(&env, Router.STDOUT, " ")
                PrintUtil.PrintAtom(&env, Router.STDOUT, v)
            }
            Router.Writeln(&env, ")")
        }
        // Rebuild agenda to remove obsolete activations
        RuleEngine.rebuildAgenda(&env)
        return .boolean(true)
    }
    return .boolean(false)
}

private func builtin_value(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard let name = args.first?.stringValue else { return .none }
    return env.localBindings[name] ?? env.globalBindings[name] ?? .none
}

private func builtin_facts(_ env: inout Environment, _ args: [Value]) throws -> Value {
    for (_, fact) in env.facts.sorted(by: { $0.key < $1.key }) {
        Router.WriteString(&env, Router.STDOUT, "(")
        Router.WriteString(&env, Router.STDOUT, fact.name)
        for (k,v) in fact.slots {
            Router.WriteString(&env, Router.STDOUT, " ")
            Router.WriteString(&env, Router.STDOUT, k)
            Router.WriteString(&env, Router.STDOUT, " ")
            PrintUtil.PrintAtom(&env, Router.STDOUT, v)
        }
        Router.Writeln(&env, ")")
    }
    return .int(Int64(env.facts.count))
}

private func builtin_templates(_ env: inout Environment, _ args: [Value]) throws -> Value {
    for (_, t) in env.templates {
        Router.WriteString(&env, Router.STDOUT, "(deftemplate ")
        Router.WriteString(&env, Router.STDOUT, t.name)
        for (_, sd) in t.slots {
            Router.WriteString(&env, Router.STDOUT, sd.isMultifield ? " (multislot " : " (slot ")
            Router.WriteString(&env, Router.STDOUT, sd.name)
            switch sd.defaultType {
            case .none: break
            case .static:
                Router.WriteString(&env, Router.STDOUT, " (default ")
                if let v = sd.defaultStatic { PrintUtil.PrintAtom(&env, Router.STDOUT, v) }
                Router.WriteString(&env, Router.STDOUT, ")")
            case .dynamic:
                Router.WriteString(&env, Router.STDOUT, " (default-dynamic ")
                Router.WriteString(&env, Router.STDOUT, sd.defaultDynamicExpr ?? "")
                Router.WriteString(&env, Router.STDOUT, ")")
            }
            Router.WriteString(&env, Router.STDOUT, ")")
        }
        Router.Writeln(&env, ")")
    }
    return .int(Int64(env.templates.count))
}

private func builtin_create$(_ env: inout Environment, _ args: [Value]) throws -> Value {
    return .multifield(args)
}

private func builtin_watch(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard let what = args.first?.stringValue?.lowercased() else { return .boolean(false) }
    switch what {
    case "facts": env.watchFacts = true; return .boolean(true)
    case "rules": env.watchRules = true; return .boolean(true)
    default: return .boolean(false)
    }
}

private func builtin_unwatch(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard let what = args.first?.stringValue?.lowercased() else { return .boolean(false) }
    switch what {
    case "facts": env.watchFacts = false; return .boolean(true)
    case "rules": env.watchRules = false; return .boolean(true)
    default: return .boolean(false)
    }
}

private func builtin_clear(_ env: inout Environment, _ args: [Value]) throws -> Value {
    env.localBindings.removeAll(); env.globalBindings.removeAll(); env.templates.removeAll(); env.facts.removeAll(); env.nextFactId = 1; env.deffacts.removeAll()
    return .boolean(true)
}

// load come builtin non implementato per evitare dipendenze con MainActor.

// Helper per ottenere env corrente
// removed CLIPSInternal helper; builtins receive env by inout

private extension Value {
    var stringValue: String? {
        switch self { case .string(let s): return s; case .symbol(let s): return s; default: return nil }
    }
    var intValue: Int64? { if case .int(let i) = self { return i } else { return nil } }
}
