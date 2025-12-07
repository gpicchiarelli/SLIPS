import XCTest
@testable import SLIPS

@MainActor
final class PerfDeltaNotExistsTests: XCTestCase {
    func testPerfExistsUnaryActivation() {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(deftemplate b)")
        _ = SLIPS.eval(expr: "(defrule r (exists (b)) => (progn))")
        measure {
            for _ in 0..<50 {
                let idVal = SLIPS.eval(expr: "(assert b)")
                _ = SLIPS.run(limit: nil)
                if case .int(let i) = idVal { SLIPS.retract(id: Int(i)) }
            }
        }
    }

    func testPerfNotUnaryActivation() {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(deftemplate c)")
        _ = SLIPS.eval(expr: "(defrule r2 (not (c)) => (progn))")
        // Asserzioni e retrazioni ripetute per osservare il delta
        measure {
            for _ in 0..<50 {
                let idVal = SLIPS.eval(expr: "(assert c)")
                _ = SLIPS.run(limit: nil)
                if case .int(let i) = idVal { SLIPS.retract(id: Int(i)) }
                _ = SLIPS.run(limit: nil)
            }
        }
    }
}

