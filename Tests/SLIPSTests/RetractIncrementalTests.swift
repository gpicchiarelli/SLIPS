import XCTest
@testable import SLIPS

@MainActor
final class RetractIncrementalTests: XCTestCase {
    func testRetractRemovesActivationsIncrementally() {
        _ = SLIPS.createEnvironment()
        guard var env = SLIPS.currentEnvironment else { XCTFail(); return }
        env.watchRete = true  // DEBUG: Abilita debug output
        // Aggiorna currentEnv usando eval che aggiorna automaticamente
        // Per ora, basta che watchRete sia abilitato quando facciamo retract
        
        _ = SLIPS.eval(expr: "(deftemplate A (slot x))")
        _ = SLIPS.eval(expr: "(deftemplate B (slot y))")
        
        _ = SLIPS.eval(expr: "(defrule join (A) (B) => (printout t \"GO\" crlf))")
        let aId = SLIPS.eval(expr: "(assert A x 1)")
        _ = SLIPS.eval(expr: "(assert B y 2)")
        // 1 attivazione in agenda
        var id: Int64 = -1
        if case .int(let i) = aId { id = i } else { XCTFail(); return }
        // Retract A: deve rimuovere l'attivazione senza rebuild
        SLIPS.retract(id: Int(id))
        // Nessuna attivazione deve fire
        XCTAssertEqual(SLIPS.run(limit: nil), 0)
    }
}
