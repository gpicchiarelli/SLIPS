import XCTest
@testable import SLIPS

@MainActor
final class ReteJoinActivateTests: XCTestCase {
    func testJoinActivateFires() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(set-join-check on)")
        _ = CLIPS.eval(expr: "(set-join-activate on)")
        _ = CLIPS.eval(expr: "(watch rete)")
        _ = CLIPS.eval(expr: "(deftemplate A (slot v))")
        _ = CLIPS.eval(expr: "(deftemplate B (slot v))")
        _ = CLIPS.eval(expr: "(deftemplate C (slot v))")
        _ = CLIPS.eval(expr: "(defrule r (A v ?x) (B v ?x) (C v ?x) => (printout t \"J\" crlf))")
        var out = ""
        guard var env = CLIPS.currentEnvironment else { XCTFail(); return }
        _ = RouterRegistry.AddRouter(&env, "cap-join", 100, query: { _, name in name == "t" }, write: { _, _, s in out += s })
        _ = CLIPS.eval(expr: "(assert A v 1)")
        _ = CLIPS.eval(expr: "(assert B v 1)")
        _ = CLIPS.eval(expr: "(assert C v 1)")
        XCTAssertEqual(CLIPS.run(limit: nil), 1)
        XCTAssertTrue(out.contains("J"))
    }
}
