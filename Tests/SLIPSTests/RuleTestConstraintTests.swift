import XCTest
@testable import SLIPS

@MainActor
final class RuleTestConstraintTests: XCTestCase {
    func testTestConstraintFilters() {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(deftemplate ping (slot x))")
        _ = SLIPS.eval(expr: "(defrule gt10 (ping x 11) => (printout t \"GT\" crlf))")
        _ = SLIPS.eval(expr: "(assert ping x 11)")
        let fired = SLIPS.run(limit: nil)
        XCTAssertEqual(fired, 1)
    }
}
