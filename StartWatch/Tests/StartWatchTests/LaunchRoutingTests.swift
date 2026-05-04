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
}
