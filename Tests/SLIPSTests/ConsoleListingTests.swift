import XCTest
@testable import SLIPS

@MainActor
final class ConsoleListingTests: XCTestCase {
    func testAgendaListsActivations() {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(deftemplate e (slot id))")
        _ = SLIPS.eval(expr: "(defrule r (e id ?x) => (printout t \"Z\"))")
        _ = SLIPS.eval(expr: "(assert e id 1)")
        var out = ""
        guard var env = SLIPS.currentEnvironment else { XCTFail(); return }
        _ = RouterRegistry.AddRouter(&env, "cap-agenda", 100, query: { _, name in name == "stdout" }, write: { _, _, s in out += s })
        _ = SLIPS.eval(expr: "(agenda)")
        XCTAssertTrue(out.contains("AGENDA:"))
        XCTAssertTrue(out.contains("r"))
    }

    func testRulesFilterByName() {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(deftemplate a (slot v))")
        _ = SLIPS.eval(expr: "(defrule r1 (a v 1) => (printout t \"R1\"))")
        _ = SLIPS.eval(expr: "(defrule r2 (a v 2) => (printout t \"R2\"))")
        var out = ""
        guard var env = SLIPS.currentEnvironment else { XCTFail(); return }
        _ = RouterRegistry.AddRouter(&env, "cap-rules", 100, query: { _, name in name == "stdout" }, write: { _, _, s in out += s })
        out = ""
        _ = SLIPS.eval(expr: "(rules r1)")
        XCTAssertTrue(out.contains("r1"))
        XCTAssertFalse(out.contains("r2"))
    }

    func testFactsFilterByTemplate() {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(deftemplate A (slot v))")
        _ = SLIPS.eval(expr: "(deftemplate B (slot v))")
        _ = SLIPS.eval(expr: "(assert A v 1)")
        _ = SLIPS.eval(expr: "(assert B v 2)")
        var out = ""
        guard var env = SLIPS.currentEnvironment else { XCTFail(); return }
        _ = RouterRegistry.AddRouter(&env, "cap-facts", 100, query: { _, name in name == "stdout" }, write: { _, _, s in out += s })
        out = ""
        _ = SLIPS.eval(expr: "(facts A)")
        XCTAssertTrue(out.contains("(A"))
        XCTAssertFalse(out.contains("(B"))
    }
}

