import XCTest
@testable import SLIPS

@MainActor
final class RuleNotTestCombinedTests: XCTestCase {
    func testNotWithTestFiltersAsExpected() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate A (slot v))")
        _ = CLIPS.eval(expr: "(deftemplate B (slot v))")
        // Fire only when there is A and no B with same v, and v > 1
        _ = CLIPS.eval(expr: "(defrule r (A v ?x) (not (B v ?x)) (test (> ?x 1)) => (printout t \"OK\"))")
        var out = ""
        guard var env = CLIPS.currentEnvironment else { XCTFail(); return }
        _ = RouterRegistry.AddRouter(&env, "cap-not", 100, query: { _, name in name == "t" }, write: { _, _, s in out += s })
        // A=1 and B=1 -> blocked by not
        _ = CLIPS.eval(expr: "(assert A v 1)")
        _ = CLIPS.eval(expr: "(assert B v 1)")
        // A=2 and no B=2 -> eligible, v>1 passes (test ...)
        _ = CLIPS.eval(expr: "(assert A v 2)")
        XCTAssertEqual(CLIPS.run(limit: nil), 1, out)
        XCTAssertTrue(out.contains("OK"))
    }
}

