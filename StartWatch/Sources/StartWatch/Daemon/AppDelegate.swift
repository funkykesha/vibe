// StartWatch — DaemonCoordinator: логика проверок, IPC (без UI, без уведомлений)
import Foundation

final class DaemonCoordinator {
    private var scheduler: CheckScheduler?
    private var ipcServer: IPCServer!
    private var config: AppConfig?
    private var processManager = ProcessManager()

    func start() {
        ipcServer = IPCServer()
        loadConfig()

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
            self?.processManager.stop(name: name)
        }
        ipcServer.onRestartService = { [weak self] name in
            guard let svc = self?.config?.services.first(where: { $0.name == name }) else { return }
            self?.processManager.restart(service: svc)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self?.runCheck() }
        }

        ipcServer.start()

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
        config = ConfigManager.load()
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

        let appPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications/StartWatchMenu.app").path

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
