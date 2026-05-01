// StartWatch — StopCommand: отправка .quit команды для остановки daemon + menu agent
import Foundation

enum StopCommand {
    static func run(args: [String]) {
        IPCClient.send(.quit)
        print("\(ANSIColors.green)Stopping StartWatch...\(ANSIColors.reset)")
    }
}
