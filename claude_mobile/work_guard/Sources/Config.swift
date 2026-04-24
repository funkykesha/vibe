import Foundation

struct Config: Codable {
    var workStart: String = "09:00"
    var workEnd: String = "19:00"
    var workDays: [Int] = [1, 2, 3, 4, 5]
    var notificationIntervalMin: Int = 5
    var overlayDelayMin: Int = 20
    var pauseUntil: String?
    var workApps: [String] = [
        "Xcode", "Visual Studio Code", "Cursor", "Terminal", "iTerm2", "Warp",
        "Safari", "Google Chrome", "Firefox", "Yandex", "Yandex Browser",
        "Mail", "Slack", "Zoom", "Telegram",
        "Notion", "Obsidian", "PyCharm", "IntelliJ IDEA",
        "Figma", "Postman", "TablePlus", "DataGrip",
        "Python", "python3", "zsh", "bash",
    ]

    enum CodingKeys: String, CodingKey {
        case workStart = "work_start"
        case workEnd = "work_end"
        case workDays = "work_days"
        case notificationIntervalMin = "notification_interval_min"
        case overlayDelayMin = "overlay_delay_min"
        case pauseUntil = "pause_until"
        case workApps = "work_apps"
    }

    static var configDir: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = paths[0]
        let workGuardDir = appSupport.appendingPathComponent("work_guard")
        return workGuardDir
    }

    static var configFile: URL {
        return configDir.appendingPathComponent("config.json")
    }

    static func load() -> Config {
        let decoder = JSONDecoder()
        let fm = FileManager.default

        do {
            try fm.createDirectory(at: configDir, withIntermediateDirectories: true)
        } catch {
            NSLog("Failed to create config dir: %@", error as NSError)
        }

        if fm.fileExists(atPath: configFile.path) {
            do {
                let data = try Data(contentsOf: configFile)
                var loaded = try decoder.decode(Config.self, from: data)
                // Merge with defaults
                if loaded.workApps.isEmpty {
                    loaded.workApps = Config().workApps
                }
                return loaded
            } catch {
                NSLog("Failed to load config: %@, using defaults", error as NSError)
            }
        }

        return Config()
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            try FileManager.default.createDirectory(at: Config.configDir, withIntermediateDirectories: true)
            let tmpFile = Config.configFile.deletingPathExtension().appendingPathExtension("json.tmp")
            let data = try encoder.encode(self)
            try data.write(to: tmpFile)

            if FileManager.default.fileExists(atPath: Config.configFile.path) {
                try FileManager.default.removeItem(at: Config.configFile)
            }
            try FileManager.default.moveItem(at: tmpFile, to: Config.configFile)
        } catch {
            NSLog("Failed to save config: %@", error as NSError)
        }
    }
}
