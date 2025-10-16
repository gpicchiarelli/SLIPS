import XCTest
@testable import SLIPS

@MainActor
final class WatchTests: XCTestCase {
    func testWatchFacts() {
        var env = CLIPS.createEnvironment()
        var captured = ""
        // Router che cattura STDOUT
        XCTAssertTrue(RouterRegistry.AddRouter(&env, "cap2", 100, query: { _, name in name == Router.STDOUT }, write: { _, _, msg in captured += msg }))

        _ = CLIPS.eval(expr: "(watch facts)")
        let idVal = CLIPS.eval(expr: "(assert person name \"Bob\" age 42)")
        if case .int(let id) = idVal {
            _ = CLIPS.eval(expr: "(retract \(id))")
        } else { XCTFail("id non valido") }
        XCTAssertTrue(captured.contains("==> (person"))
        XCTAssertTrue(captured.contains("<== (person"))
    }
}

