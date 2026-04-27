// StartWatch — DaemonCoordinator: логика проверок, IPC (без UI, без уведомлений)
import Foundation

final class DaemonCoordinator {
    private var scheduler: CheckScheduler?
    private var ipcServer: IPCServer!
    private var config: AppConfig?
    private var menuAgentProcess: Process?

    func start() {
        ipcServer = IPCServer()
        loadConfig()

        let interval = TimeInterval((config?.checkIntervalMinutes ?? 180) * 60)
        scheduler = CheckScheduler(interval: interval) { [weak self] in
            self?.runCheck()
        }

        ipcServer.onTriggerCheck = { [weak self] in self?.runCheck() }
        ipcServer.start()

        spawnMenuAgent()

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

    private func spawnMenuAgent() {
        let binaryPath = ProcessInfo.processInfo.arguments[0]
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        process.arguments = ["menu-agent"]
        process.terminationHandler = { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self?.spawnMenuAgent()
            }
        }
        do {
            try process.run()
            menuAgentProcess = process
        } catch {
            print("[Daemon] Failed to spawn menu-agent: \(error)")
        }
    }
}
