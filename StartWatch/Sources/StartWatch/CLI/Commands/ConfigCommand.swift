// StartWatch — ConfigCommand: открытие и просмотр конфига
import Foundation

enum ConfigCommand {
    static func run(args: [String]) {
        let configPath = ConfigManager.configURL.path

        if !FileManager.default.fileExists(atPath: configPath) {
            ConfigManager.createExample()
            print("Created example config at: \(configPath)")
        }

        if args.contains("--path") {
            print(configPath)
            return
        }

        if args.contains("--show") {
            if let content = try? String(contentsOfFile: configPath) {
                print(content)
            }
            return
        }

        let editor = ProcessInfo.processInfo.environment["EDITOR"] ?? "nano"
        print("\(ANSIColors.dim)Opening in \(editor)...\(ANSIColors.reset)")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [editor, configPath]
        process.standardInput = FileHandle.standardInput
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError
        try? process.run()
        process.waitUntilExit()
    }
}
