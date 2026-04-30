// StartWatch — IPCServer: Unix domain socket listener
import Foundation
import Darwin

final class IPCServer {
    private var serverFD: Int32 = -1

    var onTriggerCheck: (() -> Void)?
    var onStartService: ((String) -> Void)?
    var onStopService: ((String) -> Void)?
    var onRestartService: ((String) -> Void)?

    func start() {
        let path = StateManager.socketURL.path
        try? FileManager.default.removeItem(atPath: path)

        serverFD = socket(AF_UNIX, SOCK_STREAM, 0)
        guard serverFD >= 0 else { return }

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
        guard bound == 0 else { Darwin.close(serverFD); serverFD = -1; return }
        guard Darwin.listen(serverFD, 5) == 0 else { Darwin.close(serverFD); serverFD = -1; return }

        Thread.detachNewThread { self.acceptLoop() }
    }

    func stop() {
        guard serverFD >= 0 else { return }
        Darwin.close(serverFD)
        serverFD = -1
        try? FileManager.default.removeItem(at: StateManager.socketURL)
    }

    private func acceptLoop() {
        while true {
            let clientFD = Darwin.accept(serverFD, nil, nil)
            guard clientFD >= 0 else { break }
            Thread.detachNewThread { self.handle(clientFD) }
        }
    }

    private func handle(_ fd: Int32) {
        defer { Darwin.close(fd) }
        var buf = [UInt8](repeating: 0, count: 4096)
        let n = Darwin.read(fd, &buf, buf.count)
        guard n > 0,
              let cmd = try? JSONDecoder().decode(IPCCommand.self, from: Data(buf[..<n]))
        else { return }

        let ok = Data("{\"ok\":true}".utf8)
        _ = ok.withUnsafeBytes { Darwin.write(fd, $0.baseAddress, $0.count) }

        DispatchQueue.main.async { self.dispatch(cmd) }
    }

    private func dispatch(_ cmd: IPCCommand) {
        switch cmd.action {
        case "trigger_check", "check_now":
            onTriggerCheck?()
        case "start_service":
            if let n = cmd.name { onStartService?(n) }
        case "stop_service":
            if let n = cmd.name { onStopService?(n) }
        case "restart_service":
            if let n = cmd.name { onRestartService?(n) }
        case "quit":
            Logger.log(level: .info, component: "IPCServer", event: "QUIT_RECEIVED", details: ["action": .string("Received quit command, exiting process")])
            exit(0)
        default:
            break
        }
    }

    deinit { stop() }
}

private struct IPCCommand: Codable {
    let action: String
    let name: String?
}
