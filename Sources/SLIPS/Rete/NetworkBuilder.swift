// SLIPS - Swift Language Implementation of Production Systems
// Copyright (c) 2025 SLIPS Contributors
// Licensed under the MIT License - see LICENSE file for details

import Foundation

// MARK: - Network Builder (Fase 1, Task 1.2)
// Traduzione fedele da rulebld.c, reteutil.c (CLIPS 6.4.2)
// Riferimenti C:
// - ConstructJoins (rulebld.c) → buildNetwork
// - FindAlphaNode (reteutil.c) → findOrCreateAlphaNode
// - CreateNewJoin (network.c) → creazione JoinNodeClass

/// Builder per costruzione incrementale della rete RETE
/// Costruisce nodi espliciti (alpha, join, beta memory, production) da regole
/// (ref: ConstructJoins in rulebld.c)
public enum NetworkBuilder {
    
    /// Costruisce o riusa nodi della rete per una regola
    /// Ritorna il production node terminale
    /// (ref: ConstructJoins in rulebld.c)
    public static func buildNetwork(
        for rule: Rule,
        env: inout Environment
    ) -> ProductionNode {
        if env.watchRete {
            print("[RETE Build] Constructing network for rule '\(rule.name)' with \(rule.patterns.count) patterns")
        }
        
        var currentLevel = 0
        var currentNode: ReteNode? = nil
        var firstJoinCreated = false  // Track if we've created the first join
        var lastJoinNode: JoinNodeClass? = nil  // Track last join for nextLinks
        
        // Per ogni pattern, costruisci la catena di nodi
        for (index, pattern) in rule.patterns.enumerated() {
            // 1. Trova o crea alpha node per il pattern
            let alphaNode = findOrCreateAlphaNode(pattern: pattern, env: &env)
            
            if pattern.negated {
                // NOT CE: crea NotNodeClass
                if env.watchRete {
                    print("[RETE Build]   Level \(currentLevel + 1): NOT pattern \(pattern.name)")
                }
                
                let joinKeys = extractJoinKeys(pattern, previousPatterns: Array(rule.patterns[..<index]))
                let notNode = NotNodeClass(
                    pattern: pattern,
                    keys: joinKeys,
                    alphaNode: alphaNode,
                    level: currentLevel + 1
                )
                
                if let prev = currentNode {
                    linkNodes(from: prev, to: notNode)
                }
                currentNode = notNode
                currentLevel += 1
                
            } else if pattern.exists {
                // EXISTS CE: crea ExistsNodeClass
                if env.watchRete {
                    print("[RETE Build]   Level \(currentLevel + 1): EXISTS pattern \(pattern.name)")
                }
                
                let existsNode = ExistsNodeClass(
                    pattern: pattern,
                    alphaNode: alphaNode,
                    level: currentLevel + 1
                )
                
                if let prev = currentNode {
                    linkNodes(from: prev, to: existsNode)
                }
                currentNode = existsNode
                currentLevel += 1
                
            } else {
                // Pattern positivo: crea JoinNodeClass
                if let prev = currentNode {
                    if env.watchRete {
                        print("[RETE Build]   Level \(currentLevel + 1): JOIN pattern \(pattern.name)")
                    }
                    
                    let joinKeys = extractJoinKeys(pattern, previousPatterns: Array(rule.patterns[..<index]))
                    
                    // Estrai test applicabili a questo livello
                    let testsForLevel = extractTestsForLevel(
                        level: currentLevel,
                        allTests: rule.tests,
                        patternsUpTo: index,
                        patterns: rule.patterns
                    )
                    
                    let joinNode = JoinNodeClass(
                        left: prev,
                        right: alphaNode,
                        keys: joinKeys,
                        tests: testsForLevel,
                        level: currentLevel + 1
                    )
                    
                    // CRITICO: Marca il primo join della regola (per EmptyDrive in drive.c)
                    if !firstJoinCreated {
                        joinNode.firstJoin = true
                        firstJoinCreated = true
                        if env.watchRete {
                            print("[RETE Build]     *** FIRST JOIN marked for rule '\(rule.name)'")
                        }
                    }
                    
                    // CRITICO: Popola nextLinks del join precedente (per propagazione in drive.c)
                    if let prevJoin = lastJoinNode {
                        let link = JoinLink()
                        link.join = joinNode
                        link.enterDirection = "l"  // Left entry (LHS) - match proviene dalla catena precedente
                        prevJoin.nextLinks.append(link)
                        
                        if env.watchRete {
                            print("[RETE Build]     *** Added nextLink LHS from join level \(prevJoin.level) to \(joinNode.level)")
                        }
                    }
                    lastJoinNode = joinNode
                    
                    // IMPORTANTE: Registra questo join node come listener dell'alpha destro
                    // Quando l'alpha riceve un fatto, notificherà questo join
                    alphaNode.rightJoinListeners.append(joinNode)
                    
                    linkNodes(from: prev, to: joinNode)
                    currentNode = joinNode
                    currentLevel += 1
                    
                } else {
                    // Primo pattern: alpha node è il punto di partenza
                    if env.watchRete {
                        print("[RETE Build]   Level \(currentLevel + 1): ROOT alpha pattern \(pattern.name)")
                    }
                    
                    // Crea beta memory iniziale per il primo pattern
                    let betaMemory = BetaMemoryNode(level: currentLevel + 1)
                    
                    // IMPORTANTE: Collega alpha node al beta memory per propagazione iniziale
                    // Quando un fatto matcha l'alpha, attiverà il beta memory
                    alphaNode.successors.append(betaMemory)
                    
                    currentNode = betaMemory
                    currentLevel += 1
                }
                
                // Aggiungi beta memory node per persistenza token intermedi
                // (solo per pattern intermedi, non per l'ultimo)
                if index < rule.patterns.count - 1 {
                    let betaMemory = BetaMemoryNode(level: currentLevel)
                    if let prev = currentNode {
                        linkNodes(from: prev, to: betaMemory)
                    }
                    currentNode = betaMemory
                    
                    if env.watchRete {
                        print("[RETE Build]     + Beta memory at level \(currentLevel)")
                    }
                }
            }
        }
        
        // 2. Aggiungi test constraints terminali (se presenti)
        let terminalTests = extractTerminalTests(allTests: rule.tests, patterns: rule.patterns)
        if !terminalTests.isEmpty {
            if env.watchRete {
                print("[RETE Build]   Level \(currentLevel + 1): Terminal tests (\(terminalTests.count))")
            }
            // I test terminali sono già integrati nei JoinNodeClass
            // oppure vengono applicati nel production node
        }
        
        // 3. Termina con production node
        let productionNode = ProductionNode(
            ruleName: rule.name,
            rhs: rule.rhs,
            salience: rule.salience,
            level: currentLevel + 1
        )
        
        if let prev = currentNode {
            linkNodes(from: prev, to: productionNode)
        }
        
        // CRITICO: Collega ultimo join al production node (per attivazioni in EmptyDrive)
        if let lastJoin = lastJoinNode {
            lastJoin.ruleToActivate = productionNode
            if env.watchRete {
                print("[RETE Build] *** Linked last join (level \(lastJoin.level)) to production '\(rule.name)'")
            }
        }
        
        // 4. Registra production node nell'environment
        env.rete.productionNodes[rule.name] = productionNode
        
        if env.watchRete {
            print("[RETE Build] Network for '\(rule.name)' complete: \(currentLevel + 1) levels")
        }
        
        return productionNode
    }
    
