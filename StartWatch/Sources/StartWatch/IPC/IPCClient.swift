// StartWatch — IPCClient: CLI/menu-agent → daemon via Unix domain socket
import Foundation
import Darwin

enum IPCClient {
    private static let transport: IPCTransport = UnixSocketTransport(socketURL: StateManager.socketURL)

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

    static func send(_ message: IPCMessage, allowBootstrap: Bool = false) {
        Logger.log(level: .info, component: "IPCClient", event: "SEND_MESSAGE", details: ["message": .string(String(describing: message))])
        guard let payload = payload(for: message),
              let json = try? JSONEncoder().encode(payload),
              let data = try? IPCFrameCodec.encode(json)
        else {
            Logger.log(level: .error, component: "IPCClient", event: "SEND_MESSAGE_FAILED", details: ["reason": .string("Failed to encode payload"), "message": .string(String(describing: message))])
            return
        }
        _ = transport.send(data, allowBootstrap: allowBootstrap)
    }

    static func sendAndReceive(_ message: IPCMessage, allowBootstrap: Bool = false) -> IPCServiceResponse? {
        switch message {
        case .startService, .restartService:
            break
        default:
            return nil
        }

        Logger.log(level: .info, component: "IPCClient", event: "SEND_AND_RECEIVE", details: ["message": .string(String(describing: message))])
        guard let payload = payload(for: message),
              let json = try? JSONEncoder().encode(payload),
              let data = try? IPCFrameCodec.encode(json)
        else {
            Logger.log(level: .error, component: "IPCClient", event: "SEND_RECEIVE_FAILED", details: ["reason": .string("Failed to encode payload")])
            return nil
        }

        guard let responseData = transport.sendAndReceive(data, allowBootstrap: allowBootstrap) else {
            return nil
        }

        // Prefer framed response, fallback to legacy raw JSON response for compatibility.
        if let framedResponse = decodeFramedResponse(responseData) {
            return framedResponse
        }
        return try? JSONDecoder().decode(IPCServiceResponse.self, from: responseData)
    }

    static func getStatusSnapshot(allowBootstrap: Bool = false) -> [CodableCheckResult]? {
        guard let payload = payload(for: .getStatus),
              let json = try? JSONEncoder().encode(payload),
              let data = try? IPCFrameCodec.encode(json),
              let responseData = transport.sendAndReceive(data, allowBootstrap: allowBootstrap)
        else {
            return nil
        }

        if let framedMessage = decodeFramedMessage(responseData),
           case .statusSnapshot(let snapshot) = framedMessage {
            return snapshot.services
        }
        return nil
    }

    static func subscribe(
        onMessage: @escaping (IPCMessage) -> Void,
        onDisconnect: @escaping () -> Void
    ) -> IPCEventSubscription? {
        let path = StateManager.socketURL.path
        guard FileManager.default.fileExists(atPath: path) else {
            return nil
        }

        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { return nil }

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
        guard connected == 0 else {
            Darwin.close(fd)
            return nil
        }

        let subscribePayload = ["action": "subscribe"]
        guard let json = try? JSONEncoder().encode(subscribePayload),
              let frame = try? IPCFrameCodec.encode(json)
        else {
            Darwin.close(fd)
            return nil
        }
        let written = frame.withUnsafeBytes { Darwin.write(fd, $0.baseAddress, $0.count) }
        guard written == frame.count else {
            Darwin.close(fd)
            return nil
        }

        let subscription = IPCEventSubscription(fd: fd, onMessage: onMessage, onDisconnect: onDisconnect)
        subscription.start()
        return subscription
    }

    // MARK: - Private

    private static func payload(for message: IPCMessage) -> [String: String]? {
        switch message {
        case .triggerCheck:               return ["action": "trigger_check"]
        case .getStatus:                  return ["action": "get_status"]
        case .subscribe:                  return ["action": "subscribe"]
        case .startService(let name):     return ["action": "start_service", "name": name]
        case .stopService(let name):      return ["action": "stop_service", "name": name]
        case .restartService(let name):   return ["action": "restart_service", "name": name]
        case .quit:                       return ["action": "quit"]
        default:                          return nil
        }
    }

    private static func decodeFramedResponse(_ data: Data) -> IPCServiceResponse? {
        var decoder = IPCFrameDecoder()
        guard let payload = try? decoder.append(data).first else {
            return nil
        }
        return try? JSONDecoder().decode(IPCServiceResponse.self, from: payload)
    }

    private static func decodeFramedMessage(_ data: Data) -> IPCMessage? {
        var decoder = IPCFrameDecoder()
        guard let payload = try? decoder.append(data).first else {
            return nil
        }
        return try? JSONDecoder().decode(IPCMessage.self, from: payload)
    }

}
