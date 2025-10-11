import XCTest
@testable import SLIPS

@MainActor
final class RuleExistsRetractTests: XCTestCase {
    func testRetractRemovesExistsActivation() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate b)")
        _ = CLIPS.eval(expr: "(defrule r (exists (b)) => (printout t \"E\"))")
        // Asserisci un fatto e verifica che venga programmata l'attivazione
        let idVal = CLIPS.eval(expr: "(assert b)")
        let id: Int
        if case .int(let i) = idVal { id = Int(i) } else { XCTFail(); return }
        // L'attivazione deve essere presente prima del run
        guard let env0 = CLIPS.currentEnvironment else { XCTFail(); return }
        XCTAssertFalse(env0.agendaQueue.isEmpty)
        // Retract del fatto deve rimuovere l'attivazione
        CLIPS.retract(id: id)
        guard let env1 = CLIPS.currentEnvironment else { XCTFail(); return }
        XCTAssertTrue(env1.agendaQueue.isEmpty)
        // E nessuna regola deve fire
        XCTAssertEqual(CLIPS.run(limit: nil), 0)
    }
}

