// StartWatch — ServiceRunner: запуск/рестарт shell-команд
import Foundation

enum ServiceRunner {
    // Выполнить команду, вывод идёт в stdout (интерактивный режим)
    static func exec(command: String, cwd: String? = nil) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        process.standardInput = FileHandle.standardInput
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError

        if let cwd = cwd {
            let expanded = (cwd as NSString).expandingTildeInPath
            process.currentDirectoryURL = URL(fileURLWithPath: expanded)
        }

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("\(ANSIColors.red)Failed to run: \(error.localizedDescription)\(ANSIColors.reset)")
        }
    }

    // Выполнить команду в фоне, вернуть exit code
    @discardableResult
    static func run(command: String, cwd: String? = nil, serviceName: String? = nil) -> Int32 {
        Logger.log(level: .info, component: "ServiceRunner", event: "SERVICE_START_ATTEMPT", details: ["command": .string(command), "serviceName": .string(serviceName ?? "")])

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError

        if let cwd = cwd {
            let expanded = (cwd as NSString).expandingTildeInPath
            process.currentDirectoryURL = URL(fileURLWithPath: expanded)
        }

        do {
            try process.run()
            process.waitUntilExit()
            let exitCode = process.terminationStatus
            if exitCode != 0 {
                Logger.log(level: .error, component: "ServiceRunner", event: "SERVICE_START_ERROR", details: ["exitCode": .int(Int(exitCode)), "serviceName": .string(serviceName ?? "")])
            }
            return exitCode
        } catch {
            Logger.log(level: .error, component: "ServiceRunner", event: "SERVICE_START_ERROR", details: ["error": .string(error.localizedDescription), "serviceName": .string(serviceName ?? "")])
            print("\(ANSIColors.red)Failed to run: \(error.localizedDescription)\(ANSIColors.reset)")
            return 1
        }
    }
}
