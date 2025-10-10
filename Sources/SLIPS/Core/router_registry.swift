import Foundation

// MARK: - Registry dei router dinamici (API minime)

public final class RouterEntry {
    public let name: String
    public var active: Bool
    public let priority: Int
    public var query: ((inout Environment, String) -> Bool)? = nil
    public var write: ((inout Environment, String, String) -> Void)? = nil
    public var read: ((inout Environment, String) -> Int)? = nil
    public var unread: ((inout Environment, String, Int) -> Int)? = nil
    public var exit: ((inout Environment, Int) -> Void)? = nil
    public init(name: String, priority: Int, active: Bool = true) {
        self.name = name
        self.priority = priority
        self.active = active
    }
}

// Routers memorizzati direttamente in RouterDataSwift. Nessun globale.

public enum RouterRegistry {
    @discardableResult
    public static func AddRouter(_ env: inout Environment, _ name: String, _ priority: Int) -> Bool {
        var data = RouterEnvData.ensure(&env)
        if data.routers.contains(where: { $0.name == name }) { return false }
        data.routers.append(RouterEntry(name: name, priority: priority))
        data.routers.sort { $0.priority > $1.priority }
        return true
    }

    @discardableResult
    public static func AddRouter(_ env: inout Environment,
                                 _ name: String,
                                 _ priority: Int,
                                 query: ((inout Environment, String) -> Bool)? = nil,
                                 write: ((inout Environment, String, String) -> Void)? = nil,
                                 read: ((inout Environment, String) -> Int)? = nil,
                                 unread: ((inout Environment, String, Int) -> Int)? = nil,
                                 exit: ((inout Environment, Int) -> Void)? = nil) -> Bool {
        var data = RouterEnvData.ensure(&env)
        if data.routers.contains(where: { $0.name == name }) { return false }
        let entry = RouterEntry(name: name, priority: priority)
        entry.query = query
        entry.write = write
        entry.read = read
        entry.unread = unread
        entry.exit = exit
        data.routers.append(entry)
        data.routers.sort { $0.priority > $1.priority }
        return true
    }

    @discardableResult
    public static func DeleteRouter(_ env: inout Environment, _ name: String) -> Bool {
        var data = RouterEnvData.ensure(&env)
        let before = data.routers.count
        data.routers.removeAll { $0.name == name }
        return data.routers.count != before
    }

    public static func QueryRouters(_ env: Environment, _ name: String) -> Bool {
        guard let data = RouterEnvData.get(env) else { return false }
        return data.routers.contains(where: { $0.name == name })
    }

    public static func DeactivateRouter(_ env: inout Environment, _ name: String) -> Bool {
        var data = RouterEnvData.ensure(&env)
        guard let idx = data.routers.firstIndex(where: { $0.name == name }) else { return false }
        data.routers[idx].active = false
        return true
    }

    public static func ActivateRouter(_ env: inout Environment, _ name: String) -> Bool {
        var data = RouterEnvData.ensure(&env)
        guard let idx = data.routers.firstIndex(where: { $0.name == name }) else { return false }
        data.routers[idx].active = true
        return true
    }
}
