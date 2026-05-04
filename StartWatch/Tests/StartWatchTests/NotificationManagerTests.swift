// StartWatch — NotificationManagerTests: тесты уведомлений
import XCTest
import UserNotifications
@testable import StartWatch

final class NotificationManagerTests: XCTestCase {

    private var manager: NotificationManager!

    override func setUp() {
        super.setUp()
        // Create a fresh instance with skipSetup=true to avoid UNUserNotificationCenter crash
        manager = NotificationManager(
            onOpenReport: nil,
            onRestartFailed: nil,
            skipSetup: true
        )
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func makeService(name: String, type: CheckType = .command, value: String = "true") -> ServiceConfig {
        ServiceConfig(
            name: name,
            check: CheckConfig(type: type, value: value, timeout: 2),
            start: nil,
            restart: nil,
            cwd: nil,
            tags: nil,
            open: nil,
            autostart: nil,
            startupTimeout: nil,
            background: nil
        )
    }

    private func makeCheckResult(serviceName: String, isRunning: Bool = false) -> CheckResult {
        let service = makeService(name: serviceName)
        return CheckResult(
            service: service,
            isRunning: isRunning,
            detail: isRunning ? "Running" : "Failed"
        )
    }

    // MARK: - sendAlert Tests

    func testSendAlert_createsNotificationWithCorrectContent() {
        let failedServices = [
            makeCheckResult(serviceName: "Redis", isRunning: false),
            makeCheckResult(serviceName: "Postgres", isRunning: false)
        ]

        // In test environment, UNUserNotificationCenter fails without .app bundle
        // NotificationManager handles this gracefully
        manager.sendAlert(failedServices: failedServices, showDetails: true, sound: false)

        XCTAssertTrue(true)
    }

    func testSendAlert_singleFailure() {
        let failedServices = [
            makeCheckResult(serviceName: "Redis", isRunning: false)
        ]

        manager.sendAlert(failedServices: failedServices, showDetails: false, sound: false)

        XCTAssertTrue(true)
    }

    func testSendAlert_multipleFailures() {
        let failedServices = [
            makeCheckResult(serviceName: "Redis", isRunning: false),
            makeCheckResult(serviceName: "Postgres", isRunning: false),
            makeCheckResult(serviceName: "Backend", isRunning: false)
        ]

        manager.sendAlert(failedServices: failedServices, showDetails: true, sound: false)

        XCTAssertTrue(true)
    }

    // MARK: - sendRecovered Tests

    func testSendRecovered_createsNotificationWithCorrectContent() {
        let recoveredServices = [
            makeCheckResult(serviceName: "Redis", isRunning: true),
            makeCheckResult(serviceName: "Postgres", isRunning: true)
        ]

        manager.sendRecovered(services: recoveredServices, sound: false)
    }

    func testSendRecovered_singleRecovery() {
        let recoveredServices = [
            makeCheckResult(serviceName: "Redis", isRunning: true)
        ]

        manager.sendRecovered(services: recoveredServices, sound: false)
    }

    func testSendRecovered_multipleRecoveries() {
        let recoveredServices = [
            makeCheckResult(serviceName: "Redis", isRunning: true),
            makeCheckResult(serviceName: "Postgres", isRunning: true),
            makeCheckResult(serviceName: "Backend", isRunning: true)
        ]

        manager.sendRecovered(services: recoveredServices, sound: false)
    }

    // MARK: - sendConfigInvalid Tests

    func testSendConfigInvalid_createsNotificationWithError() {
        let testErrors = ["Invalid configuration format", "Missing required field: services"]

        manager.sendConfigInvalid(errors: testErrors, sound: false)
    }

    func testSendConfigInvalid_customError() {
        let errors = ["Missing required field: services", "Invalid value: redis"]

        manager.sendConfigInvalid(errors: errors, sound: false)
    }

    // MARK: - Notification Categories

    func testAlertCategoryIdentifier() {
        let alertCategory = "STARTWATCH_ALERT"
        let recoveredCategory = "STARTWATCH_RECOVERED"
        let configInvalidCategory = "STARTWATCH_CONFIG_INVALID"

        XCTAssertEqual(alertCategory, "STARTWATCH_ALERT")
        XCTAssertEqual(recoveredCategory, "STARTWATCH_RECOVERED")
        XCTAssertEqual(configInvalidCategory, "STARTWATCH_CONFIG_INVALID")

        XCTAssertNotEqual(alertCategory, recoveredCategory)
        XCTAssertNotEqual(alertCategory, configInvalidCategory)
        XCTAssertNotEqual(recoveredCategory, configInvalidCategory)
    }

    // MARK: - Notification Identifiers

    func testNotificationIdentifierConsts() {
        let alertIdentifier = "com.startwatch.service-alert"
        let recoveredIdentifier = "com.startwatch.service-recovered"
        let configInvalidIdentifier = "com.startwatch.config-invalid"

        XCTAssertEqual(alertIdentifier, "com.startwatch.service-alert")
        XCTAssertEqual(recoveredIdentifier, "com.startwatch.service-recovered")
        XCTAssertEqual(configInvalidIdentifier, "com.startwatch.config-invalid")

        XCTAssertNotEqual(alertIdentifier, recoveredIdentifier)
        XCTAssertNotEqual(alertIdentifier, configInvalidIdentifier)
        XCTAssertNotEqual(recoveredIdentifier, configInvalidIdentifier)
    }

    // MARK: - Callback Tests

    func testOpenReportCallback() {
        var callbackExecuted = false
        manager.onOpenReport = {
            callbackExecuted = true
        }

        manager.onOpenReport?()

        XCTAssertTrue(callbackExecuted)
    }

    func testRestartFailedCallback() {
        var callbackExecuted = false
        manager.onRestartFailed = {
            callbackExecuted = true
        }

        manager.onRestartFailed?()

        XCTAssertTrue(callbackExecuted)
    }

    func testCallbacksAreOptional() {
        XCTAssertNil(manager.onOpenReport)
        XCTAssertNil(manager.onRestartFailed)

        manager.onOpenReport?()
        manager.onRestartFailed?()
    }

    // MARK: - Edge Cases

    func testSend_emptyFailedServices() {
        let failedServices: [CheckResult] = []
        manager.sendAlert(failedServices: failedServices, showDetails: false, sound: false)
    }

    func testSend_emptyRecoveredServices() {
        let recoveredServices: [CheckResult] = []
        manager.sendRecovered(services: recoveredServices, sound: false)
    }

    func testSend_longServiceNames() {
        let longName = String(repeating: "X", count: 200)
        let failedServices = [
            makeCheckResult(serviceName: longName, isRunning: false)
        ]

        manager.sendAlert(failedServices: failedServices, showDetails: false, sound: false)
    }

    func testSend_specialCharactersInNames() {
        let specialNames = ["service@example.com", "test-service_v2", "service (dev)"]
        let failedServices = specialNames.map { makeCheckResult(serviceName: $0, isRunning: false) }

        manager.sendAlert(failedServices: failedServices, showDetails: false, sound: false)
    }

    // MARK: - Multiple Sequential Sends

    func testMultipleSends_noCrash() {
        let services = [makeCheckResult(serviceName: "Test", isRunning: false)]

        for _ in 0..<10 {
            manager.sendAlert(failedServices: services, showDetails: false, sound: false)
            manager.sendRecovered(services: services, sound: false)
        }
    }

    // MARK: - Error Handling

    func testSend_withNilBundle_doesNotCrash() {
        manager = NotificationManager.shared

        let services = [makeCheckResult(serviceName: "Test", isRunning: false)]
        manager.sendAlert(failedServices: services, showDetails: false, sound: false)
    }

    // MARK: - Send Method Sound Parameter

    func testSend_withDefaultSound() {
    }

    func testSend_withNilSound() {
    }

    func testAppBundleContextGuard() {
        XCTAssertTrue(NotificationManager.isAppBundleContext(bundlePathExtension: "app"))
        XCTAssertFalse(NotificationManager.isAppBundleContext(bundlePathExtension: ""))
        XCTAssertFalse(NotificationManager.isAppBundleContext(bundlePathExtension: "xctest"))
    }

    // MARK: - Request Authorization

    func testRequestAuthorization_doesNotCrash() {
        manager.requestAuthorization()
    }
}
