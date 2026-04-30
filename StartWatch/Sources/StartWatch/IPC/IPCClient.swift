// StartWatch — IPCClient: CLI/menu-agent → daemon via Unix domain socket
import Foundation
import Darwin

enum IPCClient {
    static func getLastResults() -> [CheckResult]? {
        guard let cached = StateManager.loadLastResults() else { return nil }

        if let first = cached.first,
           Date().timeIntervalSince(first.checkedAt) > 4 * 3600 {
            return nil
        }

        guard let config = ConfigManager.load() else { return nil }

        return cached.compactMap { item -> CheckResult? in
            guard let service = config.services.first(where: { $0.name == item.serviceName }) else {
                return nil
            }
            return CheckResult(
                service: service,
                isRunning: item.isRunning,
                detail: item.detail,
                checkedAt: item.checkedAt
            )
        }
    }

    static func isConnected() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        process.arguments = ["-f", "startwatch daemon"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
        return process.terminationStatus == 0
    }

    static func send(_ message: IPCMessage) {
        Logger.log(level: .info, component: "IPCClient", event: "SEND_MESSAGE", details: ["message": .string(String(describing: message))])
        guard let payload = payload(for: message),
              let data = try? JSONEncoder().encode(payload)
        else {
            Logger.log(level: .error, component: "IPCClient", event: "SEND_MESSAGE_FAILED", details: ["reason": .string("Failed to encode payload"), "message": .string(String(describing: message))])
            return
        }
        socketSend(data)
    }

    // MARK: - Private

    private static func payload(for message: IPCMessage) -> [String: String]? {
        switch message {
        case .triggerCheck:               return ["action": "trigger_check"]
        case .startService(let name):     return ["action": "start_service", "name": name]
        case .stopService(let name):      return ["action": "stop_service", "name": name]
        case .restartService(let name):   return ["action": "restart_service", "name": name]
        case .quit:                       return ["action": "quit"]
        default:                          return nil
        }
    }

    private static func socketSend(_ data: Data) {
        let path = StateManager.socketURL.path
        Logger.log(level: .info, component: "IPCClient", event: "SOCKET_SEND_START", details: ["socketPath": .string(path)])
        guard FileManager.default.fileExists(atPath: path) else {
            Logger.log(level: .error, component: "IPCClient", event: "SOCKET_NOT_FOUND", details: ["socketPath": .string(path)])
            return
        }

        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else {
            Logger.log(level: .error, component: "IPCClient", event: "SOCKET_CREATE_FAILED", details: ["errno": .int(Int(errno))])
            return
        }
        defer {
            Logger.log(level: .info, component: "IPCClient", event: "SOCKET_CLOSED", details: [:])
            Darwin.close(fd)
        }

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
            Logger.log(level: .error, component: "IPCClient", event: "SOCKET_CONNECT_FAILED", details: ["errno": .int(Int(errno))])
            return
        }
        Logger.log(level: .info, component: "IPCClient", event: "SOCKET_CONNECTED", details: [:])

        let written = data.withUnsafeBytes { Darwin.write(fd, $0.baseAddress, $0.count) }
        Logger.log(level: .info, component: "IPCClient", event: "SOCKET_WRITE_COMPLETE", details: ["bytesWritten": .int(written), "dataSize": .int(data.count)])

        var reply = [UInt8](repeating: 0, count: 64)
        let readBytes = Darwin.read(fd, &reply, reply.count)
        Logger.log(level: .info, component: "IPCClient", event: "SOCKET_READ_COMPLETE", details: ["bytesRead": .int(readBytes)])
    }
}
