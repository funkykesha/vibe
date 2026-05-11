import XCTest
@testable import StartWatch

final class DaemonOwnershipTests: XCTestCase {
    func testAddressInUseRetryOutcomeReturnsNonOwnerWhenReachable() {
        XCTAssertEqual(
            DaemonRuntime.resolveAddressInUseRetryOutcome(isReachableAfterRetry: true),
            .alreadyRunning
        )
    }

    func testAddressInUseRetryOutcomeReturnsFailedWhenStillUnreachable() {
        XCTAssertEqual(
            DaemonRuntime.resolveAddressInUseRetryOutcome(isReachableAfterRetry: false),
            .failed
        )
    }
}
