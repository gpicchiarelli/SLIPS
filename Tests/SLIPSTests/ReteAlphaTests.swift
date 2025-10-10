import XCTest
@testable import SLIPS

@MainActor
final class ReteAlphaTests: XCTestCase {
    func testAlphaIndexUpdatesOnAssertRetract() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate ping (slot x))")
        _ = CLIPS.eval(expr: "(defrule r (ping x 1) => (printout t \"P\"))")
        let idVal = CLIPS.eval(expr: "(assert ping x 1)")
        guard case .int(let fid) = idVal else { XCTFail(); return }
        guard let env = CLIPS.currentEnvironment else { XCTFail(); return }
        XCTAssertTrue(env.rete.alpha.ids(for: "ping").contains(Int(fid)))
        _ = CLIPS.retract(id: Int(fid))
        guard let env2 = CLIPS.currentEnvironment else { XCTFail(); return }
        XCTAssertFalse(env2.rete.alpha.ids(for: "ping").contains(Int(fid)))
    }
}

