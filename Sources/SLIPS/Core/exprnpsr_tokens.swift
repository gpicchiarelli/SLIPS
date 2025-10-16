import Foundation

// MARK: - Parser basato su token (port di Function1Parse/2Parse/ArgumentParse)

public enum ExprTokenParseError: Error, CustomStringConvertible {
    case expectedFunctionName
    case expectedConstantOrExpression
    case unexpectedEOF
    case missingRightParen
    case missingFunctionDeclaration(String)

    public var description: String {
        switch self {
        case .expectedFunctionName: return "Il nome della funzione deve essere un simbolo."
        case .expectedConstantOrExpression: return "Atteso costante, variabile o espressione."
        case .unexpectedEOF: return "Fine input inattesa."
        case .missingRightParen: return "Parentesi destra mancante."
        case .missingFunctionDeclaration(let n): return "Dichiarazione funzione mancante per '\(n)'."
        }
    }
}

public enum ExprTokenParser {
    // parse top-level atom or expression using a logical router
    public static func parseTop(_ env: inout Environment, logicalName: String) throws -> ExpressionNode {
        var t = Token(.STOP_TOKEN)
        Scanner.GetToken(&env, logicalName, &t)
        switch t.tknType {
        case .SYMBOL_TOKEN, .STRING_TOKEN, .INTEGER_TOKEN, .FLOAT_TOKEN:
            return tokenToConstant(t)
        case .SF_VARIABLE_TOKEN, .MF_VARIABLE_TOKEN, .GBL_VARIABLE_TOKEN, .MF_GBL_VARIABLE_TOKEN, .INSTANCE_NAME_TOKEN:
            return tokenToConstant(t)
        case .LEFT_PARENTHESIS_TOKEN:
            return try Function1Parse(&env, logicalName)
        case .RIGHT_PARENTHESIS_TOKEN:
            throw ExprTokenParseError.missingRightParen
        case .STOP_TOKEN:
            throw ExprTokenParseError.unexpectedEOF
        }
    }

    // Parse atom or expression using optional pre-read token
    public static func ParseAtomOrExpression(_ env: inout Environment,
                                             _ logicalName: String,
                                             _ useToken: Token?) throws -> ExpressionNode {
        var token = useToken ?? Token(.STOP_TOKEN)
        if useToken == nil { Scanner.GetToken(&env, logicalName, &token) }
        switch token.tknType {
        case .SYMBOL_TOKEN, .STRING_TOKEN, .INTEGER_TOKEN, .FLOAT_TOKEN:
            return tokenToConstant(token)
        case .LEFT_PARENTHESIS_TOKEN:
            return try Function1Parse(&env, logicalName)
        default:
            throw ExprTokenParseError.expectedConstantOrExpression
        }
    }

    // Group actions into a progn until endWord symbol (optional)
    public static func GroupActions(_ env: inout Environment,
                                    _ logicalName: String,
                                    _ endWord: String? = nil,
                                    functionNameParsed: Bool = false) throws -> ExpressionNode {
        let top = Expressions.GenConstant(.fcall, "progn")
        var readFirstToken = !functionNameParsed
        var lastOne: ExpressionNode? = nil
        while true {
            var t = Token(.STOP_TOKEN)
            if readFirstToken {
                Scanner.GetToken(&env, logicalName, &t)
            } else {
                readFirstToken = true
            }

            // End word handling (e.g., else)
            if t.tknType == .SYMBOL_TOKEN, let ew = endWord, !functionNameParsed {
                if t.text == ew { return top }
            }

            var nextOne: ExpressionNode?
            if functionNameParsed {
                guard let name = t.text else { throw ExprTokenParseError.expectedFunctionName }
                nextOne = try Function2Parse(&env, logicalName, name)
            } else if t.tknType == .SYMBOL_TOKEN || t.tknType == .STRING_TOKEN ||
                        t.tknType == .INTEGER_TOKEN || t.tknType == .FLOAT_TOKEN {
                nextOne = tokenToConstant(t)
            } else if t.tknType == .LEFT_PARENTHESIS_TOKEN {
                nextOne = try Function1Parse(&env, logicalName)
            } else {
                return top
            }

            if let n = nextOne {
                if lastOne == nil { top.argList = n } else { lastOne?.nextArg = n }
                // advance lastOne to tail
                var tail: ExpressionNode? = n
                while tail?.nextArg != nil { tail = tail?.nextArg }
                lastOne = tail
            }
        }
    }

