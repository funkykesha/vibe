import XCTest
@testable import StartWatch

final class MenuControlPlaneTests: XCTestCase {
    func testQuitDispatchUsesLocalWhenCoordinatorPresent() {
        XCTAssertEqual(resolveQuitDispatchMode(hasLocalCoordinator: true), .local)
    }

    func testQuitDispatchUsesRemoteWhenCoordinatorMissing() {
        XCTAssertEqual(resolveQuitDispatchMode(hasLocalCoordinator: false), .remote)
    }

    func testQuitDispatchActionLocal() {
        XCTAssertEqual(resolveQuitDispatchAction(hasLocalCoordinator: true), .localShutdown)
    }

    func testQuitDispatchActionRemote() {
        XCTAssertEqual(resolveQuitDispatchAction(hasLocalCoordinator: false), .remoteIPC)
    }
}
