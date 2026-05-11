// StartWatch — DoctorCommand: самодиагностика StartWatch
import Foundation
import UserNotifications
import CoreServices

enum DoctorCommand {
    private static let launchAgentLabel = "com.user.startwatch"
    private static let launchAgentPlistName = "com.user.startwatch.plist"
    private static let expectedMenuAppPath = "/Applications/StartWatchMenu.app"
    private static let expectedCLIBinaryPath = "/usr/local/bin/startwatch"

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

            let skippedAutostart = ConfigManager.skippedAutostartServices(config: cfg)
            check("Autostart services require background=true", &allOk) { skippedAutostart.isEmpty }
            if !skippedAutostart.isEmpty {
                for service in skippedAutostart {
                    print("     \(ANSIColors.dim)\(service.name): autostart skipped: requires background=true\(ANSIColors.reset)")
                }
            }
        }

        // 3. Daemon running
        check("Daemon is running", &allOk) {
            isLaunchAgentRunning(label: launchAgentLabel)
        }

        // 4. LaunchAgent installed
        let plistPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(launchAgentPlistName)").path
        check("LaunchAgent installed", &allOk) {
            FileManager.default.fileExists(atPath: plistPath)
        }

        // 4.1 CLI binary installed and is Mach-O
        check("CLI binary is installed at /usr/local/bin/startwatch", &allOk) {
            FileManager.default.isExecutableFile(atPath: expectedCLIBinaryPath)
        }
        check("CLI binary is Mach-O", &allOk) {
            isMachOBinary(atPath: expectedCLIBinaryPath)
        }

        // 5. Terminal available
        if let cfg = config {
            let terminal = cfg.terminal ?? "warp"
            check("Terminal '\(terminal)' available", &allOk) {
                TerminalLauncher.isAvailable(terminal: terminal)
            }
        }

        // 6. Menu app bundle installed
        let menuAppPath = expectedMenuAppPath
        check("Menu app installed", &allOk) {
            FileManager.default.fileExists(atPath: menuAppPath)
        }

        // 7. Menu app signature valid (required by newer macOS for UI agent)
        check("Menu app signature valid", &allOk) {
            verifyCodeSignature(menuAppPath)
        }

        // 8. LaunchAgent binary path consistency
        let launchAgentArgs = launchAgentProgramArguments(plistPath: plistPath)
        check("LaunchAgent ProgramArguments are '/usr/local/bin/startwatch daemon'", &allOk) {
            launchAgentArgs == [expectedCLIBinaryPath, "daemon"]
        }
        check("LaunchAgent has no --no-menu argument", &allOk) {
            !(launchAgentArgs?.contains("--no-menu") ?? false)
        }
        check("LaunchAgent RunAtLoad=true, KeepAlive.SuccessfulExit=false, ThrottleInterval=10", &allOk) {
            validateLaunchAgentLifecycleKeys(plistPath: plistPath)
        }

        check("State directory permissions are 0700", &allOk) {
            hasPOSIXMode(path: StateManager.stateDir.path, expected: 0o700)
        }
        check("Daemon socket permissions are 0600", &allOk) {
            hasPOSIXMode(path: StateManager.socketURL.path, expected: 0o600)
        }

        // 8.1 LaunchServices bundle ID resolution
        check("LaunchServices resolves com.user.startwatch.menu to /Applications/StartWatchMenu.app", &allOk) {
            launchServicesResolvesMenuApp()
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

    private static func launchAgentProgramArguments(plistPath: String) -> [String]? {
        guard let dict = launchAgentPlistDictionary(plistPath: plistPath),
              let programArgs = dict["ProgramArguments"] as? [String] else {
            return nil
        }
        return programArgs
    }

    private static func launchAgentPlistDictionary(plistPath: String) -> [String: Any]? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: plistPath)),
              let object = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let dict = object as? [String: Any] else {
            return nil
        }
        return dict
    }

    private static func validateLaunchAgentLifecycleKeys(plistPath: String) -> Bool {
        guard let dict = launchAgentPlistDictionary(plistPath: plistPath),
              let runAtLoad = dict["RunAtLoad"] as? Bool,
              let keepAlive = dict["KeepAlive"] as? [String: Any],
              let successfulExit = keepAlive["SuccessfulExit"] as? Bool,
              let throttleInterval = dict["ThrottleInterval"] as? Int else {
            return false
        }
        return runAtLoad == true && successfulExit == false && throttleInterval == 10
    }

    private static func launchServicesResolvesMenuApp() -> Bool {
        guard let urls = LSCopyApplicationURLsForBundleIdentifier("com.user.startwatch.menu" as CFString, nil)?
            .takeRetainedValue() as? [URL] else {
            return false
        }

        return urls.contains { url in
            url.standardizedFileURL.path == expectedMenuAppPath
        }
    }

    private static func hasPOSIXMode(path: String, expected: Int16) -> Bool {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let modeValue = attrs[.posixPermissions] as? NSNumber else {
            return false
        }
        return modeValue.int16Value == expected
    }

    private static func isMachOBinary(atPath path: String) -> Bool {
        guard let handle = FileHandle(forReadingAtPath: path) else { return false }
        defer { try? handle.close() }
        guard let bytes = try? handle.read(upToCount: 4), bytes.count == 4 else {
            return false
        }

        let magic = bytes.withUnsafeBytes { $0.load(as: UInt32.self) }
        switch magic {
        case 0xFEEDFACE, 0xFEEDFACF, 0xCEFAEDFE, 0xCFFAEDFE, 0xCAFEBABE, 0xBEBAFECA, 0xCAFED00D, 0x0DD0FECA:
            return true
        default:
            return false
        }
    }

    private static func isLaunchAgentRunning(label: String) -> Bool {
        let uid = String(getuid())
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["print", "gui/\(uid)/\(label)"]
        let out = Pipe()
        process.standardOutput = out
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return false }
            let data = out.fileHandleForReading.readDataToEndOfFile()
            let text = String(data: data, encoding: .utf8) ?? ""
            return text.contains("state = running")
        } catch {
            return false
        }
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
