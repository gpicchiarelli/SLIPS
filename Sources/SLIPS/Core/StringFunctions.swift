// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import Foundation

/// Funzioni stringa CLIPS
/// Traduzione semantica da clips_core_source_642/core/strngfun.c
///
/// Funzioni implementate (ref: StringFunctionDefinitions, line 132-154):
/// - str-cat, sym-cat: Concatenazione stringhe/simboli
/// - str-length, str-byte-length: Lunghezza stringa (caratteri/byte)
/// - str-compare: Confronto tra stringhe
/// - upcase, lowcase: Conversione maiuscolo/minuscolo
/// - sub-string: Estrazione sottostringa
/// - str-index: Ricerca posizione sottostringa
/// - str-replace: Sostituzione sottostringa
/// - string-to-field: Conversione stringa → valore
///
/// Nota: eval e build sono implementati in evaluator.swift
public enum StringFunctions {
    /// Registra tutte le funzioni stringa nell'environment
    /// Ref: StringFunctionDefinitions (strngfun.c, line 132)
    public static func registerAll(_ env: inout Environment) {
        env.functionTable["str-cat"] = FunctionDefinitionSwift(name: "str-cat", impl: builtin_str_cat)
        env.functionTable["sym-cat"] = FunctionDefinitionSwift(name: "sym-cat", impl: builtin_sym_cat)
        env.functionTable["str-length"] = FunctionDefinitionSwift(name: "str-length", impl: builtin_str_length)
        env.functionTable["str-byte-length"] = FunctionDefinitionSwift(name: "str-byte-length", impl: builtin_str_byte_length)
        env.functionTable["str-compare"] = FunctionDefinitionSwift(name: "str-compare", impl: builtin_str_compare)
        env.functionTable["upcase"] = FunctionDefinitionSwift(name: "upcase", impl: builtin_upcase)
        env.functionTable["lowcase"] = FunctionDefinitionSwift(name: "lowcase", impl: builtin_lowcase)
        env.functionTable["sub-string"] = FunctionDefinitionSwift(name: "sub-string", impl: builtin_sub_string)
        env.functionTable["str-index"] = FunctionDefinitionSwift(name: "str-index", impl: builtin_str_index)
        env.functionTable["str-replace"] = FunctionDefinitionSwift(name: "str-replace", impl: builtin_str_replace)
        env.functionTable["string-to-field"] = FunctionDefinitionSwift(name: "string-to-field", impl: builtin_string_to_field)
    }
}

// MARK: - str-cat: Concatenazione stringhe

/// (str-cat <expression>*) - Concatena espressioni in una stringa
/// Ref: StrCatFunction (strngfun.c, line 160)
///
/// Comportamento:
/// - Accetta 1+ argomenti di qualsiasi tipo
/// - Converte ogni argomento in stringa
/// - Ritorna la concatenazione come stringa
///
/// Esempi:
/// ```
/// (str-cat "Hello" " " "World")  → "Hello World"
/// (str-cat "Value: " 42)         → "Value: 42"
/// (str-cat)                      → ""
/// ```
public func builtin_str_cat(_ env: inout Environment, _ args: [Value]) throws -> Value {
    // str-cat accetta 0+ argomenti (CLIPS 6.42 fix per funcall)
    if args.isEmpty {
        return .string("")
    }
    
    var result = ""
    for arg in args {
        result += valueToString(arg)
    }
    
    return .string(result)
}

// MARK: - sym-cat: Concatenazione simboli

/// (sym-cat <expression>*) - Concatena espressioni in un simbolo
/// Ref: SymCatFunction (strngfun.c, line 169)
///
/// Comportamento:
/// - Come str-cat ma ritorna un simbolo invece di stringa
/// - Utile per creare nomi dinamici
///
/// Esempi:
/// ```
/// (sym-cat rule- 1)              → rule-1
/// (sym-cat prefix _ suffix)      → prefix_suffix
/// ```
public func builtin_sym_cat(_ env: inout Environment, _ args: [Value]) throws -> Value {
    if args.isEmpty {
        return .symbol("")
    }
    
    var result = ""
    for arg in args {
        result += valueToString(arg)
    }
    
    return .symbol(result)
}

// MARK: - str-length: Lunghezza stringa (caratteri)

