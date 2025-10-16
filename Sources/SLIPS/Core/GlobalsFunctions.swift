// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import Foundation

/// Funzioni Defglobal CLIPS
/// Traduzione semantica da clips_core_source_642/core/globldef.c e globlbsc.c
///
/// Funzioni implementate:
/// - defglobal: Definisce variabile globale
/// - show-defglobals: Mostra variabili globali
/// - list-defglobals: Lista nomi variabili globali
/// - undefglobal: Rimuove variabile globale
/// - get-defglobal-list: Ottiene lista come multifield
public enum GlobalsFunctions {
    /// Registra tutte le funzioni defglobal nell'environment
    public static func registerAll(_ env: inout Environment) {
        env.functionTable["defglobal"] = FunctionDefinitionSwift(name: "defglobal", impl: builtin_defglobal)
        env.functionTable["show-defglobals"] = FunctionDefinitionSwift(name: "show-defglobals", impl: builtin_show_defglobals)
        env.functionTable["list-defglobals"] = FunctionDefinitionSwift(name: "list-defglobals", impl: builtin_list_defglobals)
        env.functionTable["undefglobal"] = FunctionDefinitionSwift(name: "undefglobal", impl: builtin_undefglobal)
        env.functionTable["get-defglobal-list"] = FunctionDefinitionSwift(name: "get-defglobal-list", impl: builtin_get_defglobal_list)
        env.functionTable["get-defglobal-watch"] = FunctionDefinitionSwift(name: "get-defglobal-watch", impl: builtin_get_defglobal_watch)
        env.functionTable["set-defglobal-watch"] = FunctionDefinitionSwift(name: "set-defglobal-watch", impl: builtin_set_defglobal_watch)
        env.functionTable["ppdefglobal"] = FunctionDefinitionSwift(name: "ppdefglobal", impl: builtin_ppdefglobal)
    }
}

// MARK: - defglobal

/// (defglobal [<module-name>] <global-assignment>*) - Definisce variabili globali
/// Ref: DefglobalConstruct parsing (globlpsr.c)
///
/// Comportamento:
/// - Definisce una o più variabili globali
/// - Le variabili sono persistenti tra run
/// - Sintassi: ?*name* = value
///
/// Esempi:
/// ```
/// (defglobal ?*x* = 10)
/// (defglobal ?*name* = "John" ?*age* = 30)
/// (defglobal UTILITIES ?*debug* = TRUE)
/// ```
public func builtin_defglobal(_ env: inout Environment, _ args: [Value]) throws -> Value {
    // Parsing semplificato: (defglobal ?*var* = value ...)
    // In CLIPS reale il parsing è più complesso
    
    guard args.count >= 3 else {
        throw EvalError.wrongArgCount("defglobal", expected: "3+", got: args.count)
    }
    
    var i = 0
    
    // Check per nome modulo opzionale
    if case .symbol(let firstArg) = args[0], !firstArg.hasPrefix("?*") {
        // È un nome modulo, skip
        i = 1
    }
    
    // Parse assignments: ?*name* = value
    while i < args.count {
        // Variabile
        guard case .symbol(let varName) = args[i], varName.hasPrefix("?*"), varName.hasSuffix("*") else {
            throw EvalError.runtime("defglobal: expected global variable name (format: ?*name*)")
        }
        
        i += 1
        
        // Operatore =
        guard i < args.count, case .symbol(let op) = args[i], op == "=" else {
            throw EvalError.runtime("defglobal: expected '=' after variable name")
        }
        
        i += 1
        
        // Valore
        guard i < args.count else {
            throw EvalError.runtime("defglobal: expected value after '='")
        }
        
        let value = args[i]
        i += 1
        
        // Memorizza in globalBindings
        env.globalBindings[varName] = value
        
        if env.watchFacts {  // Riusa watch per defglobal
            Router.Writeln(&env, "==> \(varName) = \(formatValue(value))")
        }
    }
    
    return .boolean(true)
}

// MARK: - show-defglobals

/// (show-defglobals [<module-name>]) - Mostra variabili globali
/// Ref: ShowDefglobalsCommand (globlcom.c)
///
/// Esempi:
/// ```
/// (show-defglobals)        → Mostra tutte le globals
/// (show-defglobals MAIN)   → Mostra globals di MAIN
/// ```
public func builtin_show_defglobals(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count <= 1 else {
        throw EvalError.wrongArgCount("show-defglobals", expected: "0 or 1", got: args.count)
    }
    
    // Mostra tutte le variabili globali
    if env.globalBindings.isEmpty {
        Router.Writeln(&env, "No defglobals are currently defined")
        return .boolean(true)
    }
    
    for (name, value) in env.globalBindings.sorted(by: { $0.key < $1.key }) {
        Router.WriteString(&env, Router.STDOUT, "\(name) = ")
        Router.Writeln(&env, formatValue(value))
    }
    
    return .boolean(true)
}

