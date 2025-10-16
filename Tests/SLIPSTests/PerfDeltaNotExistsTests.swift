import XCTest
@testable import SLIPS

@MainActor
final class PerfDeltaNotExistsTests: XCTestCase {
    func testPerfExistsUnaryActivation() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate b)")
        _ = CLIPS.eval(expr: "(defrule r (exists (b)) => (progn))")
        measure {
            for _ in 0..<50 {
                let idVal = CLIPS.eval(expr: "(assert b)")
                _ = CLIPS.run(limit: nil)
                if case .int(let i) = idVal { CLIPS.retract(id: Int(i)) }
            }
        }
    }

    func testPerfNotUnaryActivation() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate c)")
        _ = CLIPS.eval(expr: "(defrule r2 (not (c)) => (progn))")
        // Asserzioni e retrazioni ripetute per osservare il delta
        measure {
            for _ in 0..<50 {
                let idVal = CLIPS.eval(expr: "(assert c)")
                _ = CLIPS.run(limit: nil)
                if case .int(let i) = idVal { CLIPS.retract(id: Int(i)) }
                _ = CLIPS.run(limit: nil)
            }
        }
    }
}

