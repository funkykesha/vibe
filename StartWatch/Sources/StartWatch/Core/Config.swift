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
    let open: String?
    let autostart: Bool?
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
        Logger.log(level: .info, component: "ConfigManager", event: "CONFIG_LOAD_START", details: ["path": .string(configURL.path)])

        guard let data = try? Data(contentsOf: configURL) else {
            Logger.log(level: .error, component: "ConfigManager", event: "CONFIG_LOAD_ERROR", details: ["path": .string(configURL.path), "reason": .string("file not found or unreadable")])
            return nil
        }

        let decoder = JSONDecoder()
        guard let config = try? decoder.decode(AppConfig.self, from: data) else {
            Logger.log(level: .error, component: "ConfigManager", event: "CONFIG_PARSE_ERROR", details: ["reason": .string("JSON decode failed")])
            return nil
        }

        Logger.log(level: .info, component: "ConfigManager", event: "CONFIG_PARSE_SUCCESS", details: ["serviceCount": .int(config.services.count)])
        return config
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
            errors.append("No services configured. Add at least one service to the config.")
        }
        for svc in config.services {
            if svc.name.isEmpty {
                errors.append("Service has empty name. Example: {\"name\": \"My Service\", \"check\": {...}}")
            }
            if svc.check.value.isEmpty {
                let example = svc.check.type == .http ? "http://localhost:3000" : "service-name"
                errors.append("Service '\(svc.name)' has empty check value. Example: \"\(example)\"")
            }
        }

        if errors.isEmpty {
            Logger.log(level: .info, component: "ConfigManager", event: "CONFIG_VALIDATE_SUCCESS", details: ["serviceCount": .int(config.services.count)])
        } else {
            Logger.log(level: .error, component: "ConfigManager", event: "CONFIG_VALIDATE_ERROR", details: ["errorCount": .int(errors.count)])
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
                    "autostart": true,
                    "tags": ["infra"]
                },
                {
                    "name": "Backend API",
                    "check": { "type": "http", "value": "http://localhost:3000/health", "timeout": 5 },
                    "start": "cd ~/projects/backend && npm start",
                    "cwd": "~/projects/backend",
                    "autostart": true,
                    "tags": ["app"]
                }
            ]
        }
        """
        try? example.write(to: configURL, atomically: true, encoding: .utf8)
    }
}
