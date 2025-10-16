import XCTest
@testable import SLIPS

@MainActor
final class RuleOrAndMultifieldTests: XCTestCase {
    func testOrCEExpandsAndFires() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(set-join-check on)")
        _ = CLIPS.eval(expr: "(deftemplate A (slot v))")
        _ = CLIPS.eval(expr: "(deftemplate B (slot v))")
        _ = CLIPS.eval(expr: "(deftemplate C (slot v))")
        _ = CLIPS.eval(expr: "(defrule r (or (A v ?x) (B v ?x)) (C v ?x) => (printout t \"O\"))")
        var out = ""
        guard var env = CLIPS.currentEnvironment else { XCTFail(); return }
        _ = RouterRegistry.AddRouter(&env, "cap-or", 100, query: { _, name in name == "t" }, write: { _, _, s in out += s })
        _ = CLIPS.eval(expr: "(assert A v 1)")
        _ = CLIPS.eval(expr: "(assert C v 1)")
        XCTAssertEqual(CLIPS.run(limit: nil), 1)
        _ = CLIPS.eval(expr: "(assert B v 2)")
        _ = CLIPS.eval(expr: "(assert C v 2)")
        XCTAssertEqual(CLIPS.run(limit: nil), 1)
        XCTAssertTrue(out.contains("O"))
    }

    func testMultifieldVariableBindsEntireMultislot() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(set-join-check on)")
        _ = CLIPS.eval(expr: "(deftemplate person (multislot tags))")
        _ = CLIPS.eval(expr: "(defrule r (person tags $?x) => (printout t \"M\"))")
        _ = CLIPS.eval(expr: "(assert person tags (create$ a b c))")
        XCTAssertEqual(CLIPS.run(limit: nil), 1)
        // Verifica che i token terminali contengano il binding multifield
        guard let env = CLIPS.currentEnvironment else { XCTFail(); return }
        if let toks = env.rete.beta["r"]?.tokens {
            XCTAssertFalse(toks.isEmpty)
            let b = toks[0].bindings["x"]
            if case .multifield(let arr)? = b { XCTAssertEqual(arr.count, 3) } else { XCTFail("binding multifield assente") }
        } else {
            XCTFail("nessun token rete per r")
        }
    }
}
