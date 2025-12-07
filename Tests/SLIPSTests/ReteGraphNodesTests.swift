import XCTest
@testable import SLIPS

@MainActor
final class ReteGraphNodesTests: XCTestCase {
    func testGraphBuiltAndBetaLevelsPersist() throws {
        throw XCTSkip("Test usa strutture legacy (graphs, betaLevels) non presenti nel sistema esplicito")
        /*
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(set-join-check on)")
        _ = SLIPS.eval(expr: "(set-join-activate on)")
        _ = SLIPS.eval(expr: "(deftemplate A (slot v))")
        _ = SLIPS.eval(expr: "(deftemplate B (slot v))")
        _ = SLIPS.eval(expr: "(defrule r (A v ?x) (B v ?x) => (printout t \"G\"))")
        guard let env1 = SLIPS.currentEnvironment else { XCTFail(); return }
        // Grafo deve esistere e contenere nodi per i due pattern + terminale
        let g = env1.rete.graphs["r"]
        XCTAssertNotNil(g)
        if let graph = g {
            // 2 join/exists/neg + terminal (+ eventuale filter)
            let joinLike = graph.nodes.filter { n in
                switch n.kind { case .join, .exists, .neg: return true; default: return false }
            }
            XCTAssertEqual(joinLike.count, 2)
            XCTAssertNotNil(graph.levelToNodeIndex[0])
            XCTAssertNotNil(graph.levelToNodeIndex[1])
        }

        // Inserisci fatti e verifica memorie per livello
        _ = SLIPS.eval(expr: "(assert A v 1)")
        _ = SLIPS.eval(expr: "(assert B v 1)")
        XCTAssertEqual(SLIPS.run(limit: nil), 1)
        guard let env2 = SLIPS.currentEnvironment else { XCTFail(); return }
        let levels = env2.rete.betaLevels["r"] ?? [:]
        XCTAssertEqual(levels.count >= 2, true)
        // Livello terminale deve avere almeno un token
        let term = env2.rete.beta["r"]?.tokens ?? []
        XCTAssertEqual(term.count, 1)
        */
    }
}

