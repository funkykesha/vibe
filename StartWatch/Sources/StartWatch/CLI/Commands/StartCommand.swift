// StartWatch — StartCommand: запуск конкретного сервиса
import Foundation

enum StartCommand {
    enum ExecutionPath: Equatable {
        case daemonIPC
        case interactiveShell
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

        guard let startCmd = service.start else {
            fputs("\(ANSIColors.yellow)No start command for '\(service.name)'\(ANSIColors.reset)\n", stderr)
            exit(1)
        }

        if executionPath(for: service) == .daemonIPC {
            print("\(ANSIColors.cyan)Starting \(service.name) in background...\((ANSIColors.reset))")
            guard let response = IPCClient.sendAndReceive(.startService(name: service.name)) else {
                fputs("\(ANSIColors.red)Failed to communicate with daemon\(ANSIColors.reset)\n", stderr)
                exit(1)
            }

            switch response {
            case .ok:
                print("\(ANSIColors.green)\(service.name) started successfully\(ANSIColors.reset)")
            case .executeInTerminal:
                fputs("\(ANSIColors.red)Unexpected terminal execution request for background service\(ANSIColors.reset)\n", stderr)
                exit(1)
            case .error(let message):
                fputs("\(ANSIColors.red)Failed to start \(service.name): \(message)\(ANSIColors.reset)\n", stderr)
                exit(1)
            }
        } else {
            print("\(ANSIColors.cyan)Starting \(service.name)...\(ANSIColors.reset)")
            print("\(ANSIColors.dim)$ \(startCmd)\(ANSIColors.reset)\n")
            ServiceRunner.exec(command: startCmd, cwd: service.cwd)
        }
    }

    static func executionPath(for service: ServiceConfig) -> ExecutionPath {
        service.background == true ? .daemonIPC : .interactiveShell
    }

    static func fuzzyMatch(name: String, in services: [ServiceConfig]) -> ServiceConfig? {
        let lower = name.lowercased()
        return services.first {
            $0.name.lowercased() == lower || $0.name.lowercased().contains(lower)
        }
    }
}
