import XCTest
@testable import SLIPS

@MainActor
final class RuleExistsWithBindingTests: XCTestCase {
    func testExistsRespectsBoundVariables() throws {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(deftemplate a (slot x))")
        _ = SLIPS.eval(expr: "(deftemplate b (slot x))")
        _ = SLIPS.eval(expr: "(defrule r (a x ?v) (exists (b x ?v)) => (printout t \"EX\"))")
        var out = ""
        guard var env = SLIPS.currentEnvironment else { XCTFail(); return }
        _ = RouterRegistry.AddRouter(&env, "cap-ex2", 100, query: { _, name in name == "t" }, write: { _, _, s in out += s })
        // Nessun fatto: nessuna attivazione
        XCTAssertEqual(SLIPS.run(limit: nil), 0)
        // A senza B non attiva
        SLIPS.assert(fact: "(a x 1)")
        XCTAssertEqual(SLIPS.run(limit: nil), 0)
        XCTAssertTrue(out.isEmpty)
        // B con x diverso non attiva
        SLIPS.assert(fact: "(b x 2)")
        XCTAssertEqual(SLIPS.run(limit: nil), 0)
        XCTAssertTrue(out.isEmpty)
        // B con x uguale attiva
        SLIPS.assert(fact: "(b x 1)")
        XCTAssertEqual(SLIPS.run(limit: nil), 1)
        XCTAssertTrue(out.contains("EX"))
    }
}
