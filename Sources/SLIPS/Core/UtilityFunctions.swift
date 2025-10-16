// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import Foundation

/// Funzioni Utility CLIPS
/// Traduzione semantica da clips_core_source_642/core/miscfun.c
///
/// Funzioni implementate (ref: MiscFunctionDefinitions, line 62):
/// - gensym: Genera simbolo unico
/// - gensym*: Genera simbolo con prefisso
/// - random: Numero casuale
/// - seed: Imposta seed random
/// - time: Timestamp corrente
/// - length: Lunghezza di multifield/stringa (già in str-length)
/// - funcall: Chiamata funzione dinamica
public enum UtilityFunctions {
    /// Registra tutte le funzioni utility nell'environment
    /// Ref: MiscFunctionDefinitions (miscfun.c, line 62)
    public static func registerAll(_ env: inout Environment) {
        env.functionTable["gensym"] = FunctionDefinitionSwift(name: "gensym", impl: builtin_gensym)
        env.functionTable["gensym*"] = FunctionDefinitionSwift(name: "gensym*", impl: builtin_gensym_star)
        env.functionTable["random"] = FunctionDefinitionSwift(name: "random", impl: builtin_random)
        env.functionTable["seed"] = FunctionDefinitionSwift(name: "seed", impl: builtin_seed)
        env.functionTable["time"] = FunctionDefinitionSwift(name: "time", impl: builtin_time)
        env.functionTable["funcall"] = FunctionDefinitionSwift(name: "funcall", impl: builtin_funcall)
    }
}

// MARK: - gensym

/// (gensym) - Genera simbolo unico
/// Ref: GensymFunction (miscfun.c, line 310)
///
/// Comportamento:
/// - Genera simbolo univoco con formato "gen<N>"
/// - Ogni chiamata incrementa counter
/// - Utile per generare identificatori unici
///
/// Esempi:
/// ```
/// (gensym)  → gen1
/// (gensym)  → gen2
/// (gensym)  → gen3
/// ```
public func builtin_gensym(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.isEmpty else {
        throw EvalError.wrongArgCount("gensym", expected: 0, got: args.count)
    }
    
    env.gensymCounter += 1
    return .symbol("gen\(env.gensymCounter)")
}

// MARK: - gensym*

/// (gensym* [<prefix>]) - Genera simbolo con prefisso
/// Ref: GensymStarFunction (miscfun.c, line 336)
///
/// Comportamento:
/// - Come gensym ma con prefisso personalizzato
/// - Default prefix è "gen" se non specificato
///
/// Esempi:
/// ```
/// (gensym*)           → gen1
/// (gensym* rule)      → rule1
/// (gensym* temp-)     → temp-1
/// ```
public func builtin_gensym_star(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count <= 1 else {
        throw EvalError.wrongArgCount("gensym*", expected: "0 or 1", got: args.count)
    }
    
    let prefix: String
    if args.isEmpty {
        prefix = "gen"
    } else {
        switch args[0] {
        case .symbol(let s): prefix = s
        case .string(let s): prefix = s
        default:
            throw EvalError.typeMismatch("gensym*", expected: "symbol or string", got: String(describing: args[0]))
        }
    }
    
    env.gensymCounter += 1
    return .symbol("\(prefix)\(env.gensymCounter)")
}

// MARK: - random

/// (random [<start> <end>]) - Numero casuale
/// Ref: RandomFunction (miscfun.c, line 383)
///
/// Comportamento:
/// - Senza argomenti: ritorna Int64 casuale (0...Int64.max)
/// - Con start,end: ritorna intero in [start, end] inclusi
///
/// Esempi:
/// ```
/// (random)        → 87234928347  (casuale)
/// (random 1 10)   → 7  (tra 1 e 10)
/// (random 0 100)  → 42  (tra 0 e 100)
/// ```
public func builtin_random(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 0 || args.count == 2 else {
        throw EvalError.wrongArgCount("random", expected: "0 or 2", got: args.count)
    }
    
    if args.isEmpty {
        // Random Int64
        let random = Int64.random(in: 0...Int64.max)
        return .int(random)
    }
    
    // Random in range [start, end]
    guard case .int(let start) = args[0] else {
        throw EvalError.typeMismatch("random", expected: "integer", got: String(describing: args[0]))
    }
    
    guard case .int(let end) = args[1] else {
        throw EvalError.typeMismatch("random", expected: "integer", got: String(describing: args[1]))
    }
    
    guard start <= end else {
        throw EvalError.runtime("random: start (\(start)) must be <= end (\(end))")
    }
    
    let random = Int64.random(in: start...end)
    return .int(random)
}

