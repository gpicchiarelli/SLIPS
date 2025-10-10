import XCTest
@testable import SLIPS

@MainActor
final class VariablesTests: XCTestCase {
    func testBindAndUseSingleVar() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(bind x 5)")
        XCTAssertEqual(CLIPS.eval(expr: "(value x)"), .int(5))
        XCTAssertEqual(CLIPS.eval(expr: "(+ (value x) 3)"), .int(8))
    }

    func testBindAndUseMultifieldVar() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(bind xs 1 2 3)")
        let v = CLIPS.eval(expr: "(value xs)")
        if case .multifield(let arr) = v { XCTAssertEqual(arr, [.int(1), .int(2), .int(3)]) } else { XCTFail() }
    }
}
