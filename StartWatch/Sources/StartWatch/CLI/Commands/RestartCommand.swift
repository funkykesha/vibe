// StartWatch — RestartCommand: перезапуск одного или всех упавших сервисов
import Foundation

enum RestartCommand {
    static func run(args: [String]) {
        let target = args.first ?? "all"

        guard let config = ConfigManager.load() else {
            fputs("\(ANSIColors.red)No config found\(ANSIColors.reset)\n", stderr)
            exit(1)
        }

        if target == "all" || target == "failed" {
            print("\(ANSIColors.dim)Checking services...\(ANSIColors.reset)")
            let results = runSync {
                await ServiceChecker.checkAll(services: config.services)
            }

            let failed = results.filter { !$0.isRunning }
            if failed.isEmpty {
                print("\(ANSIColors.green)All services are running!\(ANSIColors.reset)")
                exit(0)
            }

            for result in failed {
                let cmd = result.service.restart ?? result.service.start
                guard let command = cmd else {
                    print("\(ANSIColors.yellow)⚠ \(result.service.name): no start/restart command\(ANSIColors.reset)")
                    continue
                }
                print("\(ANSIColors.cyan)🔄 Restarting \(result.service.name)\(ANSIColors.reset)")
                print("\(ANSIColors.dim)$ \(command)\(ANSIColors.reset)")
                ServiceRunner.run(command: command, cwd: result.service.cwd)
                print()
            }
        } else {
            StartCommand.run(args: args)
        }
    }
}
