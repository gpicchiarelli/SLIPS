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
    public var rules: [Rule] = []
    public var agendaQueue: Agenda = Agenda()
    public var rete: ReteNetwork = ReteNetwork()
    // Flag sperimentale: confronta join vs matcher corrente senza influenzare attivazioni
    public var experimentalJoinCheck: Bool = false
    // Flag sperimentale: usa i token Beta per attivazioni (solo regole senza not)
    public var experimentalJoinActivate: Bool = false
    // Whitelist di regole per attivazione via rete quando stabili
    public var joinActivateWhitelist: Set<String> = []
    // Regole marcate stabili (join-check equivalente al naive)
    public var joinStableRules: Set<String> = []
    // Default: usa attivazione via RETE per regole stabili
    public var joinActivateDefaultOnStable: Bool = false

    public init() {
        self.theData = Array(repeating: nil, count: Environment.MAXIMUM_ENVIRONMENT_POSITIONS)
        self.cleanupFunctions = Array(repeating: nil, count: Environment.MAXIMUM_ENVIRONMENT_POSITIONS)
    }
}

// MARK: - Facciata pubblica compatibile con CLIPS

@MainActor
public enum CLIPS {
    private static var currentEnv: Environment? = nil
    static var currentEnvironment: Environment? { currentEnv }

    @discardableResult
    public static func createEnvironment() -> Environment {
        var env = Environment()
        // Inizializza moduli minimi per eval
        Functions.registerBuiltins(&env)
        ExpressionEnv.InitExpressionData(&env)
        // Strategia agenda di default
        env.agendaQueue.setStrategy(.depth)
        currentEnv = env
        return env
    }

    public static func load(_ path: String) throws {
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
                _ = eval(expr: sexpr)
                i = j
            } else {
                break
            }
        }
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
        guard let env0 = currentEnv else { return 0 }
        var env = env0
        let fired = RuleEngine.run(&env, limit: limit)
        // Se il join-check o l'attivazione via rete sono attivi, riallinea le memorie beta
        if env.experimentalJoinCheck || env.experimentalJoinActivate || !env.joinActivateWhitelist.isEmpty {
            let facts = Array(env.facts.values)
            for (rname, cr) in env.rete.rules {
                _ = BetaEngine.updateGraphOnAssert(&env, ruleName: rname, compiled: cr, facts: facts)
            }
        }
        currentEnv = env
        return fired
    }

    public static func assert(fact: String) {
        guard currentEnv != nil else { return }
        let expr = fact.trimmingCharacters(in: .whitespacesAndNewlines)
        let form = expr.hasPrefix("(") ? expr : "(assert \(expr))"
        _ = eval(expr: form)
        // env è una reference; eval ha già aggiornato currentEnv
    }

    public static func retract(id: Int) {
        guard currentEnv != nil else { return }
        _ = eval(expr: "(retract \(id))")
        // env è una reference; eval ha già aggiornato currentEnv
    }

    @discardableResult
    public static func eval(expr: String) -> Value {
        guard var env = currentEnv else { return .none }
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
            fputs("CLIPS> ", stdout)
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
