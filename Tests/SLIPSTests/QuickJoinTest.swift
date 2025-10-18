import XCTest
@testable import SLIPS

@MainActor
final class QuickJoinTest: XCTestCase {
    func testSimpleTwoPatternJoinWorks() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate A (slot x))")
        _ = CLIPS.eval(expr: "(deftemplate B (slot y))")
        _ = CLIPS.eval(expr: "(defrule join (A) (B) => (printout t \"JOINED\" crlf))")
        
        print("=== Asserting A ===")
        _ = CLIPS.eval(expr: "(assert A x 1)")
        
        print("=== Asserting B ===")
        _ = CLIPS.eval(expr: "(assert B y 2)")
        
        guard let env = CLIPS.currentEnvironment else { XCTFail(); return }
        print("\n=== Agenda ===")
        print("Activations: \(env.agendaQueue.queue.count)")
        for (i, act) in env.agendaQueue.queue.enumerated() {
            print("  [\(i)] factIDs: \(act.factIDs)")
        }
        
        print("\n=== Run ===")
        let fired = CLIPS.run(limit: nil)
        print("Fired: \(fired)")
        
        XCTAssertEqual(env.agendaQueue.queue.count, 1, "Should have 1 activation")
        XCTAssertEqual(fired, 1, "Should fire 1 rule")
        
        if let act = env.agendaQueue.queue.first {
            XCTAssertTrue(act.factIDs.contains(1), "Should include fact 1 (A)")
            XCTAssertTrue(act.factIDs.contains(2), "Should include fact 2 (B)")
        }
    }
}

