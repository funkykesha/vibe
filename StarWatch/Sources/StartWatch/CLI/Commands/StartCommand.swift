// StartWatch — StartCommand: запуск конкретного сервиса
import Foundation

enum StartCommand {
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

        print("\(ANSIColors.cyan)Starting \(service.name)...\(ANSIColors.reset)")
        print("\(ANSIColors.dim)$ \(startCmd)\(ANSIColors.reset)\n")
        ServiceRunner.exec(command: startCmd, cwd: service.cwd)
    }

    static func fuzzyMatch(name: String, in services: [ServiceConfig]) -> ServiceConfig? {
        let lower = name.lowercased()
        return services.first {
            $0.name.lowercased() == lower || $0.name.lowercased().contains(lower)
        }
    }
}
