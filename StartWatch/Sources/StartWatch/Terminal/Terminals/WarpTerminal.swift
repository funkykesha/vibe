// StartWatch — WarpTerminal: открытие Warp через temp-скрипт
import Foundation

enum WarpTerminal: TerminalApp {
    static let identifier = "warp"
    static let bundleID = "dev.warp.Warp-Stable"

    static func open(command: String) throws {
        let scriptFile = StateManager.stateDir.appendingPathComponent("open_cli.sh")
        let content = """
        #!/bin/zsh
        clear
        \(command)
        exec zsh
        """
        do {
            try content.write(to: scriptFile, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: scriptFile.path
            )
        } catch {
            throw TerminalError.openFailed(error)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Warp", scriptFile.path]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw TerminalError.openFailed(error)
        }
    }
}
