import XCTest
@testable import SLIPS

@MainActor
final class RuleEngineTests: XCTestCase {
    func testSimpleRuleFire() {
        var env = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate person (slot name) (slot age))")
        _ = CLIPS.eval(expr: "(defrule hello (person name \"Bob\" age 42) => (printout t \"HI\" crlf))")
        var captured = ""
        _ = RouterRegistry.AddRouter(&env, "cap3", 100, query: { _, name in name == "t" }, write: { _, _, msg in captured += msg })
        _ = CLIPS.eval(expr: "(assert person name \"Bob\" age 42)")
        let fired = CLIPS.run(limit: nil)
        XCTAssertEqual(fired, 1)
        XCTAssertTrue(captured.contains("HI"))
    }
}
