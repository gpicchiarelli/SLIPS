import XCTest
@testable import SLIPS

@MainActor
final class QuickJoinTest: XCTestCase {
    func testSimpleTwoPatternJoinWorks() {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(deftemplate A (slot x))")
        _ = SLIPS.eval(expr: "(deftemplate B (slot y))")
        _ = SLIPS.eval(expr: "(defrule join (A) (B) => (printout t \"JOINED\" crlf))")
        
        print("=== Asserting A ===")
        _ = SLIPS.eval(expr: "(assert A x 1)")
        
        print("=== Asserting B ===")
        _ = SLIPS.eval(expr: "(assert B y 2)")
        
        guard let env = SLIPS.currentEnvironment else { XCTFail(); return }
        print("\n=== Agenda BEFORE Run ===")
        print("Activations: \(env.agendaQueue.queue.count)")
        for (i, act) in env.agendaQueue.queue.enumerated() {
            print("  [\(i)] factIDs: \(act.factIDs)")
        }
        
        // Verifica che ci sia 1 attivazione PRIMA di run()
        XCTAssertEqual(env.agendaQueue.queue.count, 1, "Should have 1 activation before run")
        if let act = env.agendaQueue.queue.first {
            XCTAssertTrue(act.factIDs.contains(1), "Should include fact 1 (A)")
            XCTAssertTrue(act.factIDs.contains(2), "Should include fact 2 (B)")
        }
        
        print("\n=== Run ===")
        let fired = SLIPS.run(limit: nil)
        print("Fired: \(fired)")
        
        // Dopo run(), l'attivazione eseguita viene rimossa dall'agenda
        XCTAssertEqual(fired, 1, "Should fire 1 rule")
        
        // Verifica che l'agenda sia vuota dopo run() (l'attivazione è stata eseguita e rimossa)
        guard let envAfter = SLIPS.currentEnvironment else { XCTFail(); return }
        XCTAssertEqual(envAfter.agendaQueue.queue.count, 0, "Agenda should be empty after run() (activation was fired and removed)")
    }
}

