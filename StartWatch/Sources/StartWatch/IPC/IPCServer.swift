// StartWatch — IPCServer: Unix domain socket listener
import Foundation
import Darwin

final class IPCServer {
    private var serverFD: Int32 = -1

    var onTriggerCheck: (() -> Void)?
    var onStartService: ((String) -> IPCServiceResponse)?
    var onStopService: ((String) -> Void)?
    var onRestartService: ((String) -> IPCServiceResponse)?
    var onQuit: (() -> Void)?

    func start() {
        let path = StateManager.socketURL.path
        Logger.log(level: .info, component: "IPCServer", event: "START_SERVER", details: ["socketPath": .string(path)])
        try? FileManager.default.removeItem(atPath: path)

        serverFD = socket(AF_UNIX, SOCK_STREAM, 0)
        guard serverFD >= 0 else {
            Logger.log(level: .error, component: "IPCServer", event: "SOCKET_CREATE_FAILED", details: ["errno": .int(Int(errno))])
            return
        }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        path.withCString { src in
            withUnsafeMutableBytes(of: &addr.sun_path) { dst in
                dst.copyMemory(from: UnsafeRawBufferPointer(start: src, count: min(strlen(src) + 1, dst.count)))
            }
        }

        let bound = withUnsafePointer(to: addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(serverFD, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        guard bound == 0 else {
            Logger.log(level: .error, component: "IPCServer", event: "SOCKET_BIND_FAILED", details: ["errno": .int(Int(errno))])
            Darwin.close(serverFD); serverFD = -1; return
        }
        guard Darwin.listen(serverFD, 5) == 0 else {
            Logger.log(level: .error, component: "IPCServer", event: "SOCKET_LISTEN_FAILED", details: ["errno": .int(Int(errno))])
            Darwin.close(serverFD); serverFD = -1; return
        }
        Logger.log(level: .info, component: "IPCServer", event: "SERVER_STARTED", details: [:])

        Thread.detachNewThread { self.acceptLoop() }
    }

    func stop() {
        guard serverFD >= 0 else { return }
        Darwin.close(serverFD)
        serverFD = -1
        try? FileManager.default.removeItem(at: StateManager.socketURL)
    }

    private func acceptLoop() {
        Logger.log(level: .info, component: "IPCServer", event: "ACCEPT_LOOP_START", details: [:])
        while true {
            let clientFD = Darwin.accept(serverFD, nil, nil)
            Logger.log(level: .info, component: "IPCServer", event: "CLIENT_ACCEPTED", details: ["clientFD": .int(Int(clientFD))])
            guard clientFD >= 0 else {
                Logger.log(level: .error, component: "IPCServer", event: "ACCEPT_FAILED", details: ["errno": .int(Int(errno))])
                break
            }
            Thread.detachNewThread { self.handle(clientFD) }
        }
    }

    private func handle(_ fd: Int32) {
        defer {
            Logger.log(level: .info, component: "IPCServer", event: "SOCKET_CLOSED", details: [:])
            Darwin.close(fd)
        }
        var buf = [UInt8](repeating: 0, count: 4096)
        let n = Darwin.read(fd, &buf, buf.count)
        Logger.log(level: .info, component: "IPCServer", event: "SOCKET_READ", details: ["bytesRead": .int(n)])
        guard n > 0,
              let cmd = try? JSONDecoder().decode(IPCCommand.self, from: Data(buf[..<n]))
        else {
            Logger.log(level: .error, component: "IPCServer", event: "READ_FAILED", details: ["bytesRead": .int(n)])
            return
        }
        Logger.log(level: .info, component: "IPCServer", event: "COMMAND_RECEIVED", details: ["action": .string(cmd.action), "name": cmd.name.map { AnyCodable.string($0) } ?? .null])

        let response = DispatchQueue.main.sync { self.dispatch(cmd) }
        if let resp = response, let data = try? JSONEncoder().encode(resp) {
            _ = data.withUnsafeBytes { Darwin.write(fd, $0.baseAddress, $0.count) }
        } else {
            let ok = Data("{\"ok\":true}".utf8)
            _ = ok.withUnsafeBytes { Darwin.write(fd, $0.baseAddress, $0.count) }
        }
    }

    private func dispatch(_ cmd: IPCCommand) -> IPCServiceResponse? {
        switch cmd.action {
        case "trigger_check", "check_now":
            onTriggerCheck?()
        case "start_service":
            if let n = cmd.name { return onStartService?(n) }
            return .ok
        case "stop_service":
            if let n = cmd.name { onStopService?(n) }
        case "restart_service":
            if let n = cmd.name { return onRestartService?(n) }
            return .ok
        case "quit":
            Logger.log(level: .info, component: "IPCServer", event: "QUIT_RECEIVED", details: ["action": .string("Received quit command, calling onQuit callback")])
            onQuit?()
        default:
            break
        }
        return nil
    }

    deinit { stop() }
}

private struct IPCCommand: Codable {
    let action: String
    let name: String?
}
