import XCTest
@testable import SLIPS

@MainActor
final class RetePredicateFilterTests: XCTestCase {
    func testPredicateTestAsPostJoinFilter() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(set-join-check on)")
        _ = CLIPS.eval(expr: "(deftemplate A (slot v))")
        _ = CLIPS.eval(expr: "(deftemplate B (slot v))")
        _ = CLIPS.eval(expr: "(defrule r (A (v ?x)) (B (v ?x)) (test (> ?x 1)) => (printout t \"FIRE\" crlf))")
        // Assert multiple values; only x > 1 should pass the predicate node
        _ = CLIPS.eval(expr: "(assert (A (v 1)))")
        _ = CLIPS.eval(expr: "(assert (B (v 1)))")
        _ = CLIPS.eval(expr: "(assert (A (v 2)))")
        _ = CLIPS.eval(expr: "(assert (B (v 2)))")
        _ = CLIPS.eval(expr: "(assert (A (v 3)))")
        _ = CLIPS.eval(expr: "(assert (B (v 3)))")

        guard let envBefore = CLIPS.currentEnvironment else { XCTFail(); return }
        XCTAssertEqual(envBefore.rules.count, 1)
        XCTAssertEqual(envBefore.rules.first?.patterns.count, 2)
        XCTAssertEqual(envBefore.facts.count, 6)
        XCTAssertEqual(envBefore.agendaQueue.queue.count, 2)
        
        let fired = CLIPS.run(limit: nil)
        XCTAssertEqual(fired, 2)
        guard let env = CLIPS.currentEnvironment else { XCTFail(); return }
        let toks = env.rete.beta["r"]?.tokens ?? []
        XCTAssertEqual(toks.count, 2)
    }

    func testCanonicalSlotSyntaxParses() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate A (slot v))")
        _ = CLIPS.eval(expr: "(deftemplate B (slot v))")
        _ = CLIPS.eval(expr: "(defrule r (A (v ?x)) (B (v ?x)) => (printout t ?x))")
        _ = CLIPS.eval(expr: "(assert (A (v 1)))")

        guard let env = CLIPS.currentEnvironment else { XCTFail(); return }
        XCTAssertEqual(env.rules.count, 1)
        XCTAssertEqual(env.rules.first?.patterns.count, 2)
        XCTAssertEqual(env.facts.count, 1)
        if case let .variable(name)? = env.rules.first?.patterns.first?.slots["v"]?.kind {
            XCTAssertEqual(name, "x")
        } else {
            XCTFail("Il pattern canonico non è stato convertito correttamente")
        }
    }
}
