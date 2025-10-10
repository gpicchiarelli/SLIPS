import Foundation

// MARK: - Utilità stampa/diagnostica (subset di prntutil.h)

public enum PrintUtil {
    public static func WriteString(_ env: inout Environment, _ logicalName: String, _ s: String) {
        Router.WriteString(&env, logicalName, s)
    }

    public static func SyntaxErrorMessage(_ env: inout Environment, _ whereId: String) {
        Router.WriteString(&env, Router.STDERR, "Syntax error in \(whereId)\n")
    }

    public static func SystemError(_ env: inout Environment, _ module: String, _ code: Int) {
        Router.WriteString(&env, Router.STDERR, "System error [\(module):\(code)]\n")
    }

    public static func PrintErrorID(_ env: inout Environment, _ module: String, _ code: Int, _ printCR: Bool) {
        Router.WriteString(&env, Router.STDERR, "[\(module)] error \(code)")
        if printCR { Router.WriteString(&env, Router.STDERR, "\n") }
    }

    public static func WriteFloat(_ env: inout Environment, _ logicalName: String, _ value: Double) {
        WriteString(&env, logicalName, String(value))
    }

    public static func WriteInteger(_ env: inout Environment, _ logicalName: String, _ value: Int64) {
        WriteString(&env, logicalName, String(value))
    }

    public static func PrintAtom(_ env: inout Environment, _ logicalName: String, _ v: Value) {
        switch v {
        case .int(let i): WriteInteger(&env, logicalName, i)
        case .float(let d): WriteFloat(&env, logicalName, d)
        case .string(let s), .symbol(let s): WriteString(&env, logicalName, s)
        case .boolean(let b): WriteString(&env, logicalName, b ? "TRUE" : "FALSE")
        case .multifield(let arr):
            WriteString(&env, logicalName, "(")
            for (i, e) in arr.enumerated() {
                if i > 0 { WriteString(&env, logicalName, " ") }
                PrintAtom(&env, logicalName, e)
            }
            WriteString(&env, logicalName, ")")
        case .none: WriteString(&env, logicalName, "<none>")
        }
    }
}
