// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import Foundation

// MARK: - Tipi di base

public enum Value: Codable, Equatable {
    case int(Int64)
    case float(Double)
    case string(String)
    case symbol(String)
    case boolean(Bool)
    case multifield([Value])
    case none
}

// Rappresentazione dell'Environment di CLIPS (v. envrnmnt.h)
public final class Environment {
    public static let MAXIMUM_ENVIRONMENT_POSITIONS = 100

    public var initialized: Bool = false
    public var context: UnsafeMutableRawPointer? = nil
    public var TrueSymbol: CLIPSLexeme? = CLIPSLexeme("TRUE")
    public var FalseSymbol: CLIPSLexeme? = CLIPSLexeme("FALSE")
    public var VoidConstant: CLIPSVoid? = CLIPSVoid()

    // Storage generico per dati di sottosistemi (posizionale come in C)
    public var theData: [Any?]
    public var cleanupFunctions: [((inout Environment) -> Void)?]

    public final class CleanupNode {
        public let name: String
        public let funcPtr: (inout Environment) -> Void
        public let priority: Int
        public var next: CleanupNode? = nil
        public init(name: String, funcPtr: @escaping (inout Environment) -> Void, priority: Int) {
            self.name = name
            self.funcPtr = funcPtr
            self.priority = priority
        }
    }

    public var listOfCleanupEnvironmentFunctions: CleanupNode? = nil

    // Registro funzioni
    public var functionTable: [String: FunctionDefinitionSwift] = [:]

    // Variabili locali e globali
    public var localBindings: [String: Value] = [:]
    public var globalBindings: [String: Value] = [:]

    // Watch flags
    public var watchFacts: Bool = false
    public var watchRules: Bool = false
    public var watchRete: Bool = false
    public var watchReteProfile: Bool = false

    // Deffacts archivio: nome -> lista di fatti (ognuno è lista di Values come argomenti per assert)
    public var deffacts: [String: [[Value]]] = [:]

    // Costrutti: template e fatti
    public enum SlotDefaultType: String, Codable { case none, `static`, dynamic }
    public enum SlotAllowedType: String, Codable { case integer, float, number, string, symbol, lexeme }
    public struct SlotConstraints: Codable, Equatable {
        public var allowed: Set<SlotAllowedType> = []
        public var range: ClosedRange<Double>? = nil
    }
    public struct SlotDef: Codable {
        public let name: String
        public let isMultifield: Bool
        public let defaultType: SlotDefaultType
        public let defaultStatic: Value?
        public let defaultDynamicExpr: ExpressionNode?
        public var constraints: SlotConstraints?
    }
    public struct Template: Codable {
        public let name: String
        public var slots: [String: SlotDef]
    }
    public var templates: [String: Template] = [:]
    public struct FactRec { public let id: Int; public let name: String; public let slots: [String: Value] }
    public var facts: [Int: FactRec] = [:]
    public var nextFactId: Int = 1
    // Tracking PartialMatch associati ai fatti (equivalente a theFact->list in CLIPS C)
    // Ref: factmngr.h line 161 - void *list (patternMatch list)
    // Quando un PartialMatch viene creato da un fatto, viene aggiunto a questa lista
    // per permettere a NetworkRetract di trovare tutti i PartialMatch da rimuovere
    public var factPartialMatches: [Int: [PartialMatch]] = [:]
    // Tracking attivazioni -> PartialMatch (per retract)
    // Ref: agenda.c:187 - binds->marker = newActivation
    // Permette di trovare il PartialMatch associato a un'attivazione per rimuoverla correttamente
    public var activationToPartialMatch: [String: PartialMatch] = [:]  // key: "ruleName:factIDs"
    public var rules: [Rule] = []
    public var agendaQueue: Agenda = Agenda()
    public var rete: ReteNetwork = ReteNetwork()
    // Flag sperimentale: confronta join vs matcher corrente senza influenzare attivazioni
    public var experimentalJoinCheck: Bool = false
    // File aperti per I/O - gestiti con cleanup automatico
    public var openFiles: [String: FileHandle] = [:]
    // Utility functions state
    public var gensymCounter: Int = 0
    // Flag sperimentale: usa i token Beta per attivazioni (solo regole senza not)
    public var experimentalJoinActivate: Bool = false
    // Whitelist di regole per attivazione via rete quando stabili
    public var joinActivateWhitelist: Set<String> = []
    // Regole marcate stabili (join-check equivalente al naive)
    public var joinStableRules: Set<String> = []
    // Default: usa attivazione via RETE per regole stabili
    public var joinActivateDefaultOnStable: Bool = false
    // Se true, mantiene il fallback naïve anche quando RETE è attiva e la regola è stabile
    public var joinNaiveFallback: Bool = true
    // Strategia di valutazione della salienza (when-defined / when-activated)
    public enum SalienceEvaluation: String {
        case whenDefined = "when-defined"
        case whenActivated = "when-activated"
    }
    public var salienceEvaluation: SalienceEvaluation = .whenDefined
    
