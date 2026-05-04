// StartWatch — MenuAgentCommand: запуск menu bar UI как отдельного процесса
import AppKit

enum MenuAgentCommand {
    // NSApplication.delegate is not strongly retained, keep a strong ref for app lifetime.
    private static var retainedDelegate: MenuAgentDelegate?

    static func run() {
        if isAnotherMenuAgentRunning() {
            return
        }
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let delegate = MenuAgentDelegate()
        retainedDelegate = delegate
        app.delegate = delegate
        app.run()
    }

    private static func isAnotherMenuAgentRunning() -> Bool {
        let pid = getpid()
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        task.arguments = ["-f", "startwatch menu-agent"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        try? task.run()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        let pids = output
            .split(separator: "\n")
            .compactMap { Int32($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .filter { $0 != pid }
        return !pids.isEmpty
    }
}
