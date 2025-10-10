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

    // Costrutti minimi: template e fatti
    public struct Template { public let name: String; public let slots: [String] }
    public var templates: [String: Template] = [:]
    public struct FactRec { public let id: Int; public let name: String; public let slots: [String: Value] }
    public var facts: [Int: FactRec] = [:]
    public var nextFactId: Int = 1

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
        env.templates.removeAll()
        env.facts.removeAll()
        env.nextFactId = 1
        currentEnv = env
    }

    @discardableResult
    public static func run(limit: Int? = nil) -> Int {
        // In CLIPS: esegue il motore di inferenza fino al limite di attivazioni.
        // TODO: Implementare RETE/Agenda. Per ora ritorna 0 attivazioni eseguite.
        return 0
    }

    public static func assert(fact: String) {
        guard var env = currentEnv else { return }
        let expr = fact.trimmingCharacters(in: .whitespacesAndNewlines)
        let form = expr.hasPrefix("(") ? expr : "(assert \(expr))"
        _ = eval(expr: form)
        currentEnv = env
    }

    public static func retract(id: Int) {
        guard var env = currentEnv else { return }
        _ = eval(expr: "(retract \(id))")
        currentEnv = env
    }

    @discardableResult
    public static func eval(expr: String) -> Value {
        guard var env = currentEnv else { return .none }
        // Usa fast router come in CLIPS per valutare stringhe
        let router = "***EVAL***"
        var r = RouterEnvData.ensure(&env)
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
            let result = eval(expr: trimmed)
            var e = currentEnv!
            PrintUtil.PrintAtom(&e, Router.STDOUT, result)
            Router.Writeln(&e, "")
            currentEnv = e
        }
    }
}
