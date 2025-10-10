import Foundation

// MARK: - Port basilare di fileutil.h

public enum FileUtil {
    @discardableResult
    public static func DribbleOn(_ env: inout Environment, _ fileName: String) -> Bool {
        var data = FileCom.ensureData(&env)
        data.DribbleActive = true
        // In questa fase non apriamo file, ma segnaliamo attivo
        return true
    }

    public static func DribbleActive(_ env: Environment) -> Bool {
        let data: FileCom.FileCommandData? = Envrnmnt.GetEnvironmentData(env, FileCom.FILECOM_DATA)
        return data?.DribbleActive ?? false
    }

    @discardableResult
    public static func DribbleOff(_ env: inout Environment) -> Bool {
        var data = FileCom.ensureData(&env)
        let was = data.DribbleActive
        data.DribbleActive = false
        data.DribbleBuffer.removeAll(keepingCapacity: false)
        return was
    }

    public static func AppendDribble(_ env: inout Environment, _ str: String) {
        guard DribbleActive(env) else { return }
        var data = FileCom.ensureData(&env)
        data.DribbleBuffer.append(str)
    }

    public static func LLGetcBatch(_ env: inout Environment, _ logicalName: String, _ returnOnEOF: Bool) -> Int32 {
        // Usa i router registrati per leggere un carattere
        let ch = Router.ReadRouter(&env, logicalName)
        if ch == -1 { return returnOnEOF ? EOF : Int32(0) }
        return Int32(ch)
    }

    @discardableResult
    public static func Batch(_ env: inout Environment, _ fileName: String) -> Bool { OpenBatch(&env, fileName, false) }

    @discardableResult
    public static func OpenBatch(_ env: inout Environment, _ fileName: String, _ placeAtEnd: Bool) -> Bool {
        var data = FileCom.ensureData(&env)
        let entry = FileCom.BatchEntry(batchType: FileCom.FILE_BATCH)
        entry.fileName = fileName
        if data.TopOfBatchList == nil {
            data.TopOfBatchList = entry
            data.BottomOfBatchList = entry
        } else if placeAtEnd {
            data.BottomOfBatchList?.next = entry
            data.BottomOfBatchList = entry
        } else {
            entry.next = data.TopOfBatchList
            data.TopOfBatchList = entry
        }
        return true
    }

    @discardableResult
    public static func OpenStringBatch(_ env: inout Environment, _ logicalName: String, _ contents: String, _ placeAtEnd: Bool) -> Bool {
        var data = FileCom.ensureData(&env)
        let entry = FileCom.BatchEntry(batchType: FileCom.STRING_BATCH)
        entry.logicalSource = logicalName
        entry.theString = contents
        if data.TopOfBatchList == nil {
            data.TopOfBatchList = entry
            data.BottomOfBatchList = entry
        } else if placeAtEnd {
            data.BottomOfBatchList?.next = entry
            data.BottomOfBatchList = entry
        } else {
            entry.next = data.TopOfBatchList
            data.TopOfBatchList = entry
        }
        return true
    }

    @discardableResult
    public static func RemoveBatch(_ env: inout Environment) -> Bool {
        var data = FileCom.ensureData(&env)
        guard let top = data.TopOfBatchList else { return false }
        data.TopOfBatchList = top.next
        if data.TopOfBatchList == nil { data.BottomOfBatchList = nil }
        return data.TopOfBatchList != nil
    }

    public static func BatchActive(_ env: Environment) -> Bool {
        let data: FileCom.FileCommandData? = Envrnmnt.GetEnvironmentData(env, FileCom.FILECOM_DATA)
        return data?.TopOfBatchList != nil
    }

    public static func CloseAllBatchSources(_ env: inout Environment) {
        var data = FileCom.ensureData(&env)
        data.TopOfBatchList = nil
        data.BottomOfBatchList = nil
    }

    @discardableResult
    public static func BatchStar(_ env: inout Environment, _ fileName: String) -> Bool {
        // Esegue in modo sincrono il contenuto (non implementato). Per ora prova l'apertura e ritorna true/false.
        return OpenBatch(&env, fileName, false)
    }
}
