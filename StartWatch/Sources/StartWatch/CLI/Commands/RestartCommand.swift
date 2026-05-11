// StartWatch — RestartCommand: перезапуск одного или всех упавших сервисов с live выводом
import Foundation

enum RestartCommand {
    static func run(args: [String]) {
        let target = args.first ?? "all"

        guard let config = ConfigManager.load() else {
            fputs("\(ANSIColors.red)No config found\(ANSIColors.reset)\n", stderr)
            exit(1)
        }

        if target == "all" || target == "failed" {
            guard IPCClient.isConnected(),
                  let snapshot = IPCClient.getStatusSnapshot(allowBootstrap: false)
            else {
                let uid = String(getuid())
                fputs("\(ANSIColors.red)Daemon not running. Run: launchctl kickstart -k gui/\(uid)/com.user.startwatch\(ANSIColors.reset)\n", stderr)
                exit(1)
            }

            let statusByName = Dictionary(uniqueKeysWithValues: snapshot.map { ($0.serviceName, $0) })
            let targetServices: [ServiceConfig]
            if target == "failed" {
                targetServices = config.services.filter { service in
                    guard let current = statusByName[service.name] else { return false }
                    return !current.isRunning
                }
            } else {
                targetServices = config.services.filter { statusByName[$0.name] != nil }
            }

            if targetServices.isEmpty {
                let message = target == "failed"
                    ? "No failed services to restart."
                    : "No services available for restart."
                print("\(ANSIColors.green)\(message)\(ANSIColors.reset)")
                exit(0)
            }

            var failures = 0
            for service in targetServices {
                print("\(ANSIColors.cyan)Restarting \(service.name)...\(ANSIColors.reset)")
                guard let response = IPCClient.sendAndReceive(.restartService(name: service.name), allowBootstrap: false) else {
                    failures += 1
                    fputs("\(ANSIColors.red)Failed to restart \(service.name): \(IPCClient.daemonFailureDescription())\(ANSIColors.reset)\n", stderr)
                    continue
                }

                switch response {
                case .ok:
                    print("\(ANSIColors.green)\(service.name) restarted successfully\(ANSIColors.reset)")
                case .executeInTerminal(let cmd):
                    print("\(ANSIColors.yellow)\(service.name) requires terminal execution\(ANSIColors.reset)")
                    print("\(ANSIColors.dim)$ \(cmd.command)\(ANSIColors.reset)")
                    ServiceRunner.exec(command: cmd.command, cwd: service.cwd)
                case .error(let message):
                    failures += 1
                    fputs("\(ANSIColors.red)Failed to restart \(service.name): \(message)\(ANSIColors.reset)\n", stderr)
                case .statusSnapshot:
                    failures += 1
                    fputs("\(ANSIColors.red)Failed to restart \(service.name): unexpected status response\(ANSIColors.reset)\n", stderr)
                }
            }

            exit(Int32(failures))
        } else {
            guard let service = StartCommand.fuzzyMatch(name: target, in: config.services) else {
                fputs("\(ANSIColors.red)Service '\(target)' not found\(ANSIColors.reset)\n", stderr)
                fputs("Available: \(config.services.map(\.name).joined(separator: ", "))\n", stderr)
                exit(1)
            }

            print("\(ANSIColors.cyan)Restarting \(service.name)...\(ANSIColors.reset)")
            guard let response = IPCClient.sendAndReceive(.restartService(name: service.name), allowBootstrap: false) else {
                let uid = String(getuid())
                let reason = IPCClient.daemonFailureDescription()
                fputs("\(ANSIColors.red)Failed to restart \(service.name): \(reason). Run: startwatch install or launchctl kickstart -k gui/\(uid)/com.user.startwatch\(ANSIColors.reset)\n", stderr)
                exit(1)
            }

            switch response {
            case .ok:
                print("\(ANSIColors.green)\(service.name) restarted successfully\(ANSIColors.reset)")
            case .executeInTerminal(let cmd):
                print("\(ANSIColors.yellow)\(service.name) requires terminal execution\(ANSIColors.reset)")
                print("\(ANSIColors.dim)$ \(cmd.command)\(ANSIColors.reset)\n")
                ServiceRunner.exec(command: cmd.command, cwd: nil)
            case .error(let message):
                fputs("\(ANSIColors.red)Failed to restart \(service.name): \(message)\(ANSIColors.reset)\n", stderr)
                exit(1)
            case .statusSnapshot:
                fputs("\(ANSIColors.red)Failed to restart \(service.name): unexpected status response\(ANSIColors.reset)\n", stderr)
                exit(1)
            }
        }
    }
}
