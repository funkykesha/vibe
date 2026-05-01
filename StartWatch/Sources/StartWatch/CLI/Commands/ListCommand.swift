// StartWatch — ListCommand: вывод списка всех сервисов из конфига
import Foundation

enum ListCommand {
    static func run(args: [String]) {
        guard let config = ConfigManager.load() else {
            fputs("\(ANSIColors.red)No config found\(ANSIColors.reset)\n", stderr)
            exit(1)
        }

        print("\(ANSIColors.cyan)Configured services: (\(config.services.count))\(ANSIColors.reset)")
        for service in config.services {
            print("  \(ANSIColors.white)•\(ANSIColors.reset) \(service.name)")
        }
    }
}
