import Foundation
import Darwin

final class ClientConnection {
    typealias PayloadHandler = (_ payload: Data, _ framed: Bool) -> Void
    typealias DisconnectHandler = () -> Void

    private let fd: Int32
    private let onPayload: PayloadHandler
    private let onDisconnect: DisconnectHandler
    private var decoder = IPCFrameDecoder()
    private var didProcessFramedMessage = false
    private var isClosed = false

    init(fd: Int32, onPayload: @escaping PayloadHandler, onDisconnect: @escaping DisconnectHandler) {
        self.fd = fd
        self.onPayload = onPayload
        self.onDisconnect = onDisconnect
    }

    func start() {
        Thread.detachNewThread { [self] in
            readLoop()
        }
    }

    func send(_ data: Data) {
        guard !isClosed else { return }
        _ = data.withUnsafeBytes { Darwin.write(fd, $0.baseAddress, $0.count) }
    }

    private func readLoop() {
        defer { close() }

        while true {
            var buf = [UInt8](repeating: 0, count: 4096)
            let n = Darwin.read(fd, &buf, buf.count)
            Logger.log(level: .info, component: "ClientConnection", event: "SOCKET_READ", details: ["bytesRead": .int(n), "fd": .int(Int(fd))])

            guard n > 0 else {
                return
            }

            let chunk = Data(buf[..<n])
            do {
                let payloads = try decoder.append(chunk)
                if !payloads.isEmpty {
                    didProcessFramedMessage = true
                }

                for payload in payloads {
                    onPayload(payload, true)
                }
            } catch {
                Logger.log(level: .error, component: "ClientConnection", event: "FRAME_DECODE_FAILED", details: ["fd": .int(Int(fd))])
                return
            }

            if !didProcessFramedMessage {
                onPayload(chunk, false)
                return
            }
        }
    }

    func close() {
        guard !isClosed else { return }
        isClosed = true
        Darwin.close(fd)
        onDisconnect()
    }
}
