import Foundation

// MARK: - Dati Router (parziale) per supporto scanner

public final class RouterDataSwift {
    public var FastCharGetRouter: String? = nil
    public var FastCharGetString: String? = nil
    public var FastCharGetIndex: Int = 0
    public var InputUngets: Int = 0
    public var AwaitingInput: Bool = false
    public var routers: [RouterEntry] = []
    public init() {}
}

public enum RouterEnvData {
    public static let ROUTER_DATA = 46

    @discardableResult
    public static func ensure(_ env: inout Environment) -> RouterDataSwift {
        if let d: RouterDataSwift = Envrnmnt.GetEnvironmentData(env, ROUTER_DATA) { return d }
        let d = RouterDataSwift()
        Envrnmnt.SetEnvironmentData(&env, ROUTER_DATA, d)
        return d
    }

    public static func get(_ env: Environment) -> RouterDataSwift? {
        return Envrnmnt.GetEnvironmentData(env, ROUTER_DATA)
    }
}
