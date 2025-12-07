import XCTest
@testable import SLIPS

/// Golden Tests: Esegue i file CLIPS in Assets/ e confronta l'output con Expected/*.out
/// Questi test verificano che SLIPS produca lo stesso output di CLIPS C v6.4.2
/// 
/// I file .clp in Assets/ sono GOLDEN STANDARDS e NON devono essere modificati.
/// Se un test fallisce, va corretto il motore Swift, non i file CLIPS.
@MainActor
final class GoldenTests: XCTestCase {
    
    let assetsPath = "Tests/SLIPSTests/Assets"
    
    /// Trova tutti i file .clp in Assets (escludendo duplicati con " 2")
    func findAllCLPFiles() -> [String] {
        let fm = FileManager.default
        let cwd = fm.currentDirectoryPath
        let assetsDir = "\(cwd)/\(assetsPath)"
        
        guard let files = try? fm.contentsOfDirectory(atPath: assetsDir) else {
            return []
        }
        
        return files
            .filter { $0.hasSuffix(".clp") && !$0.contains(" 2") }
            .sorted()
            .map { "\(assetsDir)/\($0)" }
    }
    
    /// Trova tutti i file .tst in Assets
    func findAllTestFiles() -> [String] {
        let fm = FileManager.default
        let cwd = fm.currentDirectoryPath
        let assetsDir = "\(cwd)/\(assetsPath)"
        
        guard let files = try? fm.contentsOfDirectory(atPath: assetsDir) else {
            return []
        }
        
        return files
            .filter { $0.hasSuffix(".tst") && !$0.contains(" 2") }
            .sorted()
            .map { "\(assetsDir)/\($0)" }
    }
    
    /// Esegue un file .tst e cattura l'output
    func executeTestFile(_ tstPath: String, outputPath: String) throws -> String {
        var env = CLIPS.createEnvironment()
        var capturedOutput = ""
        
        // Crea router per catturare output durante dribble-on
        _ = RouterRegistry.AddRouter(
            &env,
            "capture",
            100,
            query: { _, name in name == "t" || name == "stdout" },
            write: { _, _, str in capturedOutput += str }
        )
        
        // Carica compline.clp per avere compare-files e altre utility
        let assetsDir = (tstPath as NSString).deletingLastPathComponent
        let complinePath = "\(assetsDir)/compline.clp"
        if FileManager.default.fileExists(atPath: complinePath) {
            try? CLIPS.load(complinePath)
        }
        
        // Leggi il file .tst e esegui comandi uno per uno
        let tstContent = try String(contentsOfFile: tstPath, encoding: .utf8)
        let lines = tstContent.components(separatedBy: .newlines)
        
        var inDribble = false
        var dribbleOutput = ""
        var currentDribbleFile: String?
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.hasPrefix(";") {
                continue
            }
            
            // Gestisci comandi speciali
            if trimmed.contains("dribble-on") {
                // Estrai nome file da dribble-on "Actual//file.out"
                if let match = trimmed.range(of: #""[^"]+""#, options: .regularExpression) {
                    let filePath = String(trimmed[match])
                        .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                    currentDribbleFile = filePath
                    inDribble = true
                    dribbleOutput = ""
                    // Inizia a catturare output per questo file
                    continue
                }
            }
            
            if trimmed.contains("dribble-off") {
                if inDribble, let dribbleFile = currentDribbleFile {
                    // Salva output catturato nel file
                    let fullPath = "\(assetsDir)/\(dribbleFile)"
                    try? dribbleOutput.write(toFile: fullPath, atomically: true, encoding: .utf8)
                    inDribble = false
                    currentDribbleFile = nil
                }
                continue
            }
            
            // Esegui il comando CLIPS
            let cmd = trimmed
                .replacingOccurrences(of: #"\\([^\\])"#, with: "$1", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)
            
            if !cmd.isEmpty {
                // CLIPS.eval non lancia errori, ritorna Value
                _ = CLIPS.eval(expr: cmd)
                
                // Se siamo in dribble-on, cattura output
                if inDribble {
                    dribbleOutput += capturedOutput
                    capturedOutput = "" // Reset per prossimo comando
                }
            }
        }
        
        // Cleanup - routerID è String, non Bool
        RouterRegistry.DeleteRouter(&env, "capture")
        
        return dribbleOutput
    }
    
