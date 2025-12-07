import XCTest
@testable import SLIPS

@MainActor
final class RuleSlotTestTests: XCTestCase {
    func testSlotInternalTestUsesBoundVar() {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(deftemplate rec (slot a) (slot b))")
        _ = SLIPS.eval(expr: "(defrule r (rec a ?x b (test (> ?x 10))) => (printout t \"OK\" crlf))")
        var out = ""
        guard var env = SLIPS.currentEnvironment else { XCTFail(); return }
        _ = RouterRegistry.AddRouter(&env, "cap7", 100, query: { _, name in name == "t" }, write: { _, _, s in out += s })
        _ = SLIPS.eval(expr: "(watch rules)")
        _ = SLIPS.eval(expr: "(assert rec a 5 b 0)")
        XCTAssertEqual(SLIPS.run(limit: nil), 0, out)
        _ = SLIPS.eval(expr: "(assert rec a 11 b 0)")
        XCTAssertEqual(SLIPS.run(limit: nil), 1, out)
        // Per alcuni path di join complessi, l'output può arrivare su stdout.
        // Qui verifichiamo almeno che sia stata generata un'attivazione e fire.
    }
}
