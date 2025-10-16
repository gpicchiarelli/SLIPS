// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import Foundation

/// Funzioni I/O CLIPS
/// Traduzione semantica da clips_core_source_642/core/iofun.c
///
/// Funzioni implementate (ref: IOFunctionDefinitions, line 213):
/// - read: Legge valore da input
/// - readline: Legge riga intera
/// - read-number: Legge numero
/// - format: Formattazione stringhe (sprintf-like)
/// - open: Apre file (base)
/// - close: Chiude file (base)
/// - get-char: Legge singolo carattere
///
/// Note: printout è già implementato in functions.swift
///
/// Storage file: I file aperti sono memorizzati in Environment.openFiles
public enum IOFunctions {
    /// Registra tutte le funzioni I/O nell'environment
    /// Ref: IOFunctionDefinitions (iofun.c, line 213)
    public static func registerAll(_ env: inout Environment) {
        env.functionTable["read"] = FunctionDefinitionSwift(name: "read", impl: builtin_read)
        env.functionTable["readline"] = FunctionDefinitionSwift(name: "readline", impl: builtin_readline)
        env.functionTable["read-number"] = FunctionDefinitionSwift(name: "read-number", impl: builtin_read_number)
        env.functionTable["format"] = FunctionDefinitionSwift(name: "format", impl: builtin_format)
        env.functionTable["open"] = FunctionDefinitionSwift(name: "open", impl: builtin_open)
        env.functionTable["close"] = FunctionDefinitionSwift(name: "close", impl: builtin_close)
        env.functionTable["get-char"] = FunctionDefinitionSwift(name: "get-char", impl: builtin_get_char)
        env.functionTable["put-char"] = FunctionDefinitionSwift(name: "put-char", impl: builtin_put_char)
        env.functionTable["flush"] = FunctionDefinitionSwift(name: "flush", impl: builtin_flush)
        env.functionTable["remove"] = FunctionDefinitionSwift(name: "remove", impl: builtin_remove)
        env.functionTable["rename"] = FunctionDefinitionSwift(name: "rename", impl: builtin_rename)
        env.functionTable["print"] = FunctionDefinitionSwift(name: "print", impl: builtin_print)
        env.functionTable["println"] = FunctionDefinitionSwift(name: "println", impl: builtin_println)
    }
}

// MARK: - read

/// (read [<logical-name>]) - Legge valore da input
/// Ref: ReadFunction (iofun.c, line 415)
///
/// Comportamento:
/// - Legge un token dall'input
/// - Parse come simbolo, numero, stringa, etc.
/// - Ritorna FALSE se errore
///
/// Esempi:
/// ```
/// (read)           → legge da stdin
/// (read stdin)     → legge da stdin esplicitamente
/// ```
public func builtin_read(_ env: inout Environment, _ args: [Value]) throws -> Value {
    // Per ora leggiamo solo da stdin
    guard args.isEmpty || args.count == 1 else {
        throw EvalError.wrongArgCount("read", expected: "0 or 1", got: args.count)
    }
    
    // In un'applicazione reale, useremmo readline o input
    // Per ora ritorniamo un placeholder
    print("read> ", terminator: "")
    
    guard let input = readLine() else {
        return .boolean(false)  // EOF o errore
    }
    
    // Parse input
    return parseInput(input)
}

// MARK: - readline

/// (readline [<logical-name>]) - Legge riga intera
/// Ref: ReadlineFunction (iofun.c, line 242)
///
/// Comportamento:
/// - Legge intera riga fino a newline
/// - Ritorna come stringa
/// - Ritorna FALSE se EOF
///
/// Esempi:
/// ```
/// (readline)       → legge riga da stdin
/// (readline stdin) → legge riga da stdin
/// ```
public func builtin_readline(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.isEmpty || args.count == 1 else {
        throw EvalError.wrongArgCount("readline", expected: "0 or 1", got: args.count)
    }
    
    print("readline> ", terminator: "")
    
    guard let line = readLine() else {
        return .boolean(false)  // EOF
    }
    
    return .string(line)
}

// MARK: - read-number

/// (read-number [<logical-name>]) - Legge numero
/// Ref: ReadNumberFunction (iofun.c, line 244)
///
/// Comportamento:
/// - Legge e parse come numero
/// - Ritorna int o float
/// - Ritorna FALSE se non è numero
///
/// Esempi:
/// ```
/// (read-number)    → 42
/// (read-number)    → 3.14
/// ```
public func builtin_read_number(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.isEmpty || args.count == 1 else {
        throw EvalError.wrongArgCount("read-number", expected: "0 or 1", got: args.count)
    }
    
    print("read-number> ", terminator: "")
    
    guard let input = readLine(), !input.isEmpty else {
        return .boolean(false)
    }
    
    // Try integer first
    if let intVal = Int64(input.trimmingCharacters(in: .whitespaces)) {
        return .int(intVal)
    }
    
    // Try float
    if let floatVal = Double(input.trimmingCharacters(in: .whitespaces)) {
        return .float(floatVal)
    }
    
    // Not a number
    return .boolean(false)
}

