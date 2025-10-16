import XCTest
@testable import SLIPS

@MainActor
final class TemplateConstraintsTests: XCTestCase {
    func testMultislotStaticDefaultAndConstraints() {
        _ = CLIPS.createEnvironment()
        // multislot default static multiplo + type/range su slot singolo
        _ = CLIPS.eval(expr: "(deftemplate person (slot age (type INTEGER) (range 0 120)) (multislot tags (default a b c)))")
        // assert senza specificare tags -> deve usare default [a b c]
        _ = CLIPS.eval(expr: "(assert person age 30)")
        guard let env = CLIPS.currentEnvironment else { XCTFail(); return }
        let fact = env.facts.values.first { $0.name == "person" }
        XCTAssertNotNil(fact)
        if let tags = fact?.slots["tags"], case .multifield(let arr) = tags {
            XCTAssertEqual(arr.count, 3)
        } else {
            XCTFail("tags non multifield")
        }
        // vincoli: fuori range
        let bad1 = CLIPS.eval(expr: "(assert person age 130)")
        if case .boolean(let ok) = bad1 { XCTAssertEqual(ok, false) } else { XCTFail() }
        // tipo errato
        let bad2 = CLIPS.eval(expr: "(assert person age \"x\")")
        if case .boolean(let ok2) = bad2 { XCTAssertEqual(ok2, false) } else { XCTFail() }
    }
}

