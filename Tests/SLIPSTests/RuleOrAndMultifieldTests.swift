import XCTest
@testable import SLIPS

@MainActor
final class RuleOrAndMultifieldTests: XCTestCase {
    func testOrCEExpandsAndFires() {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(set-join-check on)")
        _ = SLIPS.eval(expr: "(deftemplate A (slot v))")
        _ = SLIPS.eval(expr: "(deftemplate B (slot v))")
        _ = SLIPS.eval(expr: "(deftemplate C (slot v))")
        _ = SLIPS.eval(expr: "(defrule r (or (A v ?x) (B v ?x)) (C v ?x) => (printout t \"O\"))")
        var out = ""
        guard var env = SLIPS.currentEnvironment else { XCTFail(); return }
        _ = RouterRegistry.AddRouter(&env, "cap-or", 100, query: { _, name in name == "t" }, write: { _, _, s in out += s })
        _ = SLIPS.eval(expr: "(assert A v 1)")
        _ = SLIPS.eval(expr: "(assert C v 1)")
        XCTAssertEqual(SLIPS.run(limit: nil), 1)
        _ = SLIPS.eval(expr: "(assert B v 2)")
        _ = SLIPS.eval(expr: "(assert C v 2)")
        XCTAssertEqual(SLIPS.run(limit: nil), 1)
        XCTAssertTrue(out.contains("O"))
    }

    func testMultifieldVariableBindsEntireMultislot() {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(set-join-check on)")
        _ = SLIPS.eval(expr: "(deftemplate person (multislot tags))")
        _ = SLIPS.eval(expr: "(defrule r (person tags $?x) => (printout t \"M\"))")
        _ = SLIPS.eval(expr: "(assert person tags (create$ a b c))")
        XCTAssertEqual(SLIPS.run(limit: nil), 1)
        // Verifica che i token terminali contengano il binding multifield
        guard let env = SLIPS.currentEnvironment else { XCTFail(); return }
        if let toks = env.rete.beta["r"]?.tokens {
            XCTAssertFalse(toks.isEmpty)
            let b = toks[0].bindings["x"]
            if case .multifield(let arr)? = b { XCTAssertEqual(arr.count, 3) } else { XCTFail("binding multifield assente") }
        } else {
            XCTFail("nessun token rete per r")
        }
    }
}
