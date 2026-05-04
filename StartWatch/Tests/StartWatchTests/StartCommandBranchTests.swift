import XCTest
@testable import StartWatch

final class StartCommandBranchTests: XCTestCase {
    func testExecutionPathUsesDaemonIPCForBackgroundService() {
        let service = ServiceConfig(
            name: "Redis",
            check: CheckConfig(type: .port, value: "6379", timeout: 3),
            start: "redis-server",
            restart: "redis-cli shutdown && redis-server",
            cwd: nil,
            tags: nil,
            open: nil,
            autostart: nil,
            startupTimeout: nil,
            background: true
        )

        XCTAssertEqual(StartCommand.executionPath(for: service), .daemonIPC)
    }

    func testExecutionPathUsesInteractiveShellWhenBackgroundMissing() {
        let service = ServiceConfig(
            name: "API",
            check: CheckConfig(type: .process, value: "node", timeout: 5),
            start: "npm start",
            restart: "npm restart",
            cwd: "~/projects/api",
            tags: nil,
            open: nil,
            autostart: nil,
            startupTimeout: nil,
            background: nil
        )

        XCTAssertEqual(StartCommand.executionPath(for: service), .interactiveShell)
    }

    func testExecutionPathUsesInteractiveShellWhenBackgroundFalse() {
        let service = ServiceConfig(
            name: "API",
            check: CheckConfig(type: .process, value: "node", timeout: 5),
            start: "npm start",
            restart: "npm restart",
            cwd: "~/projects/api",
            tags: nil,
            open: nil,
            autostart: nil,
            startupTimeout: nil,
            background: false
        )

        XCTAssertEqual(StartCommand.executionPath(for: service), .interactiveShell)
    }
}
