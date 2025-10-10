import Foundation

// MARK: - Port minimale di memalloc.h (stub funzionali)

public enum Memalloc {
    public typealias OutOfMemoryFunction = (_ env: inout Environment, _ size: Int) -> Bool

    public static let MEM_TABLE_SIZE = 500
    public static let MEMORY_DATA = 59

    public struct MemoryDataStruct {
        public var MemoryAmount: Int64 = 0
        public var MemoryCalls: Int64 = 0
        public var ConserveMemory: Bool = false
        public var OutOfMemoryCallback: OutOfMemoryFunction? = nil
        // Tabelle non implementate in questa fase
    }

    // InitializeMemory(Environment *)
    public static func InitializeMemory(_ env: inout Environment) {
        // Alloca un blob per simulare MemoryData in theData[MEMORY_DATA]
        _ = Envrnmnt.AllocateEnvironmentData(&env, position: MEMORY_DATA, size: MemoryLayout<MemoryDataStruct>.size, cleanupFunction: nil)
    }

    // genalloc(Environment *, size_t) -> void *
    public static func genalloc(_ env: inout Environment, _ size: Int) -> UnsafeMutableRawPointer? {
        Memalloc.UpdateMemoryRequests(&env, 1)
        guard size > 0 else { return nil }
        let ptr = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: MemoryLayout<UInt8>.alignment)
        ptr.initializeMemory(as: UInt8.self, repeating: 0, count: size)
        Memalloc.UpdateMemoryUsed(&env, Int64(size))
        return ptr
    }

    // genfree(Environment *, void *, size_t)
    public static func genfree(_ env: inout Environment, _ ptr: UnsafeMutableRawPointer?, _ size: Int) {
        guard let p = ptr else { return }
        p.deallocate()
        _ = Memalloc.UpdateMemoryUsed(&env, -Int64(size))
    }

    // genrealloc(Environment *, void *, size_t, size_t) -> void *
    public static func genrealloc(_ env: inout Environment, _ old: UnsafeMutableRawPointer?, _ oldSize: Int, _ newSize: Int) -> UnsafeMutableRawPointer? {
        let newPtr = genalloc(&env, newSize)
        if let o = old, let n = newPtr {
            let copy = min(oldSize, newSize)
            n.copyMemory(from: o, byteCount: copy)
            genfree(&env, o, oldSize)
        }
        return newPtr
    }

    // Metriche basilari
    @discardableResult
    public static func UpdateMemoryUsed(_ env: inout Environment, _ delta: Int64) -> Int64 {
        // In questa fase non persistiamo una vera struttura
        return delta
    }

    @discardableResult
    public static func UpdateMemoryRequests(_ env: inout Environment, _ delta: Int64) -> Int64 {
        return delta
    }
}

