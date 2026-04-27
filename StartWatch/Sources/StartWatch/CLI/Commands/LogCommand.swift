// StartWatch — LogCommand: просмотр истории проверок
import Foundation

enum LogCommand {
    static func run(args: [String]) {
        let logPath = StateManager.historyURL.path

        guard FileManager.default.fileExists(atPath: logPath) else {
            print("No history yet. Run: startwatch check")
            return
        }

        let lines = args.contains("--all") ? 1000 : 50

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tail")
        process.arguments = ["-n", "\(lines)", logPath]
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError
        try? process.run()
        process.waitUntilExit()
    }
}