// MARK: - list-defglobals

/// (list-defglobals [<module-name>]) - Lista nomi defglobal
/// Ref: ListDefglobalsCommand (globlcom.c)
///
/// Esempi:
/// ```
/// (list-defglobals)  → stampa lista
/// ```
public func builtin_list_defglobals(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count <= 1 else {
        throw EvalError.wrongArgCount("list-defglobals", expected: "0 or 1", got: args.count)
    }
    
    for name in env.globalBindings.keys.sorted() {
        Router.Writeln(&env, name)
    }
    
    return .boolean(true)
}

// MARK: - undefglobal

/// (undefglobal <defglobal-name>) - Rimuove defglobal
/// Ref: UndefglobalCommand (globlcom.c)
///
/// Esempi:
/// ```
/// (undefglobal ?*x*)  → Rimuove ?*x*
/// ```
public func builtin_undefglobal(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("undefglobal", expected: 1, got: args.count)
    }
    
    guard case .symbol(let varName) = args[0] else {
        throw EvalError.typeMismatch("undefglobal", expected: "symbol", got: String(describing: args[0]))
    }
    
    if env.globalBindings.removeValue(forKey: varName) != nil {
        return .boolean(true)
    }
    
    return .boolean(false)
}

// MARK: - get-defglobal-list

/// (get-defglobal-list [<module-name>]) - Lista come multifield
/// Ref: GetDefglobalListFunction (globlbsc.c)
///
/// Esempi:
/// ```
/// (get-defglobal-list)  → (create$ ?*x* ?*y* ?*z*)
/// ```
public func builtin_get_defglobal_list(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count <= 1 else {
        throw EvalError.wrongArgCount("get-defglobal-list", expected: "0 or 1", got: args.count)
    }
    
    let names = env.globalBindings.keys.sorted().map { Value.symbol($0) }
    return .multifield(names)
}

// MARK: - Watch defglobal

/// (get-defglobal-watch) - Ottiene stato watch defglobal
public func builtin_get_defglobal_watch(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.isEmpty else {
        throw EvalError.wrongArgCount("get-defglobal-watch", expected: 0, got: args.count)
    }
    
    // Riusiamo watchFacts per semplicità
    return .boolean(env.watchFacts)
}

/// (set-defglobal-watch <value>) - Imposta watch defglobal
public func builtin_set_defglobal_watch(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("set-defglobal-watch", expected: 1, got: args.count)
    }
    
    guard case .symbol(let value) = args[0] else {
        throw EvalError.typeMismatch("set-defglobal-watch", expected: "symbol", got: String(describing: args[0]))
    }
    
    switch value.lowercased() {
    case "on", "true":
        env.watchFacts = true
        return .boolean(true)
    case "off", "false":
        env.watchFacts = false
        return .boolean(false)
    default:
        return .boolean(false)
    }
}

// MARK: - ppdefglobal

/// (ppdefglobal <defglobal-name>) - Pretty print defglobal
///
/// Esempi:
/// ```
/// (ppdefglobal ?*x*)  → (defglobal ?*x* = 10)
/// ```
public func builtin_ppdefglobal(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("ppdefglobal", expected: 1, got: args.count)
    }
    
    guard case .symbol(let varName) = args[0] else {
        throw EvalError.typeMismatch("ppdefglobal", expected: "symbol", got: String(describing: args[0]))
    }
    
    guard let value = env.globalBindings[varName] else {
        Router.Writeln(&env, "No such defglobal: \(varName)")
        return .boolean(false)
    }
    
    Router.WriteString(&env, Router.STDOUT, "(defglobal \(varName) = ")
    Router.WriteString(&env, Router.STDOUT, formatValue(value))
    Router.Writeln(&env, ")")
    
    return .boolean(true)
}

// MARK: - Helper

private func formatValue(_ value: Value) -> String {
    switch value {
    case .none: return "nil"
    case .int(let i): return String(i)
    case .float(let d): return String(d)
    case .string(let s): return "\"\(s)\""
    case .symbol(let s): return s
    case .boolean(let b): return b ? "TRUE" : "FALSE"
    case .multifield(let arr): return "(create$ \(arr.map { formatValue($0) }.joined(separator: " ")))"
    }
}

