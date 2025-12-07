import XCTest
@testable import SLIPS

@MainActor
final class RuleNotExistsTests: XCTestCase {
    func testNotPattern() {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(deftemplate person (slot name))")
        _ = SLIPS.eval(expr: "(deftemplate friend (slot name))")
        _ = SLIPS.eval(expr: "(defrule lonely (person name \"Bob\") (not (friend name \"Bob\")) => (printout t \"LONELY\"))")
        var out = ""
        guard var env = SLIPS.currentEnvironment else { XCTFail(); return }
        _ = RouterRegistry.AddRouter(&env, "cap7", 100, query: { _, name in name == "t" }, write: { _, _, s in out += s })
        _ = SLIPS.eval(expr: "(assert person name \"Bob\")")
        let fired1 = SLIPS.run(limit: nil)
        XCTAssertEqual(fired1, 1)
        XCTAssertTrue(out.contains("LONELY"))
        out = ""
        _ = SLIPS.eval(expr: "(assert friend name \"Bob\")")
        let fired2 = SLIPS.run(limit: nil)
        XCTAssertEqual(fired2, 0)
    }
}

