import Foundation

// MARK: - Port della logica di envrnmnt.c

public enum Envrnmnt {
    public typealias EnvironmentCleanupFunction = (inout Environment) -> Void

    // AllocateEnvironmentData(Environment *, unsigned position, size_t size, EnvironmentCleanupFunction *cleanup)
    // Ritorna true/false come in C, con messaggi diagnostici equivalenti.
    @discardableResult
    public static func AllocateEnvironmentData(_ theEnvironment: inout Environment,
                                               position: Int,
                                               size: Int,
                                               cleanupFunction: EnvironmentCleanupFunction?) -> Bool {
        if position >= Environment.MAXIMUM_ENVIRONMENT_POSITIONS {
            print("\n[ENVRNMNT2] Environment data position \(position) exceeds the maximum allowed.")
            return false
        }
        if theEnvironment.theData[position] != nil {
            print("\n[ENVRNMNT3] Environment data position \(position) already allocated.")
            return false
        }
        guard size >= 0 else {
            print("\n[ENVRNMNT4] Environment data position \(position) could not be allocated.")
            return false
        }
        theEnvironment.theData[position] = Data(count: size)
        if theEnvironment.theData[position] == nil {
            print("\n[ENVRNMNT4] Environment data position \(position) could not be allocated.")
            return false
        }
        theEnvironment.cleanupFunctions[position] = cleanupFunction
        return true
    }

    // Equivalenti delle macro GetEnvironmentData/SetEnvironmentData
    public static func GetEnvironmentData<T>(_ theEnvironment: Environment, _ position: Int) -> T? {
        return theEnvironment.theData[position] as? T
    }

    public static func SetEnvironmentData(_ theEnvironment: inout Environment, _ position: Int, _ value: Any?) {
        theEnvironment.theData[position] = value
    }

    // GetEnvironmentContext(Environment *) -> void *
    public static func GetEnvironmentContext(_ theEnvironment: Environment) -> UnsafeMutableRawPointer? {
        return theEnvironment.context
    }

    // SetEnvironmentContext(Environment *, void *) -> void * (ritorna il vecchio contesto)
    @discardableResult
    public static func SetEnvironmentContext(_ theEnvironment: inout Environment,
                                             _ theContext: UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer? {
        let old = theEnvironment.context
        theEnvironment.context = theContext
        return old
    }

    // AddEnvironmentCleanupFunction(Environment *, const char *name, EnvironmentCleanupFunction *func, int priority)
    @discardableResult
    public static func AddEnvironmentCleanupFunction(_ theEnv: inout Environment,
                                                     name: String,
                                                     functionPtr: @escaping EnvironmentCleanupFunction,
                                                     priority: Int) -> Bool {
        let newNode = Environment.CleanupNode(name: name, funcPtr: functionPtr, priority: priority)
        guard let head = theEnv.listOfCleanupEnvironmentFunctions else {
            theEnv.listOfCleanupEnvironmentFunctions = newNode
            return true
        }
        var current: Environment.CleanupNode? = head
        var last: Environment.CleanupNode? = nil
        while let c = current, priority < c.priority {
            last = c
            current = c.next
        }
        if last == nil {
            newNode.next = theEnv.listOfCleanupEnvironmentFunctions
            theEnv.listOfCleanupEnvironmentFunctions = newNode
        } else {
            newNode.next = current
            last?.next = newNode
        }
        return true
    }
}