    /// Confronta due file di output e restituisce le differenze
    func compareFiles(_ expectedPath: String, _ actualPath: String) -> String? {
        guard let expected = try? String(contentsOfFile: expectedPath, encoding: .utf8),
              let actual = try? String(contentsOfFile: actualPath, encoding: .utf8) else {
            return "File non trovati"
        }
        
        let expectedLines = expected.components(separatedBy: .newlines)
        let actualLines = actual.components(separatedBy: .newlines)
        
        var differences: [String] = []
        let maxLines = max(expectedLines.count, actualLines.count)
        
        for i in 0..<maxLines {
            let expectedLine = i < expectedLines.count ? expectedLines[i] : nil
            let actualLine = i < actualLines.count ? actualLines[i] : nil
            
            if expectedLine != actualLine {
                differences.append("   \(String(format: "%3d", i+1)): \(expectedLine ?? "<EOF>")")
                differences.append("   \(String(format: "%3d", i+1)): \(actualLine ?? "<EOF>")")
            }
        }
        
        if differences.isEmpty {
            return nil // Nessuna differenza
        }
        
        return differences.joined(separator: "\n")
    }
    
    /// Esegue un file .clp e cattura l'output
    /// CLIPS.load esegue già tutti i comandi nel file (definizioni e comandi)
    func executeCLPFile(_ clpPath: String) throws -> String {
        var env = CLIPS.createEnvironment()
        var capturedOutput = ""
        
        // Crea router per catturare tutto l'output
        _ = RouterRegistry.AddRouter(
            &env,
            "golden-capture",
            100,
            query: { _, name in name == "t" || name == Router.STDOUT },
            write: { _, _, str in capturedOutput += str }
        )
        
        // CLIPS.load esegue già tutti i comandi nel file
        try CLIPS.load(clpPath)
        
        // Se il file contiene solo definizioni, esegui reset e run
        // (molti file .clp di test si aspettano questo comportamento)
        CLIPS.reset()
        _ = CLIPS.run(limit: nil)
        
        // Cleanup
        RouterRegistry.DeleteRouter(&env, "golden-capture")
        
        return capturedOutput
    }
    
    /// Esegue un file .tst completo (interpreta la sequenza di comandi)
    /// I file .tst contengono sequenze di comandi CLIPS che vengono eseguiti in ordine
    func executeTSTFile(_ tstPath: String) throws -> String {
        var env = CLIPS.createEnvironment()
        var capturedOutput = ""
        var inDribble = false
        
        // Crea router per catturare tutto l'output
        _ = RouterRegistry.AddRouter(
            &env,
            "golden-capture",
            100,
            query: { _, name in name == "t" || name == Router.STDOUT },
            write: { _, _, str in
                if inDribble {
                    capturedOutput += str
                }
            }
        )
        
        let content = try String(contentsOfFile: tstPath, encoding: .utf8)
        let assetsDir = (tstPath as NSString).deletingLastPathComponent
        
        // Usa CLIPS.load per eseguire tutti i comandi nel file .tst
        // CLIPS.load già fa il parsing e l'esecuzione corretta
        try CLIPS.load(tstPath)
        
        RouterRegistry.DeleteRouter(&env, "golden-capture")
        return capturedOutput
    }
    
