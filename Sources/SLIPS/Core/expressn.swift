import Foundation

// MARK: - Espressioni (port semplificato di expressn.c/expressn.h)

public enum ExprType: UInt16, Codable {
    case fcall
    case integer
    case float
    case string
    case symbol
    case boolean
    case variable        // ?x
    case mfVariable      // $?xs
    case gblVariable     // ?*g*
    case mfGblVariable   // $?*g*
    case instanceName    // [name]
}

public final class ExpressionNode: Codable {
    public var type: ExprType
    public var value: AnyCodable?
    public var argList: ExpressionNode?
    public var nextArg: ExpressionNode?

    public init(type: ExprType, value: AnyCodable? = nil, argList: ExpressionNode? = nil, nextArg: ExpressionNode? = nil) {
        self.type = type
        self.value = value
        self.argList = argList
        self.nextArg = nextArg
    }
}

// MARK: - Helpers equivalenti a GenConstant / collegamenti list

public enum Expressions {
    public static func GenConstant(_ type: ExprType, _ value: Any) -> ExpressionNode {
        return ExpressionNode(type: type, value: AnyCodable(value))
    }

    public static func makeFCall(_ name: String, args: [ExpressionNode]) -> ExpressionNode {
        let head = ExpressionNode(type: .fcall, value: AnyCodable(name))
        linkArgs(head, args)
        return head
    }

    public static func linkArgs(_ call: ExpressionNode, _ args: [ExpressionNode]) {
        var prev: ExpressionNode? = nil
        for a in args {
            if call.argList == nil { call.argList = a } else { prev?.nextArg = a }
            prev = a
        }
    }

    public static func forEachArg(_ node: ExpressionNode?, _ body: (ExpressionNode) -> Void) {
        var cur = node
        while let n = cur {
            body(n)
            cur = n.nextArg
        }
    }
}

// MARK: - AnyCodable piccolo wrapper per codificare Any in JSON

public struct AnyCodable: Codable {
    public let value: Any
    public init(_ value: Any) { self.value = value }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let i = try? container.decode(Int64.self) { value = i; return }
        if let d = try? container.decode(Double.self) { value = d; return }
        if let s = try? container.decode(String.self) { value = s; return }
        if let b = try? container.decode(Bool.self) { value = b; return }
        value = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let i as Int64: try container.encode(i)
        case let i as Int: try container.encode(Int64(i))
        case let d as Double: try container.encode(d)
        case let f as Float: try container.encode(Double(f))
        case let s as String: try container.encode(s)
        case let b as Bool: try container.encode(b)
        default:
            try container.encode(String(describing: value))
        }
    }
}
