// StartWatch — Config: модели конфига и ConfigManager
import Foundation

// MARK: - Models

struct AppConfig: Codable {
    let terminal: String?
    let checkIntervalMinutes: Int?
    let notifications: NotificationsConfig?
    let services: [ServiceConfig]
}

struct NotificationsConfig: Codable {
    let enabled: Bool?
    let onlyOnFailure: Bool?
    let sound: Bool?
}

struct ServiceConfig: Codable {
    let name: String
    let check: CheckConfig
    let start: String?
    let restart: String?
    let cwd: String?
    let tags: [String]?
}

struct CheckConfig: Codable {
    let type: CheckType
    let value: String
    let timeout: Int?
}

enum CheckType: String, Codable {
    case process
    case port
    case http
    case command
}

// MARK: - ConfigManager

enum ConfigManager {
    static let configURL: URL = {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/startwatch")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("config.json")
    }()

    static func load() -> AppConfig? {
        guard let data = try? Data(contentsOf: configURL) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(AppConfig.self, from: data)
    }

    static func save(_ config: AppConfig) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: configURL, options: .atomic)
    }

    static func validate(_ config: AppConfig) -> [String] {
        var errors: [String] = []
        if config.services.isEmpty {
            errors.append("No services configured")
        }
        for svc in config.services {
            if svc.name.isEmpty {
                errors.append("Service has empty name")
            }
            if svc.check.value.isEmpty {
                errors.append("Service '\(svc.name)' has empty check value")
            }
        }
        return errors
    }

    static func createExample() {
        let example = """
        {
            "terminal": "warp",
            "checkIntervalMinutes": 180,
            "notifications": {
                "enabled": true,
                "onlyOnFailure": true,
                "sound": true
            },
            "services": [
                {
                    "name": "Redis",
                    "check": { "type": "port", "value": "6379", "timeout": 3 },
                    "start": "brew services start redis",
                    "restart": "brew services restart redis",
                    "tags": ["infra"]
                },
                {
                    "name": "Backend API",
                    "check": { "type": "http", "value": "http://localhost:3000/health", "timeout": 5 },
                    "start": "cd ~/projects/backend && npm start",
                    "cwd": "~/projects/backend",
                    "tags": ["app"]
                }
            ]
        }
        """
        try? example.write(to: configURL, atomically: true, encoding: .utf8)
    }
}
