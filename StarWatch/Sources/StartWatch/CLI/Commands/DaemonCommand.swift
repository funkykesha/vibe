// StartWatch — DaemonCommand: запуск headless daemon (без NSStatusItem)
import Foundation

enum DaemonCommand {
    static func run() {
        let coordinator = DaemonCoordinator()
        coordinator.start()
        RunLoop.main.run()
    }
}
