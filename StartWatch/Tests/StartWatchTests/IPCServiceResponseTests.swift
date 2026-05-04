import XCTest
@testable import StartWatch

final class IPCServiceResponseTests: XCTestCase {
    func testIPCServiceResponseCodableRoundtrip() throws {
        let response: IPCServiceResponse = .executeInTerminal(
            TerminalCommand(serviceName: "Redis", command: "cd /tmp && redis-server")
        )

        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(IPCServiceResponse.self, from: data)

        switch decoded {
        case .executeInTerminal(let cmd):
            XCTAssertEqual(cmd.serviceName, "Redis")
            XCTAssertEqual(cmd.command, "cd /tmp && redis-server")
        default:
            XCTFail("Expected executeInTerminal response")
        }
    }

    func testInteractiveResponseBuildsCommandWithCwd() {
        let service = ServiceConfig(
            name: "API",
            check: CheckConfig(type: .process, value: "api", timeout: 5),
            start: "npm start",
            restart: "npm restart",
            cwd: "~/projects/api",
            tags: nil,
            open: nil,
            autostart: nil,
            startupTimeout: nil,
            background: false
        )

        let response = DaemonCoordinator.interactiveResponse(
            for: service,
            command: service.start,
            missingCommandError: "No start command"
        )

        switch response {
        case .executeInTerminal(let cmd):
            XCTAssertEqual(cmd.serviceName, "API")
            XCTAssertEqual(cmd.command, "cd ~/projects/api && npm start")
        default:
            XCTFail("Expected executeInTerminal response")
        }
    }

    func testInteractiveResponseReturnsErrorForMissingCommand() {
        let service = ServiceConfig(
            name: "API",
            check: CheckConfig(type: .process, value: "api", timeout: 5),
            start: nil,
            restart: nil,
            cwd: nil,
            tags: nil,
            open: nil,
            autostart: nil,
            startupTimeout: nil,
            background: false
        )

        let response = DaemonCoordinator.interactiveResponse(
            for: service,
            command: service.start,
            missingCommandError: "No start command"
        )

        switch response {
        case .error(let message):
            XCTAssertEqual(message, "No start command")
        default:
            XCTFail("Expected error response")
        }
    }

    func testSendAndReceiveReturnsNilForUnsupportedIPCMessage() {
        let response = IPCClient.sendAndReceive(.triggerCheck, allowBootstrap: false)
        XCTAssertNil(response)
    }
}
