// StartWatch — IPCClient: CLI/menu-agent → daemon via Unix domain socket
import Foundation
import Darwin

enum IPCClient {
    enum RequestFailure {
        case offline
        case unresponsive
    }

    private static let transport: IPCTransport = UnixSocketTransport(socketURL: StateManager.socketURL)
    private static let errorQueue = DispatchQueue(label: "com.startwatch.ipcclient.error")
    private static var _lastFailure: RequestFailure?

    static func lastFailure() -> RequestFailure? {
        errorQueue.sync { _lastFailure }
    }

    static func daemonFailureDescription() -> String {
        switch lastFailure() {
        case .offline:
            return "daemon offline"
        case .unresponsive:
            return "daemon unresponsive"
        case .none:
            return "daemon did not respond"
        }
    }

    private static func setFailure(_ failure: RequestFailure?) {
        errorQueue.sync { _lastFailure = failure }
    }

    static func getLastResults() -> [CheckResult]? {
        guard let config = ConfigManager.load() else { return nil }

        guard let cached = StateManager.loadLastResults() else {
            return config.services.map { service in
                CheckResult(
                    service: service,
                    isRunning: false,
                    detail: "unknown",
                    checkedAt: Date.distantPast
                )
            }
        }

        if let first = cached.first,
           Date().timeIntervalSince(first.checkedAt) > 4 * 3600 {
            return config.services.map { service in
                CheckResult(
                    service: service,
                    isRunning: false,
                    detail: "unknown",
                    checkedAt: Date.distantPast
                )
            }
        }

        var results: [CheckResult] = []
        let cacheDict = Dictionary(uniqueKeysWithValues: cached.map { ($0.serviceName, $0) })

        for service in config.services {
            if let cachedItem = cacheDict[service.name] {
                results.append(CheckResult(
                    service: service,
                    isRunning: cachedItem.isRunning,
                    detail: cachedItem.detail,
                    checkedAt: cachedItem.checkedAt
                ))
            } else {
                results.append(CheckResult(
                    service: service,
                    isRunning: false,
                    detail: "unknown",
                    checkedAt: Date.distantPast
                ))
            }
        }

        return results
    }

    static func isConnected() -> Bool {
        let path = StateManager.socketURL.path
        guard FileManager.default.fileExists(atPath: path) else { return false }

        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { return false }
        defer { Darwin.close(fd) }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        path.withCString { src in
            withUnsafeMutableBytes(of: &addr.sun_path) { dst in
                dst.copyMemory(from: UnsafeRawBufferPointer(start: src, count: min(strlen(src) + 1, dst.count)))
            }
        }

        let connected = withUnsafePointer(to: addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        return connected == 0
    }

    static func send(_ message: IPCRequest, allowBootstrap: Bool = false) {
        Logger.log(level: .info, component: "IPCClient", event: "SEND_MESSAGE", details: ["message": .string(String(describing: message))])
        guard let data = try? JSONEncoder().encode(message)
        else {
            Logger.log(level: .error, component: "IPCClient", event: "SEND_MESSAGE_FAILED", details: ["reason": .string("Failed to encode payload"), "message": .string(String(describing: message))])
            return
        }
        _ = transport.send(data, allowBootstrap: allowBootstrap)
    }

    static func sendAndReceive(_ message: IPCRequest, allowBootstrap: Bool = false) -> IPCResponse? {
        switch message {
        case .startService, .stopService, .restartService:
            break
        default:
            return nil
        }

        Logger.log(level: .info, component: "IPCClient", event: "SEND_AND_RECEIVE", details: ["message": .string(String(describing: message))])
        guard let data = try? JSONEncoder().encode(message)
        else {
            Logger.log(level: .error, component: "IPCClient", event: "SEND_RECEIVE_FAILED", details: ["reason": .string("Failed to encode payload")])
            return nil
        }

        let responseResult = transport.sendAndReceive(data, allowBootstrap: allowBootstrap)
        let responseData: Data
        switch responseResult {
        case .success(let data):
            setFailure(nil)
            responseData = data
        case .failure(let error):
            setFailure(error == .offline ? .offline : .unresponsive)
            return nil
        }

        return try? JSONDecoder().decode(IPCResponse.self, from: responseData)
    }

    static func getStatusSnapshot(allowBootstrap: Bool = false) -> [CodableCheckResult]? {
        guard let data = try? JSONEncoder().encode(IPCRequest.getStatus)
        else {
            return nil
        }

        let responseResult = transport.sendAndReceive(data, allowBootstrap: allowBootstrap)
        let responseData: Data
        switch responseResult {
        case .success(let data):
            setFailure(nil)
            responseData = data
        case .failure(let error):
            setFailure(error == .offline ? .offline : .unresponsive)
            return nil
        }

        guard let response = try? JSONDecoder().decode(IPCResponse.self, from: responseData),
              case .statusSnapshot(let services) = response
        else { return nil }
        return services
    }

    static func subscribe(
        onMessage: @escaping (IPCResponse) -> Void,
        onDisconnect: @escaping () -> Void
    ) -> IPCEventSubscription? { nil }

}
