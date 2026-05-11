// StartWatch — IPCMessage: протокол сообщений между CLI и daemon
import Foundation

struct TerminalCommand: Codable {
    let serviceName: String
    let command: String
}

enum IPCRequest: Codable {
    case triggerCheck
    case getStatus
    case startService(name: String)
    case stopService(name: String)
    case restartService(name: String)
    case quit

    private enum CodingKeys: String, CodingKey {
        case action
        case name
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let action = try container.decode(String.self, forKey: .action)
        switch action {
        case "trigger_check", "check_now":
            self = .triggerCheck
        case "get_status":
            self = .getStatus
        case "start_service":
            self = .startService(name: try container.decode(String.self, forKey: .name))
        case "stop_service":
            self = .stopService(name: try container.decode(String.self, forKey: .name))
        case "restart_service":
            self = .restartService(name: try container.decode(String.self, forKey: .name))
        case "quit":
            self = .quit
        default:
            throw DecodingError.dataCorruptedError(forKey: .action, in: container, debugDescription: "Unknown IPC action: \(action)")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .triggerCheck:
            try container.encode("trigger_check", forKey: .action)
        case .getStatus:
            try container.encode("get_status", forKey: .action)
        case .startService(let name):
            try container.encode("start_service", forKey: .action)
            try container.encode(name, forKey: .name)
        case .stopService(let name):
            try container.encode("stop_service", forKey: .action)
            try container.encode(name, forKey: .name)
        case .restartService(let name):
            try container.encode("restart_service", forKey: .action)
            try container.encode(name, forKey: .name)
        case .quit:
            try container.encode("quit", forKey: .action)
        }
    }
}

enum IPCResponse: Codable {
    case ok
    case executeInTerminal(TerminalCommand)
    case statusSnapshot([CodableCheckResult])
    case error(String)

    private enum CodingKeys: String, CodingKey {
        case action
        case message
        case command
        case services
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let action = try container.decode(String.self, forKey: .action)
        switch action {
        case "ok":
            self = .ok
        case "execute_in_terminal":
            self = .executeInTerminal(try container.decode(TerminalCommand.self, forKey: .command))
        case "status_snapshot":
            self = .statusSnapshot(try container.decode([CodableCheckResult].self, forKey: .services))
        case "error":
            self = .error(try container.decode(String.self, forKey: .message))
        default:
            throw DecodingError.dataCorruptedError(forKey: .action, in: container, debugDescription: "Unknown IPC response action: \(action)")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .ok:
            try container.encode("ok", forKey: .action)
        case .executeInTerminal(let cmd):
            try container.encode("execute_in_terminal", forKey: .action)
            try container.encode(cmd, forKey: .command)
        case .statusSnapshot(let services):
            try container.encode("status_snapshot", forKey: .action)
            try container.encode(services, forKey: .services)
        case .error(let message):
            try container.encode("error", forKey: .action)
            try container.encode(message, forKey: .message)
        }
    }
}

typealias IPCServiceResponse = IPCResponse
