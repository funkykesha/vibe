// StartWatch — TerminalLauncher: роутер открытия терминалов
import AppKit

enum TerminalLauncher {

    static func openCLI(config: AppConfig) {
        let terminal = config.terminal ?? "terminal"
        open(terminal: terminal, command: "startwatch --help")
    }

    static func open(terminal: String, command: String) {
        do {
            switch terminal.lowercased() {
            case "warp":
                try WarpTerminal.open(command: command)
            case "iterm", "iterm2":
                try ITermTerminal.open(command: command)
            case "terminal", "apple":
                try AppleTerminal.open(command: command)
            case "alacritty":
                try AlacrittyTerminal.open(command: command)
            case "kitty":
                try KittyTerminal.open(command: command)
            default:
                // Custom .app path
                try openGeneric(appPath: terminal, command: command)
            }
        } catch {
            // Fallback → Terminal.app (always available)
            try? AppleTerminal.open(command: command)
        }
    }

    static func isAvailable(terminal: String) -> Bool {
        switch terminal.lowercased() {
        case "warp":              return WarpTerminal.isInstalled()
        case "iterm", "iterm2":  return ITermTerminal.isInstalled()
        case "terminal", "apple": return true
        case "alacritty":        return AlacrittyTerminal.isInstalled()
        case "kitty":            return KittyTerminal.isInstalled()
        default:                 return FileManager.default.fileExists(atPath: terminal)
        }
    }

    private static func openGeneric(appPath: String, command: String) throws {
        guard FileManager.default.fileExists(atPath: appPath) else {
            throw TerminalError.notInstalled(appPath)
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", appPath]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
    }
}
