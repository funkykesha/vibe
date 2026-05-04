// StartWatch — StopCommand: отправка .quit команды для остановки daemon + menu agent
import Foundation

enum StopCommand {
    static func run(args: [String]) {
        // Graceful shutdown first.
        IPCClient.send(.quit, allowBootstrap: false)

        // Fallback: stop launchd service if it exists.
        let uid = String(getuid())
        _ = runProcess("/bin/launchctl", ["bootout", "gui/\(uid)/com.user.startwatch"])

        // Fallback: kill remaining processes.
        _ = runProcess("/usr/bin/pkill", ["-f", "startwatch daemon"])
        _ = runProcess("/usr/bin/pkill", ["-f", "startwatch menu-agent"])

        print("\(ANSIColors.green)Stopping StartWatch (daemon + menu-agent)...\(ANSIColors.reset)")
    }

    @discardableResult
    private static func runProcess(_ path: String, _ arguments: [String]) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus
        } catch {
            return -1
        }
    }
}
