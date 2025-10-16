import XCTest
@testable import SLIPS

@MainActor
final class TemplateDefaultsTests: XCTestCase {
    func testStaticAndDynamicDefaults() {
        _ = CLIPS.createEnvironment()
        _ = CLIPS.eval(expr: "(deftemplate item (slot a (default 10)) (multislot tags (default-dynamic (create$ \"x\" \"y\"))))")
        // assert senza slot: usa i default
        let idVal = CLIPS.eval(expr: "(assert item)")
        if case .int = idVal { /* ok */ } else { XCTFail(); return }
        // facts conta 1
        let count = CLIPS.eval(expr: "(facts)")
        if case .int(let n) = count { XCTAssertEqual(n, 1) } else { XCTFail() }
    }
}
