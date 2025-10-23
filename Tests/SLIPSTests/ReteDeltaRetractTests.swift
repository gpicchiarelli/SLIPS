import XCTest
@testable import SLIPS

@MainActor
final class ReteDeltaRetractTests: XCTestCase {
    func testMultiLevelDeltaRetractRemovesOnlyAffectedTokens() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(set-join-check on)")
        _ = CLIPS.eval(expr: "(set-join-activate on)")
        _ = CLIPS.eval(expr: "(deftemplate A (slot v))")
        _ = CLIPS.eval(expr: "(deftemplate B (slot v))")
        _ = CLIPS.eval(expr: "(deftemplate C (slot v))")
        _ = CLIPS.eval(expr: "(defrule r (A v ?x) (B v ?x) (C v ?x) => (printout t \"F\"))")

        _ = CLIPS.eval(expr: "(assert A v 1)")
        _ = CLIPS.eval(expr: "(assert B v 1)")
        _ = CLIPS.eval(expr: "(assert C v 1)")
        _ = CLIPS.eval(expr: "(assert A v 2)")
        _ = CLIPS.eval(expr: "(assert B v 2)")
        _ = CLIPS.eval(expr: "(assert C v 2)")
        XCTAssertEqual(CLIPS.run(limit: nil), 2)
        guard let env1 = CLIPS.currentEnvironment else { XCTFail(); return }
        let before = env1.rete.beta["r"]?.tokens.count ?? 0
        XCTAssertEqual(before, 2)

        // Retract one supporting fact for x=1 path; should leave only x=2 token
        var lastId1: Int64 = -1
        // Find fact id for C v 1
        if let env = CLIPS.currentEnvironment {
            for (id, f) in env.facts { if f.name == "C", f.slots["v"] == .int(1) { lastId1 = Int64(id); break } }
        }
        XCTAssertTrue(lastId1 > 0)
        CLIPS.retract(id: Int(lastId1))

        guard let env2 = CLIPS.currentEnvironment else { XCTFail(); return }
        let after = env2.rete.beta["r"]?.tokens.count ?? 0
        XCTAssertEqual(after, 1)
    }
    
    func testRetractPurgesBetaMemoryTokens() {
        var env = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate item (slot id))")
        _ = CLIPS.eval(expr: "(defrule r (item id ?i) => (printout t ?i))")
        
        let factValue = CLIPS.eval(expr: "(assert item id 1)")
        guard case .int(let factID) = factValue else {
            XCTFail("Expected fact id from assert")
            return
        }
        
        guard let betaNode = env.rete.betaMemoryNodes.first else {
            XCTFail("Missing beta memory node for rule")
            return
        }
        XCTAssertEqual(betaNode.memory.tokens.count, 1, "Expected token stored after assert")
        
        CLIPS.retract(id: Int(factID))
        
        XCTAssertTrue(betaNode.memory.tokens.isEmpty, "Retract should purge beta memory tokens")
        XCTAssertTrue(betaNode.memory.keyIndex.isEmpty, "Key index must be rebuilt after purge")
    }
}