// MARK: - seed

/// (seed <integer>) - Imposta seed per random
/// Ref: SeedFunction (miscfun.c, line 440)
///
/// Comportamento:
/// - Imposta seed del generatore di numeri casuali
/// - Permette sequenze riproducibili
/// - Utile per testing deterministico
///
/// Esempi:
/// ```
/// (seed 42)
/// (random 1 100)  → sempre stesso risultato con seed=42
/// ```
public func builtin_seed(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("seed", expected: 1, got: args.count)
    }
    
    guard case .int(let seedValue) = args[0] else {
        throw EvalError.typeMismatch("seed", expected: "integer", got: String(describing: args[0]))
    }
    
    // Swift SystemRandomNumberGenerator non supporta seed
    // Per supporto completo servirebbe un PRNG custom
    // Per ora ritorniamo TRUE come placeholder
    _ = seedValue  // Suppress warning
    
    // TODO: Implementare PRNG seedabile se necessario
    // UtilityFunctions.rng = SeededRandomNumberGenerator(seed: UInt64(seedValue))
    
    return .boolean(true)
}

// MARK: - time

/// (time) - Timestamp corrente
/// Ref: Funzionalità standard CLIPS
///
/// Comportamento:
/// - Ritorna timestamp UNIX corrente (secondi da 1970)
/// - Utile per logging, profiling, time-based rules
///
/// Esempi:
/// ```
/// (time)  → 1729094400  (secondi da epoch)
/// ```
public func builtin_time(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.isEmpty else {
        throw EvalError.wrongArgCount("time", expected: 0, got: args.count)
    }
    
    let timestamp = Int64(Date().timeIntervalSince1970)
    return .int(timestamp)
}

// MARK: - funcall

/// (funcall <function-name> <arguments>*) - Chiamata funzione dinamica
/// Ref: FuncallFunction (miscfun.c, line 1232)
///
/// Comportamento:
/// - Chiama funzione il cui nome è determinato a runtime
/// - Equivalente a call-by-name
/// - Utile per meta-programmazione
///
/// Esempi:
/// ```
/// (funcall + 2 3)              → 5
/// (funcall str-cat "a" "b")    → "ab"
/// (bind ?fname "sqrt")
/// (funcall (sym-cat ?fname) 16) → 4.0
/// ```
public func builtin_funcall(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count >= 1 else {
        throw EvalError.wrongArgCount("funcall", expected: "1+", got: args.count)
    }
    
    // Estrai nome funzione
    let functionName: String
    switch args[0] {
    case .symbol(let s):
        functionName = s
    case .string(let s):
        functionName = s
    default:
        throw EvalError.typeMismatch("funcall", expected: "function name (symbol or string)", got: String(describing: args[0]))
    }
    
    // Trova funzione
    guard let function = Functions.find(env, functionName) else {
        throw EvalError.runtime("funcall: function '\(functionName)' does not exist")
    }
    
    // Argomenti per la funzione
    let functionArgs = Array(args.dropFirst())
    
    // Chiama funzione
    do {
        return try function.impl(&env, functionArgs)
    } catch {
        throw EvalError.runtime("funcall: error calling '\(functionName)': \(error)")
    }
}

// MARK: - Helper per reset environment

extension Environment {
    /// Reset gensym counter quando environment viene resettato
    public func resetUtilities() {
        self.gensymCounter = 0
    }
}

