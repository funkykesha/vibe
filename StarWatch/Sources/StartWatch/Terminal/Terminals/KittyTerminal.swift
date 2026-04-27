// StartWatch — KittyTerminal: открытие Kitty через CLI
import Foundation

enum KittyTerminal: TerminalApp {
    static let identifier = "kitty"
    static let bundleID = "net.kovidgoyal.kitty"

    static func open(command: String) throws {
        let escaped = command.replacingOccurrences(of: "\"", with: "\\\"")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [
            "-a", "kitty",
            "--args", "zsh", "-c", "\(escaped); exec zsh"
        ]
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
