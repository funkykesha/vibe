import Foundation

enum LogLevel: String, Codable {
    case info = "INFO"
    case error = "ERROR"
}

struct LogEntry: Codable {
    let timestamp: String
    let level: LogLevel
    let component: String
    let event: String
    let details: [String: AnyCodable]

    enum CodingKeys: String, CodingKey {
        case timestamp, level, component, event, details
    }
}

enum AnyCodable: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else {
            self = .null
        }
    }
}

enum Logger {
    private static let logsDirectory: URL = {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/startwatch/logs")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private static let eventsFile: URL = {
        logsDirectory.appendingPathComponent("events.json")
    }()

    private static let logQueue = DispatchQueue.global(qos: .utility)

    static func log(
        level: LogLevel,
        component: String,
        event: String,
        details: [String: AnyCodable] = [:]
    ) {
        let formatter = ISO8601DateFormatter()
        let entry = LogEntry(
            timestamp: formatter.string(from: Date()),
            level: level,
            component: component,
            event: event,
            details: details
        )

        logQueue.async {
            appendLogEntry(entry)
        }
    }

    private static func appendLogEntry(_ entry: LogEntry) {
        guard let encoder = JSONEncoder() as? JSONEncoder else { return }
        encoder.outputFormatting = []

        guard let jsonData = try? encoder.encode(entry),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }

        let line = jsonString + "\n"
        guard let data = line.data(using: .utf8) else { return }

        if FileManager.default.fileExists(atPath: eventsFile.path),
           let handle = try? FileHandle(forWritingTo: eventsFile) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.close()
        } else {
            try? data.write(to: eventsFile, options: .atomic)
        }
    }
}
