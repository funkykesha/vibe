// StartWatch — DaemonCoordinator: логика проверок, IPC (без UI, без уведомлений)
import Foundation

final class DaemonCoordinator {
    private var scheduler: CheckScheduler?
    private var ipcServer: IPCServer!
    private var config: AppConfig?
    private var processManager = ProcessManager()
    private var fileWatcher: FileWatcher?
    private let configQueue = DispatchQueue(label: "com.startwatch.config", attributes: .concurrent)

    func start() {
        let pid = getpid()
        let workingDir = FileManager.default.currentDirectoryPath
        Logger.log(level: .info, component: "DaemonCoordinator", event: "DAEMON_START", details: ["pid": .int(Int(pid)), "workingDir": .string(workingDir)])

        ipcServer = IPCServer()
        loadConfig()
        watchConfigFile()

        let interval = TimeInterval((config?.checkIntervalMinutes ?? 180) * 60)
        scheduler = CheckScheduler(interval: interval) { [weak self] in
            self?.runCheck()
        }

        ipcServer.onTriggerCheck = { [weak self] in self?.runCheck() }

        ipcServer.onStartService = { [weak self] name in
            guard let svc = self?.config?.services.first(where: { $0.name == name }) else { return }
            self?.processManager.start(service: svc)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self?.runCheck() }
        }
        ipcServer.onStopService = { [weak self] name in
            guard let svc = self?.config?.services.first(where: { $0.name == name }) else { return }
            self?.processManager.stop(service: svc)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self?.runCheck() }
        }
        ipcServer.onRestartService = { [weak self] name in
            guard let svc = self?.config?.services.first(where: { $0.name == name }) else { return }
            self?.processManager.restart(service: svc)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self?.runCheck() }
        }

        ipcServer.start()
        Logger.log(level: .info, component: "DaemonCoordinator", event: "MONITORING_START", details: ["serviceCount": .int(config?.services.count ?? 0)])

        spawnMenuAgentIfNeeded()

        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.spawnMenuAgentIfNeeded()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            self?.runCheck()
        }
    }

    // MARK: - Private

    private func loadConfig() {
        guard let newConfig = ConfigManager.load() else {
            print("[Daemon] Failed to load config")
            return
        }
        let errors = ConfigManager.validate(newConfig)
        if !errors.isEmpty {
            print("[Daemon] Config validation failed: \(errors.joined(separator: "; "))")
            return
        }
        config = newConfig
        Logger.log(level: .info, component: "DaemonCoordinator", event: "CONFIG_APPLY_SUCCESS", details: ["serviceCount": .int(newConfig.services.count)])
        print("[Daemon] Config loaded: \(newConfig.services.count) services configured")
    }

    private func reloadConfig() {
        guard let newConfig = ConfigManager.load() else {
            print("[Daemon] Failed to reload config")
            return
        }
        let errors = ConfigManager.validate(newConfig)
        if !errors.isEmpty {
            print("[Daemon] Config reload rejected: \(errors.joined(separator: "; "))")
            return
        }
        let oldCount = config?.services.count ?? 0
        let newCount = newConfig.services.count

        if oldCount != newCount {
            Logger.log(level: .info, component: "DaemonCoordinator", event: "CONFIG_CHANGE_DETECTED", details: ["oldServiceCount": .int(oldCount), "newServiceCount": .int(newCount)])
        }

        config = newConfig
        Logger.log(level: .info, component: "DaemonCoordinator", event: "CONFIG_APPLY_SUCCESS", details: ["serviceCount": .int(newConfig.services.count)])
        print("[Daemon] Config reloaded: \(newCount) services (was \(oldCount))")
        runCheck()
    }

    private func watchConfigFile() {
        let configPath = ConfigManager.configURL.path
        let logPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config/startwatch/fw.log")
        let logMsg = "[Daemon] watchConfigFile called, path: \(configPath)\n"
        if let data = logMsg.data(using: .utf8) {
            try? data.write(to: logPath, options: .atomic)
        }

        fileWatcher = FileWatcher(filePath: configPath)
        fileWatcher?.start { [weak self] in
            print("[Daemon] Config file changed, reloading...")
            self?.reloadConfig()
        }
    }

    private func runCheck() {
        guard let config = config else {
            loadConfig()
            return
        }

        Task {
            let results = await ServiceChecker.checkAll(services: config.services)

            await MainActor.run {
                StateManager.saveLastResults(results)
                HistoryLogger.log(results)
            }
        }
    }

    private func spawnMenuAgentIfNeeded() {
        guard !isMenuAgentRunning() else { return }

        let appPath = "/Applications/StartWatchMenu.app"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-na", appPath, "--args", "menu-agent"]
        do {
            try process.run()
        } catch {
            print("[Daemon] Failed to spawn menu-agent: \(error)")
        }
    }

    private func isMenuAgentRunning() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        task.arguments = ["-f", "startwatch menu-agent"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        try? task.run()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
