import XCTest
@testable import SLIPS

@MainActor
final class ReteJoinCheckTests: XCTestCase {
    func testThreePatternJoinBetaVsNaive() throws {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(set-join-check on)")
        _ = CLIPS.eval(expr: "(deftemplate A (slot v))")
        _ = CLIPS.eval(expr: "(deftemplate B (slot v))")
        _ = CLIPS.eval(expr: "(deftemplate C (slot v))")
        _ = CLIPS.eval(expr: "(defrule r (A v ?x) (B v ?x) (C v ?x) => (printout t \"J\"))")
        // Primo triple match x=1
        _ = CLIPS.eval(expr: "(assert A v 1)")
        _ = CLIPS.eval(expr: "(assert B v 1)")
        _ = CLIPS.eval(expr: "(assert C v 1)")
        XCTAssertEqual(CLIPS.run(limit: nil), 1)
        // Secondo triple match x=2
        _ = CLIPS.eval(expr: "(assert A v 2)")
        _ = CLIPS.eval(expr: "(assert B v 2)")
        _ = CLIPS.eval(expr: "(assert C v 2)")
        XCTAssertEqual(CLIPS.run(limit: nil), 1)
        // BetaMemory deve contenere due token finali per r
        guard let env = CLIPS.currentEnvironment else { XCTFail(); return }
        let toks = env.rete.beta["r"]?.tokens ?? []
        XCTAssertEqual(toks.count, 2)
    }
}
