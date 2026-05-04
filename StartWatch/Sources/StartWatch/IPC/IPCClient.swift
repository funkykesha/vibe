// StartWatch — IPCClient: CLI/menu-agent → daemon via Unix domain socket
import Foundation
import Darwin

enum IPCClient {
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
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        process.arguments = ["-f", "startwatch daemon"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
        return process.terminationStatus == 0
    }

    static func send(_ message: IPCMessage, allowBootstrap: Bool = true) {
        Logger.log(level: .info, component: "IPCClient", event: "SEND_MESSAGE", details: ["message": .string(String(describing: message))])
        guard let payload = payload(for: message),
              let data = try? JSONEncoder().encode(payload)
        else {
            Logger.log(level: .error, component: "IPCClient", event: "SEND_MESSAGE_FAILED", details: ["reason": .string("Failed to encode payload"), "message": .string(String(describing: message))])
            return
        }
        socketSend(data, allowBootstrap: allowBootstrap)
    }

    static func sendAndReceive(_ message: IPCMessage, allowBootstrap: Bool = true) -> IPCServiceResponse? {
        switch message {
        case .startService, .restartService:
            break
        default:
            return nil
        }

        Logger.log(level: .info, component: "IPCClient", event: "SEND_AND_RECEIVE", details: ["message": .string(String(describing: message))])
        guard let payload = payload(for: message),
              let data = try? JSONEncoder().encode(payload)
        else {
            Logger.log(level: .error, component: "IPCClient", event: "SEND_RECEIVE_FAILED", details: ["reason": .string("Failed to encode payload")])
            return nil
        }

        return socketSendAndReceive(data, allowBootstrap: allowBootstrap)
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

    private static func socketSend(_ data: Data, allowBootstrap: Bool) {
        let path = StateManager.socketURL.path
        Logger.log(level: .info, component: "IPCClient", event: "SOCKET_SEND_START", details: ["socketPath": .string(path)])
        if !FileManager.default.fileExists(atPath: path) {
            if allowBootstrap {
                _ = bootstrapViaMainApp()
            }

            var retries = 0
            while retries < 10 && !FileManager.default.fileExists(atPath: path) {
                usleep(200_000) // 200ms, up to 2s total
                retries += 1
            }

            guard FileManager.default.fileExists(atPath: path) else {
                Logger.log(level: .error, component: "IPCClient", event: "SOCKET_NOT_FOUND", details: ["socketPath": .string(path), "afterBootstrap": .bool(allowBootstrap)])
                return
            }
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

    private static func socketSendAndReceive(_ data: Data, allowBootstrap: Bool) -> IPCServiceResponse? {
        let path = StateManager.socketURL.path
        Logger.log(level: .info, component: "IPCClient", event: "SOCKET_SEND_RECV_START", details: ["socketPath": .string(path)])
        if !FileManager.default.fileExists(atPath: path) {
            if allowBootstrap {
                _ = bootstrapViaMainApp()
            }

            var retries = 0
            while retries < 10 && !FileManager.default.fileExists(atPath: path) {
                usleep(200_000)
                retries += 1
            }

            guard FileManager.default.fileExists(atPath: path) else {
                Logger.log(level: .error, component: "IPCClient", event: "SOCKET_NOT_FOUND", details: ["socketPath": .string(path)])
                return nil
            }
        }

        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else {
            Logger.log(level: .error, component: "IPCClient", event: "SOCKET_CREATE_FAILED", details: ["errno": .int(Int(errno))])
            return nil
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
            return nil
        }
        Logger.log(level: .info, component: "IPCClient", event: "SOCKET_CONNECTED", details: [:])

        let written = data.withUnsafeBytes { Darwin.write(fd, $0.baseAddress, $0.count) }
        Logger.log(level: .info, component: "IPCClient", event: "SOCKET_WRITE_COMPLETE", details: ["bytesWritten": .int(written), "dataSize": .int(data.count)])

        var reply = [UInt8](repeating: 0, count: 4096)
        let readBytes = Darwin.read(fd, &reply, reply.count)
        Logger.log(level: .info, component: "IPCClient", event: "SOCKET_READ_COMPLETE", details: ["bytesRead": .int(readBytes)])

        guard readBytes > 0 else {
            Logger.log(level: .error, component: "IPCClient", event: "SOCKET_READ_FAILED", details: ["reason": .string("No data read")])
            return nil
        }

        let responseData = Data(reply.prefix(readBytes))
        guard let response = try? JSONDecoder().decode(IPCServiceResponse.self, from: responseData) else {
            Logger.log(level: .error, component: "IPCClient", event: "SOCKET_DECODE_FAILED", details: ["dataSize": .int(responseData.count)])
            return nil
        }

        return response
    }

    @discardableResult
    private static func bootstrapViaMainApp() -> Bool {
        let appPath = detectMenuAppPath()
        Logger.log(level: .info, component: "IPCClient", event: "APP_BOOTSTRAP_START", details: ["appPath": .string(appPath)])

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-na", appPath, "--args", "menu-agent"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            let ok = process.terminationStatus == 0
            Logger.log(level: ok ? .info : .error, component: "IPCClient", event: "APP_BOOTSTRAP_DONE", details: ["status": .int(Int(process.terminationStatus))])
            return ok
        } catch {
            Logger.log(level: .error, component: "IPCClient", event: "APP_BOOTSTRAP_FAILED", details: ["error": .string(error.localizedDescription)])
            return false
        }
    }

    private static func detectMenuAppPath() -> String {
        let userPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications/StartWatchMenu.app").path
        if FileManager.default.fileExists(atPath: userPath) {
            return userPath
        }
        return "/Applications/StartWatchMenu.app"
    }
}
