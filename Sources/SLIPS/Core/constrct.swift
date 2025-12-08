import Foundation

// MARK: - Port di constrct.h/c (Construct Manager)

public enum Constrct {
    public static let CONSTRUCT_DATA = 42
    
    // Ref: constrct.h:121 - struct constructData
    public struct ConstructDataStruct {
        public var PrintWhileLoading: Bool = false
        public var LoadInProgress: Bool = false
        // Altri campi verranno aggiunti quando necessario
    }
    
    // Ref: constrct.c:401 - SetPrintWhileLoading
    public static func SetPrintWhileLoading(_ env: inout Environment, _ value: Bool) {
        let data = ensureData(&env)
        var mutable = data
        mutable.PrintWhileLoading = value
        Envrnmnt.SetEnvironmentData(&env, CONSTRUCT_DATA, mutable)
    }
    
    // Ref: constrct.c:412 - GetPrintWhileLoading
    public static func GetPrintWhileLoading(_ env: Environment) -> Bool {
        if let data: ConstructDataStruct = Envrnmnt.GetEnvironmentData(env, CONSTRUCT_DATA) {
            return data.PrintWhileLoading
        }
        return false
    }
    
    // Ref: constrct.c:422 - SetLoadInProgress
    public static func SetLoadInProgress(_ env: inout Environment, _ value: Bool) {
        let data = ensureData(&env)
        var mutable = data
        mutable.LoadInProgress = value
        Envrnmnt.SetEnvironmentData(&env, CONSTRUCT_DATA, mutable)
    }
    
    // Ref: constrct.c:433 - GetLoadInProgress
    public static func GetLoadInProgress(_ env: Environment) -> Bool {
        if let data: ConstructDataStruct = Envrnmnt.GetEnvironmentData(env, CONSTRUCT_DATA) {
            return data.LoadInProgress
        }
        return false
    }
    
    @discardableResult
    private static func ensureData(_ env: inout Environment) -> ConstructDataStruct {
        if let data: ConstructDataStruct = Envrnmnt.GetEnvironmentData(env, CONSTRUCT_DATA) {
            return data
        }
        let data = ConstructDataStruct()
        _ = Envrnmnt.AllocateEnvironmentData(&env, position: CONSTRUCT_DATA, size: MemoryLayout<ConstructDataStruct>.size, cleanupFunction: nil)
        Envrnmnt.SetEnvironmentData(&env, CONSTRUCT_DATA, data)
        return data
    }
}


