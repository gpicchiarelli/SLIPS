import XCTest
@testable import SLIPS

@MainActor
final class AgendaSalienceEvalTests: XCTestCase {
    func testGetSetSalienceEvaluation() {
        _ = CLIPS.createEnvironment()
        // Default should be when-defined
        if case .symbol(let s1) = CLIPS.eval(expr: "(get-salience-evaluation)") {
            XCTAssertEqual(s1, "when-defined")
        } else { XCTFail("Expected symbol when-defined") }
        
        // Set to when-activated
        if case .symbol(let s2) = CLIPS.eval(expr: "(set-salience-evaluation when-activated)") {
            XCTAssertEqual(s2, "when-activated")
        } else { XCTFail("Expected symbol when-activated") }
        
        // Read back
        if case .symbol(let s3) = CLIPS.eval(expr: "(get-salience-evaluation)") {
            XCTAssertEqual(s3, "when-activated")
        } else { XCTFail("Expected symbol when-activated") }
    }
}