    // Assumes '(' already consumed
    public static func Function1Parse(_ env: inout Environment, _ logicalName: String) throws -> ExpressionNode {
        var theToken = Token(.STOP_TOKEN)
        Scanner.GetToken(&env, logicalName, &theToken)
        guard theToken.tknType == .SYMBOL_TOKEN, let name = theToken.text else {
            throw ExprTokenParseError.expectedFunctionName
        }
        return try Function2Parse(&env, logicalName, name)
    }

    // After '(' and function name consumed
    public static func Function2Parse(_ env: inout Environment, _ logicalName: String, _ name: String) throws -> ExpressionNode {
        // Non forziamo l'esistenza della funzione: costrutti come (person ...) in deffacts non sono funzioni.
        let top = Expressions.GenConstant(.fcall, name)
        return try CollectArguments(&env, top, logicalName)
    }

    public static func CollectArguments(_ env: inout Environment, _ top: ExpressionNode, _ logicalName: String) throws -> ExpressionNode {
        var lastOne: ExpressionNode? = nil
        while true {
            var nextOne: ExpressionNode? = nil
            var errorFlag = false
            nextOne = try ArgumentParse(&env, logicalName, &errorFlag)
            if errorFlag { throw ExprTokenParseError.expectedConstantOrExpression }
            if nextOne == nil {
                // ')' già consumata da ArgumentParse
                return top
            }
            if lastOne == nil { top.argList = nextOne } else { lastOne?.nextArg = nextOne }
            // sposta lastOne in fondo alla lista nextOne
            var tail = nextOne
            while tail?.nextArg != nil { tail = tail?.nextArg }
            lastOne = tail
        }
    }

    public static func ArgumentParse(_ env: inout Environment, _ logicalName: String, _ errorFlag: inout Bool) throws -> ExpressionNode? {
        var theToken = Token(.STOP_TOKEN)
        Scanner.GetToken(&env, logicalName, &theToken)
        // ')' => nessun argomento
        if theToken.tknType == .RIGHT_PARENTHESIS_TOKEN { return nil }
        switch theToken.tknType {
        case .SYMBOL_TOKEN, .STRING_TOKEN, .INTEGER_TOKEN, .FLOAT_TOKEN,
             .SF_VARIABLE_TOKEN, .MF_VARIABLE_TOKEN, .GBL_VARIABLE_TOKEN, .MF_GBL_VARIABLE_TOKEN, .INSTANCE_NAME_TOKEN:
            return tokenToConstant(theToken)
        case .LEFT_PARENTHESIS_TOKEN:
            return try Function1Parse(&env, logicalName)
        default:
            errorFlag = true
            throw ExprTokenParseError.expectedConstantOrExpression
        }
    }

    private static func tokenToConstant(_ t: Token) -> ExpressionNode {
        switch t.tknType {
        case .INTEGER_TOKEN:
            return Expressions.GenConstant(.integer, t.intValue ?? 0)
        case .FLOAT_TOKEN:
            return Expressions.GenConstant(.float, t.floatValue ?? 0.0)
        case .STRING_TOKEN:
            return Expressions.GenConstant(.string, t.text ?? "")
        case .SF_VARIABLE_TOKEN:
            return Expressions.GenConstant(.variable, t.text ?? "")
        case .MF_VARIABLE_TOKEN:
            return Expressions.GenConstant(.mfVariable, t.text ?? "")
        case .GBL_VARIABLE_TOKEN:
            return Expressions.GenConstant(.gblVariable, t.text ?? "")
        case .MF_GBL_VARIABLE_TOKEN:
            return Expressions.GenConstant(.mfGblVariable, t.text ?? "")
        case .INSTANCE_NAME_TOKEN:
            return Expressions.GenConstant(.instanceName, t.text ?? "")
        case .SYMBOL_TOKEN:
            let s = t.text ?? ""
            let upper = s.uppercased()
            if upper == "TRUE" { return Expressions.GenConstant(.boolean, true) }
            if upper == "FALSE" { return Expressions.GenConstant(.boolean, false) }
            return Expressions.GenConstant(.symbol, s)
        default:
            return Expressions.GenConstant(.symbol, "")
        }
    }
}
