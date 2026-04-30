// StartWatch — WarpTerminal: открытие Warp через AppleScript (System Events)
import AppKit
import ApplicationServices

enum WarpTerminal: TerminalApp {
    static let identifier = "warp"
    static let bundleID = "dev.warp.Warp-Stable"

    static func open(command: String) throws {
        guard AXIsProcessTrusted() else {
            openWarpFallback()
            DispatchQueue.main.async { showAccessibilityAlert() }
            return
        }
        try runKeystroke(command: command)
    }

    private static func runKeystroke(command: String) throws {
        let escaped = command
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "Warp" to activate
        delay 0.8
        tell application "System Events"
            tell process "Warp"
                keystroke "\(escaped)"
                key code 36
            end tell
        end tell
        """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw TerminalError.openFailed(error)
        }
    }

    private static func openWarpFallback() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["warp://action/new_tab"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
    }

    private static func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Нужен доступ Accessibility"
        alert.informativeText = """
        Чтобы StartWatch мог вводить команды в Warp, нужно выдать разрешение:

        System Settings → Privacy & Security → Accessibility → добавить StartWatchMenu.app
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Открыть System Settings")
        alert.addButton(withTitle: "Закрыть")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
