// StartWatch — IPCMessage: протокол сообщений между CLI и daemon
import Foundation

enum IPCMessage: Codable {
    case triggerCheck
    case getStatus
    case startService(name: String)
    case stopService(name: String)
    case restartService(name: String)
    case restartAllFailed
    case quit
}

struct TerminalCommand: Codable {
    let serviceName: String
    let command: String
}

enum IPCServiceResponse: Codable {
    case ok
    case executeInTerminal(TerminalCommand)
    case error(String)
}
