import XCTest
@testable import SLIPS

@MainActor
final class ConstructsTests: XCTestCase {
    func testTemplateAndFacts() {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(deftemplate person (slot name) (slot age))")
        let idVal = SLIPS.eval(expr: "(assert person name \"Bob\" age 42)")
        var id: Int64 = -1
        if case .int(let v) = idVal { id = v } else { XCTFail("Id non valido") }
        XCTAssertEqual(SLIPS.eval(expr: "(retract \(id))"), .boolean(true))
        XCTAssertEqual(SLIPS.eval(expr: "(retract \(id))"), .boolean(false))
    }
}

