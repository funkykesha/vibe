import XCTest
@testable import StartWatch

final class LaunchRoutingTests: XCTestCase {
    func testDaemonCommandRoutesToDaemonMode() {
        let mode = resolveLaunchMode(arguments: ["daemon", "--no-menu"], isAppBundle: true)
        XCTAssertEqual(mode, .daemon(["--no-menu"]))
    }

    func testMenuAgentCommandRoutesToMenuMode() {
        let mode = resolveLaunchMode(arguments: ["menu-agent"], isAppBundle: true)
        XCTAssertEqual(mode, .menuAgent)
    }

    func testCLICommandsAlwaysRouteToCLI() {
        XCTAssertEqual(resolveLaunchMode(arguments: ["status"], isAppBundle: true), .cli(["status"]))
        XCTAssertEqual(resolveLaunchMode(arguments: ["check"], isAppBundle: true), .cli(["check"]))
        XCTAssertEqual(resolveLaunchMode(arguments: ["config"], isAppBundle: true), .cli(["config"]))
        XCTAssertEqual(resolveLaunchMode(arguments: ["log"], isAppBundle: true), .cli(["log"]))
        XCTAssertEqual(resolveLaunchMode(arguments: ["start"], isAppBundle: true), .cli(["start"]))
        XCTAssertEqual(resolveLaunchMode(arguments: ["restart"], isAppBundle: true), .cli(["restart"]))
        XCTAssertEqual(resolveLaunchMode(arguments: ["doctor"], isAppBundle: true), .cli(["doctor"]))
        XCTAssertEqual(resolveLaunchMode(arguments: ["help"], isAppBundle: true), .cli(["help"]))
        XCTAssertEqual(resolveLaunchMode(arguments: ["version"], isAppBundle: true), .cli(["version"]))
    }

    func testNoArgsFromAppBundleRoutesToAppBundleDefault() {
        XCTAssertEqual(resolveLaunchMode(arguments: [], isAppBundle: true), .appBundleDefault)
    }

    func testNoArgsFromNonBundleRoutesToCLI() {
        XCTAssertEqual(resolveLaunchMode(arguments: [], isAppBundle: false), .cli([]))
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
