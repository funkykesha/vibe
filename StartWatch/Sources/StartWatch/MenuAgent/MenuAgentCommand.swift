// StartWatch — MenuAgentCommand: запуск menu bar UI как отдельного процесса
import AppKit

enum MenuAgentCommand {
    static func run() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let delegate = MenuAgentDelegate()
        app.delegate = delegate
        app.run()
    }
}
