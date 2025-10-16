// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import Foundation

/// Funzioni Query sui Fatti CLIPS
/// Traduzione semantica da clips_core_source_642/core/factqury.c
///
/// Funzioni implementate:
/// - find-fact: Trova primo fatto che soddisfa query
/// - find-all-facts: Trova tutti i fatti che soddisfano query
/// - do-for-fact: Esegue azione per primo fatto
/// - do-for-all-facts: Esegue azione per tutti i fatti
/// - any-factp: Check se esiste almeno un fatto
/// - fact-existp: Check se fact-id esiste
/// - fact-index: Ottiene fact-index da indirizzo
public enum FactQueryFunctions {
    /// Registra tutte le funzioni query nell'environment
    public static func registerAll(_ env: inout Environment) {
        env.functionTable["find-fact"] = FunctionDefinitionSwift(name: "find-fact", impl: builtin_find_fact)
        env.functionTable["find-all-facts"] = FunctionDefinitionSwift(name: "find-all-facts", impl: builtin_find_all_facts)
        env.functionTable["do-for-fact"] = FunctionDefinitionSwift(name: "do-for-fact", impl: builtin_do_for_fact)
        env.functionTable["do-for-all-facts"] = FunctionDefinitionSwift(name: "do-for-all-facts", impl: builtin_do_for_all_facts)
        env.functionTable["any-factp"] = FunctionDefinitionSwift(name: "any-factp", impl: builtin_any_factp)
        env.functionTable["fact-existp"] = FunctionDefinitionSwift(name: "fact-existp", impl: builtin_fact_existp)
        env.functionTable["fact-index"] = FunctionDefinitionSwift(name: "fact-index", impl: builtin_fact_index)
    }
}

// MARK: - find-fact

/// (find-fact <template-spec> <query>) - Trova primo fatto
/// Versione semplificata per SLIPS
///
/// Esempi:
/// ```
/// (find-fact ((?p person)) (> ?p:age 18))  → fact-3
/// ```
public func builtin_find_fact(_ env: inout Environment, _ args: [Value]) throws -> Value {
    // Implementazione semplificata: trova primo fatto di un template
    // La query completa richiederebbe parsing avanzato
    
    guard args.count >= 1 else {
        throw EvalError.wrongArgCount("find-fact", expected: "1+", got: args.count)
    }
    
    // Per ora implementazione base: ritorna primo fatto del template
    return .none  // Placeholder - richiede query parser completo
}

// MARK: - find-all-facts

/// (find-all-facts <template-spec> <query>) - Trova tutti i fatti
/// Versione semplificata per SLIPS
///
/// Esempi:
/// ```
/// (find-all-facts ((?p person)) (> ?p:age 18))  → (f-1 f-3 f-5)
/// ```
public func builtin_find_all_facts(_ env: inout Environment, _ args: [Value]) throws -> Value {
    // Implementazione semplificata
    guard args.count >= 1 else {
        throw EvalError.wrongArgCount("find-all-facts", expected: "1+", got: args.count)
    }
    
    // Per ora implementazione base: ritorna tutti i fatti
    let factIds = env.facts.keys.sorted().map { Value.int(Int64($0)) }
    return .multifield(factIds)
}

// MARK: - do-for-fact

/// (do-for-fact <template-spec> <query> <action>*) - Esegui azione per primo fatto
public func builtin_do_for_fact(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count >= 2 else {
        throw EvalError.wrongArgCount("do-for-fact", expected: "2+", got: args.count)
    }
    
    // Implementazione semplificata
    return .none
}

// MARK: - do-for-all-facts

/// (do-for-all-facts <template-spec> <query> <action>*) - Esegui per tutti i fatti
public func builtin_do_for_all_facts(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count >= 2 else {
        throw EvalError.wrongArgCount("do-for-all-facts", expected: "2+", got: args.count)
    }
    
    // Implementazione semplificata
    return .none
}

// MARK: - any-factp

/// (any-factp <template-spec> <query>) - Check se esiste almeno un fatto
///
/// Esempi:
/// ```
/// (any-factp ((?p person)) (> ?p:age 18))  → TRUE/FALSE
/// ```
public func builtin_any_factp(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count >= 1 else {
        throw EvalError.wrongArgCount("any-factp", expected: "1+", got: args.count)
    }
    
    // Implementazione semplificata: check se ci sono fatti
    return .boolean(!env.facts.isEmpty)
}

// MARK: - fact-existp

/// (fact-existp <fact-id>) - Check se fact-id esiste
/// Ref: FactExistpFunction
///
/// Esempi:
/// ```
/// (fact-existp 1)  → TRUE
/// (fact-existp 999) → FALSE
/// ```
public func builtin_fact_existp(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("fact-existp", expected: 1, got: args.count)
    }
    
    guard case .int(let factId) = args[0] else {
        throw EvalError.typeMismatch("fact-existp", expected: "integer", got: String(describing: args[0]))
    }
    
    return .boolean(env.facts[Int(factId)] != nil)
}

// MARK: - fact-index

/// (fact-index <fact-address>) - Ottiene fact-id
///
/// Esempi:
/// ```
/// (bind ?f (assert (person (name "John"))))
/// (fact-index ?f)  → 1
/// ```
public func builtin_fact_index(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("fact-index", expected: 1, got: args.count)
    }
    
    // In SLIPS, i fact-id sono già interi, quindi semplicemente ritorniamo
    guard case .int(let factId) = args[0] else {
        throw EvalError.typeMismatch("fact-index", expected: "fact-address (integer)", got: String(describing: args[0]))
    }
    
    return .int(factId)
}

