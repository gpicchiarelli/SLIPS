import XCTest
@testable import SLIPS

@MainActor
final class RuleTestConstraintTests: XCTestCase {
    func testTestConstraintFilters() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate ping (slot x))")
        _ = CLIPS.eval(expr: "(defrule gt10 (ping x 11) => (printout t \"GT\" crlf))")
        _ = CLIPS.eval(expr: "(assert ping x 11)")
        let fired = CLIPS.run(limit: nil)
        XCTAssertEqual(fired, 1)
    }
}
