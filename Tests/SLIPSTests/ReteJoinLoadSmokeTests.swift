import XCTest
@testable import SLIPS

@MainActor
final class ReteJoinLoadSmokeTests: XCTestCase {
    func testLoadAndRunJoinSmoke() throws {
        var env = CLIPS.createEnvironment()
        let path = FileManager.default.currentDirectoryPath + "/Tests/SLIPSTests/Assets/join_smoke.clp"
        try CLIPS.load(path)
        // Dopo i 2 run nel file, dovremmo avere 2 token finali in beta['r']
        guard let mem = env.rete.beta["r"] else { XCTFail("Missing beta memory for r"); return }
        XCTAssertEqual(mem.tokens.count, 2)
    }
}

