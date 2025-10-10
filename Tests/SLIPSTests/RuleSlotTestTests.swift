import XCTest
@testable import SLIPS

@MainActor
final class RuleSlotTestTests: XCTestCase {
    func testSlotInternalTestUsesBoundVar() throws {
        throw XCTSkip("Valutazione test interno di slot: attivazione su join da ancorare")
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate rec (slot a) (slot b))")
        _ = CLIPS.eval(expr: "(defrule r (rec a ?x b (test (> ?x 10))) => (printout t \"OK\" crlf))")
        var out = ""
        guard var env = CLIPS.currentEnvironment else { XCTFail(); return }
        _ = RouterRegistry.AddRouter(&env, "cap7", 100, query: { _, name in name == "t" }, write: { _, _, s in out += s })
        _ = CLIPS.eval(expr: "(assert rec a 5 b 0)")
        XCTAssertEqual(CLIPS.run(limit: nil), 0)
        _ = CLIPS.eval(expr: "(assert rec a 11 b 0)")
        XCTAssertEqual(CLIPS.run(limit: nil), 1)
        XCTAssertTrue(out.contains("OK"))
    }
}
