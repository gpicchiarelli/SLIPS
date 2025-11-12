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
        // Assert multiple values; only x > 1 should survive the predicate filter node
        _ = CLIPS.eval(expr: "(assert (A (v 1)))")
        _ = CLIPS.eval(expr: "(assert (B (v 1)))")
        _ = CLIPS.eval(expr: "(assert (A (v 2)))")
        _ = CLIPS.eval(expr: "(assert (B (v 2)))")
        _ = CLIPS.eval(expr: "(assert (A (v 3)))")
        _ = CLIPS.eval(expr: "(assert (B (v 3)))")

        guard let env = CLIPS.currentEnvironment else { XCTFail(); return }
        XCTAssertEqual(env.rules.count, 1)
        XCTAssertEqual(env.rules.first?.patterns.count, 2)
        if case let .variable(name)? = env.rules.first?.patterns.first?.slots["v"]?.kind {
            XCTAssertEqual(name, "?x")
        } else {
            XCTFail("Il pattern di A.v non è stato interpretato come variabile")
        }
        XCTAssertEqual(env.rete.alphaNodes.count, 2)

        XCTAssertEqual(env.facts.count, 6)
        let aValues = env.facts.values
            .filter { $0.name == "A" }
            .compactMap { fact -> Int64? in
                if case .int(let value) = fact.slots["v"] { return value }
                return nil
            }.sorted()
        let bValues = env.facts.values
            .filter { $0.name == "B" }
            .compactMap { fact -> Int64? in
                if case .int(let value) = fact.slots["v"] { return value }
                return nil
            }.sorted()
        XCTAssertEqual(aValues, [1, 2, 3])
        XCTAssertEqual(bValues, [1, 2, 3])

        // Predicate CE should drop the x = 1 combination, leaving only the two valid tokens
        XCTAssertEqual(env.agendaQueue.queue.count, 2)
        XCTAssertEqual(env.rete.beta["r"]?.tokens.count, 2)
    }
}
