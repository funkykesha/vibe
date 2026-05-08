// StartWatch — IPCMessage: протокол сообщений между CLI и daemon
import Foundation

enum IPCMessage: Codable {
    // Requests / commands
    case triggerCheck
    case getStatus
    case subscribe
    case startService(name: String)
    case stopService(name: String)
    case restartService(name: String)
    case restartAllFailed
    case quit

    // Responses / events
    case statusSnapshot(IPCStatusSnapshot)
    case serviceChanged(IPCServiceChange)
    case ok
    case error(String)
}

struct IPCStatusSnapshot: Codable {
    let services: [CodableCheckResult]
}

struct IPCServiceChange: Codable {
    let service: CodableCheckResult
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
