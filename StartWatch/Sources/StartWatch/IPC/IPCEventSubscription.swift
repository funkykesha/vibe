import Foundation
import Darwin

final class IPCEventSubscription {
    private var fd: Int32
    private var decoder = IPCFrameDecoder()
    private let onMessage: (IPCResponse) -> Void
    private let onDisconnect: () -> Void
    private var isClosed = false

    init(fd: Int32, onMessage: @escaping (IPCResponse) -> Void, onDisconnect: @escaping () -> Void) {
        self.fd = fd
        self.onMessage = onMessage
        self.onDisconnect = onDisconnect
    }

    func start() {
        Thread.detachNewThread { [weak self] in
            self?.readLoop()
        }
    }

    func close() {
        guard !isClosed else { return }
        isClosed = true
        Darwin.close(fd)
        onDisconnect()
    }

    private func readLoop() {
        defer { close() }

        while true {
            var buf = [UInt8](repeating: 0, count: 4096)
            let n = Darwin.read(fd, &buf, buf.count)
            guard n > 0 else { return }

            do {
                let payloads = try decoder.append(Data(buf[..<n]))
                for payload in payloads {
                    if let message = try? JSONDecoder().decode(IPCResponse.self, from: payload) {
                        onMessage(message)
                    }
                }
            } catch {
                return
            }
        }
    }
}