// MARK: - format

/// (format <logical-name> <format-string> <arguments>*) - Formattazione stringhe
/// Ref: FormatFunction (iofun.c, line 241)
///
/// Comportamento:
/// - Formatta stringa stile printf
/// - Supporta %d, %f, %s, %g, etc.
/// - Ritorna stringa formattata
///
/// Esempi:
/// ```
/// (format nil "Value: %d" 42)        → "Value: 42"
/// (format nil "%.2f" 3.14159)        → "3.14"
/// (format nil "%s %s" "Hello" "World") → "Hello World"
/// ```
public func builtin_format(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count >= 2 else {
        throw EvalError.wrongArgCount("format", expected: "2+", got: args.count)
    }
    
    // Logical name (nil, t, stdout, etc.) - ignoriamo per ora
    // args[0] è il logical name
    
    // Format string
    guard case .string(let formatStr) = args[1] else {
        throw EvalError.typeMismatch("format", expected: "string", got: String(describing: args[1]))
    }
    
    // Argomenti per formattazione
    let formatArgs = Array(args.dropFirst(2))
    
    // Semplice implementazione di format
    var result = formatStr
    var argIndex = 0
    
    // Sostituisci placeholder %d, %s, %f, %g
    while let range = result.range(of: "%(\\d*\\.?\\d*)[dsfg]", options: .regularExpression) {
        if argIndex < formatArgs.count {
            let placeholder = String(result[range])
            let formatted = formatValue(formatArgs[argIndex], placeholder: placeholder)
            result.replaceSubrange(range, with: formatted)
            argIndex += 1
        } else {
            break
        }
    }
    
    return .string(result)
}

// MARK: - open

/// (open <file-name> <mode> [<logical-name>]) - Apre file
/// Ref: OpenFunction (iofun.c, line 230)
///
/// Modi supportati:
/// - "r": read
/// - "w": write
/// - "a": append
/// - "r+": read/write
///
/// Esempi:
/// ```
/// (open "data.txt" "r")            → TRUE
/// (open "output.txt" "w" myfile)   → TRUE
/// ```
public func builtin_open(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count >= 2 && args.count <= 3 else {
        throw EvalError.wrongArgCount("open", expected: "2 or 3", got: args.count)
    }
    
    // File name
    let fileName: String
    switch args[0] {
    case .string(let s): fileName = s
    case .symbol(let s): fileName = s
    default:
        throw EvalError.typeMismatch("open", expected: "string", got: String(describing: args[0]))
    }
    
    // Mode
    let mode: String
    switch args[1] {
    case .string(let s): mode = s
    case .symbol(let s): mode = s
    default:
        throw EvalError.typeMismatch("open", expected: "string", got: String(describing: args[1]))
    }
    
    // Logical name (optional)
    let logicalName = args.count == 3 ? extractString(args[2]) : fileName
    
    // Apri file
    do {
        let fileURL = URL(fileURLWithPath: fileName)
        
        switch mode {
        case "r":
            // Read mode
            guard FileManager.default.fileExists(atPath: fileName) else {
                return .boolean(false)
            }
            let handle = try FileHandle(forReadingFrom: fileURL)
            env.openFiles[logicalName] = handle
            return .boolean(true)
            
        case "w":
            // Write mode (create/truncate)
            FileManager.default.createFile(atPath: fileName, contents: nil)
            let handle = try FileHandle(forWritingTo: fileURL)
            env.openFiles[logicalName] = handle
            return .boolean(true)
            
        case "a":
            // Append mode
            if !FileManager.default.fileExists(atPath: fileName) {
                FileManager.default.createFile(atPath: fileName, contents: nil)
            }
            let handle = try FileHandle(forWritingTo: fileURL)
            try handle.seekToEnd()
            env.openFiles[logicalName] = handle
            return .boolean(true)
            
        default:
            throw EvalError.runtime("open: unsupported mode '\(mode)'")
        }
    } catch {
        return .boolean(false)
    }
}

// MARK: - close

