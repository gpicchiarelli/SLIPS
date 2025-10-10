import Foundation

// MARK: - Parser s-espressioni (port minimale di exprnpsr.c)

public enum ExprParseError: Error, CustomStringConvertible {
    case expectedFunctionName
    case unexpectedEOF
    case expectedToken(String)
    case invalidNumber(String)
    case generic(String)

    public var description: String {
        switch self {
        case .expectedFunctionName: return "Nome funzione mancante o non simbolo"
        case .unexpectedEOF: return "Fine input inattesa"
        case .expectedToken(let s): return "Token atteso: \(s)"
        case .invalidNumber(let s): return "Numero non valido: \(s)"
        case .generic(let s): return s
        }
    }
}

public struct ExprParser {
    let input: String
    var scalars: [UnicodeScalar]
    var index: Int = 0

    public init(_ s: String) {
        self.input = s
        self.scalars = Array(s.unicodeScalars)
    }

    public mutating func parse() throws -> ExpressionNode {
        skipSpaces()
        guard peek() == "(" else { throw ExprParseError.expectedToken("(") }
        _ = pop() // '('
        let fn = try parseSymbol()
        var args: [ExpressionNode] = []
        while true {
            skipSpaces()
            guard let c = peek() else { throw ExprParseError.unexpectedEOF }
            if c == ")" { _ = pop(); break }
            if c == "(" {
                let sub = try parse()
                args.append(sub)
            } else if c == "\"" {
                let s = try parseString()
                args.append(Expressions.GenConstant(.string, s))
            } else {
                // atom: number, boolean, symbol
                let atom = try parseAtom()
                args.append(atom)
            }
        }
        return Expressions.makeFCall(fn, args: args)
    }

    // MARK: - Lexing helpers

    mutating func parseAtom() throws -> ExpressionNode {
        let token = readToken()
        if token.isEmpty { throw ExprParseError.unexpectedEOF }
        if let i = Int64(token) { return Expressions.GenConstant(.integer, i) }
        if let d = Double(token) { return Expressions.GenConstant(.float, d) }
        let upper = token.uppercased()
        if upper == "TRUE" { return Expressions.GenConstant(.boolean, true) }
        if upper == "FALSE" { return Expressions.GenConstant(.boolean, false) }
        return Expressions.GenConstant(.symbol, token)
    }

    mutating func parseSymbol() throws -> String {
        let t = readToken()
        if t.isEmpty { throw ExprParseError.expectedFunctionName }
        return t
    }

    mutating func parseString() throws -> String {
        guard pop() == "\"" else { throw ExprParseError.expectedToken("\"") }
        var s = ""
        while let c = peek() {
            _ = pop()
            if c == "\\" { // escape
                guard let n = pop() else { throw ExprParseError.unexpectedEOF }
                s.unicodeScalars.append(n)
            } else if c == "\"" {
                return s
            } else {
                s.unicodeScalars.append(c)
            }
        }
        throw ExprParseError.unexpectedEOF
    }

    mutating func readToken() -> String {
        skipSpaces()
        var t = ""
        while let c = peek(), !CharacterSet.whitespacesAndNewlines.contains(c), c != "(", c != ")" {
            _ = pop()
            t.unicodeScalars.append(c)
        }
        return t
    }

    mutating func skipSpaces() {
        while let c = peek(), CharacterSet.whitespacesAndNewlines.contains(c) { _ = pop() }
    }

    func peek() -> UnicodeScalar? {
        return index < scalars.count ? scalars[index] : nil
    }

    @discardableResult
    mutating func pop() -> UnicodeScalar? {
        guard index < scalars.count else { return nil }
        let c = scalars[index]
        index += 1
        return c
    }
}