    // RETE Network: Usa implementazione FEDELE al C di CLIPS (drive.c, network.h, reteutil.c)
    // Traduzione diretta delle strutture joinNode, partialMatch, betaMemory, NetworkAssert, etc.
    // Questa è l'architettura RETE standard di CLIPS 6.4.2, non una semplificazione
    public var useExplicitReteNodes: Bool = true  // ✅ SEMPRE ATTIVO - traduzione fedele CLIPS C
    
    // FASE 3: Sistema di moduli (ref: struct defmoduleData in moduldef.h linee 209-236)
    // Lista di tutti i moduli
    internal var _listOfDefmodules: Defmodule? = nil
    // Modulo corrente
    internal var _currentModule: Defmodule? = nil
    // Ultimo modulo creato
    internal var _lastDefmodule: Defmodule? = nil
    // Lista di tipi di item registrati
    internal var _listOfModuleItems: ModuleItem? = nil
    // Ultimo module item registrato
    internal var _lastModuleItem: ModuleItem? = nil
    // Numero di tipi di item registrati
    internal var _numberOfModuleItems: UInt = 0
    // Stack di focus
    internal var _moduleStack: ModuleStackItem? = nil

    public init() {
        self.theData = Array(repeating: nil, count: Environment.MAXIMUM_ENVIRONMENT_POSITIONS)
        self.cleanupFunctions = Array(repeating: nil, count: Environment.MAXIMUM_ENVIRONMENT_POSITIONS)
    }
    
    /// Cleanup method per liberare risorse e prevenire memory leaks
    deinit {
        // Chiudi tutti i file aperti
        for (_, fileHandle) in openFiles {
            try? fileHandle.close()
        }
        openFiles.removeAll()
        
        // Esegui cleanup functions registrate
        var current = listOfCleanupEnvironmentFunctions
        while let node = current {
            var envRef = self
            node.funcPtr(&envRef)
            current = node.next
        }
    }
}

// MARK: - Facciata pubblica SLIPS

@MainActor
public enum SLIPS {
    private static var currentEnv: Environment? = nil
    public static var currentEnvironment: Environment? { currentEnv }

    @discardableResult
    public static func createEnvironment() -> Environment {
        var env = Environment()
        // Inizializza moduli minimi per eval
        Functions.registerBuiltins(&env)
        ExpressionEnv.InitExpressionData(&env)
        // Inizializza sistema di moduli (FASE 3)
        env.initializeModules()
        // Strategia agenda di default
        env.agendaQueue.setStrategy(.depth)
        // NOTA: experimentalJoinCheck è false di default, può essere attivato con (set-join-check on)
        // env.experimentalJoinCheck = false  // default value
        env.joinActivateDefaultOnStable = false  // Cambiato a false per usare percorso esplicito di default
        currentEnv = env
        return env
    }

    public static func load(_ path: String) throws {
        guard var env = currentEnv else { return }
        try SLIPSHelpers.loadInternal(&env, path)
        currentEnv = env
    }

