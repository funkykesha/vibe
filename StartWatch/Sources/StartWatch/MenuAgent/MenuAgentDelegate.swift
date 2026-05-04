// StartWatch — MenuAgentDelegate: AppDelegate menu agent, владеет NSStatusItem + уведомления
import AppKit

final class MenuAgentDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBarController!
    private var pollTimer: Timer?
    private var previousFailedNames: Set<String> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBar = MenuBarController()

        NotificationManager.shared.requestAuthorization()
        NotificationManager.shared.onOpenReport = {
            guard let config = ConfigManager.load() else { return }
            TerminalLauncher.openCLI(config: config)
        }
        NotificationManager.shared.onRestartFailed = {
            guard let config = ConfigManager.load() else { return }
            let terminal = config.terminal ?? "terminal"
            TerminalLauncher.open(terminal: terminal, command: "startwatch restart all")
        }

        menuBar.onCheckNow = {
            MenuAgentIPC.send(action: "check_now")
        }

        menuBar.onOpenCLI = {
            guard let config = ConfigManager.load() else { return }
            TerminalLauncher.openCLI(config: config)
        }

        menuBar.onOpenConfig = {
            NSWorkspace.shared.open(ConfigManager.configURL)
        }

        menuBar.onStartService = { name in
            guard let response = IPCClient.sendAndReceive(.startService(name: name)) else { return }
            handleTerminalIntent(response)
        }
        menuBar.onStopService  = { name in IPCClient.send(.stopService(name: name)) }
        menuBar.onRestartService = { name in
            guard let response = IPCClient.sendAndReceive(.restartService(name: name)) else { return }
            handleTerminalIntent(response)
        }

        menuBar.onSetTerminal = { terminal in
            guard var config = ConfigManager.load() else { return }
            config = AppConfig(
                terminal: terminal,
                checkIntervalMinutes: config.checkIntervalMinutes,
                notifications: config.notifications,
                services: config.services
            )
            try? ConfigManager.save(config)
        }

        menuBar.onQuit = {
            Logger.log(level: .info, component: "MenuAgentDelegate", event: "QUIT_CLICKED", details: ["action": .string("Sending quit command via IPC")])
            IPCClient.send(.quit)
            Logger.log(level: .info, component: "MenuAgentDelegate", event: "QUIT_SENT", details: ["action": .string("Quit command sent, waiting for daemon to shutdown")])
            
            // Дать daemon время для graceful shutdown (1 секунда)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                NSApplication.shared.terminate(nil)
            }
        }

        if let config = ConfigManager.load() {
            menuBar.updateConfig(config)
        }

        startPolling()
    }

    // MARK: - Private

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.pollStatus()
        }
        if let t = pollTimer { RunLoop.main.add(t, forMode: .common) }
    }

    private func reschedulePolling(interval: TimeInterval) {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.pollStatus()
            self?.reschedulePollingBasedOnResults()
        }
        if let t = pollTimer { RunLoop.main.add(t, forMode: .common) }
    }

    private func reschedulePollingBasedOnResults() {
        let nextInterval: TimeInterval
        if let results = IPCClient.getLastResults(), results.contains(where: { $0.isStarting }) {
            nextInterval = 0.5
        } else {
            nextInterval = 3.0
        }
        reschedulePolling(interval: nextInterval)
    }

    private func pollStatus() {
        if let results = IPCClient.getLastResults() {
            menuBar.update(results: results)
            sendNotificationsIfNeeded(results: results)
        }
        if let config = ConfigManager.load() {
            menuBar.updateConfig(config)
        }
    }

    private func sendNotificationsIfNeeded(results: [CheckResult]) {
        guard let config = ConfigManager.load(),
              config.notifications?.enabled ?? true else { return }

        let currentFailedNames = Set(results.filter { !$0.isRunning }.map { $0.service.name })
        let newlyFailed = currentFailedNames.subtracting(previousFailedNames)

        if !newlyFailed.isEmpty {
            let failed = results.filter { newlyFailed.contains($0.service.name) }
            NotificationManager.shared.sendAlert(failedServices: failed, showDetails: config.notifications?.showFailureDetails ?? false, sound: config.notifications?.sound ?? false)
        }

        previousFailedNames = currentFailedNames
    }
}

private func handleTerminalIntent(_ response: IPCServiceResponse) {
    guard case .executeInTerminal(let cmd) = response else { return }
    DispatchQueue.main.async {
        guard let config = ConfigManager.load() else { return }
        let terminal = config.terminal ?? "terminal"
        TerminalLauncher.open(terminal: terminal, command: cmd.command)
    }
}

// MARK: - IPC helpers

enum MenuAgentIPC {
    static func send(action: String) {
        guard let data = try? JSONEncoder().encode(["action": action]) else { return }
        let url = StateManager.stateDir.appendingPathComponent("menu_command.json")
        try? data.write(to: url, options: .atomic)
    }
}
