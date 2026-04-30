// StartWatch — LogCommand: просмотр истории проверок и событий
import Foundation

enum LogCommand {
    static func run(args: [String]) {
        let showEvents = args.contains("--events")

        if showEvents {
            showEventLogs(args: args)
        } else {
            showCheckHistory(args: args)
        }
    }

    private static func showCheckHistory(args: [String]) {
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

    private static func showEventLogs(args: [String]) {
        let eventsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/startwatch/logs/events.json")

        guard FileManager.default.fileExists(atPath: eventsPath.path) else {
            print("No event logs yet.")
            return
        }

        guard let content = try? String(contentsOf: eventsPath, encoding: .utf8) else {
            print("Failed to read event logs")
            return
        }

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        let serviceFilter = args.first(where: { $0.hasPrefix("--service=") })?.replacingOccurrences(of: "--service=", with: "")
        let levelFilter = args.first(where: { $0.hasPrefix("--level=") })?.replacingOccurrences(of: "--level=", with: "")
        let sinceFilter = args.first(where: { $0.hasPrefix("--since=") })?.replacingOccurrences(of: "--since=", with: "")

        var filtered = lines
        if let service = serviceFilter {
            filtered = filtered.filter { $0.contains("\"serviceName\":\"\(service)\"") }
        }
        if let level = levelFilter {
            filtered = filtered.filter { $0.contains("\"level\":\"\(level)\"") }
        }

        if let since = sinceFilter {
            filtered = filtered.filter { $0.contains("\"timestamp\":\"") && $0.contains("\"\(since)") }
        }

        let maxLines = args.contains("--all") ? 1000 : 50
        let recent = filtered.suffix(maxLines)

        for line in recent {
            if let data = line.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let timestamp = json["timestamp"] as? String,
               let component = json["component"] as? String,
               let event = json["event"] as? String {
                print("[\(timestamp)] \(component) \(event)")
            } else {
                print(line)
            }
        }
    }
}
