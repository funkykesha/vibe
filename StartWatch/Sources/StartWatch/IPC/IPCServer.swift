// StartWatch — IPCServer: Unix domain socket listener
import Foundation
import Darwin

final class IPCServer {
    enum StartResult: Equatable {
        case started
        case addressInUse
        case failed(Int32)
    }

    private var serverFD: Int32 = -1
    private let subscribersQueue = DispatchQueue(label: "com.startwatch.ipc.subscribers", attributes: .concurrent)
    private let connectionsQueue = DispatchQueue(label: "com.startwatch.ipc.connections", attributes: .concurrent)
    private var subscribers: Set<Int32> = []
    private var connections: [Int32: ClientConnection] = [:]

    var onTriggerCheck: (() -> Void)?
    var onStartService: ((String) -> IPCServiceResponse)?
    var onStopService: ((String) -> Void)?
    var onRestartService: ((String) -> IPCServiceResponse)?
    var onQuit: (() -> Void)?
    var onSubscribeSnapshot: (() -> [CodableCheckResult])?
    var onGetStatusSnapshot: (() -> [CodableCheckResult])?

    func start() -> StartResult {
        let path = StateManager.socketURL.path
        Logger.log(level: .info, component: "IPCServer", event: "START_SERVER", details: ["socketPath": .string(path)])

        serverFD = socket(AF_UNIX, SOCK_STREAM, 0)
        guard serverFD >= 0 else {
            Logger.log(level: .error, component: "IPCServer", event: "SOCKET_CREATE_FAILED", details: ["errno": .int(Int(errno))])
            return .failed(errno)
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
            let bindErrno = errno
            if bindErrno == EADDRINUSE {
                Logger.log(level: .info, component: "IPCServer", event: "SOCKET_ALREADY_IN_USE", details: ["errno": .int(Int(bindErrno))])
                Darwin.close(serverFD)
                serverFD = -1
                return .addressInUse
            }
            Logger.log(level: .error, component: "IPCServer", event: "SOCKET_BIND_FAILED", details: ["errno": .int(Int(bindErrno))])
            Darwin.close(serverFD)
            serverFD = -1
            return .failed(bindErrno)
        }
        guard Darwin.listen(serverFD, 5) == 0 else {
            let listenErrno = errno
            Logger.log(level: .error, component: "IPCServer", event: "SOCKET_LISTEN_FAILED", details: ["errno": .int(Int(listenErrno))])
            Darwin.close(serverFD)
            serverFD = -1
            return .failed(listenErrno)
        }
        Logger.log(level: .info, component: "IPCServer", event: "SERVER_STARTED", details: [:])

        Thread.detachNewThread { self.acceptLoop() }
        return .started
    }

    func stop() {
        guard serverFD >= 0 else { return }
        Darwin.close(serverFD)
        serverFD = -1
        let snapshot = connectionsQueue.sync { Array(connections.values) }
        for connection in snapshot {
            connection.close()
        }
        connectionsQueue.sync(flags: .barrier) {
            connections.removeAll()
        }
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
            registerConnection(clientFD)
        }
    }

    private func registerConnection(_ fd: Int32) {
        let connection = ClientConnection(
            fd: fd,
            onPayload: { [weak self] payload, framed in
                self?.process(payload: payload, fd: fd, framed: framed)
            },
            onDisconnect: { [weak self] in
                self?.removeConnection(fd)
                self?.removeSubscriber(fd)
                Logger.log(level: .info, component: "IPCServer", event: "SOCKET_CLOSED", details: ["fd": .int(Int(fd))])
            }
        )

        connectionsQueue.sync(flags: .barrier) {
            connections[fd] = connection
        }

        connection.start()
    }

    private func removeConnection(_ fd: Int32) {
        _ = connectionsQueue.sync(flags: .barrier) {
            connections.removeValue(forKey: fd)
        }
    }

    private func process(payload: Data, fd: Int32, framed: Bool) {
        guard let cmd = try? JSONDecoder().decode(IPCCommand.self, from: payload) else {
            Logger.log(level: .error, component: "IPCServer", event: "COMMAND_DECODE_FAILED", details: ["framed": .bool(framed)])
            return
        }

        Logger.log(level: .info, component: "IPCServer", event: "COMMAND_RECEIVED", details: ["action": .string(cmd.action), "name": cmd.name.map { AnyCodable.string($0) } ?? .null])

        if cmd.action == "subscribe" {
            addSubscriber(fd)
            let snapshot = IPCStatusSnapshot(services: onSubscribeSnapshot?() ?? [])
            send(message: .statusSnapshot(snapshot), fd: fd, framed: framed)
            return
        }

        if cmd.action == "get_status" {
            let snapshot = IPCStatusSnapshot(services: onGetStatusSnapshot?() ?? [])
            send(message: .statusSnapshot(snapshot), fd: fd, framed: framed)
            return
        }

        let response = DispatchQueue.main.sync { self.dispatch(cmd) } ?? .ok
        send(response: response, fd: fd, framed: framed)
    }

    private func send(response: IPCServiceResponse, fd: Int32, framed: Bool) {
        guard let payload = try? JSONEncoder().encode(response) else {
            return
        }

        let data: Data
        if framed, let framedPayload = try? IPCFrameCodec.encode(payload) {
            data = framedPayload
        } else {
            data = payload
        }

        send(data: data, fd: fd)
    }

    private func send(message: IPCMessage, fd: Int32, framed: Bool) {
        guard let payload = try? JSONEncoder().encode(message) else {
            return
        }

        let data: Data
        if framed, let framedPayload = try? IPCFrameCodec.encode(payload) {
            data = framedPayload
        } else {
            data = payload
        }

        send(data: data, fd: fd)
    }

    private func addSubscriber(_ fd: Int32) {
        _ = subscribersQueue.sync(flags: .barrier) {
            subscribers.insert(fd)
        }
    }

    private func removeSubscriber(_ fd: Int32) {
        _ = subscribersQueue.sync(flags: .barrier) {
            subscribers.remove(fd)
        }
    }

    func broadcastServiceChanged(_ service: CodableCheckResult) {
        let snapshot = subscribersQueue.sync { Array(subscribers) }
        guard !snapshot.isEmpty else { return }

        let message = IPCMessage.serviceChanged(IPCServiceChange(service: service))
        guard let payload = try? JSONEncoder().encode(message),
              let framed = try? IPCFrameCodec.encode(payload) else {
            return
        }

        var failed: [Int32] = []
        for fd in snapshot {
            let wrote = framed.withUnsafeBytes { Darwin.write(fd, $0.baseAddress, $0.count) }
            if wrote < 0 {
                failed.append(fd)
            }
        }

        if !failed.isEmpty {
            subscribersQueue.sync(flags: .barrier) {
                for fd in failed {
                    subscribers.remove(fd)
                }
            }
        }
    }

    private func send(data: Data, fd: Int32) {
        let connection = connectionsQueue.sync { connections[fd] }
        connection?.send(data)
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
