import XCTest
@testable import SLIPS

@MainActor
final class RouterCallbackTests: XCTestCase {
    func testWriteCallback() {
        var env = CLIPS.createEnvironment()
        var captured = ""
        XCTAssertTrue(RouterRegistry.AddRouter(&env, "cap", 100, query: { _, name in name == "t" }, write: { _, _, msg in captured += msg }))
        _ = CLIPS.eval(expr: "(printout t \"HELLO\" crlf)")
        XCTAssertTrue(captured.contains("HELLO"))
    }
}

