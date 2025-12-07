import Foundation

// MARK: - Port di factfile.c (load-facts, save-facts)

/// Gestisce caricamento e salvataggio di fatti da file
public enum FactFile {
    
    /// LoadFacts: carica fatti da un file .fct
    /// Ref: factfile.c:523 - LoadFacts
    /// Il file .fct contiene fatti come S-expressions, uno per riga (possibilmente multi-linea)
    public static func loadFacts(_ env: inout Environment, fileName: String) -> Int {
        // Risolvi path relativo se necessario
        let filePath: String
        if fileName.hasPrefix("/") {
            filePath = fileName
        } else {
            let cwd = FileManager.default.currentDirectoryPath
            filePath = "\(cwd)/\(fileName)"
        }
        
        guard FileManager.default.fileExists(atPath: filePath) else {
            Router.WriteString(&env, Router.STDERR, "Cannot open file \(fileName)\n")
            return -1
        }
        
        guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else {
            Router.WriteString(&env, Router.STDERR, "Cannot read file \(fileName)\n")
            return -1
        }
        
        // Parse fatti dal file
        // I fatti sono S-expressions, possibilmente su più righe
        var factCount = 0
        var i = content.startIndex
        
        while i < content.endIndex {
            // Skip whitespaces
            while i < content.endIndex, content[i].isWhitespace { i = content.index(after: i) }
            guard i < content.endIndex else { break }
            
            // Skip commenti
            if i < content.endIndex && content[i] == ";" {
                while i < content.endIndex, content[i] != "\n" { i = content.index(after: i) }
                continue
            }
            
            // Parse S-expression (fatto)
            if content[i] == "(" {
                var depth = 0
                var j = i
                var inString = false
                while j < content.endIndex {
                    let c = content[j]
                    if c == "\"" { inString.toggle() }
                    if !inString {
                        if c == "(" { depth += 1 }
                        else if c == ")" { 
                            depth -= 1
                            if depth == 0 {
                                j = content.index(after: j)
                                break
                            }
                        }
                    }
                    j = content.index(after: j)
                }
                
                if depth == 0 {
                    let factSexpr = String(content[i..<j]).trimmingCharacters(in: .whitespacesAndNewlines)
                    // Converti in comando assert
                    // Formato: (template slot1 value1 slot2 value2 ...) -> (assert template slot1 value1 ...)
                    if !factSexpr.isEmpty {
                        // StandardLoadFact in CLIPS crea un'espressione (assert <fact-pattern>)
                        // Il fatto nel file è già nel formato corretto: (template slot1 val1 ...)
                        // Dobbiamo wrapparlo in (assert ...)
                        let assertCmd: String
                        if factSexpr.hasPrefix("(assert") {
                            assertCmd = factSexpr
                        } else if factSexpr.hasPrefix("(") {
                            // Estrai contenuto interno e wrappa in assert
                            let inner = factSexpr.dropFirst().dropLast().trimmingCharacters(in: .whitespacesAndNewlines)
                            assertCmd = "(assert \(inner))"
                        } else {
                            // Fatto senza parentesi (raro ma possibile)
                            assertCmd = "(assert \(factSexpr))"
                        }
                        
                        // Usa evalInternal che non richiede MainActor (no prompt per load-facts)
                        _ = SLIPSHelpers.evalInternal(&env, expr: assertCmd, printPrompt: false)
                        factCount += 1
                    }
                    i = j
                } else {
                    // Parentesi non bilanciate, skip
                    break
                }
            } else {
                // Skip caratteri non validi
                while i < content.endIndex, !content[i].isWhitespace, content[i] != "(" { i = content.index(after: i) }
            }
        }
        
        return factCount
    }
}

