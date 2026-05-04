// StartWatch — CLIRouter: парсинг аргументов и диспетчеризация команд
import Foundation

enum CLIRouter {
    static func route(arguments: [String]) {
        let command = arguments.first ?? "status"
        let rest = Array(arguments.dropFirst())

        switch command {
        case "status", "s":
            StatusCommand.run(args: rest)
        case "check", "c":
            CheckCommand.run(args: rest)
        case "start":
            StartCommand.run(args: rest)
        case "restart":
            RestartCommand.run(args: rest)
        case "list":
            ListCommand.run(args: rest)
        case "stop":
            StopCommand.run(args: rest)
        case "config":
            ConfigCommand.run(args: rest)
        case "log":
            LogCommand.run(args: rest)
        case "doctor":
            DoctorCommand.run(args: rest)
        case "help", "-h", "--help":
            printHelp()
        case "version", "-v", "--version":
            print("StartWatch 1.0.0")
        default:
            fputs("Unknown command: \(command)\n", stderr)
            printHelp()
            exit(1)
        }
    }

    static func printHelp() {
        print("""
        \(ANSIColors.bold)StartWatch\(ANSIColors.reset) — service monitor for macOS

        \(ANSIColors.bold)USAGE:\(ANSIColors.reset)
            startwatch <command> [options]

        \(ANSIColors.bold)COMMANDS:\(ANSIColors.reset)
            status, s          Show status of all services
            check, c           Run checks now and show results
            start <name>       Start a specific service
            restart <name|all> Restart a service or all failed
            list               List all configured services
            stop               Stop daemon and menu agent
            config             Open config in $EDITOR
            log                Show check history
            doctor             Diagnose StartWatch itself

        \(ANSIColors.bold)EXAMPLES:\(ANSIColors.reset)
            startwatch status              Show service status
            startwatch check               Run all checks
            startwatch restart all         Restart all failed (live table)
            startwatch restart Redis       Restart specific service
            startwatch list                List configured services
            startwatch stop                Stop StartWatch
            startwatch doctor --repair-ui  Repair signature + menubar cache
            startwatch daemon --no-menu    Run daemon without menu bar

        \(ANSIColors.bold)OPTIONS:\(ANSIColors.reset)
            --json             Output as JSON
            --tag <tag>        Filter by tag
            --no-color         Disable colors

        \(ANSIColors.bold)CONFIG:\(ANSIColors.reset)
            \(ConfigManager.configURL.path)
        """)
    }
}
