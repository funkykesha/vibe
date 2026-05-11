import XCTest
@testable import StartWatch

final class LaunchRoutingTests: XCTestCase {
    func testDaemonCommandRoutesToDaemonMode() {
        let mode = resolveLaunchMode(arguments: ["daemon"], isAppBundle: true)
        XCTAssertEqual(mode, .menuAgent)

        let nonBundleMode = resolveLaunchMode(arguments: ["daemon"], isAppBundle: false)
        XCTAssertEqual(nonBundleMode, .daemon([]))
    }

    func testMenuAgentCommandRoutesToMenuMode() {
        let mode = resolveLaunchMode(arguments: ["menu-agent"], isAppBundle: true)
        XCTAssertEqual(mode, .menuAgent)
    }

    func testCLICommandsAlwaysRouteToCLI() {
        XCTAssertEqual(resolveLaunchMode(arguments: ["status"], isAppBundle: false), .cli(["status"]))
        XCTAssertEqual(resolveLaunchMode(arguments: ["check"], isAppBundle: false), .cli(["check"]))
        XCTAssertEqual(resolveLaunchMode(arguments: ["config"], isAppBundle: false), .cli(["config"]))
        XCTAssertEqual(resolveLaunchMode(arguments: ["log"], isAppBundle: false), .cli(["log"]))
        XCTAssertEqual(resolveLaunchMode(arguments: ["start"], isAppBundle: false), .cli(["start"]))
        XCTAssertEqual(resolveLaunchMode(arguments: ["restart"], isAppBundle: false), .cli(["restart"]))
        XCTAssertEqual(resolveLaunchMode(arguments: ["doctor"], isAppBundle: false), .cli(["doctor"]))
        XCTAssertEqual(resolveLaunchMode(arguments: ["install"], isAppBundle: false), .cli(["install"]))
        XCTAssertEqual(resolveLaunchMode(arguments: ["uninstall"], isAppBundle: false), .cli(["uninstall"]))
        XCTAssertEqual(resolveLaunchMode(arguments: ["help"], isAppBundle: false), .cli(["help"]))
        XCTAssertEqual(resolveLaunchMode(arguments: ["version"], isAppBundle: false), .cli(["version"]))
    }

    func testNoArgsFromAppBundleRoutesToMenuAgent() {
        XCTAssertEqual(resolveLaunchMode(arguments: [], isAppBundle: true), .menuAgent)
    }

    func testNoArgsFromNonBundleRoutesToStatusCommand() {
        XCTAssertEqual(resolveLaunchMode(arguments: [], isAppBundle: false), .cli(["status"]))
    }

    func testLaunchAgentRunningParserRequiresRunningState() {
        XCTAssertTrue(DaemonCommand.launchAgentIsRunning("""
        gui/501/com.user.startwatch = {
            state = running
        }
        """))

        XCTAssertFalse(DaemonCommand.launchAgentIsRunning("""
        gui/501/com.user.startwatch = {
            state = not running
        }
        """))
    }
}
