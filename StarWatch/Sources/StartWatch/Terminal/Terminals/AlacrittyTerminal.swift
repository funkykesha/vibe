// StartWatch — AlacrittyTerminal: открытие Alacritty через CLI
import Foundation

enum AlacrittyTerminal: TerminalApp {
    static let identifier = "alacritty"
    static let bundleID = "org.alacritty"

    static func open(command: String) throws {
        // Alacritty: alacritty -e zsh -c "cmd; exec zsh"
        let escaped = command.replacingOccurrences(of: "\"", with: "\\\"")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [
            "-a", "Alacritty",
            "--args", "-e", "zsh", "-c", "\(escaped); exec zsh"
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
