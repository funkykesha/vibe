// StartWatch — точка входа, роутинг daemon vs menu-agent vs CLI
import Foundation

let args = Array(CommandLine.arguments.dropFirst())
let command = args.first ?? "status"

if command == "daemon" {
    DaemonCommand.run()
} else if command == "menu-agent" {
    MenuAgentCommand.run()
} else {
    CLIRouter.route(arguments: args)
    exit(0)
}
