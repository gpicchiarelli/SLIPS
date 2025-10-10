import Foundation

// MARK: - Port basilare di router.h

public enum Router {
    public static let STDOUT: String = "stdout"
    public static let STDIN: String = "stdin"
    public static let STDERR: String = "stderr"
    public static let STDWRN: String = "stdwrn"

    public static func WriteString(_ env: inout Environment, _ logicalName: String, _ message: String) {
        // Tenta di inoltrare ai router registrati che dichiarano interesse
        let data = RouterEnvData.ensure(&env)
        for entry in data.routers where entry.active {
            if let q = entry.query, q(&env, logicalName) {
                entry.write?(&env, logicalName, message)
                return
            }
        }
        // Fallback: 't' e STDOUT su stdout; STDERR/STDWRN su stderr
        if logicalName == STDERR || logicalName == STDWRN {
            fputs(message, stderr)
        } else {
            fputs(message, stdout)
        }
    }

    public static func Write(_ env: inout Environment, _ message: String) {
        WriteString(&env, STDOUT, message)
    }

    public static func Writeln(_ env: inout Environment, _ message: String) {
        WriteString(&env, STDOUT, message + "\n")
    }

    public static func ReadRouter(_ env: inout Environment, _ logicalName: String) -> Int {
        let data = RouterEnvData.ensure(&env)
        for entry in data.routers where entry.active {
            if let q = entry.query, q(&env, logicalName) {
                if let r = entry.read { return r(&env, logicalName) }
            }
        }
        return -1 // EOF
    }

    @discardableResult
    public static func UnreadRouter(_ env: inout Environment, _ logicalName: String, _ ch: Int) -> Int {
        let data = RouterEnvData.ensure(&env)
        for entry in data.routers where entry.active {
            if let q = entry.query, q(&env, logicalName) {
                if let u = entry.unread { return u(&env, logicalName, ch) }
            }
        }
        return ch
    }
}
