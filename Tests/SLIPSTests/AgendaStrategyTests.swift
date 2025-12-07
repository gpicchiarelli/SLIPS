import XCTest
@testable import SLIPS

@MainActor
final class AgendaStrategyTests: XCTestCase {
    func testDepthVsBreadth() {
        _ = SLIPS.createEnvironment()
        _ = SLIPS.eval(expr: "(deftemplate e (slot id))")
        _ = SLIPS.eval(expr: "(defrule r1 (e id 1) => (printout t \"R1\"))")
        _ = SLIPS.eval(expr: "(defrule r2 (e id 2) => (printout t \"R2\"))")
        var out = ""
        guard var env = SLIPS.currentEnvironment else { XCTFail(); return }
        _ = RouterRegistry.AddRouter(&env, "cap7", 100, query: { _, name in name == "t" }, write: { _, _, s in out += s })
        _ = SLIPS.eval(expr: "(set-strategy breadth)")
        _ = SLIPS.eval(expr: "(assert e id 1)")
        _ = SLIPS.eval(expr: "(assert e id 2)")
        XCTAssertEqual(SLIPS.run(limit: 2), 2)
        XCTAssertTrue(out.contains("R1"))
        XCTAssertTrue(out.contains("R2"))
        // order: breadth -> FIFO: R1 then R2
        let p1a = out.range(of: "R1")!.lowerBound
        let p2a = out.range(of: "R2")!.lowerBound
        XCTAssertTrue(p1a < p2a)
        out = ""
        _ = SLIPS.eval(expr: "(set-strategy depth)")
        _ = SLIPS.eval(expr: "(assert e id 1)")
        _ = SLIPS.eval(expr: "(assert e id 2)")
        XCTAssertEqual(SLIPS.run(limit: 2), 2)
        // order: depth -> LIFO: R2 then R1
        let p2b = out.range(of: "R2")!.lowerBound
        let p1b = out.range(of: "R1")!.lowerBound
        XCTAssertTrue(p2b < p1b)
        out = ""
        _ = SLIPS.eval(expr: "(set-strategy lex)")
        _ = SLIPS.eval(expr: "(assert e id 1)")
        _ = SLIPS.eval(expr: "(assert e id 2)")
        XCTAssertEqual(SLIPS.run(limit: 2), 2)
        // order lex -> by rule name: r1 then r2
        let p1c = out.range(of: "R1")!.lowerBound
        let p2c = out.range(of: "R2")!.lowerBound
        XCTAssertTrue(p1c < p2c)
    }
}
