// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details
//
// File: MultifieldFunctions.swift
// Traduzione fedele di multifun.c da CLIPS 6.42
// Ref: clips_core_source_642/core/multifun.c

import Foundation

// MARK: - Funzioni Multifield (ref: multifun.c)

/// (nth$ <index> <multifield>) - Ritorna l'n-esimo elemento di un multifield
/// Ref: NthFunction in multifun.c (line 176)
public func builtin_nth$(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 2 else {
        throw EvalError.wrongArgCount("nth$", expected: 2, got: args.count)
    }
    
    // Primo argomento: indice (1-based come in CLIPS)
    guard case .int(let index) = args[0] else {
        throw EvalError.typeMismatch("nth$", expected: "integer", got: String(describing: args[0]))
    }
    
    // Secondo argomento: multifield
    guard case .multifield(let arr) = args[1] else {
        throw EvalError.typeMismatch("nth$", expected: "multifield", got: String(describing: args[1]))
    }
    
    // Verifica indice valido (1-based)
    if index < 1 || index > arr.count {
        throw EvalError.indexOutOfBounds("nth$", index: Int(index), size: arr.count)
    }
    
    // Ritorna elemento (converti da 1-based a 0-based)
    return arr[Int(index - 1)]
}

/// (length$ <multifield>) - Ritorna la lunghezza di un multifield
/// Ref: ImplicitLengthCheck in CLIPS (inferred from create$ behavior)
public func builtin_length$(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("length$", expected: 1, got: args.count)
    }
    
    guard case .multifield(let arr) = args[0] else {
        throw EvalError.typeMismatch("length$", expected: "multifield", got: String(describing: args[0]))
    }
    
    return .int(Int64(arr.count))
}

/// (first$ <multifield>) - Ritorna il primo elemento (singleton multifield)
/// Ref: FirstFunction in multifun.c (line 166)
public func builtin_first$(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("first$", expected: 1, got: args.count)
    }
    
    guard case .multifield(let arr) = args[0] else {
        throw EvalError.typeMismatch("first$", expected: "multifield", got: String(describing: args[0]))
    }
    
    // Ritorna multifield con solo il primo elemento (o vuoto se input vuoto)
    if arr.isEmpty {
        return .multifield([])
    }
    
    return .multifield([arr[0]])
}

/// (rest$ <multifield>) - Ritorna tutti gli elementi tranne il primo
/// Ref: RestFunction in multifun.c (line 167)
public func builtin_rest$(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("rest$", expected: 1, got: args.count)
    }
    
    guard case .multifield(let arr) = args[0] else {
        throw EvalError.typeMismatch("rest$", expected: "multifield", got: String(describing: args[0]))
    }
    
    // Ritorna multifield senza il primo elemento
    if arr.isEmpty {
        return .multifield([])
    }
    
    return .multifield(Array(arr.dropFirst()))
}

/// (subseq$ <multifield> <begin> <end>) - Ritorna sottosequenza [begin, end]
/// Ref: SubseqFunction in multifun.c (line 168)
public func builtin_subseq$(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 3 else {
        throw EvalError.wrongArgCount("subseq$", expected: 3, got: args.count)
    }
    
    guard case .multifield(let arr) = args[0] else {
        throw EvalError.typeMismatch("subseq$", expected: "multifield", got: String(describing: args[0]))
    }
    
    guard case .int(let begin) = args[1] else {
        throw EvalError.typeMismatch("subseq$", expected: "integer for begin", got: String(describing: args[1]))
    }
    
    guard case .int(let end) = args[2] else {
        throw EvalError.typeMismatch("subseq$", expected: "integer for end", got: String(describing: args[2]))
    }
    
    // Verifica indici validi (1-based, inclusivi)
    if begin < 1 || end < begin || end > arr.count {
        throw EvalError.invalidRange("subseq$", begin: Int(begin), end: Int(end), size: arr.count)
    }
    
    // Estrai sottosequenza (converti da 1-based a 0-based)
    let startIdx = Int(begin - 1)
    let endIdx = Int(end) // end è inclusivo in CLIPS
    
    return .multifield(Array(arr[startIdx..<endIdx]))
}

/// (member$ <value> <multifield>) - Cerca valore in multifield, ritorna posizione o FALSE
/// Ref: MemberFunction in multifun.c (line 177)
public func builtin_member$(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 2 else {
        throw EvalError.wrongArgCount("member$", expected: 2, got: args.count)
    }
    
    let needle = args[0]
    
    guard case .multifield(let haystack) = args[1] else {
        throw EvalError.typeMismatch("member$", expected: "multifield", got: String(describing: args[1]))
    }
    
    // Cerca needle in haystack
    if let index = haystack.firstIndex(where: { $0 == needle }) {
        // Ritorna posizione (1-based) come multifield con due elementi: posizione e lunghezza match
        // In CLIPS, member$ ritorna (index length-of-match) dove length è sempre 1 per match singolo
        return .multifield([.int(Int64(index + 1)), .int(1)])
    }
    
    // Non trovato: ritorna FALSE
    return .boolean(false)
}

