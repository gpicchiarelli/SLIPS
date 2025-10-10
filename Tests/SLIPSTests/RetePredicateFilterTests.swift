import XCTest
@testable import SLIPS

@MainActor
final class RetePredicateFilterTests: XCTestCase {
    func testPredicateTestAsPostJoinFilter() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(set-join-check on)")
        _ = CLIPS.eval(expr: "(deftemplate A (slot v))")
        _ = CLIPS.eval(expr: "(deftemplate B (slot v))")
        _ = CLIPS.eval(expr: "(defrule r (A v ?x) (B v ?x) (test (> ?x 1)) => (printout t \"FIRE\" crlf))")
        // Assert multiple values; only x > 1 should pass the test node
        _ = CLIPS.eval(expr: "(assert A v 1)")
        _ = CLIPS.eval(expr: "(assert B v 1)")
        _ = CLIPS.eval(expr: "(assert A v 2)")
        _ = CLIPS.eval(expr: "(assert B v 2)")
        _ = CLIPS.eval(expr: "(assert A v 3)")
        _ = CLIPS.eval(expr: "(assert B v 3)")
        // Run and verify only x=2 and x=3 fire
        let fired = CLIPS.run(limit: nil)
        XCTAssertEqual(fired, 2)
        // Check beta terminal tokens equal 2 as well (post-filter)
        guard let env = CLIPS.currentEnvironment else { XCTFail(); return }
        let toks = env.rete.beta["r"]?.tokens ?? []
        XCTAssertEqual(toks.count, 2)
    }
}

