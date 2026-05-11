import Foundation

enum InstallCommand {
    private static let label = "com.user.startwatch"
    private static let legacyLabel = "com.startwatch.daemon"

    static func run(args: [String]) {
        let uid = String(getuid())
        let domain = "gui/\(uid)"
        let fm = FileManager.default
        let launchAgentsDir = fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents")
        let plistDestination = launchAgentsDir.appendingPathComponent("\(label).plist")
        let legacyPlistDestination = launchAgentsDir.appendingPathComponent("\(legacyLabel).plist")

        guard let binaryPath = detectDaemonBinaryPath() else {
            fputs("\(ANSIColors.red)Could not locate startwatch daemon binary\(ANSIColors.reset)\n", stderr)
            exit(1)
        }

        do {
            print("\(ANSIColors.dim)Writing LaunchAgent plist...\(ANSIColors.reset)")
            try fm.createDirectory(at: launchAgentsDir, withIntermediateDirectories: true)
            try launchAgentTemplate(binaryPath: binaryPath).write(to: plistDestination, atomically: true, encoding: .utf8)
        } catch {
            fputs("\(ANSIColors.red)Failed to write LaunchAgent plist: \(error.localizedDescription)\(ANSIColors.reset)\n", stderr)
            exit(1)
        }

        print("\(ANSIColors.dim)Cleaning legacy LaunchAgent artifacts...\(ANSIColors.reset)")
        _ = runProcess("/bin/launchctl", ["bootout", "\(domain)/\(legacyLabel)"])
        _ = runProcess("/bin/launchctl", ["bootout", domain, legacyPlistDestination.path])
        try? fm.removeItem(at: legacyPlistDestination)

        print("\(ANSIColors.dim)Reloading current LaunchAgent...\(ANSIColors.reset)")
        _ = runProcess("/bin/launchctl", ["bootout", "\(domain)/\(label)"])
        _ = runProcess("/bin/launchctl", ["bootout", domain, plistDestination.path])

        print("\(ANSIColors.dim)Bootstrapping launchd job \(label)...\(ANSIColors.reset)")
        let bootstrapStatus = runProcess("/bin/launchctl", ["bootstrap", domain, plistDestination.path])
        if bootstrapStatus != 0 {
            fputs("\(ANSIColors.red)Failed to bootstrap LaunchAgent \(label)\(ANSIColors.reset)\n", stderr)
            exit(1)
        }

        print("\(ANSIColors.dim)Kickstarting daemon process...\(ANSIColors.reset)")
        let kickstartStatus = runProcess("/bin/launchctl", ["kickstart", "-k", "\(domain)/\(label)"])
        if kickstartStatus != 0 {
            fputs("\(ANSIColors.red)Failed to kickstart daemon job \(label)\(ANSIColors.reset)\n", stderr)
            exit(1)
        }

        print("\(ANSIColors.green)Installed LaunchAgent and started daemon (\(label))\(ANSIColors.reset)")
    }

    private static func detectDaemonBinaryPath() -> String? {
        let cliBinary = "/usr/local/bin/startwatch"
        if FileManager.default.isExecutableFile(atPath: cliBinary) {
            return cliBinary
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["startwatch"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let value = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return value.isEmpty ? nil : value
        } catch {
            return nil
        }
    }

    private static func launchAgentTemplate(binaryPath: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(label)</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(binaryPath)</string>
                <string>daemon</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <dict>
                <key>SuccessfulExit</key>
                <false/>
            </dict>
            <key>ThrottleInterval</key>
            <integer>10</integer>
            <key>StandardOutPath</key>
            <string>\(home)/.local/state/startwatch/daemon.log</string>
            <key>StandardErrorPath</key>
            <string>\(home)/.local/state/startwatch/daemon-error.log</string>
            <key>EnvironmentVariables</key>
            <dict>
                <key>PATH</key>
                <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin</string>
            </dict>
        </dict>
        </plist>
        """
    }

    @discardableResult
    private static func runProcess(_ path: String, _ arguments: [String]) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus
        } catch {
            return -1
        }
    }
}
