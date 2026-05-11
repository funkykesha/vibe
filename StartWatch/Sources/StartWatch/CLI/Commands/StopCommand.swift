// StartWatch — StopCommand: stop single service via daemon IPC
import Foundation

enum StopCommand {
    static func run(args: [String]) {
        guard let name = args.first, !name.isEmpty else {
            fputs("\(ANSIColors.red)Usage: startwatch stop <service-name>. Did you mean 'startwatch quit'?\(ANSIColors.reset)\n", stderr)
            exit(1)
        }

        guard IPCClient.isConnected() else {
            let uid = String(getuid())
            fputs("\(ANSIColors.red)Daemon not running. Run: launchctl kickstart -k gui/\(uid)/com.user.startwatch\(ANSIColors.reset)\n", stderr)
            exit(1)
        }

        guard let response = IPCClient.sendAndReceive(.stopService(name: name), allowBootstrap: false) else {
            fputs("\(ANSIColors.red)Failed to stop '\(name)': \(IPCClient.daemonFailureDescription())\(ANSIColors.reset)\n", stderr)
            exit(1)
        }

        switch response {
        case .ok:
            print("\(ANSIColors.green)Requested stop for service '\(name)'.\(ANSIColors.reset)")
        case .error(let message):
            fputs("\(ANSIColors.red)Failed to stop '\(name)': \(message)\(ANSIColors.reset)\n", stderr)
            exit(1)
        case .executeInTerminal:
            fputs("\(ANSIColors.red)Unexpected terminal execution response for stop request\(ANSIColors.reset)\n", stderr)
            exit(1)
        case .statusSnapshot:
            fputs("\(ANSIColors.red)Failed to stop '\(name)': unexpected status response\(ANSIColors.reset)\n", stderr)
            exit(1)
        }
    }
}
