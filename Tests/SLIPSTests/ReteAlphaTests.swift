import XCTest
@testable import SLIPS

@MainActor
final class ReteAlphaTests: XCTestCase {
    func testAlphaIndexUpdatesOnAssertRetract() {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(deftemplate ping (slot x))")
        _ = SLIPS.eval(expr: "(defrule r (ping x 1) => (printout t \"P\"))")
        let idVal = SLIPS.eval(expr: "(assert ping x 1)")
        guard case .int(let fid) = idVal else { XCTFail(); return }
        guard let env = SLIPS.currentEnvironment else { XCTFail(); return }
        XCTAssertTrue(env.rete.alpha.ids(for: "ping").contains(Int(fid)))
        SLIPS.retract(id: Int(fid))
        guard let env2 = SLIPS.currentEnvironment else { XCTFail(); return }
        XCTAssertFalse(env2.rete.alpha.ids(for: "ping").contains(Int(fid)))
    }
}
