import XCTest
@testable import SLIPS

@MainActor
final class RuleExistsUnaryTests: XCTestCase {
    func testExistsUnaryDoesNotBind() throws {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(deftemplate b)")
        _ = SLIPS.eval(expr: "(defrule r (exists (b)) => (printout t \"E\"))")
        // Sanity: la regola deve avere 1 CE exists
        if let env0 = SLIPS.currentEnvironment, let r = env0.rules.first(where: { $0.name == "r" }) {
            XCTAssertEqual(r.patterns.count, 1)
            XCTAssertTrue(r.patterns[0].exists)
            XCTAssertEqual(r.patterns[0].name, "b")
        }
        var out = ""
        guard var env = SLIPS.currentEnvironment else { XCTFail(); return }
        _ = RouterRegistry.AddRouter(&env, "cap-ex", 100, query: { _, name in name == "t" }, write: { _, _, s in out += s })
        let fired0 = SLIPS.run(limit: nil)
        XCTAssertEqual(fired0, 0)
        XCTAssertTrue(out.isEmpty)
        out = ""
        SLIPS.assert(fact: "(b)")
        if let env1 = SLIPS.currentEnvironment {
            XCTAssertFalse(env1.agendaQueue.isEmpty)
        }
        let fired1 = SLIPS.run(limit: nil)
        XCTAssertEqual(fired1, 1)
        XCTAssertTrue(out.contains("E"))
    }
}
