import XCTest
@testable import SLIPS

@MainActor
final class RetePredicateFilterTests: XCTestCase {
    func testPredicateTestAsPostJoinFilter() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(set-join-check on)")
        _ = CLIPS.eval(expr: "(watch rete)")
        _ = CLIPS.eval(expr: "(watch rules)")
        _ = CLIPS.eval(expr: "(deftemplate A (slot v))")
        _ = CLIPS.eval(expr: "(deftemplate B (slot v))")
        _ = CLIPS.eval(expr: "(defrule r (A (v ?x)) (B (v ?x)) (test (> ?x 1)) => (printout t \"FIRE\" crlf))")
        // Assert multiple values; only x > 1 should pass the test node
        _ = CLIPS.eval(expr: "(assert (A (v 1)))")
        _ = CLIPS.eval(expr: "(assert (B (v 1)))")
        _ = CLIPS.eval(expr: "(assert (A (v 2)))")
        _ = CLIPS.eval(expr: "(assert (B (v 2)))")
        _ = CLIPS.eval(expr: "(assert (A (v 3)))")
        _ = CLIPS.eval(expr: "(assert (B (v 3)))")
        guard var env = CLIPS.currentEnvironment else { XCTFail(); return }
        XCTAssertEqual(env.rules.count, 1)
        XCTAssertEqual(env.rules.first?.patterns.count, 2, "La defrule r dovrebbe avere due pattern (A e B)")
        XCTAssertEqual(env.rules.first?.patterns.first?.slots.keys.sorted(), ["v"])
        XCTAssertEqual(env.rules.first?.name, "r")
        XCTAssertEqual(env.rete.alphaNodes.count, 2, "La rete dovrebbe avere due alpha nodes per A e B")
        XCTAssertTrue(env.watchRete, "Il comando (watch rete) dovrebbe attivare il tracing")
        XCTAssertTrue(env.watchRules, "Il comando (watch rules) dovrebbe attivare il tracing delle regole")
        XCTAssertEqual(env.agendaQueue.queue.count, 2, "Prima di run, ci aspettiamo due attivazioni in agenda")
        XCTAssertTrue(env.agendaQueue.queue.allSatisfy { $0.ruleName == "r" }, "Le attivazioni devono riferirsi alla regola r")
        // Run and verify only x=2 and x=3 fire
        let fired = CLIPS.run(limit: nil)
        XCTAssertEqual(fired, 2)
        // Check beta terminal tokens equal 2 as well (post-filter)
        XCTAssertEqual(env.facts.count, 6, "Aspettavamo 6 fatti asseriti da A/B")
        XCTAssertTrue(env.agendaQueue.queue.isEmpty, "Dopo run l'agenda deve essere vuota")
        let aFacts = env.facts.values.filter { $0.name == "A" }.compactMap { fact -> Int64? in
            if case .int(let value) = fact.slots["v"] { return value } else { return nil }
        }.sorted()
        let bFacts = env.facts.values.filter { $0.name == "B" }.compactMap { fact -> Int64? in
            if case .int(let value) = fact.slots["v"] { return value } else { return nil }
        }.sorted()
        XCTAssertEqual(aFacts, [1, 2, 3])
        XCTAssertEqual(bFacts, [1, 2, 3])
        let toks = env.rete.beta["r"]?.tokens ?? []
        XCTAssertEqual(toks.count, 2)
    }
}
