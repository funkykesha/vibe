import Foundation
import XCTest
@testable import StartWatch

final class RefactorV2CoverageTests: XCTestCase {
    func testIPCRequestCodableShapesRoundTrip() throws {
        let requests: [IPCRequest] = [
            .triggerCheck,
            .getStatus,
            .startService(name: "redis"),
            .stopService(name: "redis"),
            .restartService(name: "redis"),
            .quit
        ]

        for request in requests {
            let data = try JSONEncoder().encode(request)
            let decoded = try JSONDecoder().decode(IPCRequest.self, from: data)
            let reencoded = try JSONEncoder().encode(decoded)
            XCTAssertEqual(data, reencoded)
        }
    }

    func testIPCResponseCodableShapesRoundTrip() throws {
        let responses: [IPCResponse] = [
            .ok,
            .error("oops"),
            .statusSnapshot([
                CodableCheckResult(serviceName: "redis", isRunning: true, detail: "ok", checkedAt: Date(), isStarting: false)
            ]),
            .executeInTerminal(TerminalCommand(serviceName: "api", command: "npm run dev"))
        ]

        for response in responses {
            let data = try JSONEncoder().encode(response)
            let decoded = try JSONDecoder().decode(IPCResponse.self, from: data)
            let reencoded = try JSONEncoder().encode(decoded)
            XCTAssertEqual(data, reencoded)
        }
    }

    func testSkippedAutostartServicesHelper() {
        let config = AppConfig(
            terminal: nil,
            checkIntervalMinutes: nil,
            notifications: nil,
            services: [
                ServiceConfig(
                    name: "bg",
                    check: CheckConfig(type: .process, value: "bg", timeout: nil),
                    start: "echo bg",
                    restart: nil,
                    cwd: nil,
                    tags: nil,
                    open: nil,
                    autostart: true,
                    startupTimeout: nil,
                    background: true
                ),
                ServiceConfig(
                    name: "term",
                    check: CheckConfig(type: .process, value: "term", timeout: nil),
                    start: "echo term",
                    restart: nil,
                    cwd: nil,
                    tags: nil,
                    open: nil,
                    autostart: true,
                    startupTimeout: nil,
                    background: false
                )
            ]
        )

        let skipped = ConfigManager.skippedAutostartServices(config: config)
        XCTAssertEqual(skipped.map(\.name), ["term"])
        XCTAssertTrue(ConfigManager.validate(config).isEmpty)
    }

    func testLaunchAgentTemplateMatchesRefactorV2Contract() throws {
        let plistURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("com.user.startwatch.plist")
        let data = try Data(contentsOf: plistURL)
        let object = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        let dict = try XCTUnwrap(object as? [String: Any])

        XCTAssertEqual(dict["Label"] as? String, "com.user.startwatch")
        XCTAssertEqual(dict["ProgramArguments"] as? [String], ["/usr/local/bin/startwatch", "daemon"])
        XCTAssertEqual(dict["RunAtLoad"] as? Bool, true)

        let keepAlive = try XCTUnwrap(dict["KeepAlive"] as? [String: Any])
        XCTAssertEqual(keepAlive["SuccessfulExit"] as? Bool, false)
        XCTAssertEqual(dict["ThrottleInterval"] as? Int, 10)
    }

    func testBoundaryScriptExists() {
        let scriptPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/check-daemon-boundary.sh").path
        XCTAssertTrue(FileManager.default.isExecutableFile(atPath: scriptPath))
    }
}
