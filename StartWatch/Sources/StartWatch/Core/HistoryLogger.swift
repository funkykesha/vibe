// StartWatch — HistoryLogger: аппенд результатов в лог-файл
import Foundation

enum HistoryLogger {
    static func log(_ results: [CheckResult]) {
        let formatter = ISO8601DateFormatter()
        var lines: [String] = []

        for result in results {
            let status = result.isRunning ? "UP" : "DOWN"
            let line = "[\(formatter.string(from: result.checkedAt))] \(status) \(result.service.name): \(result.detail)"
            lines.append(line)
        }

        let entry = lines.joined(separator: "\n") + "\n"
        guard let data = entry.data(using: .utf8) else { return }

        let url = StateManager.historyURL
        if FileManager.default.fileExists(atPath: url.path),
           let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.close()
        } else {
            try? data.write(to: url, options: .atomic)
        }
    }
}