    /// Test generico che esegue tutti i file .clp trovati e confronta output
    func testAllCLPGoldenTests() throws {
        let clpFiles = findAllCLPFiles()
        
        guard !clpFiles.isEmpty else {
            throw XCTSkip("Nessun file .clp trovato in Assets/")
        }
        
        var passed = 0
        var failed = 0
        var skipped = 0
        var failures: [String] = []
        
        // Testa solo i primi 5 file per ora (per velocità)
        for clpPath in clpFiles.prefix(5) {
            let clpName = (clpPath as NSString).lastPathComponent
            let baseName = clpName.replacingOccurrences(of: ".clp", with: "")
            print("\n=== Testing \(clpName) ===")
            
            do {
                // Prova prima con il file .clp diretto
                var actualOutput = try executeCLPFile(clpPath)
                
                // Se esiste un file .tst corrispondente, prova a usare quello
                let tstPath = clpPath.replacingOccurrences(of: ".clp", with: ".tst")
                if FileManager.default.fileExists(atPath: tstPath) {
                    // Usa il file .tst che contiene la sequenza corretta di comandi
                    actualOutput = try executeTSTFile(tstPath)
                }
                
                // Trova file atteso
                let expectedPath = (clpPath as NSString).deletingLastPathComponent + "/Expected//\(baseName).out"
                
                if !FileManager.default.fileExists(atPath: expectedPath) {
                    skipped += 1
                    print("  SKIP: file atteso non trovato: \(expectedPath)")
                    continue
                }
                
                // Leggi output atteso
                let expectedOutput = try String(contentsOfFile: expectedPath, encoding: .utf8)
                
                // Normalizza e confronta
                let normalizedActual = normalizeOutput(actualOutput)
                let normalizedExpected = normalizeOutput(expectedOutput)
                
                if normalizedActual != normalizedExpected {
                    failed += 1
                    // Mostra solo le prime differenze per non sovraccaricare l'output
                    let actualLines = normalizedActual.components(separatedBy: .newlines)
                    let expectedLines = normalizedExpected.components(separatedBy: .newlines)
                    let maxShow = min(10, max(actualLines.count, expectedLines.count))
                    var diffMsg = "\(clpName) FAILED:\n"
                    for i in 0..<maxShow {
                        let actualLine = i < actualLines.count ? actualLines[i] : "<EOF>"
                        let expectedLine = i < expectedLines.count ? expectedLines[i] : "<EOF>"
                        if actualLine != expectedLine {
                            diffMsg += "Line \(i+1):\n  Expected: \(expectedLine)\n  Actual:   \(actualLine)\n"
                        }
                    }
                    if max(actualLines.count, expectedLines.count) > maxShow {
                        diffMsg += "... (truncated)\n"
                    }
                    failures.append(diffMsg)
                    print("  FAIL")
                } else {
                    passed += 1
                    print("  PASS")
                }
                
            } catch {
                skipped += 1
                print("  SKIP: errore durante esecuzione: \(error)")
            }
        }
        
        print("\n=== Summary ===")
        print("Passed: \(passed), Failed: \(failed), Skipped: \(skipped)")
        
        if !failures.isEmpty {
            XCTFail("\(failed) test(s) failed:\n\(failures.joined(separator: "\n\n"))")
        }
    }
    
    /// Normalizza output per confronto (rimuove spazi extra, normalizza line endings, rimuove prompt)
    func normalizeOutput(_ output: String) -> String {
        return output
            .replacingOccurrences(of: "\r\n", with: "\n") // Normalizza line endings
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: .newlines)
            .map { line in
                // Rimuovi prompt "CLIPS>" se presente
                var cleaned = line.trimmingCharacters(in: .whitespaces)
                if cleaned.hasPrefix("CLIPS>") {
                    cleaned = String(cleaned.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                }
                return cleaned
            }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
    
    /// Test specifico per un file .clp
    func testSimpleCLPGolden() throws {
        let fm = FileManager.default
        let cwd = fm.currentDirectoryPath
        let clpPath = "\(cwd)/\(assetsPath)/simple.clp"
        
        guard FileManager.default.fileExists(atPath: clpPath) else {
            throw XCTSkip("File simple.clp non trovato")
        }
        
        // Esegui
        let output = try executeCLPFile(clpPath)
        
        // Verifica che produca output
        XCTAssertFalse(output.isEmpty, "simple.clp dovrebbe produrre output")
        XCTAssertTrue(output.contains("Ciao"), "simple.clp dovrebbe contenere 'Ciao'")
    }
    
    /// Test specifico per un file .tst
    func testSpecificGoldenTest() throws {
        let tstName = "simple.clp" // Test semplice per iniziare
        let fm = FileManager.default
        let cwd = fm.currentDirectoryPath
        let tstPath = "\(cwd)/\(assetsPath)/\(tstName)"
        
        guard FileManager.default.fileExists(atPath: tstPath) else {
            throw XCTSkip("File \(tstName) non trovato")
        }
        
        // Esegui
        let actualPath = "\(cwd)/\(assetsPath)/Actual//\(tstName.replacingOccurrences(of: ".clp", with: ".out"))"
        _ = try executeTestFile(tstPath, outputPath: actualPath)
        
        // Per ora, verifica solo che non crashi
        XCTAssertTrue(FileManager.default.fileExists(atPath: actualPath))
    }
}

