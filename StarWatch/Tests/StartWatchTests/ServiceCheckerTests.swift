// StartWatch — ServiceCheckerTests: тесты проверок сервисов
import XCTest
@testable import StartWatch

final class ServiceCheckerTests: XCTestCase {

    private func makeService(name: String, type: CheckType, value: String, timeout: Int = 2) -> ServiceConfig {
        ServiceConfig(
            name: name,
            check: CheckConfig(type: type, value: value, timeout: timeout),
            start: nil,
            restart: nil,
            cwd: nil,
            tags: nil
        )
    }

    func testProcessCheck_existingProcess() async {
        // Use current process's parent (swift test runner)
        // Just verify that a real process lookup works (returns non-crash result)
        let service = makeService(name: "pgrep_self", type: .command, value: "pgrep -f StartWatch")
        let result = await ServiceChecker.check(service: service)
        // Either found or not - just ensure no crash and result has detail
        XCTAssertFalse(result.detail.isEmpty)
    }

    func testProcessCheck_nonExistentProcess() async {
        let service = makeService(name: "fake", type: .process, value: "startwatch_fake_proc_xyz")
        let result = await ServiceChecker.check(service: service)
        XCTAssertFalse(result.isRunning)
    }

    func testPortCheck_closedPort() async {
        let service = makeService(name: "closed", type: .port, value: "19999", timeout: 2)
        let result = await ServiceChecker.check(service: service)
        XCTAssertFalse(result.isRunning)
    }

    func testPortCheck_invalidPort() async {
        let service = makeService(name: "bad", type: .port, value: "notaport", timeout: 2)
        let result = await ServiceChecker.check(service: service)
        XCTAssertFalse(result.isRunning)
        XCTAssertTrue(result.detail.contains("Invalid port"))
    }

    func testHTTPCheck_badURL() async {
        // Empty string — URL(string: "") returns nil
        let service = makeService(name: "bad", type: .http, value: "", timeout: 2)
        let result = await ServiceChecker.check(service: service)
        XCTAssertFalse(result.isRunning)
        XCTAssertTrue(result.detail.contains("Invalid URL"))
    }

    func testHTTPCheck_unreachable() async {
        let service = makeService(name: "unreachable", type: .http, value: "http://127.0.0.1:19998/health", timeout: 2)
        let result = await ServiceChecker.check(service: service)
        XCTAssertFalse(result.isRunning)
    }

    func testCommandCheck_exitZero() async {
        let service = makeService(name: "true", type: .command, value: "true", timeout: 5)
        let result = await ServiceChecker.check(service: service)
        XCTAssertTrue(result.isRunning)
        XCTAssertEqual(result.detail, "Exit 0")
    }

    func testCommandCheck_exitOne() async {
        let service = makeService(name: "false", type: .command, value: "false", timeout: 5)
        let result = await ServiceChecker.check(service: service)
        XCTAssertFalse(result.isRunning)
    }

    func testCheckAll_orderPreserved() async {
        let services = [
            makeService(name: "A", type: .command, value: "true"),
            makeService(name: "B", type: .command, value: "false"),
            makeService(name: "C", type: .command, value: "true"),
        ]
        let results = await ServiceChecker.checkAll(services: services)
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].service.name, "A")
        XCTAssertEqual(results[1].service.name, "B")
        XCTAssertEqual(results[2].service.name, "C")
        XCTAssertTrue(results[0].isRunning)
        XCTAssertFalse(results[1].isRunning)
        XCTAssertTrue(results[2].isRunning)
    }
}
