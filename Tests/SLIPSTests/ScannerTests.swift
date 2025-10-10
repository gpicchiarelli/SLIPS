import XCTest
@testable import SLIPS

@MainActor
final class ScannerTests: XCTestCase {
    func testGetTokenFastRouter() {
        var env = CLIPS.createEnvironment()
        var r = RouterEnvData.ensure(&env)
        r.FastCharGetRouter = "R"
        r.FastCharGetString = "(+ 1 2 \"ciao\")"
        r.FastCharGetIndex = 0

        var t = Token(.STOP_TOKEN)
        Scanner.GetToken(&env, "R", &t)
        XCTAssertEqual(t.tknType, .LEFT_PARENTHESIS_TOKEN)
        Scanner.GetToken(&env, "R", &t)
        XCTAssertEqual(t.tknType, .SYMBOL_TOKEN)
        XCTAssertEqual(t.text, "+")
        Scanner.GetToken(&env, "R", &t)
        XCTAssertEqual(t.tknType, .INTEGER_TOKEN)
        XCTAssertEqual(t.intValue, 1)
        Scanner.GetToken(&env, "R", &t)
        XCTAssertEqual(t.tknType, .INTEGER_TOKEN)
        XCTAssertEqual(t.intValue, 2)
        Scanner.GetToken(&env, "R", &t)
        XCTAssertEqual(t.tknType, .STRING_TOKEN)
        XCTAssertEqual(t.text, "ciao")
        Scanner.GetToken(&env, "R", &t)
        XCTAssertEqual(t.tknType, .RIGHT_PARENTHESIS_TOKEN)
        Scanner.GetToken(&env, "R", &t)
        XCTAssertEqual(t.tknType, .STOP_TOKEN)
    }

    func testVariableTokens() {
        var env = CLIPS.createEnvironment()
        var r = RouterEnvData.ensure(&env)
        r.FastCharGetRouter = "R2"
        r.FastCharGetString = "(bind ?x 5)"
        r.FastCharGetIndex = 0
        var t = Token(.STOP_TOKEN)
        Scanner.GetToken(&env, "R2", &t) // (
        Scanner.GetToken(&env, "R2", &t) // bind
        Scanner.GetToken(&env, "R2", &t) // ?x
        XCTAssertEqual(t.tknType, .SF_VARIABLE_TOKEN)
        XCTAssertEqual(t.text, "x")
    }
}
