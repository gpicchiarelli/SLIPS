import XCTest
@testable import SLIPS

@MainActor
final class MultifieldAdvancedTests: XCTestCase {
    func testSegmentedMultislotBindsMultipleMfVars() {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(deftemplate person (multislot tags))")
        _ = SLIPS.eval(expr: "(defrule r (person tags a $?x b $?y c) => (printout t \"S\"))")
        // a 1 2 b 3 4 c should match with x=(1 2), y=(3 4)
        _ = SLIPS.eval(expr: "(assert person tags (create$ a 1 2 b 3 4 c))")
        XCTAssertEqual(SLIPS.run(limit: nil), 1)
        guard let env = SLIPS.currentEnvironment else { XCTFail(); return }
        let toks = env.rete.beta["r"]?.tokens ?? []
        XCTAssertEqual(toks.count, 1)
        if let bx = toks.first?.bindings["x"], case .multifield(let ax) = bx { XCTAssertEqual(ax, [.int(1), .int(2)]) } else { XCTFail("x binding not multifield") }
        if let by = toks.first?.bindings["y"], case .multifield(let ay) = by { XCTAssertEqual(ay, [.int(3), .int(4)]) } else { XCTFail("y binding not multifield") }
    }

    func testCrossSlotVariableSharingWithSequence() {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(deftemplate person (slot name) (multislot tags))")
        _ = SLIPS.eval(expr: "(defrule r (person name ?n tags a ?n $?rest) => (printout t \"C\"))")
        _ = SLIPS.eval(expr: "(assert person name Luca tags (create$ a Luca b))")
        XCTAssertEqual(SLIPS.run(limit: nil), 1)
    }

    func testNotWithSequence() {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(deftemplate person (multislot tags))")
        _ = SLIPS.eval(expr: "(defrule r (not (person tags a $?x b)) => (printout t \"N\"))")
        // First assert: no 'b' after a => rule fires
        _ = SLIPS.eval(expr: "(assert person tags (create$ a 1 2 c))")
        XCTAssertEqual(SLIPS.run(limit: nil), 1)
        // Second assert introduces 'b' after 'a' -> rule should not add another activation
        _ = SLIPS.eval(expr: "(assert person tags (create$ a 9 b))")
        XCTAssertEqual(SLIPS.run(limit: nil), 0)
    }

    func testExistsWithSequence() {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(deftemplate person (multislot tags))")
        _ = SLIPS.eval(expr: "(defrule r (exists (person tags a $?x)) => (printout t \"E\"))")
        _ = SLIPS.eval(expr: "(assert person tags (create$ z y x))")
        XCTAssertEqual(SLIPS.run(limit: nil), 0)
        _ = SLIPS.eval(expr: "(assert person tags (create$ a 1 2))")
        XCTAssertEqual(SLIPS.run(limit: nil), 1)
    }

    func testRetractRemovesTokensForSequenceRule() {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(set-join-check on)")
        _ = SLIPS.eval(expr: "(set-join-activate on)")
        _ = SLIPS.eval(expr: "(deftemplate person (multislot tags))")
        _ = SLIPS.eval(expr: "(defrule r (person tags a $?x b $?y) => (printout t \"R\"))")
        let idv = SLIPS.eval(expr: "(assert person tags (create$ a 1 b 2 3))")
        guard case .int(let fid) = idv else { XCTFail(); return }
        XCTAssertEqual(SLIPS.run(limit: nil), 1)
        guard let env1 = SLIPS.currentEnvironment else { XCTFail(); return }
        let before = env1.rete.beta["r"]?.tokens.count ?? 0
        XCTAssertEqual(before, 1)
        SLIPS.retract(id: Int(fid))
        guard let env2 = SLIPS.currentEnvironment else { XCTFail(); return }
        let after = env2.rete.beta["r"]?.tokens.count ?? 0
        XCTAssertEqual(after, 0)
    }
}
