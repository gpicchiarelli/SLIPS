import XCTest
@testable import SLIPS

@MainActor
final class RuleExistsWithBindingTests: XCTestCase {
    func testExistsRespectsBoundVariables() throws {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate a (slot x))")
        _ = CLIPS.eval(expr: "(deftemplate b (slot x))")
        _ = CLIPS.eval(expr: "(defrule r (a x ?v) (exists (b x ?v)) => (printout t \"EX\"))")
        var out = ""
        guard var env = CLIPS.currentEnvironment else { XCTFail(); return }
        _ = RouterRegistry.AddRouter(&env, "cap-ex2", 100, query: { _, name in name == "t" }, write: { _, _, s in out += s })
        // Nessun fatto: nessuna attivazione
        XCTAssertEqual(CLIPS.run(limit: nil), 0)
        // A senza B non attiva
        CLIPS.assert(fact: "(a x 1)")
        XCTAssertEqual(CLIPS.run(limit: nil), 0)
        XCTAssertTrue(out.isEmpty)
        // B con x diverso non attiva
        CLIPS.assert(fact: "(b x 2)")
        XCTAssertEqual(CLIPS.run(limit: nil), 0)
        XCTAssertTrue(out.isEmpty)
        // B con x uguale attiva
        CLIPS.assert(fact: "(b x 1)")
        XCTAssertEqual(CLIPS.run(limit: nil), 1)
        XCTAssertTrue(out.contains("EX"))
    }
}