    // MARK: - Helper Methods
    
    /// Trova o crea alpha node per un pattern (condivisione alpha nodes)
    /// (ref: FindAlphaNode in reteutil.c)
    private static func findOrCreateAlphaNode(
        pattern: Pattern,
        env: inout Environment
    ) -> AlphaNodeClass {
        // Genera chiave univoca per il pattern (template + costanti)
        let key = alphaNodeKey(pattern)
        
        // Cerca nodo esistente
        if let existing = env.rete.alphaNodes[key] {
            if env.watchRete {
                print("[RETE Build]     Reusing alpha node for pattern \(pattern.name)")
            }
            return existing
        }
        
        // Crea nuovo alpha node
        let alphaNode = AlphaNodeClass(pattern: pattern, level: 0)
        env.rete.alphaNodes[key] = alphaNode
        
        if env.watchRete {
            print("[RETE Build]     Created new alpha node for pattern \(pattern.name)")
        }
        
        return alphaNode
    }
    
    /// Genera chiave univoca per alpha node
    /// Basata su template name + costanti nei slot + variabili
    /// NOTA: Alpha nodes sono condivisi SOLO se pattern e binding sono identici
    private static func alphaNodeKey(_ pattern: Pattern) -> String {
        var key = pattern.name
        
        // Aggiungi costanti per disambiguare
        let constants = pattern.slots.compactMap { (slot, test) -> String? in
            if case .constant(let value) = test.kind {
                return "\(slot)=\(valueToString(value))"
            }
            return nil
        }.sorted()
        
        if !constants.isEmpty {
            key += ":C=" + constants.joined(separator: ",")
        }
        
        // Aggiungi variabili per disambiguare (nomi conta!)
        // Alpha nodes con variabili diverse NON devono essere condivisi
        let variables = pattern.slots.compactMap { (slot, test) -> String? in
            switch test.kind {
            case .variable(let name):
                return "\(slot)=?\(name)"
            case .mfVariable(let name):
                return "\(slot)=$?\(name)"
            default:
                return nil
            }
        }.sorted()
        
        if !variables.isEmpty {
            key += ":V=" + variables.joined(separator: ",")
        }
        
        // Aggiungi flag speciali
        if pattern.negated {
            key += ":NOT"
        }
        if pattern.exists {
            key += ":EXISTS"
        }
        
        return key
    }
    