    public static func reset() {
        guard let env0 = currentEnv else { return }
        var env = env0
        env.localBindings.removeAll()
        env.globalBindings.removeAll()
        env.facts.removeAll()
        env.nextFactId = 1
        // Reassert deffacts
        if let assertFn = env.functionTable["assert"] {
            for (_, factsList) in env.deffacts {
                for factArgs in factsList {
                    _ = try? assertFn.impl(&env, factArgs)
                }
            }
        }
        currentEnv = env
    }

    @discardableResult
    public static func run(limit: Int? = nil) -> Int {
        guard var env = currentEnv else { return 0 }
        // Nel sistema esplicito, le attivazioni sono create dalla rete RETE durante propagation
        // Non serve rebuild agenda - tutto è gestito da NetworkAssert/ProductionNode.activate
        let fired = RuleEngine.run(&env, limit: limit)
        currentEnv = env
        return fired
    }

    public static func assert(fact: String) {
        guard currentEnv != nil else { return }
        let expr = fact.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmed = expr
        let form: String
        if trimmed.hasPrefix("(assert") {
            form = trimmed
        } else if trimmed.hasPrefix("(") && trimmed.hasSuffix(")") {
            // Converte (b x 1) -> (assert b x 1)
            let inner = String(trimmed.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
            form = "(assert \(inner))"
        } else {
            form = "(assert \(trimmed))"
        }
        _ = eval(expr: form)
        // Nel sistema esplicito, EXISTS è gestito come NOT(NOT) dalla rete
        // Le attivazioni vengono create automaticamente durante propagation attraverso ProductionNode
    }

    public static func retract(id: Int) {
        guard currentEnv != nil else { return }
        _ = eval(expr: "(retract \(id))")
        // env è una reference; eval ha già aggiornato currentEnv
    }

    @discardableResult
    public static func eval(expr: String) -> Value {
        guard var env = currentEnv else { return .none }
        if ProcessInfo.processInfo.environment["SLIPS_DEBUG_EVAL"] == "1" {
            if let data = "[SLIPS.eval] \(expr)\n".data(using: .utf8) {
                FileHandle.standardError.write(data)
            }
        }
        // Usa fast router come in CLIPS per valutare stringhe
        let router = "***EVAL***"
        let r = RouterEnvData.ensure(&env)
        r.FastCharGetRouter = router
        r.FastCharGetString = expr
        r.FastCharGetIndex = 0
        do {
            let ast = try ExprTokenParser.parseTop(&env, logicalName: router)
            let val = try Evaluator.eval(&env, ast)
            currentEnv = env
            return val
        } catch {
            return .none
        }
    }

    public static func commandLoop() {
        guard var env = currentEnv else { _ = createEnvironment(); return commandLoop() }
        Functions.registerBuiltins(&env)
        ExpressionEnv.InitExpressionData(&env)
        currentEnv = env
        let stdinHandle = FileHandle.standardInput
        while true {
            fputs("SLIPS> ", stdout)
            guard let data = try? stdinHandle.read(upToCount: 4096), !data.isEmpty,
                  let line = String(data: data, encoding: .utf8) else { break }
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            if trimmed == "(exit)" || trimmed == "exit" { break }
            // Comandi sintetici senza parentesi: load/reset/run/assert/eval
            if !trimmed.hasPrefix("(") {
                let parts = trimmed.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                let cmd = parts.first?.lowercased() ?? ""
                let arg = parts.count > 1 ? String(parts[1]) : nil
                switch cmd {
                case "load":
                    if let p = arg { try? load(p) }
                    continue
                case "reset":
                    reset(); continue
                case "run":
                    if let a = arg, let n = Int(a) { _ = run(limit: n) } else { _ = run(limit: nil) }
                    continue
                case "assert":
                    if let f = arg { assert(fact: f) }
                    continue
                case "eval":
                    if let e = arg { _ = eval(expr: e) }
                    continue
                default:
                    break
                }
            }
            let result = eval(expr: trimmed)
            var e = currentEnv!
            PrintUtil.PrintAtom(&e, Router.STDOUT, result)
            Router.Writeln(&e, "")
            currentEnv = e
        }
    }
}

// MARK: - Helper non-isolati per chiamate da contesti non-MainActor

/// Helper functions che non richiedono MainActor isolation
/// Usate dalle builtin functions che devono operare in contesti sincroni
enum SLIPSHelpers {
    /// Versione interna che accetta env direttamente (non richiede MainActor)
    static func loadInternal(_ env: inout Environment, _ path: String) throws {
        // In CLIPS: carica un file .clp e ne elabora i costrutti.
        var contents = try String(contentsOfFile: path, encoding: .utf8)
        // Rimuovi commenti ';' fino a fine riga (semplificato)
        contents = contents.split(separator: "\n", omittingEmptySubsequences: false).map { line in
            if let idx = line.firstIndex(of: ";") { return String(line[..<idx]) } else { return String(line) }
        }.joined(separator: "\n")
        // Estrai S-expression top-level e valuta
        var i = contents.startIndex
        while i < contents.endIndex {
            // Skip whitespaces
            while i < contents.endIndex, contents[i].isWhitespace { i = contents.index(after: i) }
            guard i < contents.endIndex else { break }
            if contents[i] != "(" { // ignora linee non s-exp in questa fase
                // salta fino a newline
                while i < contents.endIndex, contents[i] != "\n" { i = contents.index(after: i) }
                continue
            }
            // parse balanced parentheses
            var depth = 0
            var j = i
            var inString = false
            while j < contents.endIndex {
                let c = contents[j]
                if c == "\"" { inString.toggle() }
                if !inString {
                    if c == "(" { depth += 1 }
                    else if c == ")" { depth -= 1; if depth == 0 { j = contents.index(after: j); break } }
                }
                j = contents.index(after: j)
            }
            if depth == 0 {
                let sexpr = String(contents[i..<j])
                // Usa eval interno che non richiede MainActor
                _ = evalInternal(&env, expr: sexpr)
                i = j
            } else {
                break
            }
        }
    }
    
