import Foundation
import Darwin

protocol IPCTransport {
    func send(_ data: Data, allowBootstrap: Bool) -> Bool
    func sendAndReceive(_ data: Data, allowBootstrap: Bool) -> Data?
}

final class UnixSocketTransport: IPCTransport {
    private let socketURL: URL

    init(socketURL: URL) {
        self.socketURL = socketURL
    }

    func send(_ data: Data, allowBootstrap: Bool) -> Bool {
        guard let fd = connect(allowBootstrap: allowBootstrap) else {
            return false
        }
        defer { Darwin.close(fd) }

        let written = data.withUnsafeBytes { Darwin.write(fd, $0.baseAddress, $0.count) }
        return written == data.count
    }

    func sendAndReceive(_ data: Data, allowBootstrap: Bool) -> Data? {
        guard let fd = connect(allowBootstrap: allowBootstrap) else {
            return nil
        }
        defer { Darwin.close(fd) }

        let written = data.withUnsafeBytes { Darwin.write(fd, $0.baseAddress, $0.count) }
        guard written == data.count else { return nil }

        var reply = [UInt8](repeating: 0, count: 4096)
        let readBytes = Darwin.read(fd, &reply, reply.count)
        guard readBytes > 0 else { return nil }
        return Data(reply.prefix(readBytes))
    }

    private func connect(allowBootstrap: Bool) -> Int32? {
        let path = socketURL.path
        if !FileManager.default.fileExists(atPath: path) {
            var retries = 0
            while retries < 10 && !FileManager.default.fileExists(atPath: path) {
                usleep(200_000)
                retries += 1
            }
            guard FileManager.default.fileExists(atPath: path) else {
                Logger.log(level: .error, component: "UnixSocketTransport", event: "SOCKET_NOT_FOUND", details: ["socketPath": .string(path), "afterBootstrap": .bool(allowBootstrap)])
                return nil
            }
        }

        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else {
            Logger.log(level: .error, component: "UnixSocketTransport", event: "SOCKET_CREATE_FAILED", details: ["errno": .int(Int(errno))])
            return nil
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
            Logger.log(level: .error, component: "UnixSocketTransport", event: "SOCKET_CONNECT_FAILED", details: ["errno": .int(Int(errno))])
            Darwin.close(fd)
            return nil
        }

        return fd
    }
}
