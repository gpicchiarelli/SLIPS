import XCTest
@testable import SLIPS

@MainActor
final class DeffactsTests: XCTestCase {
    func testDeffactsAndReset() {
        _ = CLIPS.createEnvironment()
        // Definisce template e deffacts con due fatti
        _ = CLIPS.eval(expr: "(deftemplate person (slot name) (slot age))")
        let rv = CLIPS.eval(expr: "(deffacts base (person name \"Anna\" age 30) (person name \"Luca\" age 28))")
        if case .int(let n) = rv { XCTAssertEqual(n, 2) } else { XCTFail() }
        // reset deve asserire i due fatti
        CLIPS.reset()
        let count = CLIPS.eval(expr: "(facts)")
        if case .int(let n) = count { XCTAssertEqual(n, 2) } else { XCTFail() }
    }
}
