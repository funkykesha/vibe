// StartWatch — DaemonCommand: запуск headless daemon (без NSStatusItem)
import Foundation

enum DaemonCommand {
    static func run(args: [String]) {
        let noMenu = args.contains("--no-menu")
        let coordinator = DaemonCoordinator()
        coordinator.start(noMenu: noMenu)
        RunLoop.main.run()
    }
}
