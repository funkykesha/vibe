// StartWatch — точка входа, роутинг daemon vs menu-agent vs CLI
import AppKit
import Foundation

enum LaunchMode: Equatable {
    case daemon([String])
    case menuAgent
    case cli([String])
    case appBundleDefault
}

// Логирование аргументов командной строки для отладки launchd
func logCommandLineArguments() {
    let homeDir = FileManager.default.homeDirectoryForCurrentUser
    let logDir = homeDir.appendingPathComponent(".startwatch")
    let logFile = logDir.appendingPathComponent("launch.log")
    
    // Создаём директорию, если её нет
    try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
    
    // Формируем строку лога
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let dateString = dateFormatter.string(from: Date())
    let pid = ProcessInfo.processInfo.processIdentifier
    let argv = CommandLine.arguments.joined(separator: " ")
    let argvArray = CommandLine.arguments.map { "\"\($0)\"" }.joined(separator: ", ")
    let logLine = "[\(dateString)] pid=\(pid) argv=[\(argv)] args=[\(argvArray)]\n"
    
    // Записываем в файл (добавляем в конец)
    if let handle = try? FileHandle(forWritingTo: logFile) {
        handle.seekToEndOfFile()
        handle.write(logLine.data(using: .utf8)!)
        handle.closeFile()
    } else {
        try? logLine.write(to: logFile, atomically: true, encoding: .utf8)
    }
}

logCommandLineArguments()

let args = Array(CommandLine.arguments.dropFirst())
let isAppBundle = Bundle.main.bundlePath.hasSuffix(".app")
let mode = resolveLaunchMode(arguments: args, isAppBundle: isAppBundle)

switch mode {
case .daemon(let daemonArgs):
    startApp(showMenu: !daemonArgs.contains("--no-menu"))
case .menuAgent:
    startApp(showMenu: true)
case .cli(let cliArgs):
    CLIRouter.route(arguments: cliArgs)
    exit(0)
case .appBundleDefault:
    // App bundle launch without explicit CLI command => full mode
    startApp(showMenu: true)
}

func resolveLaunchMode(arguments: [String], isAppBundle: Bool) -> LaunchMode {
    let command = arguments.first
    let cliCommands: Set<String> = [
    "status", "s",
    "check", "c",
    "start",
    "restart",
    "install",
    "uninstall",
    "config",
    "log",
    "doctor",
    "help", "-h", "--help",
    "version", "-v", "--version"
]

    if command == "daemon" {
        return .daemon(Array(arguments.dropFirst()))
    } else if command == "menu-agent" {
        return .menuAgent
    } else if let command, cliCommands.contains(command) {
        return .cli(arguments)
    } else if isAppBundle {
        return .appBundleDefault
    } else {
        return .cli(arguments)
    }
}

private func startApp(showMenu: Bool) {
    let coordinator = DaemonCoordinator()
    let outcome = coordinator.start(noMenu: !showMenu)
    switch resolveStartupAction(showMenu: showMenu, outcome: outcome) {
    case .ownerWithMenu:
            let control = LocalMenuControlPlane(coordinator: coordinator)
            MenuAgentCommand.run(delegate: MenuAgentDelegate(controlPlane: control))
    case .ownerHeadless:
        RunLoop.main.run()
    case .clientWithMenu:
        MenuAgentCommand.run(delegate: MenuAgentDelegate(controlPlane: RemoteMenuControlPlane()))
    case .duplicateHeadlessExit:
        exit(0)
    case .fatalExit:
        exit(1)
    }
}
