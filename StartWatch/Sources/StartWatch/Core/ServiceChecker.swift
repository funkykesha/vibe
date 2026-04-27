// StartWatch — ServiceChecker: 4 типа проверок сервисов
import Foundation
import Network

enum ServiceChecker {

    // MARK: - Public API

    static func checkAll(services: [ServiceConfig]) async -> [CheckResult] {
        await withTaskGroup(of: (Int, CheckResult).self) { group in
            for (index, service) in services.enumerated() {
                group.addTask {
                    let result = await check(service: service)
                    return (index, result)
                }
            }
            var indexed: [(Int, CheckResult)] = []
            for await pair in group {
                indexed.append(pair)
            }
            return indexed.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }

    static func check(service: ServiceConfig) async -> CheckResult {
        let timeout = service.check.timeout ?? 5
        switch service.check.type {
        case .process:
            return await checkProcess(service: service)
        case .port:
            return await checkPort(service: service, timeout: timeout)
        case .http:
            return await checkHTTP(service: service, timeout: timeout)
        case .command:
            return await checkCommand(service: service, timeout: timeout)
        }
    }

    // MARK: - Process check

    private static func checkProcess(service: ServiceConfig) async -> CheckResult {
        await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
            process.arguments = ["-x", service.check.value]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice

            do {
                try process.run()
                process.waitUntilExit()
                let running = process.terminationStatus == 0
                let detail = running
                    ? "Process '\(service.check.value)' found"
                    : "Process '\(service.check.value)' not found"
                continuation.resume(returning: CheckResult(service: service, isRunning: running, detail: detail))
            } catch {
                continuation.resume(returning: CheckResult(
                    service: service, isRunning: false,
                    detail: "pgrep error: \(error.localizedDescription)"
                ))
            }
        }
    }

    // MARK: - Port check

    private static func checkPort(service: ServiceConfig, timeout: Int) async -> CheckResult {
        let portStr = service.check.value
        guard let port = UInt16(portStr), let nwPort = NWEndpoint.Port(rawValue: port) else {
            return CheckResult(service: service, isRunning: false, detail: "Invalid port: \(portStr)")
        }

        return await withCheckedContinuation { continuation in
            var resumed = false
            let connection = NWConnection(
                host: "127.0.0.1",
                port: nwPort,
                using: .tcp
            )

            let queue = DispatchQueue(label: "startwatch.portcheck.\(portStr)")

            let timeoutWork = DispatchWorkItem {
                guard !resumed else { return }
                resumed = true
                connection.cancel()
                continuation.resume(returning: CheckResult(
                    service: service, isRunning: false,
                    detail: "Port \(portStr): connection timeout"
                ))
            }
            queue.asyncAfter(deadline: .now() + .seconds(timeout), execute: timeoutWork)

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    timeoutWork.cancel()
                    guard !resumed else { return }
                    resumed = true
                    connection.cancel()
                    continuation.resume(returning: CheckResult(
                        service: service, isRunning: true,
                        detail: "Port \(portStr) open"
                    ))
                case .failed(let error):
                    timeoutWork.cancel()
                    guard !resumed else { return }
                    resumed = true
                    continuation.resume(returning: CheckResult(
                        service: service, isRunning: false,
                        detail: "Port \(portStr): \(error.localizedDescription)"
                    ))
                case .cancelled:
                    // handled by timeout or ready
                    break
                default:
                    break
                }
            }
            connection.start(queue: queue)
        }
    }

    // MARK: - HTTP check

    private static func checkHTTP(service: ServiceConfig, timeout: Int) async -> CheckResult {
        guard let url = URL(string: service.check.value) else {
            return CheckResult(service: service, isRunning: false, detail: "Invalid URL: \(service.check.value)")
        }

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = TimeInterval(timeout)
        config.timeoutIntervalForResource = TimeInterval(timeout)
        let session = URLSession(configuration: config)

        do {
            let (_, response) = try await session.data(from: url)
            if let http = response as? HTTPURLResponse {
                let ok = (200..<300).contains(http.statusCode)
                return CheckResult(
                    service: service, isRunning: ok,
                    detail: "HTTP \(http.statusCode)"
                )
            }
            return CheckResult(service: service, isRunning: false, detail: "No HTTP response")
        } catch let urlError as URLError {
            return CheckResult(service: service, isRunning: false, detail: "HTTP error: \(urlError.localizedDescription)")
        } catch {
            return CheckResult(service: service, isRunning: false, detail: "HTTP error: \(error.localizedDescription)")
        }
    }

    // MARK: - Command check

    private static func checkCommand(service: ServiceConfig, timeout: Int) async -> CheckResult {
        await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", service.check.value]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice

            let queue = DispatchQueue(label: "startwatch.cmdcheck")
            var resumed = false

            let timeoutWork = DispatchWorkItem {
                guard !resumed else { return }
                resumed = true
                process.terminate()
                continuation.resume(returning: CheckResult(
                    service: service, isRunning: false,
                    detail: "Command timeout after \(timeout)s"
                ))
            }
            queue.asyncAfter(deadline: .now() + .seconds(timeout), execute: timeoutWork)

            do {
                try process.run()
            } catch {
                timeoutWork.cancel()
                guard !resumed else { return }
                resumed = true
                continuation.resume(returning: CheckResult(
                    service: service, isRunning: false,
                    detail: "Command error: \(error.localizedDescription)"
                ))
                return
            }

            queue.async {
                process.waitUntilExit()
                timeoutWork.cancel()
                guard !resumed else { return }
                resumed = true
                let ok = process.terminationStatus == 0
                continuation.resume(returning: CheckResult(
                    service: service, isRunning: ok,
                    detail: ok ? "Exit 0" : "Exit \(process.terminationStatus)"
                ))
            }
        }
    }
}
