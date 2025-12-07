import Foundation

// MARK: - Port basilare di router.h

public enum Router {
    public static let STDOUT: String = "stdout"
    public static let STDIN: String = "stdin"
    public static let STDERR: String = "stderr"
    public static let STDWRN: String = "stdwrn"

    public static func WriteString(_ env: inout Environment, _ logicalName: String, _ message: String) {
        // Tenta di inoltrare ai router registrati che dichiarano interesse
        // I router sono ordinati per priorità (più alta = eseguito prima)
        // Ref: router.c - WriteString cerca router interessati e li chiama
        // IMPORTANTE: Il router dribble deve scrivere nel file E poi passare al router successivo/stdout
        let data = RouterEnvData.ensure(&env)
        
        // Cerca il primo router attivo interessato
        var handledByRouter = false
        for entry in data.routers where entry.active {
            if let q = entry.query, q(&env, logicalName) {
                // Il router gestisce il messaggio (es. dribble scrive su file)
                entry.write?(&env, logicalName, message)
                handledByRouter = true
                // IMPORTANTE: In CLIPS, il router write callback DEVE gestire anche il passaggio
                // al router successivo. Quindi NON facciamo break qui - il router stesso decide
                // se passare al successivo (vedi fileutil.c:140 - WriteDribbleCallback fa
                // DeactivateRouter, WriteString, ActivateRouter)
                // Per router che NON passano al successivo, devono fare return nel loro callback
                // Per ora, assumiamo che il router dribble gestisca il passaggio internamente
                // Altri router potrebbero fermarsi qui
                break
            }
        }
        
        // Se nessun router ha gestito, usa fallback standard (stdout/stderr)
        if !handledByRouter {
            if logicalName == STDERR || logicalName == STDWRN {
                fputs(message, stderr)
            } else {
                fputs(message, stdout)
            }
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
