// StartWatch — QuitCommand: graceful daemon quit, menu keeps running
import Foundation

enum QuitCommand {
    static func run(args: [String]) {
        IPCClient.send(.quit, allowBootstrap: false)
        print("\(ANSIColors.green)Requested daemon shutdown.\(ANSIColors.reset)")
    }
}