    /// Versione interna di eval che accetta env direttamente
    /// - printPrompt: se true, stampa prompt prima del comando (modalità interattiva)
    /// - printResult: se true, stampa il risultato dopo l'esecuzione (ref: RouteCommand printResult)
    static func evalInternal(_ env: inout Environment, expr: String, printPrompt: Bool = false, printResult: Bool = false) -> Value {
        if printPrompt {
            // Stampa prompt prima del comando (ref: ExecuteIfCommandComplete in commline.c:831)
            Router.WriteString(&env, Router.STDOUT, "SLIPS> ")
        }
        
        if ProcessInfo.processInfo.environment["SLIPS_DEBUG_EVAL"] == "1" {
            if let data = "[SLIPS.eval] \(expr)\n".data(using: .utf8) {
                FileHandle.standardError.write(data)
            }
        }
        let router = "***EVAL***"
        let r = RouterEnvData.ensure(&env)
        r.FastCharGetRouter = router
        r.FastCharGetString = expr
        r.FastCharGetIndex = 0
        do {
            let ast = try ExprTokenParser.parseTop(&env, logicalName: router)
            let val = try Evaluator.eval(&env, ast)
            
            // Stampa risultato se non void (ref: RouteCommand in commline.c:1067-1071)
            if printResult {
                // Stampa risultato solo se non è void
                switch val {
                case .none: break  // Void, non stampare (ref: RouteCommand:1067 - type != VOID_TYPE)
                default:
                    PrintUtil.PrintAtom(&env, Router.STDOUT, val)
                    Router.Writeln(&env, "")
                }
            }
            
            return val
        } catch {
            return .none
        }
    }
}

// MARK: - Compatibilità CLIPS (alias per retrocompatibilità)

/// Tipo alias per retrocompatibilità con codice esistente
@available(*, deprecated, message: "Usa SLIPS invece di CLIPS")
public typealias CLIPS = SLIPS

