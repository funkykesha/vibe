// StartWatch — StartCommand: запуск конкретного сервиса
import Foundation

enum StartCommand {
    enum ExecutionPath: Equatable {
        case daemonIPC
    }

    static func run(args: [String]) {
        guard let name = args.first else {
            fputs("Usage: startwatch start <service-name>\n", stderr)
            exit(1)
        }

        guard let config = ConfigManager.load() else {
            fputs("\(ANSIColors.red)No config found\(ANSIColors.reset)\n", stderr)
            exit(1)
        }

        guard let service = fuzzyMatch(name: name, in: config.services) else {
            fputs("\(ANSIColors.red)Service '\(name)' not found\(ANSIColors.reset)\n", stderr)
            fputs("Available: \(config.services.map(\.name).joined(separator: ", "))\n", stderr)
            exit(1)
        }

        print("\(ANSIColors.cyan)Starting \(service.name)...\(ANSIColors.reset)")
        guard let response = IPCClient.sendAndReceive(.startService(name: service.name), allowBootstrap: false) else {
            let uid = String(getuid())
            let reason = IPCClient.daemonFailureDescription()
            fputs("\(ANSIColors.red)Failed to start \(service.name): \(reason). Run: startwatch install or launchctl kickstart -k gui/\(uid)/com.user.startwatch\(ANSIColors.reset)\n", stderr)
            exit(1)
        }

        switch response {
        case .ok:
            print("\(ANSIColors.green)\(service.name) started successfully\(ANSIColors.reset)")
        case .executeInTerminal(let cmd):
            print("\(ANSIColors.yellow)\(service.name) requires terminal execution\(ANSIColors.reset)")
            print("\(ANSIColors.dim)$ \(cmd.command)\(ANSIColors.reset)\n")
            ServiceRunner.exec(command: cmd.command, cwd: nil)
        case .error(let message):
            fputs("\(ANSIColors.red)Failed to start \(service.name): \(message)\(ANSIColors.reset)\n", stderr)
            exit(1)
        case .statusSnapshot:
            fputs("\(ANSIColors.red)Failed to start \(service.name): unexpected status response\(ANSIColors.reset)\n", stderr)
            exit(1)
        }
    }

    static func executionPath(for service: ServiceConfig) -> ExecutionPath {
        .daemonIPC
    }

    static func fuzzyMatch(name: String, in services: [ServiceConfig]) -> ServiceConfig? {
        let lower = name.lowercased()
        return services.first {
            $0.name.lowercased() == lower || $0.name.lowercased().contains(lower)
        }
    }
}
