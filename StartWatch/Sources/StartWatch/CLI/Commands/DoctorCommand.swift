// StartWatch — DoctorCommand: самодиагностика StartWatch
import Foundation
import UserNotifications

enum DoctorCommand {
    static func run(args: [String]) {
        let shouldRepairSignature = args.contains("--repair-signature")
        let shouldRepairUI = args.contains("--repair-ui")

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

        // 6. Menu app bundle installed
        let menuAppPath = detectMenuAppPath()
        check("Menu app installed", &allOk) {
            FileManager.default.fileExists(atPath: menuAppPath)
        }

        // 7. Menu app signature valid (required by newer macOS for UI agent)
        check("Menu app signature valid", &allOk) {
            verifyCodeSignature(menuAppPath)
        }

        // 8. LaunchAgent binary path consistency
        let launchAgentProgram = launchAgentProgramPath(plistPath: plistPath)
        check("LaunchAgent binary path matches installed app", &allOk) {
            guard let launchAgentProgram else { return false }
            return launchAgentProgram == "\(menuAppPath)/Contents/MacOS/startwatch"
        }

        // 9. Notification permission (requires .app bundle — only meaningful in daemon mode)
        // Check if we're running in the menu app bundle context
        let isMenuAppBundle = Bundle.main.bundleIdentifier?.contains("startwatch.menu") ?? false
        if isMenuAppBundle {
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

        if shouldRepairSignature {
            let repaired = repairSignature(menuAppPath: menuAppPath)
            print("  \(repaired ? "\(ANSIColors.green)✓\(ANSIColors.reset)" : "\(ANSIColors.red)✗\(ANSIColors.reset)") Repair signature")
        }

        if shouldRepairUI {
            let repaired = repairUI(menuAppPath: menuAppPath)
            print("  \(repaired ? "\(ANSIColors.green)✓\(ANSIColors.reset)" : "\(ANSIColors.red)✗\(ANSIColors.reset)") Repair UI cache")
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

    private static func detectMenuAppPath() -> String {
        let userPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications/StartWatchMenu.app").path
        if FileManager.default.fileExists(atPath: userPath) {
            return userPath
        }
        return "/Applications/StartWatchMenu.app"
    }

    private static func verifyCodeSignature(_ menuAppPath: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        process.arguments = ["-vvv", menuAppPath]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    private static func launchAgentProgramPath(plistPath: String) -> String? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: plistPath)),
              let object = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let dict = object as? [String: Any],
              let programArgs = dict["ProgramArguments"] as? [String],
              let first = programArgs.first else {
            return nil
        }
        return first
    }

    private static func repairSignature(menuAppPath: String) -> Bool {
        runProcess("/usr/bin/codesign", ["--force", "--deep", "--sign", "-", menuAppPath]) == 0
    }

    private static func repairUI(menuAppPath: String) -> Bool {
        _ = runProcess("/usr/bin/pkill", ["-f", "startwatch"])
        let signed = repairSignature(menuAppPath: menuAppPath)
        _ = runProcess("/usr/bin/killall", ["SystemUIServer"])
        let opened = runProcess("/usr/bin/open", ["-na", menuAppPath, "--args", "menu-agent"]) == 0
        return signed && opened
    }

    @discardableResult
    private static func runProcess(_ path: String, _ arguments: [String]) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus
        } catch {
            return -1
        }
    }
}
