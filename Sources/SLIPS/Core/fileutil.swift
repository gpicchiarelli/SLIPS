import Foundation

// MARK: - Port basilare di fileutil.h

public enum FileUtil {
    @discardableResult
    public static func DribbleOn(_ env: inout Environment, _ fileName: String) -> Bool {
        let data = FileCom.ensureData(&env)
        
        // Se già attivo, chiudi il precedente
        if data.DribbleActive {
            _ = DribbleOff(&env)
        }
        
        // Apri file per scrittura (ref: fileutil.c:310)
        let filePath: String
        if fileName.hasPrefix("/") {
            filePath = fileName
        } else {
            let cwd = FileManager.default.currentDirectoryPath
            filePath = "\(cwd)/\(fileName)"
        }
        
        // Crea directory se necessario
        let dirPath = (filePath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
        
        // Crea file vuoto per indicare che è aperto
        FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
        
        data.DribbleActive = true
        data.DribbleFilePath = filePath
        data.DribbleBuffer = ""  // Reset buffer
        
        // Registra router dribble (ref: fileutil.c:321)
        // Il router intercetta stdout/stdin/stderr/stdwrn e scrive anche nel file
        _ = RouterRegistry.AddRouter(
            &env,
            "dribble",
            40,  // Priorità alta (ref: fileutil.c:321)
            query: { _, logicalName in
                // Query callback: intercetta stdout/stdin/stderr/stdwrn
                logicalName == Router.STDOUT || logicalName == Router.STDIN ||
                logicalName == Router.STDERR || logicalName == Router.STDWRN ||
                logicalName == "t"  // 't' è anche stdout
            },
            write: { envWrite, logicalName, str in
                // Write callback: scrive nel file dribble E passa al router successivo
                guard DribbleActive(envWrite) else { return }
                let fileData = FileCom.ensureData(&envWrite)
                
                // Accumula nel buffer
                fileData.DribbleBuffer.append(str)
                
                // Scrive immediatamente su file (ref: PutcDribbleBuffer in fileutil.c:182)
                if let path = fileData.DribbleFilePath {
                    if let fileHandle = FileHandle(forWritingAtPath: path) {
                        fileHandle.seekToEndOfFile()
                        if let data = str.data(using: .utf8) {
                            fileHandle.write(data)
                        }
                        try? fileHandle.close()
                    } else {
                        // Se il file non esiste o è chiuso, crealo
                        if let data = str.data(using: .utf8) {
                            FileManager.default.createFile(atPath: path, contents: data, attributes: nil)
                        }
                    }
                }
                
                // Passa al router successivo (ref: WriteDribbleCallback in fileutil.c:140)
                // IMPORTANTE: Deattiva temporaneamente dribble per evitare loop infiniti
                // Poi chiama WriteString che cercherà il prossimo router o userà fallback (stdout)
                RouterRegistry.DeactivateRouter(&envWrite, "dribble")
                
                // Scrivi direttamente al fallback (stdout/stderr) per evitare loop
                // In alternativa, potremmo cercare il prossimo router, ma per semplicità
                // usiamo il fallback diretto
                if logicalName == Router.STDERR || logicalName == Router.STDWRN {
                    fputs(str, stderr)
                } else {
                    fputs(str, stdout)
                }
                
                RouterRegistry.ActivateRouter(&envWrite, "dribble")
            },
            read: { envRead, logicalName in
                // Read callback: passa al router successivo e aggiunge al buffer
                RouterRegistry.DeactivateRouter(&envRead, "dribble")
                let ch = Router.ReadRouter(&envRead, logicalName)
                RouterRegistry.ActivateRouter(&envRead, "dribble")
                
                // Aggiungi al buffer se non EOF
                if ch != -1 {
                    AppendDribble(&envRead, String(Character(UnicodeScalar(ch)!)))
                }
                return ch
            },
            unread: { envUnread, logicalName, ch in
                // Unread callback: rimuovi dal buffer e passa al router successivo
                let fileData = FileCom.ensureData(&envUnread)
                if !fileData.DribbleBuffer.isEmpty {
                    fileData.DribbleBuffer.removeLast()
                }
                
                RouterRegistry.DeactivateRouter(&envUnread, "dribble")
                let result = Router.UnreadRouter(&envUnread, logicalName, ch)
                RouterRegistry.ActivateRouter(&envUnread, "dribble")
                return result
            },
            exit: { envExit, _ in
                // Exit callback: scrivi buffer residuo e chiudi
                let fileData = FileCom.ensureData(&envExit)
                if let path = fileData.DribbleFilePath, !fileData.DribbleBuffer.isEmpty {
                    if let fileHandle = FileHandle(forWritingAtPath: path) {
                        fileHandle.seekToEndOfFile()
                        if let data = fileData.DribbleBuffer.data(using: .utf8) {
                            fileHandle.write(data)
                        }
                        try? fileHandle.close()
                    }
                }
                fileData.DribbleBuffer.removeAll()
                fileData.DribbleFilePath = nil
            }
        )
        
        return true
    }

    public static func DribbleActive(_ env: Environment) -> Bool {
        let data: FileCom.FileCommandData? = Envrnmnt.GetEnvironmentData(env, FileCom.FILECOM_DATA)
        return data?.DribbleActive ?? false
    }

    @discardableResult
    public static func DribbleOff(_ env: inout Environment) -> Bool {
        let data = FileCom.ensureData(&env)
        let was = data.DribbleActive
        let savedPath = data.DribbleFilePath  // Salva il path prima di rimuoverlo
        
        if was {
            // Scrive buffer residuo su file (ref: ExitDribbleCallback in fileutil.c:275)
            if let path = savedPath {
                // Assicurati che il path sia risolto correttamente
                var fullPath = path
                if !path.hasPrefix("/") {
                    let currentDir = FileManager.default.currentDirectoryPath
                    fullPath = "\(currentDir)/\(path)"
                }
                
                // Crea directory se necessario
                let dirPath = (fullPath as NSString).deletingLastPathComponent
                try? FileManager.default.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
                
                // Scrive buffer residuo su file
                if !data.DribbleBuffer.isEmpty {
                    if let fileHandle = FileHandle(forWritingAtPath: fullPath) {
                        fileHandle.seekToEndOfFile()
                        if let bufferData = data.DribbleBuffer.data(using: .utf8) {
                            fileHandle.write(bufferData)
                        }
                        try? fileHandle.close()
                    } else {
                        // Se il file non esiste, crealo e scrivi
                        try? data.DribbleBuffer.write(toFile: fullPath, atomically: true, encoding: .utf8)
                    }
                }
                
                // Mantieni il path salvato per permettere la lettura successiva
                // (ma solo se non è già stato rimosso)
            }
            
            // Chiama exit callback se presente (per cleanup router)
            if let exitFn = RouterEnvData.get(env)?.routers.first(where: { $0.name == "dribble" })?.exit {
                exitFn(&env, 0)
            }
            
            // Rimuovi router (ref: fileutil.c:388 - DeleteRouter)
            _ = RouterRegistry.DeleteRouter(&env, "dribble")
            
            data.DribbleActive = false
            data.DribbleBuffer.removeAll(keepingCapacity: false)
            // NON rimuovere DribbleFilePath subito - sarà necessario per leggere il file
            // Verrà rimosso quando necessario o alla prossima apertura
        }
        
        return was
    }

    public static func AppendDribble(_ env: inout Environment, _ str: String) {
        guard DribbleActive(env) else { return }
        let data = FileCom.ensureData(&env)
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
        let data = FileCom.ensureData(&env)
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
        let data = FileCom.ensureData(&env)
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
        let data = FileCom.ensureData(&env)
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
        let data = FileCom.ensureData(&env)
        data.TopOfBatchList = nil
        data.BottomOfBatchList = nil
    }

    @discardableResult
    public static func BatchStar(_ env: inout Environment, _ fileName: String) -> Bool {
        // Esegue in modo sincrono il contenuto (non implementato). Per ora prova l'apertura e ritorna true/false.
        return OpenBatch(&env, fileName, false)
    }
}
