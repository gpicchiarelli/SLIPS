import XCTest
@testable import SLIPS

@MainActor
final class RuleJoinTests: XCTestCase {
    func testTwoPatternJoin() {
        var env = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate person (slot name) (slot age))")
        _ = CLIPS.eval(expr: "(deftemplate friend (slot name))")
        _ = CLIPS.eval(expr: "(defrule greet (person name \"Bob\" age 42) (friend name \"Bob\") => (printout t \"GREET\" crlf))")
        var msg = ""
        _ = RouterRegistry.AddRouter(&env, "cap4", 100, query: { _, name in name == "t" }, write: { _, _, s in msg += s })
        _ = CLIPS.eval(expr: "(assert person name \"Bob\" age 42)")
        _ = CLIPS.eval(expr: "(assert friend name \"Bob\")")
        let fired = CLIPS.run(limit: nil)
        XCTAssertEqual(fired, 1)
        XCTAssertTrue(msg.contains("GREET"))
    }

    func testSalienceOrdering() {
        var env2 = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate ping (slot x))")
        _ = CLIPS.eval(expr: "(defrule r1 (declare (salience 10)) (ping x 1) => (printout t \"A\"))")
        _ = CLIPS.eval(expr: "(defrule r2 (declare (salience 20)) (ping x 1) => (printout t \"B\"))")
        var out = ""
        _ = RouterRegistry.AddRouter(&env2, "cap5", 100, query: { _, name in name == "t" }, write: { _, _, s in out += s })
        _ = CLIPS.eval(expr: "(assert ping x 1)")
        _ = CLIPS.run(limit: nil)
        // Expect B fired before A due to higher salience
        XCTAssertTrue(out.contains("BA") || out == "B" || out.hasPrefix("B"))
    }
}
