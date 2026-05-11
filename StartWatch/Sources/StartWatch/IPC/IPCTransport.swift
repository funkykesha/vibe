import Foundation
import Darwin

protocol IPCTransport {
    func send(_ data: Data, allowBootstrap: Bool) -> Bool
    func sendAndReceive(_ data: Data, allowBootstrap: Bool) -> Result<Data, IPCTransportError>
}

enum IPCTransportError: Error, Equatable {
    case offline
    case unresponsive
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

    func sendAndReceive(_ data: Data, allowBootstrap: Bool) -> Result<Data, IPCTransportError> {
        guard let fd = connect(allowBootstrap: allowBootstrap) else {
            return .failure(.offline)
        }
        defer { Darwin.close(fd) }

        let written = data.withUnsafeBytes { Darwin.write(fd, $0.baseAddress, $0.count) }
        guard written == data.count else { return .failure(.unresponsive) }
        _ = Darwin.shutdown(fd, SHUT_WR)

        var timeout = timeval(tv_sec: 5, tv_usec: 0)
        withUnsafePointer(to: &timeout) { ptr in
            _ = Darwin.setsockopt(
                fd,
                SOL_SOCKET,
                SO_RCVTIMEO,
                ptr,
                socklen_t(MemoryLayout<timeval>.size)
            )
        }

        var reply = Data()
        var chunk = [UInt8](repeating: 0, count: 4096)
        while true {
            let readBytes = Darwin.read(fd, &chunk, chunk.count)
            if readBytes > 0 {
                reply.append(contentsOf: chunk[..<readBytes])
                continue
            }
            break
        }
        guard !reply.isEmpty else { return .failure(.unresponsive) }
        return .success(reply)
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

        let flags = fcntl(fd, F_GETFL, 0)
        _ = fcntl(fd, F_SETFL, flags | O_NONBLOCK)

        let connected = withUnsafePointer(to: addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        if connected == 0 {
            _ = fcntl(fd, F_SETFL, flags)
            return fd
        }

        if errno != EINPROGRESS {
            Logger.log(level: .error, component: "UnixSocketTransport", event: "SOCKET_CONNECT_FAILED", details: ["errno": .int(Int(errno))])
            Darwin.close(fd)
            return nil
        }

        var pfd = pollfd(fd: fd, events: Int16(POLLOUT), revents: 0)
        let ready = Darwin.poll(&pfd, 1, 3000)
        guard ready > 0 else {
            Logger.log(level: .error, component: "UnixSocketTransport", event: "SOCKET_CONNECT_TIMEOUT", details: ["timeoutSec": .int(3)])
            Darwin.close(fd)
            return nil
        }

        var soError: Int32 = 0
        var soLen = socklen_t(MemoryLayout<Int32>.size)
        guard getsockopt(fd, SOL_SOCKET, SO_ERROR, &soError, &soLen) == 0, soError == 0 else {
            Logger.log(level: .error, component: "UnixSocketTransport", event: "SOCKET_CONNECT_FAILED", details: ["errno": .int(Int(soError))])
            Darwin.close(fd)
            return nil
        }

        _ = fcntl(fd, F_SETFL, flags)
        return fd
    }
}
