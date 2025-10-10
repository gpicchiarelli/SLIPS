import XCTest
@testable import SLIPS

@MainActor
final class NotUnboundVarTests: XCTestCase {
    func testNotWithUnboundVariable() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate person (slot name))")
        _ = CLIPS.eval(expr: "(deftemplate enemy (slot of) (slot name))")
        _ = CLIPS.eval(expr: "(defrule safe (person name \"Bob\") (not (enemy of \"Bob\" name ?x)) => (printout t \"SAFE\" crlf))")
        var out = ""
        guard var env = CLIPS.currentEnvironment else { XCTFail(); return }
        _ = RouterRegistry.AddRouter(&env, "cap7", 100, query: { _, name in name == "t" }, write: { _, _, s in out += s })
        _ = CLIPS.eval(expr: "(assert person name \"Bob\")")
        XCTAssertEqual(CLIPS.run(limit: nil), 1)
        XCTAssertTrue(out.contains("SAFE"))
        out = ""
        _ = CLIPS.eval(expr: "(assert enemy of \"Bob\" name \"Eve\")")
        XCTAssertEqual(CLIPS.run(limit: nil), 0)
        XCTAssertFalse(out.contains("SAFE"))
    }
}