/// (close [<logical-name>]) - Chiude file
/// Ref: CloseFunction (iofun.c, line 231)
///
/// Esempi:
/// ```
/// (close myfile)   → TRUE
/// (close)          → TRUE (chiude tutti)
/// ```
public func builtin_close(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count <= 1 else {
        throw EvalError.wrongArgCount("close", expected: "0 or 1", got: args.count)
    }
    
    if args.isEmpty {
        // Chiudi tutti i file
        for (_, handle) in env.openFiles {
            try? handle.close()
        }
        env.openFiles.removeAll()
        return .boolean(true)
    }
    
    // Chiudi file specifico
    let logicalName = extractString(args[0])
    
    if let handle = env.openFiles[logicalName] {
        try? handle.close()
        env.openFiles.removeValue(forKey: logicalName)
        return .boolean(true)
    }
    
    return .boolean(false)
}

// MARK: - get-char

/// (get-char [<logical-name>]) - Legge singolo carattere
/// Ref: GetCharFunction (iofun.c, line 236)
///
/// Comportamento:
/// - Ritorna codice ASCII del carattere
/// - Ritorna -1 se EOF
///
/// Esempi:
/// ```
/// (get-char)       → 65  (carattere 'A')
/// (get-char stdin) → 66  (carattere 'B')
/// ```
public func builtin_get_char(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.isEmpty || args.count == 1 else {
        throw EvalError.wrongArgCount("get-char", expected: "0 or 1", got: args.count)
    }
    
    // Per stdin, leggi un carattere
    if args.isEmpty || extractString(args[0]) == "stdin" {
        // In ambiente CLI, readLine legge tutta la riga
        // Per un singolo carattere servirebbe terminal raw mode
        // Per ora implementazione semplificata
        guard let line = readLine(), let first = line.first else {
            return .int(-1)  // EOF
        }
        
        return .int(Int64(first.asciiValue ?? 0))
    }
    
    // Da file
    let logicalName = extractString(args[0])
    guard let handle = env.openFiles[logicalName] else {
        return .int(-1)
    }
    
    do {
        if let byte = try handle.read(upToCount: 1)?.first {
            return .int(Int64(byte))
        }
        return .int(-1)  // EOF
    } catch {
        return .int(-1)
    }
}

// MARK: - put-char

/// (put-char <logical-name> <integer>) - Scrive singolo carattere
/// Ref: PutCharFunction (iofun.c, line 238)
///
/// Esempi:
/// ```
/// (put-char t 65)      → Scrive 'A' su stdout
/// (put-char myfile 66) → Scrive 'B' su file
/// ```
public func builtin_put_char(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 2 else {
        throw EvalError.wrongArgCount("put-char", expected: 2, got: args.count)
    }
    
    let logicalName = extractString(args[0])
    
    guard case .int(let charCode) = args[1] else {
        throw EvalError.typeMismatch("put-char", expected: "integer", got: String(describing: args[1]))
    }
    
    guard charCode >= 0 && charCode <= 255 else {
        throw EvalError.runtime("put-char: character code must be in [0, 255]")
    }
    
    let char = Character(UnicodeScalar(UInt8(charCode)))
    
    // Scrive su stdout/stderr o file
    if logicalName == "t" || logicalName == "stdout" {
        print(char, terminator: "")
        return .none
    }
    
    // Scrive su file
    if let handle = env.openFiles[logicalName] {
        if let data = String(char).data(using: .utf8) {
            try? handle.write(contentsOf: data)
        }
        return .none
    }
    
    return .boolean(false)
}

// MARK: - flush

/// (flush [<logical-name>]) - Flush buffer output
/// Ref: FlushFunction (iofun.c, line 232)
///
/// Esempi:
/// ```
/// (flush t)        → Flush stdout
/// (flush myfile)   → Flush file
/// ```
public func builtin_flush(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count <= 1 else {
        throw EvalError.wrongArgCount("flush", expected: "0 or 1", got: args.count)
    }
    
    if args.isEmpty || extractString(args[0]) == "t" || extractString(args[0]) == "stdout" {
        // Flush stdout
        fflush(stdout)
        return .boolean(true)
    }
    
    // Flush file
    let logicalName = extractString(args[0])
    if let handle = env.openFiles[logicalName] {
        try? handle.synchronize()
        return .boolean(true)
    }
    
    return .boolean(false)
}

// MARK: - remove

/// (remove <file-name>) - Rimuove file
/// Ref: RemoveFunction (iofun.c, line 239)
///
/// Esempi:
/// ```
/// (remove "temp.txt")  → TRUE
/// ```
public func builtin_remove(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 1 else {
        throw EvalError.wrongArgCount("remove", expected: 1, got: args.count)
    }
    
    let fileName = extractString(args[0])
    
    do {
        try FileManager.default.removeItem(atPath: fileName)
        return .boolean(true)
    } catch {
        return .boolean(false)
    }
}

