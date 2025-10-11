import XCTest
@testable import SLIPS

@MainActor
final class RuleExistsUnaryTests: XCTestCase {
    func testExistsUnaryDoesNotBind() throws {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate b)")
        _ = CLIPS.eval(expr: "(defrule r (exists (b)) => (printout t \"E\"))")
        // Sanity: la regola deve avere 1 CE exists
        if let env0 = CLIPS.currentEnvironment, let r = env0.rules.first(where: { $0.name == "r" }) {
            XCTAssertEqual(r.patterns.count, 1)
            XCTAssertTrue(r.patterns[0].exists)
            XCTAssertEqual(r.patterns[0].name, "b")
        }
        var out = ""
        guard var env = CLIPS.currentEnvironment else { XCTFail(); return }
        _ = RouterRegistry.AddRouter(&env, "cap-ex", 100, query: { _, name in name == "t" }, write: { _, _, s in out += s })
        let fired0 = CLIPS.run(limit: nil)
        XCTAssertEqual(fired0, 0)
        XCTAssertTrue(out.isEmpty)
        out = ""
        CLIPS.assert(fact: "(b)")
        if let env1 = CLIPS.currentEnvironment {
            XCTAssertFalse(env1.agendaQueue.isEmpty)
        }
        let fired1 = CLIPS.run(limit: nil)
        XCTAssertEqual(fired1, 1)
        XCTAssertTrue(out.contains("E"))
    }
}
