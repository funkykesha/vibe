// StartWatch — StateManager: персистенция состояния на диск
import Foundation

enum StateManager {
    static let stateDir: URL = {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/state/startwatch")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static let lastResultsURL = stateDir.appendingPathComponent("last_check.json")
    static let historyURL = stateDir.appendingPathComponent("history.log")
    static let socketURL = stateDir.appendingPathComponent("sock")

    static func saveLastResults(_ results: [CheckResult]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(results.map { $0.toCodable() }) else { return }
        try? data.write(to: lastResultsURL, options: .atomic)
    }

    static func saveCodableResults(_ results: [CodableCheckResult]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(results) else { return }
        try? data.write(to: lastResultsURL, options: .atomic)
    }

    static func loadLastResults() -> [CodableCheckResult]? {
        guard let data = try? Data(contentsOf: lastResultsURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode([CodableCheckResult].self, from: data)
    }
}
