import XCTest
@testable import StartWatch

final class StartupPlannerTests: XCTestCase {
    func testOwnerWithMenuResolvesToOwnerWithMenu() {
        XCTAssertEqual(
            resolveStartupAction(showMenu: true, outcome: .owner),
            .ownerWithMenu
        )
    }

    func testOwnerHeadlessResolvesToOwnerHeadless() {
        XCTAssertEqual(
            resolveStartupAction(showMenu: false, outcome: .owner),
            .ownerHeadless
        )
    }

    func testNonOwnerWithMenuResolvesToClientWithMenu() {
        XCTAssertEqual(
            resolveStartupAction(showMenu: true, outcome: .nonOwner),
            .clientWithMenu
        )
    }

    func testNonOwnerHeadlessResolvesToDuplicateExit() {
        XCTAssertEqual(
            resolveStartupAction(showMenu: false, outcome: .nonOwner),
            .duplicateHeadlessExit
        )
    }

    func testFailedOutcomeResolvesToFatalExit() {
        XCTAssertEqual(
            resolveStartupAction(showMenu: true, outcome: .failed),
            .fatalExit
        )
    }
}
