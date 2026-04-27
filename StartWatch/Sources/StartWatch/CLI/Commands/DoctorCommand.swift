// StartWatch — DoctorCommand: самодиагностика StartWatch
import Foundation
import UserNotifications

enum DoctorCommand {
    static func run(args: [String]) {
        print("\(ANSIColors.bold)StartWatch Doctor\(ANSIColors.reset)\n")

        var allOk = true

        // 1. Config exists
        check("Config exists", &allOk) {
            FileManager.default.fileExists(atPath: ConfigManager.configURL.path)
        }

        // 2. Config is valid
        var config: AppConfig?
        check("Config is valid JSON", &allOk) {
            config = ConfigManager.load()
            return config != nil
        }

        if let cfg = config {
            let errors = ConfigManager.validate(cfg)
            check("Config has no errors", &allOk) { errors.isEmpty }
            if !errors.isEmpty {
                for e in errors {
                    print("     \(ANSIColors.dim)\(e)\(ANSIColors.reset)")
                }
            }
        }

        // 3. Daemon running
        check("Daemon is running", &allOk) {
            IPCClient.isConnected()
        }

        // 4. LaunchAgent installed
        let plistPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/com.user.startwatch.plist").path
        check("LaunchAgent installed", &allOk) {
            FileManager.default.fileExists(atPath: plistPath)
        }

        // 5. Terminal available
        if let cfg = config {
            let terminal = cfg.terminal ?? "warp"
            check("Terminal '\(terminal)' available", &allOk) {
                TerminalLauncher.isAvailable(terminal: terminal)
            }
        }

        // 6. Notification permission (requires .app bundle — only meaningful in daemon mode)
        if Bundle.main.bundleIdentifier != nil {
            check("Notification permission", &allOk) {
                let semaphore = DispatchSemaphore(value: 0)
                var granted = false
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    granted = settings.authorizationStatus == .authorized
                    semaphore.signal()
                }
                semaphore.wait()
                return granted
            }
        } else {
            print("  \(ANSIColors.yellow)⚠\(ANSIColors.reset) Notification permission (skip — no .app bundle in CLI mode)")
        }

        print()

        if let cfg = config {
            print("Services configured: \(cfg.services.count)")
            for svc in cfg.services {
                print("  • \(svc.name) [\(svc.check.type.rawValue):\(svc.check.value)]")
            }
        }

        print()
        exit(allOk ? 0 : 1)
    }

    private static func check(_ name: String, _ allOk: inout Bool, _ fn: () -> Bool) {
        let ok = fn()
        if !ok { allOk = false }
        let icon = ok
            ? "\(ANSIColors.green)✓\(ANSIColors.reset)"
            : "\(ANSIColors.red)✗\(ANSIColors.reset)"
        print("  \(icon) \(name)")
    }
}
