// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import Foundation

/// Funzioni di Pretty Printing CLIPS
/// Traduzione semantica da clips_core_source_642/core/pprint.c e crstrtgy.c
///
/// Funzioni implementate:
/// - ppdefmodule: Pretty print defmodule
/// - ppdeffacts: Pretty print deffacts
/// - Miglioramenti a ppdefrule e ppdeftemplate esistenti
public enum PrettyPrintFunctions {
    /// Registra tutte le funzioni di pretty printing nell'environment
    public static func registerAll(_ env: inout Environment) {
        env.functionTable["ppdefmodule"] = FunctionDefinitionSwift(name: "ppdefmodule", impl: builtin_ppdefmodule)
        env.functionTable["ppdeffacts"] = FunctionDefinitionSwift(name: "ppdeffacts", impl: builtin_ppdeffacts)
        env.functionTable["list-constructs"] = FunctionDefinitionSwift(name: "list-constructs", impl: builtin_list_constructs)
        env.functionTable["get-construct-list"] = FunctionDefinitionSwift(name: "get-construct-list", impl: builtin_get_construct_list)
    }
}

// MARK: - ppdefmodule

/// (ppdefmodule <module-name>) - Pretty print di un defmodule
/// Ref: PPDefmoduleCommand (modulpsr.c, CLIPS 6.42)
///
/// Comportamento:
/// - Stampa la definizione completa del modulo
/// - Include import/export se presenti
/// - Formattazione leggibile
///
/// Esempi:
/// ```
/// (ppdefmodule MAIN)
/// (defmodule MAIN
///   (export ?ALL))
///
/// (ppdefmodule MY-MODULE)
/// (defmodule MY-MODULE
///   (import MAIN ?ALL)
///   (export deftemplate person))
/// ```
public func builtin_ppdefmodule(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("ppdefmodule", expected: 1, got: args.count)
    }
    
    let moduleName: String
    switch args[0] {
    case .string(let s):
        moduleName = s
    case .symbol(let s):
        moduleName = s
    default:
        throw EvalError.typeMismatch("ppdefmodule", expected: "symbol or string", got: String(describing: args[0]))
    }
    
    // Cerca il modulo nel sistema moduli di Modules.swift
    // Per ora implementazione base - stampa nome modulo
    // TODO: integrare con sistema moduli completo quando Defmodule è accessibile
    Router.WriteString(&env, Router.STDOUT, "(defmodule ")
    Router.WriteString(&env, Router.STDOUT, moduleName)
    Router.Writeln(&env, ")")
    
    Router.Writeln(&env, "; Module details not available in current implementation")
    
    return .boolean(true)
}

// MARK: - ppdeffacts

/// (ppdeffacts <deffacts-name>) - Pretty print di un deffacts
/// Ref: PPDeffactsCommand (dffctpsr.c, CLIPS 6.42)
///
/// Comportamento:
/// - Stampa la definizione completa del deffacts
/// - Include tutti i fatti iniziali
/// - Formattazione leggibile
///
/// Esempi:
/// ```
/// (ppdeffacts startup)
/// (deffacts startup
///   (initial-fact)
///   (count 0))
/// ```
public func builtin_ppdeffacts(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("ppdeffacts", expected: 1, got: args.count)
    }
    
    let deffactsName: String
    switch args[0] {
    case .string(let s):
        deffactsName = s
    case .symbol(let s):
        deffactsName = s
    default:
        throw EvalError.typeMismatch("ppdeffacts", expected: "symbol or string", got: String(describing: args[0]))
    }
    
    // Cerca il deffacts
    // deffacts è [String: [[Value]]] - array di array di Value
    guard let factsList = env.deffacts[deffactsName] else {
        Router.Writeln(&env, "No such deffacts: \(deffactsName)")
        return .boolean(false)
    }
    
    // Stampa header
    Router.WriteString(&env, Router.STDOUT, "(deffacts ")
    Router.WriteString(&env, Router.STDOUT, deffactsName)
    Router.Writeln(&env, "")
    
    // Stampa ogni fatto (ogni fact è [Value])
    for fact in factsList {
        Router.WriteString(&env, Router.STDOUT, "  (")
        let factStr = fact.map { prettyPrintValue($0) }.joined(separator: " ")
        Router.WriteString(&env, Router.STDOUT, factStr)
        Router.Writeln(&env, ")")
    }
    
    Router.Writeln(&env, ")")
    
    return .boolean(true)
}

// MARK: - list-constructs

