// StartWatch — DaemonCommand: запуск headless daemon (без NSStatusItem)
import Foundation

enum DaemonCommand {
    static let launchAgentLabels = ["com.user.startwatch", "com.startwatch.daemon"]

    static func run(args: [String]) {
        _ = args
        let runtime = DaemonRuntime()
        switch runtime.start() {
        case .started:
            RunLoop.main.run()
        case .alreadyRunning:
            exit(0)
        case .failed:
            exit(1)
        }
    }

    static func ensureDaemonRunning() {
        for label in launchAgentLabels {
            guard let output = launchAgentPrint(label: label) else { continue }
            if launchAgentIsRunning(output) { return }
            kickstart(label: label)
            return
        }
    }

    static func launchAgentIsRunning(_ output: String) -> Bool {
        output
            .split(separator: "\n")
            .contains { $0.trimmingCharacters(in: .whitespacesAndNewlines) == "state = running" }
    }

    private static func launchAgentPrint(label: String) -> String? {
        let uid = String(getuid())
        let domain = "gui/\(uid)"

        let printTask = Process()
        printTask.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        printTask.arguments = ["print", "\(domain)/\(label)"]
        let printPipe = Pipe()
        printTask.standardOutput = printPipe
        printTask.standardError = Pipe()
        try? printTask.run()
        printTask.waitUntilExit()
        guard printTask.terminationStatus == 0 else { return nil }

        let data = printPipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }

    private static func kickstart(label: String) {
        let uid = String(getuid())
        let domain = "gui/\(uid)"

        let kickstart = Process()
        kickstart.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        kickstart.arguments = ["kickstart", "-k", "\(domain)/\(label)"]
        kickstart.standardOutput = Pipe()
        kickstart.standardError = Pipe()
        _ = try? kickstart.run()
        kickstart.waitUntilExit()
    }
}
