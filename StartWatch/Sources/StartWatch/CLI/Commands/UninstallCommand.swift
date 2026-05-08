import Foundation

enum UninstallCommand {
    private static let label = "com.startwatch.daemon"
    private static let legacyLabel = "com.user.startwatch"

    static func run(args: [String]) {
        let uid = String(getuid())
        let domain = "gui/\(uid)"
        let fm = FileManager.default
        let launchAgentsDir = fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents")
        let plistPath = launchAgentsDir.appendingPathComponent("\(label).plist")
        let legacyPlistPath = launchAgentsDir.appendingPathComponent("\(legacyLabel).plist")

        print("\(ANSIColors.dim)Stopping launchd job \(label)...\(ANSIColors.reset)")
        _ = runProcess("/bin/launchctl", ["bootout", "\(domain)/\(label)"])
        _ = runProcess("/bin/launchctl", ["bootout", domain, plistPath.path])
        print("\(ANSIColors.dim)Removing plist \(plistPath.path)...\(ANSIColors.reset)")
        try? fm.removeItem(at: plistPath)

        print("\(ANSIColors.dim)Cleaning legacy artifacts (\(legacyLabel))...\(ANSIColors.reset)")
        _ = runProcess("/bin/launchctl", ["bootout", "\(domain)/\(legacyLabel)"])
        _ = runProcess("/bin/launchctl", ["bootout", domain, legacyPlistPath.path])
        try? fm.removeItem(at: legacyPlistPath)

        print("\(ANSIColors.green)Uninstalled LaunchAgent (\(label)) and cleaned legacy artifacts\(ANSIColors.reset)")
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