/// (list-constructs [<module-name>]) - Lista tutti i costrutti
///
/// Comportamento:
/// - Lista deftemplate, defrule, deffacts, defmodule, defglobal
///
/// Esempi:
/// ```
/// (list-constructs)  → stampa tutti i costrutti
/// ```
public func builtin_list_constructs(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count <= 1 else {
        throw EvalError.wrongArgCount("list-constructs", expected: "0 or 1", got: args.count)
    }
    
    // Lista templates
    if !env.templates.isEmpty {
        Router.Writeln(&env, "Templates:")
        for name in env.templates.keys.sorted() {
            Router.Writeln(&env, "  \(name)")
        }
    }
    
    // Lista rules
    if !env.rules.isEmpty {
        Router.Writeln(&env, "Rules:")
        for rule in env.rules.sorted(by: { $0.name < $1.name }) {
            Router.Writeln(&env, "  \(rule.name)")
        }
    }
    
    // Lista deffacts
    if !env.deffacts.isEmpty {
        Router.Writeln(&env, "Deffacts:")
        for name in env.deffacts.keys.sorted() {
            Router.Writeln(&env, "  \(name)")
        }
    }
    
    // Lista globals
    if !env.globalBindings.isEmpty {
        Router.Writeln(&env, "Globals:")
        for name in env.globalBindings.keys.sorted() {
            Router.Writeln(&env, "  \(name)")
        }
    }
    
    return .boolean(true)
}

// MARK: - get-construct-list

/// (get-construct-list <construct-type> [<module-name>]) - Ottiene lista costrutti
///
/// Tipi supportati:
/// - deftemplate, defrule, deffacts, defmodule, defglobal
///
/// Esempi:
/// ```
/// (get-construct-list deftemplate)  → (create$ person car house)
/// (get-construct-list defrule)      → (create$ rule1 rule2)
/// ```
public func builtin_get_construct_list(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count >= 1 && args.count <= 2 else {
        throw EvalError.wrongArgCount("get-construct-list", expected: "1 or 2", got: args.count)
    }
    
    guard case .symbol(let constructType) = args[0] else {
        throw EvalError.typeMismatch("get-construct-list", expected: "symbol", got: String(describing: args[0]))
    }
    
    switch constructType.lowercased() {
    case "deftemplate":
        let names = env.templates.keys.sorted().map { Value.symbol($0) }
        return .multifield(names)
        
    case "defrule":
        let names = env.rules.map { Value.symbol($0.name) }
        return .multifield(names)
        
    case "deffacts":
        let names = env.deffacts.keys.sorted().map { Value.symbol($0) }
        return .multifield(names)
        
    case "defglobal":
        let names = env.globalBindings.keys.sorted().map { Value.symbol($0) }
        return .multifield(names)
        
    case "defmodule":
        // Per ora solo MAIN
        return .multifield([.symbol("MAIN")])
        
    default:
        throw EvalError.runtime("get-construct-list: unknown construct type '\(constructType)'")
    }
}

// MARK: - Helper: Pretty Print Value

/// Converte un Value in rappresentazione stringa pretty
private func prettyPrintValue(_ value: Value) -> String {
    switch value {
    case .none:
        return "nil"
    case .int(let i):
        return String(i)
    case .float(let d):
        // Formatta float come CLIPS
        if d == Double(Int64(d)) {
            return String(format: "%.1f", d)
        } else {
            return String(d)
        }
    case .string(let s):
        // Escape quotes
        let escaped = s.replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    case .symbol(let s):
        return s
    case .boolean(let b):
        return b ? "TRUE" : "FALSE"
    case .multifield(let arr):
        return arr.map { prettyPrintValue($0) }.joined(separator: " ")
    }
}

// MARK: - Estensioni Pretty Print per Funzioni Esistenti

/// Migliora builtin_ppdefrule esistente con formattazione più ricca
/// (Manteniamo la funzione esistente ma potremmo estenderla in futuro)
extension Environment {
    /// Formatta una regola in modo leggibile
    public func prettyPrintRule(_ rule: Rule) -> String {
        var result = "(defrule \(rule.displayName)"
        
        // Salience se non default
        if rule.salience != 0 {
            result += "\n  (declare (salience \(rule.salience)))"
        }
        
        // Pattern
        for pattern in rule.patterns {
            result += "\n  "
            result += prettyPrintPattern(pattern)
        }
        
        // RHS (non disponibile nella struttura attuale)
        // TODO: salvare RHS nel Rule per pretty print completo
        
        result += ")"
        return result
    }
    
    /// Formatta un pattern
    private func prettyPrintPattern(_ pattern: Pattern) -> String {
        var result = "(\(pattern.name)"
        
        for (slotName, test) in pattern.slots.sorted(by: { $0.key < $1.key }) {
            result += " (\(slotName) "
            result += prettyPrintTest(test)
            result += ")"
        }
        
        result += ")"
        return result
    }
    
    /// Formatta un test di pattern
    private func prettyPrintTest(_ test: PatternTest) -> String {
        switch test.kind {
        case .constant(let value):
            return prettyPrintValue(value)
        case .variable(let varName):
            return "?\(varName)"
        case .mfVariable(let varName):
            return "$?\(varName)"
        case .predicate:
            return "<predicate>"  // Simplified
        case .sequence(let tests):
            return tests.map { prettyPrintTest($0) }.joined(separator: " ")
        }
    }
}

