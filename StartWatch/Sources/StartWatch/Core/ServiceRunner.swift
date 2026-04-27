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
    static func run(command: String, cwd: String? = nil) -> Int32 {
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
            return process.terminationStatus
        } catch {
            print("\(ANSIColors.red)Failed to run: \(error.localizedDescription)\(ANSIColors.reset)")
            return 1
        }
    }
}
