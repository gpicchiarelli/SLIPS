import XCTest
@testable import SLIPS

@MainActor
final class RouterRegistryTests: XCTestCase {
    func testAddQueryDeleteRouter() {
        var env = CLIPS.createEnvironment()
        XCTAssertFalse(RouterRegistry.QueryRouters(env, "r1"))
        XCTAssertTrue(RouterRegistry.AddRouter(&env, "r1", 10))
        XCTAssertTrue(RouterRegistry.QueryRouters(env, "r1"))
        XCTAssertTrue(RouterRegistry.DeactivateRouter(&env, "r1"))
        XCTAssertTrue(RouterRegistry.ActivateRouter(&env, "r1"))
        XCTAssertTrue(RouterRegistry.DeleteRouter(&env, "r1"))
        XCTAssertFalse(RouterRegistry.QueryRouters(env, "r1"))
    }
}

