import XCTest
@testable import SLIPS

@MainActor
final class RuleNotExistsTests: XCTestCase {
    func testNotPattern() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate person (slot name))")
        _ = CLIPS.eval(expr: "(deftemplate friend (slot name))")
        _ = CLIPS.eval(expr: "(defrule lonely (person name \"Bob\") (not (friend name \"Bob\")) => (printout t \"LONELY\"))")
        var out = ""
        guard var env = CLIPS.currentEnvironment else { XCTFail(); return }
        _ = RouterRegistry.AddRouter(&env, "cap7", 100, query: { _, name in name == "t" }, write: { _, _, s in out += s })
        _ = CLIPS.eval(expr: "(assert person name \"Bob\")")
        let fired1 = CLIPS.run(limit: nil)
        XCTAssertEqual(fired1, 1)
        XCTAssertTrue(out.contains("LONELY"))
        out = ""
        _ = CLIPS.eval(expr: "(assert friend name \"Bob\")")
        let fired2 = CLIPS.run(limit: nil)
        XCTAssertEqual(fired2, 0)
    }
}

