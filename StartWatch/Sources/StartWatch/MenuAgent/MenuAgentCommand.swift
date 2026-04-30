// StartWatch — MenuAgentCommand: запуск menu bar UI как отдельного процесса
import AppKit

enum MenuAgentCommand {
    // NSApplication.delegate is not strongly retained, keep a strong ref for app lifetime.
    private static var retainedDelegate: MenuAgentDelegate?

    static func run() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let delegate = MenuAgentDelegate()
        retainedDelegate = delegate
        app.delegate = delegate
        app.run()
    }
}