// MARK: - rename

/// (rename <old-name> <new-name>) - Rinomina file
/// Ref: RenameFunction (iofun.c, line 240)
///
/// Esempi:
/// ```
/// (rename "old.txt" "new.txt")  → TRUE
/// ```
public func builtin_rename(_ env: inout Environment, _ args: [Value]) throws -> Value {
    guard args.count == 2 else {
        throw EvalError.wrongArgCount("rename", expected: 2, got: args.count)
    }
    
    let oldName = extractString(args[0])
    let newName = extractString(args[1])
    
    do {
        try FileManager.default.moveItem(atPath: oldName, toPath: newName)
        return .boolean(true)
    } catch {
        return .boolean(false)
    }
}

// MARK: - print

/// (print <expression>*) - Stampa senza newline finale
/// Ref: PrintFunction (iofun.c, line 227)
///
/// Esempi:
/// ```
/// (print "Hello" " " "World")  → stampa "Hello World"
/// ```
public func builtin_print(_ env: inout Environment, _ args: [Value]) throws -> Value {
    for arg in args {
        let str = formatValueForPrint(arg)
        print(str, terminator: "")
    }
    return .none
}

// MARK: - println

/// (println <expression>*) - Stampa con newline finale
/// Ref: PrintlnFunction (iofun.c, line 228)
///
/// Esempi:
/// ```
/// (println "Hello World")  → stampa "Hello World\n"
/// ```
public func builtin_println(_ env: inout Environment, _ args: [Value]) throws -> Value {
    for arg in args {
        let str = formatValueForPrint(arg)
        print(str, terminator: "")
    }
    print()  // Newline
    return .none
}

// MARK: - Helper Functions

/// Formatta value per printing (senza quotes per stringhe)
private func formatValueForPrint(_ value: Value) -> String {
    switch value {
    case .none: return "nil"
    case .int(let i): return String(i)
    case .float(let d): return String(d)
    case .string(let s): return s  // NO quotes
    case .symbol(let s): return s
    case .boolean(let b): return b ? "TRUE" : "FALSE"
    case .multifield(let arr): return arr.map { formatValueForPrint($0) }.joined(separator: " ")
    }
}

/// Parse input string in valore appropriato
private func parseInput(_ input: String) -> Value {
    let trimmed = input.trimmingCharacters(in: .whitespaces)
    
    // Try integer
    if let intVal = Int64(trimmed) {
        return .int(intVal)
    }
    
    // Try float
    if let floatVal = Double(trimmed) {
        return .float(floatVal)
    }
    
    // Try boolean
    if trimmed.lowercased() == "true" || trimmed.lowercased() == "t" {
        return .boolean(true)
    }
    if trimmed.lowercased() == "false" || trimmed.lowercased() == "nil" {
        return .boolean(false)
    }
    
    // Try string (with quotes)
    if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") {
        let content = String(trimmed.dropFirst().dropLast())
        return .string(content)
    }
    
    // Default: symbol
    return .symbol(trimmed)
}

/// Formatta valore con placeholder specifico
private func formatValue(_ value: Value, placeholder: String) -> String {
    switch value {
    case .int(let i):
        if placeholder.contains("d") {
            return String(i)
        }
        return String(i)
    case .float(let d):
        // Extract precision from placeholder (e.g. "%.2f")
        if let precisionMatch = placeholder.range(of: "\\.(\\d+)", options: .regularExpression) {
            let precisionStr = String(placeholder[precisionMatch]).dropFirst()  // Remove '.'
            if let precision = Int(precisionStr) {
                return String(format: "%.\(precision)f", d)
            }
        }
        return String(d)
    case .string(let s):
        return s
    case .symbol(let s):
        return s
    case .boolean(let b):
        return b ? "TRUE" : "FALSE"
    case .none:
        return "nil"
    case .multifield(let arr):
        return arr.map { formatValueSimple($0) }.joined(separator: " ")
    }
}

/// Formatta valore semplice senza placeholder
private func formatValueSimple(_ value: Value) -> String {
    switch value {
    case .none: return "nil"
    case .int(let i): return String(i)
    case .float(let d): return String(d)
    case .string(let s): return s
    case .symbol(let s): return s
    case .boolean(let b): return b ? "TRUE" : "FALSE"
    case .multifield(let arr): return arr.map { formatValueSimple($0) }.joined(separator: " ")
    }
}

/// Estrae stringa da Value
private func extractString(_ value: Value) -> String {
    switch value {
    case .string(let s): return s
    case .symbol(let s): return s
    default: return String(describing: value)
    }
}