/// (str-length <string-or-symbol>) - Ritorna lunghezza in caratteri UTF-8
/// Ref: StrLengthFunction (strngfun.c, line 235)
///
/// Comportamento:
/// - Conta caratteri Unicode, non byte
/// - "café" ha lunghezza 4, non 5
///
/// Esempi:
/// ```
/// (str-length "Hello")           → 5
/// (str-length "café")            → 4
/// (str-length "")                → 0
/// (str-length abc)               → 3
/// ```
public func builtin_str_length(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("str-length", expected: 1, got: args.count)
    }
    
    let str: String
    switch args[0] {
    case .string(let s):
        str = s
    case .symbol(let s):
        str = s
    default:
        throw EvalError.typeMismatch("str-length", expected: "string or symbol", got: String(describing: args[0]))
    }
    
    // Swift String.count ritorna il numero di caratteri Unicode (grafemi)
    return .int(Int64(str.count))
}

// MARK: - str-byte-length: Lunghezza stringa (byte)

/// (str-byte-length <string-or-symbol>) - Ritorna lunghezza in byte UTF-8
/// Ref: StrByteLengthFunction (strngfun.c, line 268)
///
/// Comportamento:
/// - Conta byte UTF-8, non caratteri
/// - "café" ha lunghezza 5 byte (é = 2 byte)
///
/// Esempi:
/// ```
/// (str-byte-length "Hello")      → 5
/// (str-byte-length "café")       → 5
/// (str-byte-length "日本")       → 6
/// ```
public func builtin_str_byte_length(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("str-byte-length", expected: 1, got: args.count)
    }
    
    let str: String
    switch args[0] {
    case .string(let s):
        str = s
    case .symbol(let s):
        str = s
    default:
        throw EvalError.typeMismatch("str-byte-length", expected: "string or symbol", got: String(describing: args[0]))
    }
    
    return .int(Int64(str.utf8.count))
}

// MARK: - str-compare: Confronto stringhe

/// (str-compare <string1> <string2> [<max-length>]) - Confronta stringhe
/// Ref: StrCompareFunction (strngfun.c, line 301)
///
/// Comportamento:
/// - Ritorna < 0 se str1 < str2
/// - Ritorna 0 se str1 == str2
/// - Ritorna > 0 se str1 > str2
/// - Se <max-length> specificato, confronta solo primi N caratteri
///
/// Esempi:
/// ```
/// (str-compare "abc" "def")      → -1
/// (str-compare "xyz" "abc")      → 1
/// (str-compare "test" "test")    → 0
/// (str-compare "hello" "help" 3) → 0  (confronta "hel" vs "hel")
/// ```
public func builtin_str_compare(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count >= 2 && args.count <= 3 else {
        throw EvalError.wrongArgCount("str-compare", expected: "2 or 3", got: args.count)
    }
    
    let str1: String
    let str2: String
    
    switch args[0] {
    case .string(let s): str1 = s
    case .symbol(let s): str1 = s
    default:
        throw EvalError.typeMismatch("str-compare", expected: "string or symbol", got: String(describing: args[0]))
    }
    
    switch args[1] {
    case .string(let s): str2 = s
    case .symbol(let s): str2 = s
    default:
        throw EvalError.typeMismatch("str-compare", expected: "string or symbol", got: String(describing: args[1]))
    }
    
    // Se max-length specificato
    if args.count == 3 {
        guard case .int(let maxLen) = args[2] else {
            throw EvalError.typeMismatch("str-compare", expected: "integer", got: String(describing: args[2]))
        }
        
        let len = Int(maxLen)
        let prefix1 = String(str1.prefix(len))
        let prefix2 = String(str2.prefix(len))
        
        if prefix1 < prefix2 {
            return .int(-1)
        } else if prefix1 > prefix2 {
            return .int(1)
        } else {
            return .int(0)
        }
    }
    
    // Confronto completo
    if str1 < str2 {
        return .int(-1)
    } else if str1 > str2 {
        return .int(1)
    } else {
        return .int(0)
    }
}

// MARK: - upcase: Conversione maiuscolo

/// (upcase <string-or-symbol>) - Converte in maiuscolo
/// Ref: UpcaseFunction (strngfun.c, line 378)
///
/// Comportamento:
/// - Ritorna stringa se input è stringa
/// - Ritorna simbolo se input è simbolo
///
/// Esempi:
/// ```
/// (upcase "hello")               → "HELLO"
/// (upcase abc)                   → ABC
/// (upcase "Café")                → "CAFÉ"
/// ```
public func builtin_upcase(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("upcase", expected: 1, got: args.count)
    }
    
    switch args[0] {
    case .string(let s):
        return .string(s.uppercased())
    case .symbol(let s):
        return .symbol(s.uppercased())
    default:
        throw EvalError.typeMismatch("upcase", expected: "string or symbol", got: String(describing: args[0]))
    }
}

