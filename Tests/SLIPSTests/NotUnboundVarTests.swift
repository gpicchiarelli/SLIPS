import XCTest
@testable import SLIPS

@MainActor
final class NotUnboundVarTests: XCTestCase {
    func testNotWithUnboundVariable() {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(deftemplate person (slot name))")
        _ = SLIPS.eval(expr: "(deftemplate enemy (slot of) (slot name))")
        _ = SLIPS.eval(expr: "(defrule safe (person name \"Bob\") (not (enemy of \"Bob\" name ?x)) => (printout t \"SAFE\" crlf))")
        var out = ""
        guard var env = SLIPS.currentEnvironment else { XCTFail(); return }
        _ = RouterRegistry.AddRouter(&env, "cap7", 100, query: { _, name in name == "t" }, write: { _, _, s in out += s })
        _ = SLIPS.eval(expr: "(assert person name \"Bob\")")
        XCTAssertEqual(SLIPS.run(limit: nil), 1)
        XCTAssertTrue(out.contains("SAFE"))
        out = ""
        _ = SLIPS.eval(expr: "(assert enemy of \"Bob\" name \"Eve\")")
        XCTAssertEqual(SLIPS.run(limit: nil), 0)
        XCTAssertFalse(out.contains("SAFE"))
    }
}
