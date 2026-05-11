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
            terminateWithEscalation(process)
            running.removeValue(forKey: name)
        }
    }

    @discardableResult
    func stop(service: ServiceConfig) -> Bool {
        Logger.log(level: .info, component: "ProcessManager", event: "SERVICE_STOP_ATTEMPT", details: ["serviceName": .string(service.name)])

        // 1) Explicit stop command wins.
        if let stopCommand = service.stop, !stopCommand.isEmpty {
            Logger.log(level: .info, component: "ProcessManager", event: "SERVICE_STOP_STRATEGY", details: ["serviceName": .string(service.name), "strategy": .string("explicit_command"), "command": .string(stopCommand)])
            let ok = run(shell: stopCommand, cwd: service.cwd) == 0
            if ok {
                Logger.log(level: .info, component: "ProcessManager", event: "SERVICE_STOP_SUCCESS", details: ["serviceName": .string(service.name), "strategy": .string("explicit_command")])
            }
            return ok
        }

        // 2) Managed process PID.
        if let process = running[service.name] {
            Logger.log(level: .info, component: "ProcessManager", event: "SERVICE_STOP_STRATEGY", details: ["serviceName": .string(service.name), "strategy": .string("managed_pid")])
            terminateWithEscalation(process)
            running.removeValue(forKey: service.name)
            Logger.log(level: .info, component: "ProcessManager", event: "SERVICE_STOP_SUCCESS", details: ["serviceName": .string(service.name), "strategy": .string("managed_pid")])
            return true
        }

        // 3) Discovered process/port fallback.
        Logger.log(level: .info, component: "ProcessManager", event: "SERVICE_STOP_STRATEGY", details: ["serviceName": .string(service.name), "strategy": .string("discovered_target")])
        let stopped = killExternalWithEscalation(service: service)
        if stopped {
            Logger.log(level: .info, component: "ProcessManager", event: "SERVICE_STOP_SUCCESS", details: ["serviceName": .string(service.name), "strategy": .string("discovered_target")])
        } else {
            Logger.log(level: .error, component: "ProcessManager", event: "SERVICE_STOP_NO_STOPPABLE_TARGET", details: ["serviceName": .string(service.name)])
        }
        return stopped
    }

    private func killExternalWithEscalation(service: ServiceConfig) -> Bool {
        let pids = discoverPIDs(for: service)
        guard !pids.isEmpty else { return false }

        Logger.log(level: .info, component: "ProcessManager", event: "SERVICE_STOP_DISCOVERED_TARGET", details: ["serviceName": .string(service.name), "checkType": .string(service.check.type.rawValue)])
        send(signal: SIGTERM, to: pids)

        Thread.sleep(forTimeInterval: 5.0)

        let survivors = pids.filter(isAlive(pid:))
        if !survivors.isEmpty {
            Logger.log(level: .info, component: "ProcessManager", event: "SERVICE_STOP_ESCALATE_SIGKILL", details: ["serviceName": .string(service.name), "pidCount": .int(survivors.count)])
            send(signal: SIGKILL, to: survivors)
        }

        return true
    }

    @discardableResult
    private func run(shell script: String, cwd: String? = nil) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", script]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        if let cwd = cwd {
            process.currentDirectoryURL = URL(fileURLWithPath: (cwd as NSString).expandingTildeInPath)
        }
        try? process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }

    private func shellEscape(_ s: String) -> String {
        "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private func terminateWithEscalation(_ process: Process) {
        process.terminate()
        let deadline = Date().addingTimeInterval(5)
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.1)
        }

        if process.isRunning {
            Logger.log(level: .info, component: "ProcessManager", event: "SERVICE_STOP_ESCALATE_SIGKILL", details: ["pid": .int(Int(process.processIdentifier))])
            _ = Darwin.kill(process.processIdentifier, SIGKILL)
        }
    }

    private func discoverPIDs(for service: ServiceConfig) -> [Int32] {
        let script: String
        switch service.check.type {
        case .process:
            script = "pgrep -f \(shellEscape(service.check.value)) || true"
        case .port:
            script = "lsof -ti tcp:\(service.check.value) || true"
        case .http:
            guard let url = URL(string: service.check.value), let port = url.port else {
                return []
            }
            script = "lsof -ti tcp:\(port) || true"
        case .command:
            return []
        }

        guard let output = capture(shell: script) else { return [] }
        return output
            .split(whereSeparator: \.isNewline)
            .compactMap { Int32($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
    }

    private func capture(shell script: String) -> String? {
        let process = Process()
        let out = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", script]
        process.standardOutput = out
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            let data = out.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }

    private func send(signal: Int32, to pids: [Int32]) {
        for pid in pids {
            _ = Darwin.kill(pid_t(pid), signal)
        }
    }

    private func isAlive(pid: Int32) -> Bool {
        Darwin.kill(pid_t(pid), 0) == 0
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