// MARK: - lowcase: Conversione minuscolo

/// (lowcase <string-or-symbol>) - Converte in minuscolo
/// Ref: LowcaseFunction (strngfun.c, line 411)
///
/// Comportamento:
/// - Ritorna stringa se input è stringa
/// - Ritorna simbolo se input è simbolo
///
/// Esempi:
/// ```
/// (lowcase "HELLO")              → "hello"
/// (lowcase ABC)                  → abc
/// (lowcase "CAFÉ")               → "café"
/// ```
public func builtin_lowcase(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("lowcase", expected: 1, got: args.count)
    }
    
    switch args[0] {
    case .string(let s):
        return .string(s.lowercased())
    case .symbol(let s):
        return .symbol(s.lowercased())
    default:
        throw EvalError.typeMismatch("lowcase", expected: "string or symbol", got: String(describing: args[0]))
    }
}

// MARK: - sub-string: Estrazione sottostringa

/// (sub-string <start> <end> <string-or-symbol>) - Estrae sottostringa
/// Ref: SubStringFunction (strngfun.c, line 444)
///
/// Comportamento:
/// - Indici 1-based come CLIPS
/// - <end> è incluso (diverso da Swift!)
/// - Gestisce UTF-8 correttamente
///
/// Esempi:
/// ```
/// (sub-string 1 5 "Hello World")   → "Hello"
/// (sub-string 7 11 "Hello World")  → "World"
/// (sub-string 1 1 "X")             → "X"
/// (sub-string 2 4 "café")          → "afé"
/// ```
public func builtin_sub_string(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 3 else {
        throw EvalError.wrongArgCount("sub-string", expected: 3, got: args.count)
    }
    
    guard case .int(let start) = args[0] else {
        throw EvalError.typeMismatch("sub-string", expected: "integer", got: String(describing: args[0]))
    }
    
    guard case .int(let end) = args[1] else {
        throw EvalError.typeMismatch("sub-string", expected: "integer", got: String(describing: args[1]))
    }
    
    let str: String
    switch args[2] {
    case .string(let s):
        str = s
    case .symbol(let s):
        str = s
    default:
        throw EvalError.typeMismatch("sub-string", expected: "string or symbol", got: String(describing: args[2]))
    }
    
    // Validazione indici (1-based)
    let length = str.count
    if start < 1 || start > length {
        throw EvalError.indexOutOfBounds("sub-string", index: Int(start), size: length)
    }
    if end < start || end > length {
        throw EvalError.indexOutOfBounds("sub-string", index: Int(end), size: length)
    }
    
    // Conversione a 0-based per Swift
    let startIndex = str.index(str.startIndex, offsetBy: Int(start - 1))
    let endIndex = str.index(str.startIndex, offsetBy: Int(end))
    let substring = String(str[startIndex..<endIndex])
    
    return .string(substring)
}

// MARK: - str-index: Ricerca sottostringa

/// (str-index <search-string> <target-string>) - Trova posizione sottostringa
/// Ref: StrIndexFunction (strngfun.c, line 526)
///
/// Comportamento:
/// - Ritorna posizione 1-based della prima occorrenza
/// - Ritorna FALSE se non trovata
/// - Ritorna 1 se search-string è "" (CLIPS 6.40+)
///
/// Esempi:
/// ```
/// (str-index "World" "Hello World")  → 7
/// (str-index "xyz" "Hello World")    → FALSE
/// (str-index "" "test")              → 1
/// (str-index "ll" "Hello")           → 3
/// ```
public func builtin_str_index(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 2 else {
        throw EvalError.wrongArgCount("str-index", expected: 2, got: args.count)
    }
    
    let searchStr: String
    let targetStr: String
    
    switch args[0] {
    case .string(let s): searchStr = s
    case .symbol(let s): searchStr = s
    default:
        throw EvalError.typeMismatch("str-index", expected: "string or symbol", got: String(describing: args[0]))
    }
    
    switch args[1] {
    case .string(let s): targetStr = s
    case .symbol(let s): targetStr = s
    default:
        throw EvalError.typeMismatch("str-index", expected: "string or symbol", got: String(describing: args[1]))
    }
    
    // Caso speciale: stringa vuota ritorna 1 (CLIPS 6.40+)
    if searchStr.isEmpty {
        return .int(1)
    }
    
    // Ricerca sottostringa
    if let range = targetStr.range(of: searchStr) {
        let distance = targetStr.distance(from: targetStr.startIndex, to: range.lowerBound)
        return .int(Int64(distance + 1))  // 1-based
    } else {
        return .symbol("FALSE")
    }
}

