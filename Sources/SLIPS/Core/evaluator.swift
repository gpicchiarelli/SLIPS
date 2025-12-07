import Foundation

// MARK: - Valutazione delle espressioni

public enum EvalError: Error, CustomStringConvertible {
    case unknownFunction(String)
    case invalidExpression
    case runtime(String)
    case wrongArgCount(String, expected: Any, got: Int)
    case typeMismatch(String, expected: String, got: String)
    case indexOutOfBounds(String, index: Int, size: Int)
    case invalidRange(String, begin: Int, end: Int, size: Int)
    
    public var description: String {
        switch self {
        case .unknownFunction(let n): 
            return "Funzione sconosciuta: \(n)"
        case .invalidExpression: 
            return "Espressione non valida"
        case .runtime(let s): 
            return s
        case .wrongArgCount(let fn, let expected, let got):
            return "[\(fn)] Numero argomenti errato: attesi \(expected), ricevuti \(got)"
        case .typeMismatch(let fn, let expected, let got):
            return "[\(fn)] Tipo errato: atteso \(expected), ricevuto \(got)"
        case .indexOutOfBounds(let fn, let index, let size):
            return "[\(fn)] Indice fuori range: \(index) (dimensione: \(size))"
        case .invalidRange(let fn, let begin, let end, let size):
            return "[\(fn)] Range non valido: [\(begin), \(end)] (dimensione: \(size))"
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
                let template = Environment.Template(name: tname, slots: slots)
                env.templates[tname] = template
                // Ref: Tracking memoria per template (CLIPS usa genalloc)
                MemoryTracking.trackTemplate(&env, template)
                return .symbol(tname)
            }
            if name == "defrule" {
                // defrule parsing: (defrule name <patterns/CE> => <actions...>)
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
                var salience = 0
                var tests: [ExpressionNode] = []
                var altSets: [[Pattern]] = [[]] // alternative liste di pattern per gestione (or ...)
                // Collect LHS until '=>' symbol
                while let n = cur {
                    if n.type == .symbol, (n.value?.value as? String) == "=>" { cur = n.nextArg; break }
                    if n.type == .fcall, (n.value?.value as? String) == "declare" {
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
                    if n.type == .fcall, (n.value?.value as? String) == "and" {
                        var child = n.argList
                        while let cn = child {
                            if cn.type == .fcall, (cn.value?.value as? String) == "test" { tests.append(cn) }
                            else if cn.type == .fcall, (cn.value?.value as? String) == "not" {
                                if let inner = cn.argList, let (p, _) = parseSimplePattern(&env, inner) {
                                    let np = Pattern(name: p.name, slots: p.slots, negated: true, exists: false)
                                    altSets = altSets.map { $0 + [np] }
                                }
                            }
                            else if cn.type == .fcall, (cn.value?.value as? String) == "exists" {
                                // EXISTS marcato con flag; NetworkBuilder lo trasforma in NOT(NOT)
                                if let inner = cn.argList, let (p, _) = parseSimplePattern(&env, inner) {
                                    let ep = Pattern(name: p.name, slots: p.slots, negated: false, exists: true)
                                    altSets = altSets.map { $0 + [ep] }
                                }
                            } else if let (p, preds) = parseSimplePattern(&env, cn) {
                                altSets = altSets.map { $0 + [p] }
                                for pr in preds { tests.append(pr) }
                            }
                            child = cn.nextArg
                        }
                        cur = n.nextArg
                        continue
                    }
                    if n.type == .fcall, (n.value?.value as? String) == "or" {
                        var newAlts: [[Pattern]] = []
                        var child = n.argList
                        var parsedAny = false
                        while let cn = child {
                            if let (p0, preds) = parseSimplePattern(&env, cn) {
                                for alt in altSets { newAlts.append(alt + [p0]) }
                                for pr in preds { tests.append(pr) }
                                parsedAny = true
                            }
                            child = cn.nextArg
                        }
                        if parsedAny { altSets = newAlts }
                        cur = n.nextArg
                        continue
                    }
                    if n.type == .fcall, (n.value?.value as? String) == "not" {
                        if let inner = n.argList, let (p, _) = parseSimplePattern(&env, inner) {
                            let np = Pattern(name: p.name, slots: p.slots, negated: true, exists: false)
                            altSets = altSets.map { $0 + [np] }
                        }
                        cur = n.nextArg
                        continue
                    }
                    if n.type == .fcall, (n.value?.value as? String) == "exists" {
                        // EXISTS viene marcato con flag; NetworkBuilder lo trasforma in NOT(NOT)
                        // Ref: rulelhs.c:827-843 - EXISTS trasformato in struttura albero NOT(NOT)
                        if let inner = n.argList, let (p, _) = parseSimplePattern(&env, inner) {
                            let ep = Pattern(name: p.name, slots: p.slots, negated: false, exists: true)
                            altSets = altSets.map { $0 + [ep] }
                        }
                        cur = n.nextArg
                        continue
                    }
                    if n.type == .fcall {
                        if let (p, preds) = parseSimplePattern(&env, n) {
                            altSets = altSets.map { $0 + [p] }
                            for pr in preds { tests.append(pr) }
                        }
                    }
                    cur = n.nextArg
                }
                // RHS actions
                var rhs: [ExpressionNode] = []
                while let n = cur { rhs.append(n); cur = n.nextArg }
                if altSets.isEmpty { altSets = [[]] }
                for (i, pats) in altSets.enumerated() {
                    let rname = (i == 0) ? ruleName : (ruleName + "$or" + String(i))
                    var rule = Rule(name: rname, displayName: ruleName, patterns: pats, rhs: rhs, salience: salience, tests: tests)
                    // FASE 3: Associa regola al modulo corrente (ref: ruledef.c - ParseDefrule)
                    if let currentMod = env.getCurrentModule() {
                        rule.moduleName = currentMod.name
                    }
                    RuleEngine.addRule(&env, rule)
                }
                return .symbol(ruleName)
            }
            if name == "defmodule" {
                // (defmodule <name> [export-list] [import-list])
                // Parsing del modulo (ref: ParseDefmodule in modulpsr.c)
                var cur = node.argList
                guard let nameNode = cur else { return .boolean(false) }
                let nameVal = try eval(&env, nameNode)
                let moduleName: String
                switch nameVal {
                case .string(let s): moduleName = s
                case .symbol(let s): moduleName = s
                default: moduleName = "UNNAMED"
                }
                
                cur = nameNode.nextArg
                var exportList: PortItem? = nil
                var importList: PortItem? = nil
                
                // Parsing export/import list
                while let clause = cur {
                    if clause.type == .fcall {
                        let clauseName = (clause.value?.value as? String) ?? ""
                        
                        if clauseName == "export" {
                            // (export ?ALL) o (export <type> <names>...)
                            var arg = clause.argList
                            if let firstArg = arg, firstArg.type == .symbol,
                               let sym = firstArg.value?.value as? String, sym == "?ALL" {
                                // Export tutto
                                exportList = PortItem(moduleName: "*", constructType: nil, constructName: nil)
                            } else if let typeArg = arg {
                                let constructType = (typeArg.value?.value as? String) ?? ""
                                arg = typeArg.nextArg
                                // Export specifici costrutti
                                while let nameArg = arg {
                                    let constructName = (nameArg.value?.value as? String) ?? ""
                                    let item = PortItem(moduleName: moduleName, constructType: constructType, constructName: constructName)
                                    item.next = exportList
                                    exportList = item
                                    arg = nameArg.nextArg
                                }
                            }
                        } else if clauseName == "import" {
                            // (import <module-name> <type> <names>...)
                            var arg = clause.argList
                            guard let fromModuleArg = arg else { cur = clause.nextArg; continue }
                            let fromModule = (fromModuleArg.value?.value as? String) ?? ""
                            arg = fromModuleArg.nextArg
                            
                            guard let typeArg = arg else { cur = clause.nextArg; continue }
                            let constructType = (typeArg.value?.value as? String) ?? ""
                            arg = typeArg.nextArg
                            
                            // Import specifici costrutti
                            while let nameArg = arg {
                                let constructName = (nameArg.value?.value as? String) ?? ""
                                let item = PortItem(moduleName: fromModule, constructType: constructType, constructName: constructName)
                                item.next = importList
                                importList = item
                                arg = nameArg.nextArg
                            }
                        }
                    }
                    cur = clause.nextArg
                }
                
                // Crea il modulo
                if let newModule = env.createDefmodule(name: moduleName, importList: importList, exportList: exportList) {
                    // Imposta come modulo corrente
                    _ = env.setCurrentModule(newModule)
                    return .symbol(moduleName)
                } else {
                    return .boolean(false)
                }
            }
            if name == "assert" {
                // Special form: supporta due sintassi:
                //   1. (assert (fact-name (slot value)...))  - deftemplate format
                //   2. (assert fact-name slot value...)       - ordered/flat format
                // Ref: FactParseToken in factmngr.c
                guard let firstArg = node.argList else { return .none }
                
                var assertArgs: [Value] = []
                
                // Check quale formato: se firstArg è fcall, è formato 1, altrimenti formato 2
                if firstArg.type == .fcall, let factName = firstArg.value?.value as? String {
                    // Formato 1: (assert (fact-name (slot value)...))
                    assertArgs.append(.symbol(factName))
                    
                    var slotNode = firstArg.argList
                    while let sn = slotNode {
                        defer { slotNode = sn.nextArg }
                        guard let slotName = sn.value?.value as? String else { continue }
                        assertArgs.append(.symbol(slotName))
                        
                        let isMultifield = env.templates[factName]?.slots[slotName]?.isMultifield ?? false
                        if isMultifield {
                            var values: [Value] = []
                            var valueNode = sn.argList
                            while let vn = valueNode {
                                values.append(try eval(&env, vn))
                                valueNode = vn.nextArg
                            }
                            assertArgs.append(.multifield(values))
                        } else if let valueNode = sn.argList {
                            let val = try eval(&env, valueNode)
                            assertArgs.append(val)
                        } else {
                            assertArgs.append(.none)
                        }
                    }
                } else {
                    // Formato 2: (assert fact-name slot value...) - valuta tutti gli argomenti
                    var cur = node.argList
                    while let arg = cur {
                        let val = try eval(&env, arg)
                        assertArgs.append(val)
                        cur = arg.nextArg
                    }
                }
                
                // Chiama builtin_assert con gli argomenti correttamente formattati
                if let assertFn = env.functionTable["assert"] {
                    return try assertFn.impl(&env, assertArgs)
                }
                return .none
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
            var name = (node.value?.value as? String) ?? ""
            // ✅ Rimuovi "?" dal nome per compatibilità con bindings (salvati senza "?")
            if name.hasPrefix("?") { name = String(name.dropFirst()) }
            return env.localBindings[name] ?? env.globalBindings[name] ?? .none
        case .mfVariable:
            var name = (node.value?.value as? String) ?? ""
            // ✅ Rimuovi "$?" dal nome
            if name.hasPrefix("$?") { name = String(name.dropFirst(2)) }
            else if name.hasPrefix("?") { name = String(name.dropFirst()) }
            return env.localBindings[name] ?? .none
        case .gblVariable:
            var name = (node.value?.value as? String) ?? ""
            // ✅ Rimuovi "?*" e "*" dal nome
            if name.hasPrefix("?*") { name = String(name.dropFirst(2)) }
            if name.hasSuffix("*") { name = String(name.dropLast()) }
            return env.globalBindings[name] ?? .none
        case .mfGblVariable:
            var name = (node.value?.value as? String) ?? ""
            // ✅ Rimuovi "$?*" e "*" dal nome
            if name.hasPrefix("$?*") { name = String(name.dropFirst(3)) }
            if name.hasSuffix("*") { name = String(name.dropLast()) }
            return env.globalBindings[name] ?? .none
        case .instanceName:
            return .symbol((node.value?.value as? String) ?? "")
        }
    }

    // Parse a simple pattern di forma (entity slot val slot val ...)
    // Also collects predicate expressions found in slot values.
    private static func parseSimplePattern(_ env: inout Environment, _ node: ExpressionNode) -> (Pattern, [ExpressionNode])? {
        guard node.type == .fcall else { return nil }
        normalizePatternNodeInPlace(node)
        let pname = (node.value?.value as? String) ?? ""
        var slots: [String: PatternTest] = [:]
        var predicates: [ExpressionNode] = []
        var arg = node.argList
        while let snameNode = arg {
            guard snameNode.type == .symbol, let sname = (snameNode.value?.value as? String) else { break }
            var cur = snameNode.nextArg
            guard let valNode = cur else { break }
            let isMulti = env.templates[pname]?.slots[sname]?.isMultifield ?? false
            if isMulti {
                let slotNames = Set(env.templates[pname]?.slots.keys.map { $0 } ?? [])
                var items: [PatternTest] = []
                var last: ExpressionNode? = nil
                var run = true
                while run, let vn = cur {
                    if vn.type == .symbol, let sym = (vn.value?.value as? String), items.count > 0, slotNames.contains(sym) {
                        break
                    }
                    items.append(patternTestFromNode(&env, vn, &predicates))
                    last = vn
                    cur = vn.nextArg
                    if cur == nil { run = false }
                }
                let test: PatternTest = PatternTest(kind: .sequence(items))
                slots[sname] = test
                arg = (last?.nextArg) ?? cur
            } else {
                let test = patternTestFromNode(&env, valNode, &predicates)
                slots[sname] = test
                arg = valNode.nextArg
            }
        }
        return (Pattern(name: pname, slots: slots, negated: false, exists: false), predicates)
    }

    private static func patternTestFromNode(
        _ env: inout Environment,
        _ node: ExpressionNode,
        _ predicates: inout [ExpressionNode]
    ) -> PatternTest {
        switch node.type {
        case .integer, .float, .string, .symbol:
            let val = (try? eval(&env, node)) ?? .none
            return PatternTest(kind: .constant(val))
        case .variable:
            return PatternTest(kind: .variable((node.value?.value as? String) ?? ""))
        case .mfVariable:
            return PatternTest(kind: .mfVariable((node.value?.value as? String) ?? ""))
        case .fcall:
            predicates.append(node)
            return PatternTest(kind: .predicate(node))
        default:
            return PatternTest(kind: .constant(.none))
        }
    }

    private static func normalizePatternNodeInPlace(_ node: ExpressionNode) {
        var previous: ExpressionNode? = nil
        var current = node.argList
        while let arg = current {
            if arg.type == .fcall, let slotName = arg.value?.value as? String {
                let symbolNode = Expressions.GenConstant(.symbol, slotName)
                var last: ExpressionNode? = symbolNode
                var child = arg.argList
                while let valueNode = child {
                    let clonedValue = cloneExpressionNode(valueNode)
                    last?.nextArg = clonedValue
                    last = clonedValue
                    child = valueNode.nextArg
                }
                last?.nextArg = arg.nextArg
                if let prev = previous {
                    prev.nextArg = symbolNode
                } else {
                    node.argList = symbolNode
                }
                previous = last
                current = last?.nextArg
                continue
            }
            previous = arg
            current = arg.nextArg
        }
    }

    private static func cloneExpressionNode(_ node: ExpressionNode) -> ExpressionNode {
        let copy = ExpressionNode(type: node.type, value: node.value)
        if let argHead = node.argList {
            var clonedArgs: [ExpressionNode] = []
            var current: ExpressionNode? = argHead
            while let n = current {
                clonedArgs.append(cloneExpressionNode(n))
                current = n.nextArg
            }
            Expressions.linkArgs(copy, clonedArgs)
        }
        return copy
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