/// (insert$ <multifield> <index> <value>+) - Inserisce valori a una posizione
/// Ref: InsertFunction in multifun.c (line 173)
public func builtin_insert$(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count >= 3 else {
        throw EvalError.wrongArgCount("insert$", expected: "3+", got: args.count)
    }
    
    guard case .multifield(var arr) = args[0] else {
        throw EvalError.typeMismatch("insert$", expected: "multifield", got: String(describing: args[0]))
    }
    
    guard case .int(let position) = args[1] else {
        throw EvalError.typeMismatch("insert$", expected: "integer for position", got: String(describing: args[1]))
    }
    
    // Verifica posizione valida (1-based, può essere arr.count+1 per append)
    if position < 1 || position > arr.count + 1 {
        throw EvalError.indexOutOfBounds("insert$", index: Int(position), size: arr.count + 1)
    }
    
    // Valori da inserire (args[2...])
    let toInsert = Array(args[2...])
    
    // Inserisci a posizione (converti da 1-based a 0-based)
    let idx = Int(position - 1)
    arr.insert(contentsOf: toInsert, at: idx)
    
    return .multifield(arr)
}

/// (delete$ <multifield> <begin> <end>) - Cancella range [begin, end]
/// Ref: DeleteFunction in multifun.c (line 171)
public func builtin_delete$(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 3 else {
        throw EvalError.wrongArgCount("delete$", expected: 3, got: args.count)
    }
    
    guard case .multifield(var arr) = args[0] else {
        throw EvalError.typeMismatch("delete$", expected: "multifield", got: String(describing: args[0]))
    }
    
    guard case .int(let begin) = args[1] else {
        throw EvalError.typeMismatch("delete$", expected: "integer for begin", got: String(describing: args[1]))
    }
    
    guard case .int(let end) = args[2] else {
        throw EvalError.typeMismatch("delete$", expected: "integer for end", got: String(describing: args[2]))
    }
    
    // Verifica range valido (1-based, inclusivo)
    if begin < 1 || end < begin || end > arr.count {
        throw EvalError.invalidRange("delete$", begin: Int(begin), end: Int(end), size: arr.count)
    }
    
    // Rimuovi range (converti da 1-based a 0-based)
    let startIdx = Int(begin - 1)
    let endIdx = Int(end) // end è inclusivo, quindi rimuovi fino a endIdx-1 incluso
    
    arr.removeSubrange(startIdx..<endIdx)
    
    return .multifield(arr)
}

/// (explode$ <string>) - Converte stringa in multifield di simboli
/// Ref: ExplodeFunction in multifun.c (line 174)
public func builtin_explode$(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("explode$", expected: 1, got: args.count)
    }
    
    let str: String
    switch args[0] {
    case .string(let s):
        str = s
    case .symbol(let s):
        str = s
    default:
        throw EvalError.typeMismatch("explode$", expected: "string or symbol", got: String(describing: args[0]))
    }
    
    // Split per whitespace e converti tokens in simboli/numeri
    let tokens = str.split(whereSeparator: { $0.isWhitespace })
    var result: [Value] = []
    
    for token in tokens {
        let trimmed = token.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { continue }
        
        // Prova a parsare come numero
        if let intVal = Int64(trimmed) {
            result.append(.int(intVal))
        } else if let floatVal = Double(trimmed) {
            result.append(.float(floatVal))
        } else {
            // Altrimenti è un simbolo
            result.append(.symbol(String(trimmed)))
        }
    }
    
    return .multifield(result)
}

/// (implode$ <multifield>) - Converte multifield in stringa
/// Ref: ImplodeFunction in multifun.c (line 175) e ImplodeMultifield in multifld.c
public func builtin_implode$(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("implode$", expected: 1, got: args.count)
    }
    
    guard case .multifield(let arr) = args[0] else {
        throw EvalError.typeMismatch("implode$", expected: "multifield", got: String(describing: args[0]))
    }
    
    // Converti ogni elemento in stringa e concatena con spazi
    let parts = arr.map { valueToString($0) }
    let result = parts.joined(separator: " ")
    
    return .string(result)
}

// MARK: - Helper per implode$

private func valueToString(_ value: Value) -> String {
    switch value {
    case .int(let i):
        return String(i)
    case .float(let d):
        return String(d)
    case .string(let s):
        return "\"\(s)\""  // Quote strings
    case .symbol(let s):
        return s
    case .boolean(let b):
        return b ? "TRUE" : "FALSE"
    case .multifield(let arr):
        // Nested multifield: stampa come parentesi
        let inner = arr.map { valueToString($0) }.joined(separator: " ")
        return "(\(inner))"
    case .none:
        return "nil"
    }
}

// MARK: - Registrazione funzioni

public enum MultifieldFunctions {
    /// Registra tutte le funzioni multifield nell'environment
    /// Ref: MultifieldFunctionDefinitions in multifun.c (line 160)
    public static func registerAll(_ env: inout Environment) {
        env.functionTable["nth$"] = FunctionDefinitionSwift(name: "nth$", impl: builtin_nth$)
        env.functionTable["length$"] = FunctionDefinitionSwift(name: "length$", impl: builtin_length$)
        env.functionTable["first$"] = FunctionDefinitionSwift(name: "first$", impl: builtin_first$)
        env.functionTable["rest$"] = FunctionDefinitionSwift(name: "rest$", impl: builtin_rest$)
        env.functionTable["subseq$"] = FunctionDefinitionSwift(name: "subseq$", impl: builtin_subseq$)
        env.functionTable["member$"] = FunctionDefinitionSwift(name: "member$", impl: builtin_member$)
        env.functionTable["insert$"] = FunctionDefinitionSwift(name: "insert$", impl: builtin_insert$)
        env.functionTable["delete$"] = FunctionDefinitionSwift(name: "delete$", impl: builtin_delete$)
        env.functionTable["explode$"] = FunctionDefinitionSwift(name: "explode$", impl: builtin_explode$)
        env.functionTable["implode$"] = FunctionDefinitionSwift(name: "implode$", impl: builtin_implode$)
    }
}

