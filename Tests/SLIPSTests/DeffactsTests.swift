import XCTest
@testable import SLIPS

@MainActor
final class DeffactsTests: XCTestCase {
    func testDeffactsAndReset() {
        _ = SLIPS.createEnvironment()
        // Definisce template e deffacts con due fatti
        _ = SLIPS.eval(expr: "(deftemplate person (slot name) (slot age))")
        let rv = SLIPS.eval(expr: "(deffacts base (person name \"Anna\" age 30) (person name \"Luca\" age 28))")
        if case .int(let n) = rv { XCTAssertEqual(n, 2) } else { XCTFail() }
        // reset deve asserire i due fatti
        SLIPS.reset()
        let count = SLIPS.eval(expr: "(facts)")
        if case .int(let n) = count { XCTAssertEqual(n, 2) } else { XCTFail() }
    }
}
