// StartWatch — AppleTerminal: открытие Terminal.app через AppleScript
import Foundation

enum AppleTerminal: TerminalApp {
    static let identifier = "terminal"
    static let bundleID = "com.apple.Terminal"

    static func open(command: String) throws {
        let escaped = command
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "Terminal"
            activate
            do script "\(escaped)"
        end tell
        """
        try runAppleScript(script)
    }

    private static func runAppleScript(_ script: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            throw TerminalError.scriptFailed(process.terminationStatus)
        }
    }
}

enum TerminalError: Error {
    case scriptFailed(Int32)
    case notInstalled(String)
    case openFailed(Error)
}