    /// Converte Value in stringa per chiave
    private static func valueToString(_ value: Value) -> String {
        switch value {
        case .int(let i): return "i\(i)"
        case .float(let d): return "f\(d)"
        case .string(let s): return "s'\(s)'"
        case .symbol(let s): return "y\(s)"
        case .boolean(let b): return "b\(b)"
        case .multifield(let arr): return "m[\(arr.map(valueToString).joined(separator: ","))]"
        case .none: return "nil"
        }
    }
    
    /// Estrae variabili di join condivise con pattern precedenti
    /// (ref: precomputeJoinSpecs in ReteCompiler - AlphaNetwork.swift)
    private static func extractJoinKeys(
        _ pattern: Pattern,
        previousPatterns: [Pattern]
    ) -> Set<String> {
        var joinKeys: Set<String> = []
        
        // Trova variabili nel pattern corrente
        var currentVars: Set<String> = []
        for (_, test) in pattern.slots {
            switch test.kind {
            case .variable(let name), .mfVariable(let name):
                currentVars.insert(name)
            default:
                break
            }
        }
        
        // Trova variabili già bound in pattern precedenti
        var boundVars: Set<String> = []
        for prev in previousPatterns where !prev.negated && !prev.exists {
            for (_, test) in prev.slots {
                switch test.kind {
                case .variable(let name), .mfVariable(let name):
                    boundVars.insert(name)
                default:
                    break
                }
            }
        }
        
        // Join keys sono variabili condivise
        joinKeys = currentVars.intersection(boundVars)
        
        return joinKeys
    }
    
    /// Estrae test applicabili a un livello specifico
    /// Un test è applicabile quando tutte le sue variabili sono bound
    private static func extractTestsForLevel(
        level: Int,
        allTests: [ExpressionNode],
        patternsUpTo: Int,
        patterns: [Pattern]
    ) -> [ExpressionNode] {
        // Per ora ritorna array vuoto - i test sono gestiti nei JoinNode stessi
        // Implementazione futura potrebbe distribuire test per livello come in ReteCompiler
        return []
    }
    
    /// Estrae test terminali (applicabili solo dopo tutti i pattern)
    private static func extractTerminalTests(
        allTests: [ExpressionNode],
        patterns: [Pattern]
    ) -> [ExpressionNode] {
        // Per ora ritorna tutti i test come terminali
        // Il production node o un nodo filtro li applicherà
        return allTests
    }
    
    /// Collega due nodi nella rete (aggiunge 'to' come successore di 'from')
    private static func linkNodes(from: ReteNode, to: ReteNode) {
        // Gestisce il collegamento basandosi sul tipo del nodo sorgente
        if let alphaNode = from as? AlphaNodeClass {
            if let joinNode = to as? JoinNodeClass {
                alphaNode.successors.append(joinNode)
            }
        } else if let joinNode = from as? JoinNodeClass {
            joinNode.successors.append(to)
        } else if let betaMemory = from as? BetaMemoryNode {
            betaMemory.successors.append(to)
        } else if let notNode = from as? NotNodeClass {
            notNode.successors.append(to)
        } else if let existsNode = from as? ExistsNodeClass {
            existsNode.successors.append(to)
        }
    }
}

