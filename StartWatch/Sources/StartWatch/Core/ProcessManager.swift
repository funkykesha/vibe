import Foundation

final class ProcessManager {
    private var running: [String: Process] = [:]

    func start(service: ServiceConfig) {
        guard let cmd = service.start else { return }
        stop(name: service.name)

        Logger.log(level: .info, component: "ProcessManager", event: "SERVICE_START_ATTEMPT", details: ["serviceName": .string(service.name), "command": .string(cmd)])

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", cmd]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        if let cwd = service.cwd {
            process.currentDirectoryURL = URL(fileURLWithPath: (cwd as NSString).expandingTildeInPath)
        }

        process.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async { self?.running.removeValue(forKey: service.name) }
        }

        do {
            try process.run()
            running[service.name] = process
        } catch {
            Logger.log(level: .error, component: "ProcessManager", event: "SERVICE_START_ERROR", details: ["serviceName": .string(service.name), "error": .string(error.localizedDescription)])
            print("[ProcessManager] Failed to start \(service.name): \(error)")
        }
    }

    func stop(name: String) {
        if let process = running[name] {
            process.terminate()
            running.removeValue(forKey: name)
        }
    }

    func stop(service: ServiceConfig) {
        // Try managed process first
        if let process = running[service.name] {
            process.terminate()
            running.removeValue(forKey: service.name)
            return
        }
        // Fall back to kill by check type for externally-started processes
        killExternal(service: service)
    }

    private func killExternal(service: ServiceConfig) {
        let script: String
        switch service.check.type {
        case .process:
            script = "pkill -f \(shellEscape(service.check.value))"
        case .port:
            script = "lsof -ti tcp:\(service.check.value) | xargs kill -9 2>/dev/null || true"
        case .http:
            // Extract port from URL if possible, else no-op
            if let url = URL(string: service.check.value), let port = url.port {
                script = "lsof -ti tcp:\(port) | xargs kill -9 2>/dev/null || true"
            } else {
                return
            }
        case .command:
            return
        }
        run(shell: script)
    }

    private func run(shell script: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", script]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
    }

    private func shellEscape(_ s: String) -> String {
        "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    func restart(service: ServiceConfig) {
        Logger.log(level: .info, component: "ProcessManager", event: "SERVICE_RESTART_ATTEMPT", details: ["serviceName": .string(service.name)])
        stop(name: service.name)
        start(service: service)
        Logger.log(level: .info, component: "ProcessManager", event: "SERVICE_RESTART_SUCCESS", details: ["serviceName": .string(service.name)])
    }

    func isRunning(name: String) -> Bool {
        running[name]?.isRunning ?? false
    }
}
