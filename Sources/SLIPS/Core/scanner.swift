import Foundation

// MARK: - Token e Scanner (sottoinsieme compatibile)

public enum TokenType {
    case LEFT_PARENTHESIS_TOKEN
    case RIGHT_PARENTHESIS_TOKEN
    case SYMBOL_TOKEN
    case STRING_TOKEN
    case INTEGER_TOKEN
    case FLOAT_TOKEN
    case SF_VARIABLE_TOKEN
    case MF_VARIABLE_TOKEN
    case GBL_VARIABLE_TOKEN
    case MF_GBL_VARIABLE_TOKEN
    case INSTANCE_NAME_TOKEN
    case STOP_TOKEN
}

public struct Token {
    public var tknType: TokenType
    public var text: String?
    public var intValue: Int64?
    public var floatValue: Double?
    public init(_ t: TokenType) { self.tknType = t }
}

public enum Scanner {
    public static func GetToken(_ env: inout Environment, _ logicalName: String, _ out: inout Token) {
        let rdata = RouterEnvData.ensure(&env)
        if logicalName == (rdata.FastCharGetRouter ?? "") {
            let src = rdata.FastCharGetString ?? ""
            var idx = rdata.FastCharGetIndex
            let scalars = Array(src.unicodeScalars)
            // skip whitespace and ';' comments to end of line
            while idx < scalars.count {
                // whitespace
                while idx < scalars.count, CharacterSet.whitespacesAndNewlines.contains(scalars[idx]) { idx += 1 }
                if idx < scalars.count, scalars[idx] == ";" {
                    // skip comment until newline or end
                    while idx < scalars.count, scalars[idx] != "\n" { idx += 1 }
                    continue
                }
                break
            }
            guard idx < scalars.count else { out = Token(.STOP_TOKEN); rdata.FastCharGetIndex = idx; return }
            let c = scalars[idx]
            if c == "(" { idx += 1; out = Token(.LEFT_PARENTHESIS_TOKEN); rdata.FastCharGetIndex = idx; return }
            if c == ")" { idx += 1; out = Token(.RIGHT_PARENTHESIS_TOKEN); rdata.FastCharGetIndex = idx; return }
            if c == "\"" {
                // parse string
                idx += 1
                var s = ""
                var i = idx
                var escaped = false
                while i < scalars.count {
                    let ch = scalars[i]
                    i += 1
                    if escaped { s.unicodeScalars.append(ch); escaped = false; continue }
                    if ch == "\\" { escaped = true; continue }
                    if ch == "\"" { break }
                    s.unicodeScalars.append(ch)
                }
                out = Token(.STRING_TOKEN)
                out.text = s
                rdata.FastCharGetIndex = i
                return
            }
            // variables / globals / multifield variables
            if c == "?" {
                // global ?*name*
                if idx + 1 < scalars.count, scalars[idx+1] == "*" {
                    var i = idx + 2
                    var name = ""
                    while i < scalars.count {
                        let ch = scalars[i]
                        if ch == "*" { i += 1; break }
                        name.unicodeScalars.append(ch)
                        i += 1
                    }
                    out = Token(.GBL_VARIABLE_TOKEN); out.text = name
                    rdata.FastCharGetIndex = i
                    return
                }
                // single field variable ?name
                var i = idx + 1
                var name = ""
                while i < scalars.count {
                    let ch = scalars[i]
                    if CharacterSet.whitespacesAndNewlines.contains(ch) || ch == "(" || ch == ")" { break }
                    name.unicodeScalars.append(ch)
                    i += 1
                }
                out = Token(.SF_VARIABLE_TOKEN); out.text = name
                rdata.FastCharGetIndex = i
                return
            }
            if c == "$" && idx + 1 < scalars.count && scalars[idx+1] == "?" {
                // $?*g* or $?name
                var i = idx + 2
                if i < scalars.count, scalars[i] == "*" {
                    i += 1
                    var name = ""
                    while i < scalars.count {
                        let ch = scalars[i]
                        if ch == "*" { i += 1; break }
                        name.unicodeScalars.append(ch)
                        i += 1
                    }
                    out = Token(.MF_GBL_VARIABLE_TOKEN); out.text = name
                    rdata.FastCharGetIndex = i
                    return
                } else {
                    var name = ""
                    while i < scalars.count {
                        let ch = scalars[i]
                        if CharacterSet.whitespacesAndNewlines.contains(ch) || ch == "(" || ch == ")" { break }
                        name.unicodeScalars.append(ch)
                        i += 1
                    }
                    out = Token(.MF_VARIABLE_TOKEN); out.text = name
                    rdata.FastCharGetIndex = i
                    return
                }
            }
            // instance name [name]
            if c == "[" {
                var i = idx + 1
                var name = ""
                while i < scalars.count {
                    let ch = scalars[i]
                    if ch == "]" { i += 1; break }
                    name.unicodeScalars.append(ch)
                    i += 1
                }
                out = Token(.INSTANCE_NAME_TOKEN); out.text = name
                rdata.FastCharGetIndex = i
                return
            }

            // symbol or number
            var i = idx
            var buf = ""
            while i < scalars.count {
                let ch = scalars[i]
                if CharacterSet.whitespacesAndNewlines.contains(ch) || ch == "(" || ch == ")" { break }
                buf.unicodeScalars.append(ch)
                i += 1
            }
            rdata.FastCharGetIndex = i
            if let iv = Int64(buf) { out = Token(.INTEGER_TOKEN); out.intValue = iv; out.text = buf; return }
            if let dv = Double(buf) { out = Token(.FLOAT_TOKEN); out.floatValue = dv; out.text = buf; return }
            out = Token(.SYMBOL_TOKEN); out.text = buf; return
        }
        // Fallback: end of input for unknown router
        out = Token(.STOP_TOKEN)
    }
}
