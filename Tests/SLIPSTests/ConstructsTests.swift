import XCTest
@testable import SLIPS

@MainActor
final class ConstructsTests: XCTestCase {
    func testTemplateAndFacts() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate person (slot name) (slot age))")
        let idVal = CLIPS.eval(expr: "(assert person name \"Bob\" age 42)")
        var id: Int64 = -1
        if case .int(let v) = idVal { id = v } else { XCTFail("Id non valido") }
        XCTAssertEqual(CLIPS.eval(expr: "(retract \(id))"), .boolean(true))
        XCTAssertEqual(CLIPS.eval(expr: "(retract \(id))"), .boolean(false))
    }
}

