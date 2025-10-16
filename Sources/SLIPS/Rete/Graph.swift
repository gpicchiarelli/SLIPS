// SLIPS - Swift Language Implementation of Production Systems
// Grafo nodi RETE esplicito ispirato ai corrispettivi in CLIPS (pattern/join/beta/filter)

import Foundation

// Nodo logico della rete per una singola regola.
public struct ReteNodeRef: Codable, Equatable {
    public enum Kind: Codable, Equatable {
        case alpha(template: String)
        case join(patternIndex: Int)     // CE positivo
        case exists(patternIndex: Int)   // CE exists unario
        case neg(patternIndex: Int)      // CE negato (per completezza del grafo)
        case filter                      // Nodo test post-join (predicate/test)
        case terminal                    // Nodo terminale (attivazioni)
    }
    public let id: Int
    public let kind: Kind
    // Livello del join-order a cui appartiene il nodo (se applicabile)
    public let level: Int?
}

// Grafo per regola: elenco nodi ordinati e mapping livello->indice nodo
public struct RuleGraph: Codable, Equatable {
    public let ruleName: String
    public let nodes: [ReteNodeRef]
    public let levelToNodeIndex: [Int: Int]
}

public enum ReteGraphBuilder {
    // Costruisce un grafo minimale dai dati compilati (joinOrder/tests/exists) senza duplicare memoria.
    public static func build(ruleName: String, compiled: CompiledRule) -> RuleGraph {
        var nodes: [ReteNodeRef] = []
        var levelToNode: [Int: Int] = [:]
        // Nodo alpha sintetico per ciascun template usato (non mappato a livello)
        let templates = Set(compiled.patterns.map { $0.original.name })
        for t in templates.sorted() {
            nodes.append(ReteNodeRef(id: nodes.count, kind: .alpha(template: t), level: nil))
        }
        // Nodi join/exists/neg secondo joinOrder
        let patterns = compiled.patterns.map { $0.original }
        for (pos, pidx) in compiled.joinOrder.enumerated() {
            let p = patterns[pidx]
            let kind: ReteNodeRef.Kind = p.exists ? .exists(patternIndex: pidx) : (p.negated ? .neg(patternIndex: pidx) : .join(patternIndex: pidx))
            let nid = nodes.count
            nodes.append(ReteNodeRef(id: nid, kind: kind, level: pos))
            levelToNode[pos] = nid
        }
        // Nodo filtro se presenti test terminali
        if let f = compiled.filterNode, !f.tests.isEmpty {
            nodes.append(ReteNodeRef(id: nodes.count, kind: .filter, level: nil))
        }
        // Nodo terminale
        nodes.append(ReteNodeRef(id: nodes.count, kind: .terminal, level: nil))
        return RuleGraph(ruleName: ruleName, nodes: nodes, levelToNodeIndex: levelToNode)
    }
}

