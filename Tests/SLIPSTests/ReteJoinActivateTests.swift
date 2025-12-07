import XCTest
@testable import SLIPS

@MainActor
final class ReteJoinActivateTests: XCTestCase {
    func testJoinActivateFires() {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(set-join-check on)")
        _ = SLIPS.eval(expr: "(set-join-activate on)")
        _ = SLIPS.eval(expr: "(watch rete)")
        _ = SLIPS.eval(expr: "(deftemplate A (slot v))")
        _ = SLIPS.eval(expr: "(deftemplate B (slot v))")
        _ = SLIPS.eval(expr: "(deftemplate C (slot v))")
        _ = SLIPS.eval(expr: "(defrule r (A v ?x) (B v ?x) (C v ?x) => (printout t \"J\" crlf))")
        var out = ""
        guard var env = SLIPS.currentEnvironment else { XCTFail(); return }
        _ = RouterRegistry.AddRouter(&env, "cap-join", 100, query: { _, name in name == "t" }, write: { _, _, s in out += s })
        _ = SLIPS.eval(expr: "(assert A v 1)")
        _ = SLIPS.eval(expr: "(assert B v 1)")
        _ = SLIPS.eval(expr: "(assert C v 1)")
        XCTAssertEqual(SLIPS.run(limit: nil), 1)
        XCTAssertTrue(out.contains("J"))
    }
}
