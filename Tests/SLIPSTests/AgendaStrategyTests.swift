import XCTest
@testable import SLIPS

@MainActor
final class AgendaStrategyTests: XCTestCase {
    func testDepthVsBreadth() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate e (slot id))")
        _ = CLIPS.eval(expr: "(defrule r1 (e id 1) => (printout t \"R1\"))")
        _ = CLIPS.eval(expr: "(defrule r2 (e id 2) => (printout t \"R2\"))")
        var out = ""
        guard var env = CLIPS.currentEnvironment else { XCTFail(); return }
        _ = RouterRegistry.AddRouter(&env, "cap7", 100, query: { _, name in name == "t" }, write: { _, _, s in out += s })
        _ = CLIPS.eval(expr: "(set-strategy breadth)")
        _ = CLIPS.eval(expr: "(assert e id 1)")
        _ = CLIPS.eval(expr: "(assert e id 2)")
        XCTAssertEqual(CLIPS.run(limit: 2), 2)
        XCTAssertTrue(out.contains("R1"))
        XCTAssertTrue(out.contains("R2"))
        // order: breadth -> FIFO: R1 then R2
        let p1a = out.range(of: "R1")!.lowerBound
        let p2a = out.range(of: "R2")!.lowerBound
        XCTAssertTrue(p1a < p2a)
        out = ""
        _ = CLIPS.eval(expr: "(set-strategy depth)")
        _ = CLIPS.eval(expr: "(assert e id 1)")
        _ = CLIPS.eval(expr: "(assert e id 2)")
        XCTAssertEqual(CLIPS.run(limit: 2), 2)
        // order: depth -> LIFO: R2 then R1
        let p2b = out.range(of: "R2")!.lowerBound
        let p1b = out.range(of: "R1")!.lowerBound
        XCTAssertTrue(p2b < p1b)
        out = ""
        _ = CLIPS.eval(expr: "(set-strategy lex)")
        _ = CLIPS.eval(expr: "(assert e id 1)")
        _ = CLIPS.eval(expr: "(assert e id 2)")
        XCTAssertEqual(CLIPS.run(limit: 2), 2)
        // order lex -> by rule name: r1 then r2
        let p1c = out.range(of: "R1")!.lowerBound
        let p2c = out.range(of: "R2")!.lowerBound
        XCTAssertTrue(p1c < p2c)
    }
}
