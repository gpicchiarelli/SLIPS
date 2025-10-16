import XCTest
@testable import SLIPS

@MainActor
final class JoinWhitelistStableTests: XCTestCase {
    func testStableDetectionAndWhitelistActivation() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(set-join-check on)")
        _ = CLIPS.eval(expr: "(deftemplate A (slot v))")
        _ = CLIPS.eval(expr: "(deftemplate B (slot v))")
        _ = CLIPS.eval(expr: "(defrule r (A v ?x) (B v ?x) => (printout t \"R\"))")
        _ = CLIPS.eval(expr: "(assert A v 1)")
        _ = CLIPS.eval(expr: "(assert B v 1)")
        _ = CLIPS.eval(expr: "(assert A v 2)")
        _ = CLIPS.eval(expr: "(assert B v 2)")
        // Trigger evaluation to mark stable
        XCTAssertEqual(CLIPS.run(limit: nil), 2)
        // Check stability via builtin
        let stable = CLIPS.eval(expr: "(get-join-stable r)")
        if case .boolean(let b) = stable { XCTAssertTrue(b) } else { XCTFail("Expected boolean") }
        // Whitelist and ensure activations still happen
        _ = CLIPS.eval(expr: "(add-join-activate-rule r)")
        _ = CLIPS.eval(expr: "(assert A v 3)")
        _ = CLIPS.eval(expr: "(assert B v 3)")
        XCTAssertEqual(CLIPS.run(limit: nil), 1)
    }
}

