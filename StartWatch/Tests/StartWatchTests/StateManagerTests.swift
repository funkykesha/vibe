import XCTest
@testable import StartWatch

final class StateManagerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        StateManager.resetForTests()
    }

    func testGenerationIncrementsOnMutation() {
        let before = StateManager.generationState().generation
        StateManager.saveCodableResults([
            CodableCheckResult(serviceName: "svc", isRunning: true, detail: "ok", checkedAt: Date(), isStarting: false)
        ])
        let after = StateManager.generationState().generation
        XCTAssertGreaterThan(after, before)
    }

    func testPrunesRemovedServicesOnUpdate() {
        let now = Date()
        StateManager.saveCodableResults([
            CodableCheckResult(serviceName: "a", isRunning: true, detail: "ok", checkedAt: now),
            CodableCheckResult(serviceName: "b", isRunning: true, detail: "ok", checkedAt: now)
        ])

        StateManager.saveCodableResults([
            CodableCheckResult(serviceName: "a", isRunning: false, detail: "down", checkedAt: now)
        ])

        let snapshot = StateManager.currentSnapshot()
        XCTAssertEqual(snapshot.services.map(\.serviceName), ["a"])
    }

    func testFlushUpdatesLastFlushedGeneration() {
        StateManager.saveCodableResults([
            CodableCheckResult(serviceName: "svc", isRunning: true, detail: "ok", checkedAt: Date())
        ])
        XCTAssertTrue(StateManager.shouldFlush())
        StateManager.flushNow()
        XCTAssertFalse(StateManager.shouldFlush())
    }
}
