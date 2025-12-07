import Foundation

// MARK: - Port di filecom.h (dati per comandi file)

public enum FileCom {
    public static let FILE_BATCH = 0
    public static let STRING_BATCH = 1
    public static let BUFFER_SIZE = 120
    public static let FILECOM_DATA = 14

    public final class BatchEntry {
        public var batchType: Int
        public var fileSource: UnsafeMutablePointer<FILE>?
        public var logicalSource: String?
        public var theString: String?
        public var fileName: String?
        public var lineNumber: Int64 = 0
        public var next: BatchEntry? = nil
        public init(batchType: Int) { self.batchType = batchType }
    }

    public final class FileCommandData {
        // DEBUGGING_FUNCTIONS blocco dribble semplificato
        public var DribbleActive: Bool = false
        public var DribbleBuffer: String = ""
        public var DribbleFilePath: String? = nil  // Path del file dribble aperto
        public var DribbleStatusFunction: ((inout Environment, Bool) -> Int)? = nil

        // Batch
        public var BatchType: Int = FILE_BATCH
        public var BatchFileSource: UnsafeMutablePointer<FILE>? = nil
        public var BatchLogicalSource: String? = nil
        public var BatchBuffer: String = ""
        public var TopOfBatchList: BatchEntry? = nil
        public var BottomOfBatchList: BatchEntry? = nil
        public var batchPriorParsingFile: String? = nil
    }

    @discardableResult
    public static func ensureData(_ env: inout Environment) -> FileCommandData {
        if let d: FileCommandData = Envrnmnt.GetEnvironmentData(env, FILECOM_DATA) {
            return d
        }
        let d = FileCommandData()
        Envrnmnt.SetEnvironmentData(&env, FILECOM_DATA, d)
        return d
    }
}

