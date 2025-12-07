import XCTest
@testable import SLIPS

@MainActor
final class RulesPrettyPrintTests: XCTestCase {
    func testRulesAndPpDefRuleWithSequences() {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(deftemplate person (slot name) (multislot tags))")
        _ = SLIPS.eval(expr: "(defrule r (or (person name ?n tags a $?x b) (person name ?n tags c $?y d)) => (printout t \"X\"))")
        var out = ""
        guard var env = SLIPS.currentEnvironment else { XCTFail(); return }
        _ = RouterRegistry.AddRouter(&env, "cap-rules", 100, query: { _, name in name == "t" || name == "stdout" }, write: { _, _, s in out += s })
        _ = SLIPS.eval(expr: "(rules)")
        XCTAssertTrue(out.contains("r"))
        out = ""
        _ = SLIPS.eval(expr: "(ppdefrule r)")
        XCTAssertTrue(out.contains("(person name ?n tags a $?x b)"))
        XCTAssertTrue(out.contains("(person name ?n tags c $?y d)"))
    }
}
