// StartWatch — ITermTerminal: открытие iTerm2 через AppleScript
import Foundation

enum ITermTerminal: TerminalApp {
    static let identifier = "iterm"
    static let bundleID = "com.googlecode.iterm2"

    static func open(command: String) throws {
        let escaped = command
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "iTerm"
            activate
            create window with default profile command "zsh -c \\"\(escaped); exec zsh\\""
        end tell
        """
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
