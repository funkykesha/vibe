// StartWatch — DaemonCommand: запуск headless daemon (без NSStatusItem)
import Foundation

enum DaemonCommand {
    static func run(args: [String]) {
        let noMenu = args.contains("--no-menu")
        let coordinator = DaemonCoordinator()
        coordinator.start(noMenu: noMenu)
        RunLoop.main.run()
    }

    static func ensureDaemonRunning() {
        let label = "com.user.startwatch"
        let uid = String(getuid())
        let domain = "gui/\(uid)"

        let printTask = Process()
        printTask.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        printTask.arguments = ["print", "\(domain)/\(label)"]
        let printPipe = Pipe()
        printTask.standardOutput = printPipe
        printTask.standardError = Pipe()
        try? printTask.run()
        printTask.waitUntilExit()
        if printTask.terminationStatus == 0 { return }

        let kickstart = Process()
        kickstart.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        kickstart.arguments = ["kickstart", "-k", "\(domain)/\(label)"]
        kickstart.standardOutput = Pipe()
        kickstart.standardError = Pipe()
        _ = try? kickstart.run()
        kickstart.waitUntilExit()
    }
}
