import XCTest
@testable import SLIPS

@MainActor
final class EvalTests: XCTestCase {
    func testArithmetic() {
        _ = SLIPS.createEnvironment()
        XCTAssertEqual(SLIPS.eval(expr: "(+ 1 2)"), .int(3))
        let v = SLIPS.eval(expr: "(/ (* 5 4) 2)")
        if case .float(let d) = v { XCTAssertEqual(d, 10.0, accuracy: 1e-9) } else { XCTFail() }
        XCTAssertEqual(SLIPS.eval(expr: "(= 4 4.0 4)"), .boolean(true))
        XCTAssertEqual(SLIPS.eval(expr: "(<> 4 5)"), .boolean(true))
        XCTAssertEqual(SLIPS.eval(expr: "(< 1 2 3)"), .boolean(true))
        XCTAssertEqual(SLIPS.eval(expr: "(<= 1 2 2)"), .boolean(true))
        XCTAssertEqual(SLIPS.eval(expr: "(> 3 2 1)"), .boolean(true))
        XCTAssertEqual(SLIPS.eval(expr: "(>= 3 3 2)"), .boolean(true))
    }

    func testLogic() {
        _ = SLIPS.createEnvironment()
        XCTAssertEqual(SLIPS.eval(expr: "(and TRUE FALSE)"), .boolean(false))
        XCTAssertEqual(SLIPS.eval(expr: "(or TRUE FALSE)"), .boolean(true))
        XCTAssertEqual(SLIPS.eval(expr: "(not TRUE)"), .boolean(false))
        // GroupActions via progn
        XCTAssertEqual(SLIPS.eval(expr: "(progn (printout t \"X\") 5)"), .int(5))
    }

    func testSymbolsAndStrings() {
        _ = SLIPS.createEnvironment()
        XCTAssertEqual(SLIPS.eval(expr: "(eq \"a\" \"a\")"), .boolean(true))
        XCTAssertEqual(SLIPS.eval(expr: "(eq foo foo)"), .boolean(true))
    }

    func testPrintout() {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(printout t \"Hello\" crlf)")
    }
}
