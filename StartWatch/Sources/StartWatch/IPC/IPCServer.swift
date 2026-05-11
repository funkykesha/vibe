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
    private let connectionsQueue = DispatchQueue(label: "com.startwatch.ipc.connections", attributes: .concurrent)
    private var connections: [Int32: ClientConnection] = [:]

    var onTriggerCheck: (() -> Void)?
    var onStartService: ((String) -> IPCResponse)?
    var onStopService: ((String) -> IPCResponse)?
    var onRestartService: ((String) -> IPCResponse)?
    var onQuit: (() -> Void)?
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
        if chmod(path, 0o600) != 0 {
            Logger.log(level: .error, component: "IPCServer", event: "SOCKET_CHMOD_FAILED", details: ["errno": .int(Int(errno)), "socketPath": .string(path)])
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
                self?.process(payload: payload, fd: fd)
            },
            onDisconnect: { [weak self] in
                self?.removeConnection(fd)
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

    private func process(payload: Data, fd: Int32) {
        guard let cmd = try? JSONDecoder().decode(IPCRequest.self, from: payload) else {
            Logger.log(level: .error, component: "IPCServer", event: "COMMAND_DECODE_FAILED", details: [:])
            return
        }

        let response = DispatchQueue.main.sync { self.dispatch(cmd) } ?? .ok
        send(response: response, fd: fd)
    }

    private func send(response: IPCResponse, fd: Int32) {
        guard let payload = try? JSONEncoder().encode(response) else {
            return
        }
        send(data: payload, fd: fd)
    }

    private func send(data: Data, fd: Int32) {
        let connection = connectionsQueue.sync { connections[fd] }
        connection?.send(data)
    }

    private func dispatch(_ cmd: IPCRequest) -> IPCResponse? {
        switch cmd {
        case .triggerCheck:
            onTriggerCheck?()
        case .getStatus:
            return .statusSnapshot(onGetStatusSnapshot?() ?? [])
        case .startService(let name):
            return onStartService?(name) ?? .error("service handler unavailable")
        case .stopService(let name):
            return onStopService?(name) ?? .error("service handler unavailable")
        case .restartService(let name):
            return onRestartService?(name) ?? .error("service handler unavailable")
        case .quit:
            Logger.log(level: .info, component: "IPCServer", event: "QUIT_RECEIVED", details: ["action": .string("Received quit command, calling onQuit callback")])
            onQuit?()
        }
        return nil
    }

    deinit { stop() }
}
