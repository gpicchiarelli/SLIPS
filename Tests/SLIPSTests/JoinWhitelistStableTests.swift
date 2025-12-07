import XCTest
@testable import SLIPS

@MainActor
final class JoinWhitelistStableTests: XCTestCase {
    func testStableDetectionAndWhitelistActivation() {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(set-join-check on)")
        _ = SLIPS.eval(expr: "(deftemplate A (slot v))")
        _ = SLIPS.eval(expr: "(deftemplate B (slot v))")
        _ = SLIPS.eval(expr: "(defrule r (A v ?x) (B v ?x) => (printout t \"R\"))")
        _ = SLIPS.eval(expr: "(assert A v 1)")
        _ = SLIPS.eval(expr: "(assert B v 1)")
        _ = SLIPS.eval(expr: "(assert A v 2)")
        _ = SLIPS.eval(expr: "(assert B v 2)")
        // Trigger evaluation to mark stable
        XCTAssertEqual(SLIPS.run(limit: nil), 2)
        // Check stability via builtin
        let stable = SLIPS.eval(expr: "(get-join-stable r)")
        if case .boolean(let b) = stable { XCTAssertTrue(b) } else { XCTFail("Expected boolean") }
        // Whitelist and ensure activations still happen
        _ = SLIPS.eval(expr: "(add-join-activate-rule r)")
        _ = SLIPS.eval(expr: "(assert A v 3)")
        _ = SLIPS.eval(expr: "(assert B v 3)")
        XCTAssertEqual(SLIPS.run(limit: nil), 1)
    }
}