// MARK: - str-replace: Sostituzione sottostringa

/// (str-replace <target> <search> <replace>) - Sostituisce tutte le occorrenze
/// Ref: StrReplaceFunction (strngfun.c, line 572)
///
/// Comportamento:
/// - Sostituisce tutte le occorrenze di <search> con <replace> in <target>
/// - Ritorna stringa/simbolo in base al tipo di <target>
///
/// Esempi:
/// ```
/// (str-replace "Hello World" "World" "CLIPS")  → "Hello CLIPS"
/// (str-replace "aaa" "a" "b")                  → "bbb"
/// (str-replace abc a X)                        → Xbc
/// ```
public func builtin_str_replace(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 3 else {
        throw EvalError.wrongArgCount("str-replace", expected: 3, got: args.count)
    }
    
    let targetStr: String
    let isSymbol: Bool
    
    switch args[0] {
    case .string(let s):
        targetStr = s
        isSymbol = false
    case .symbol(let s):
        targetStr = s
        isSymbol = true
    default:
        throw EvalError.typeMismatch("str-replace", expected: "string or symbol", got: String(describing: args[0]))
    }
    
    let searchStr: String
    switch args[1] {
    case .string(let s): searchStr = s
    case .symbol(let s): searchStr = s
    default:
        throw EvalError.typeMismatch("str-replace", expected: "string or symbol", got: String(describing: args[1]))
    }
    
    let replaceStr: String
    switch args[2] {
    case .string(let s): replaceStr = s
    case .symbol(let s): replaceStr = s
    default:
        throw EvalError.typeMismatch("str-replace", expected: "string or symbol", got: String(describing: args[2]))
    }
    
    let result = targetStr.replacingOccurrences(of: searchStr, with: replaceStr)
    
    return isSymbol ? .symbol(result) : .string(result)
}

// MARK: - string-to-field: Conversione stringa → valore

/// (string-to-field <string>) - Converte stringa in valore tipizzato
/// Ref: StringToFieldFunction (strngfun.c, line 630)
///
/// Comportamento:
/// - Tenta di parsare la stringa come numero, simbolo, ecc.
/// - Ritorna il valore tipizzato appropriato
///
/// Esempi:
/// ```
/// (string-to-field "42")         → 42
/// (string-to-field "3.14")       → 3.14
/// (string-to-field "abc")        → abc
/// (string-to-field "\"text\"")   → "text"
/// ```
public func builtin_string_to_field(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("string-to-field", expected: 1, got: args.count)
    }
    
    let str: String
    switch args[0] {
    case .string(let s):
        str = s
    case .symbol(let s):
        str = s
    default:
        throw EvalError.typeMismatch("string-to-field", expected: "string or symbol", got: String(describing: args[0]))
    }
    
    // Prova a parsare come numero intero
    if let intVal = Int64(str) {
        return .int(intVal)
    }
    
    // Prova a parsare come float
    if let floatVal = Double(str) {
        return .float(floatVal)
    }
    
    // Se inizia e finisce con virgolette, è una stringa
    if str.hasPrefix("\"") && str.hasSuffix("\"") {
        let content = String(str.dropFirst().dropLast())
        return .string(content)
    }
    
    // Altrimenti è un simbolo
    return .symbol(str)
}

// MARK: - Helper: Conversione Value → String

/// Converte un Value in rappresentazione stringa
/// Utilizzato da str-cat e sym-cat
private func valueToString(_ value: Value) -> String {
    switch value {
    case .none:
        return "nil"
    case .int(let i):
        return String(i)
    case .float(let d):
        // Formatta float come CLIPS (evita notazione scientifica se possibile)
        if d == Double(Int64(d)) {
            return String(format: "%.1f", d)
        } else {
            return String(d)
        }
    case .string(let s):
        return s
    case .symbol(let s):
        return s
    case .boolean(let b):
        return b ? "TRUE" : "FALSE"
    case .multifield(let arr):
        // Multifield viene convertito in spazio-separato
        return arr.map { valueToString($0) }.joined(separator: " ")
    }
}

