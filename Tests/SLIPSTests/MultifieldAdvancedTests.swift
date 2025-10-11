import XCTest
@testable import SLIPS

@MainActor
final class MultifieldAdvancedTests: XCTestCase {
    func testSegmentedMultislotBindsMultipleMfVars() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate person (multislot tags))")
        _ = CLIPS.eval(expr: "(defrule r (person tags a $?x b $?y c) => (printout t \"S\"))")
        // a 1 2 b 3 4 c should match with x=(1 2), y=(3 4)
        _ = CLIPS.eval(expr: "(assert person tags (create$ a 1 2 b 3 4 c))")
        XCTAssertEqual(CLIPS.run(limit: nil), 1)
        guard let env = CLIPS.currentEnvironment else { XCTFail(); return }
        let toks = env.rete.beta["r"]?.tokens ?? []
        XCTAssertEqual(toks.count, 1)
        if let bx = toks.first?.bindings["x"], case .multifield(let ax) = bx { XCTAssertEqual(ax, [.int(1), .int(2)]) } else { XCTFail("x binding not multifield") }
        if let by = toks.first?.bindings["y"], case .multifield(let ay) = by { XCTAssertEqual(ay, [.int(3), .int(4)]) } else { XCTFail("y binding not multifield") }
    }

    func testCrossSlotVariableSharingWithSequence() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate person (slot name) (multislot tags))")
        _ = CLIPS.eval(expr: "(defrule r (person name ?n tags a ?n $?rest) => (printout t \"C\"))")
        _ = CLIPS.eval(expr: "(assert person name Luca tags (create$ a Luca b))")
        XCTAssertEqual(CLIPS.run(limit: nil), 1)
    }

    func testNotWithSequence() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate person (multislot tags))")
        _ = CLIPS.eval(expr: "(defrule r (not (person tags a $?x b)) => (printout t \"N\"))")
        // First assert: no 'b' after a => rule fires
        _ = CLIPS.eval(expr: "(assert person tags (create$ a 1 2 c))")
        XCTAssertEqual(CLIPS.run(limit: nil), 1)
        // Second assert introduces 'b' after 'a' -> rule should not add another activation
        _ = CLIPS.eval(expr: "(assert person tags (create$ a 9 b))")
        XCTAssertEqual(CLIPS.run(limit: nil), 0)
    }

    func testExistsWithSequence() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate person (multislot tags))")
        _ = CLIPS.eval(expr: "(defrule r (exists (person tags a $?x)) => (printout t \"E\"))")
        _ = CLIPS.eval(expr: "(assert person tags (create$ z y x))")
        XCTAssertEqual(CLIPS.run(limit: nil), 0)
        _ = CLIPS.eval(expr: "(assert person tags (create$ a 1 2))")
        XCTAssertEqual(CLIPS.run(limit: nil), 1)
    }

    func testRetractRemovesTokensForSequenceRule() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(set-join-check on)")
        _ = CLIPS.eval(expr: "(set-join-activate on)")
        _ = CLIPS.eval(expr: "(deftemplate person (multislot tags))")
        _ = CLIPS.eval(expr: "(defrule r (person tags a $?x b $?y) => (printout t \"R\"))")
        let idv = CLIPS.eval(expr: "(assert person tags (create$ a 1 b 2 3))")
        guard case .int(let fid) = idv else { XCTFail(); return }
        XCTAssertEqual(CLIPS.run(limit: nil), 1)
        guard let env1 = CLIPS.currentEnvironment else { XCTFail(); return }
        let before = env1.rete.beta["r"]?.tokens.count ?? 0
        XCTAssertEqual(before, 1)
        CLIPS.retract(id: Int(fid))
        guard let env2 = CLIPS.currentEnvironment else { XCTFail(); return }
        let after = env2.rete.beta["r"]?.tokens.count ?? 0
        XCTAssertEqual(after, 0)
    }
}
