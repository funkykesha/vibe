// StartWatch — точка входа, роутинг daemon vs menu-agent vs CLI
import Foundation

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
let command = args.first ?? "status"

// Определяем, запущены ли мы из app bundle
let isAppBundle = Bundle.main.bundlePath.hasSuffix(".app")
let cliCommands: Set<String> = [
    "status", "s",
    "check", "c",
    "start",
    "restart",
    "config",
    "log",
    "doctor",
    "help", "-h", "--help",
    "version", "-v", "--version"
]

if command == "daemon" {
    DaemonCommand.run()
} else if command == "menu-agent" {
    MenuAgentCommand.run()
} else if cliCommands.contains(command) {
    CLIRouter.route(arguments: args)
    exit(0)
} else if isAppBundle {
    // Если запущены из app bundle без явной команды, используем menu-agent
    MenuAgentCommand.run()
} else {
    CLIRouter.route(arguments: args)
    exit(0)
}
