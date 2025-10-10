import XCTest
@testable import SLIPS

@MainActor
final class RetractIncrementalTests: XCTestCase {
    func testRetractRemovesActivationsIncrementally() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate A (slot x))")
        _ = CLIPS.eval(expr: "(deftemplate B (slot y))")
        _ = CLIPS.eval(expr: "(defrule join (A) (B) => (printout t \"GO\" crlf))")
        let aId = CLIPS.eval(expr: "(assert A x 1)")
        _ = CLIPS.eval(expr: "(assert B y 2)")
        // 1 attivazione in agenda
        var id: Int64 = -1
        if case .int(let i) = aId { id = i } else { XCTFail(); return }
        // Retract A: deve rimuovere l'attivazione senza rebuild
        _ = CLIPS.retract(id: Int(id))
        // Nessuna attivazione deve fire
        XCTAssertEqual(CLIPS.run(limit: nil), 0)
    }
}

