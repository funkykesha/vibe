import XCTest
@testable import StartWatch

final class DaemonOwnershipTests: XCTestCase {
    func testAddressInUseRetryOutcomeReturnsNonOwnerWhenReachable() {
        XCTAssertEqual(
            DaemonCoordinator.resolveAddressInUseRetryOutcome(isReachableAfterRetry: true),
            .nonOwner
        )
    }

    func testAddressInUseRetryOutcomeReturnsFailedWhenStillUnreachable() {
        XCTAssertEqual(
            DaemonCoordinator.resolveAddressInUseRetryOutcome(isReachableAfterRetry: false),
            .failed
        )
    }
}
