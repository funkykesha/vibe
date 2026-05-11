// StartWatch — MenuAgentDelegate: AppDelegate menu agent, владеет NSStatusItem + уведомления
import AppKit

final class MenuAgentDelegate: NSObject, NSApplicationDelegate {
    private let controlPlane: MenuControlPlane
    private var menuBar: MenuBarController!
    private var previousFailedNames: Set<String> = []
    private var pollTimer: Timer?
    private var latestByService: [String: CheckResult] = [:]
    private var offlineSince: Date?
    private var staleTimer: Timer?
    private var currentPollInterval: TimeInterval?

    init(controlPlane: MenuControlPlane = RemoteMenuControlPlane()) {
        self.controlPlane = controlPlane
    }

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
            self.controlPlane.triggerCheck()
            self.pollStatus()
        }

        menuBar.onOpenCLI = {
            guard let config = ConfigManager.load() else { return }
            TerminalLauncher.openCLI(config: config)
        }

        menuBar.onOpenConfig = {
            NSWorkspace.shared.open(ConfigManager.configURL)
        }

        menuBar.onStartService = { name in
            guard let response = self.controlPlane.startService(name: name) else { return }
            handleTerminalIntent(response)
            self.pollStatus()
        }
        menuBar.onStopService  = { name in
            self.controlPlane.stopService(name: name)
            self.pollStatus()
        }
        menuBar.onRestartService = { name in
            guard let response = self.controlPlane.restartService(name: name) else { return }
            handleTerminalIntent(response)
            self.pollStatus()
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

        menuBar.onStopDaemon = {
            Logger.log(level: .info, component: "MenuAgentDelegate", event: "STOP_DAEMON_CLICKED", details: ["action": .string("Requesting daemon quit via control plane")])
            self.controlPlane.requestQuit()
            self.pollStatus()
        }
        menuBar.onQuitMenu = {
            NSApplication.shared.terminate(nil)
        }
        menuBar.onStartDaemon = { [weak self] in
            self?.startDaemonViaLaunchctl()
        }

        if let config = ConfigManager.load() {
            menuBar.updateConfig(config)
        }

        startPolling()
    }

    // MARK: - Private

    private func startPolling() {
        pollStatus()
    }

    private func schedulePolling(interval: TimeInterval) {
        guard currentPollInterval != interval else { return }
        currentPollInterval = interval
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.pollStatus()
        }
        if let timer = pollTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func pollStatus() {
        if let snapshot = IPCClient.getStatusSnapshot(allowBootstrap: false) {
            schedulePolling(interval: 3)
            offlineSince = nil
            staleTimer?.invalidate()
            staleTimer = nil
            applySnapshot(snapshot)
            if let config = ConfigManager.load() {
                menuBar.updateConfig(config)
            }
            return
        }
        schedulePolling(interval: 5)
        handleDisconnected()
    }

    private func handleDisconnected() {
        if offlineSince == nil {
            offlineSince = Date()
            staleTimer?.invalidate()
            staleTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { [weak self] _ in
                self?.refreshOfflineStaleness()
            }
            if let timer = staleTimer {
                RunLoop.main.add(timer, forMode: .common)
            }
        }
        refreshOfflineStaleness()
    }

    private func refreshOfflineStaleness() {
        let ordered = orderedLatestResults()
        guard let seconds = deriveOfflineStaleSeconds() else {
            menuBar.showDaemonOffline(lastKnown: ordered, staleSeconds: nil)
            return
        }
        menuBar.showDaemonOffline(lastKnown: ordered, staleSeconds: seconds)
    }

    private func deriveOfflineStaleSeconds() -> Int? {
        let snapshot = StateManager.currentSnapshot()
        if !snapshot.services.isEmpty {
            return max(0, Int(Date().timeIntervalSince(snapshot.timestamp)))
        }

        let attrs = try? FileManager.default.attributesOfItem(atPath: StateManager.lastResultsURL.path)
        if let modified = attrs?[.modificationDate] as? Date {
            return max(0, Int(Date().timeIntervalSince(modified)))
        }

        guard let since = offlineSince else { return nil }
        return max(0, Int(Date().timeIntervalSince(since)))
    }

    private func applySnapshot(_ items: [CodableCheckResult]) {
        let results = mapToCheckResults(items)
        latestByService = Dictionary(uniqueKeysWithValues: results.map { ($0.service.name, $0) })
        menuBar.update(results: results)
        sendNotificationsIfNeeded(results: results)
    }

    private func mapToCheckResults(_ items: [CodableCheckResult]) -> [CheckResult] {
        guard let config = ConfigManager.load() else { return [] }
        let byName = Dictionary(uniqueKeysWithValues: items.map { ($0.serviceName, $0) })
        return config.services.compactMap { service in
            guard let item = byName[service.name] else { return nil }
            return CheckResult(
                service: service,
                isRunning: item.isRunning,
                detail: item.detail,
                checkedAt: item.checkedAt,
                isStarting: item.isStarting
            )
        }
    }

    private func orderedLatestResults() -> [CheckResult] {
        guard let config = ConfigManager.load() else { return Array(latestByService.values) }
        return config.services.compactMap { latestByService[$0.name] }
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

    private func startDaemonViaLaunchctl() {
        let uid = String(getuid())
        let domain = "gui/\(uid)"
        let label = "com.user.startwatch"

        let kickstartStatus = runProcess("/bin/launchctl", ["kickstart", "\(domain)/\(label)"])
        if kickstartStatus != 0 {
            Logger.log(level: .error, component: "MenuAgentDelegate", event: "DAEMON_KICKSTART_FAILED", details: ["status": .int(Int(kickstartStatus))])
        }
        pollStatus()
    }

    @discardableResult
    private func runProcess(_ path: String, _ arguments: [String]) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus
        } catch {
            Logger.log(level: .error, component: "MenuAgentDelegate", event: "PROCESS_RUN_FAILED", details: ["error": .string(error.localizedDescription)])
            return -1
        }
    }
}

protocol MenuControlPlane {
    func triggerCheck()
    func startService(name: String) -> IPCResponse?
    func stopService(name: String)
    func restartService(name: String) -> IPCResponse?
    func requestQuit()
}

struct RemoteMenuControlPlane: MenuControlPlane {
    func triggerCheck() {
        if IPCClient.isConnected() {
            IPCClient.send(.triggerCheck)
        }
    }

    func startService(name: String) -> IPCResponse? {
        IPCClient.sendAndReceive(.startService(name: name), allowBootstrap: false)
    }

    func stopService(name: String) {
        _ = IPCClient.sendAndReceive(.stopService(name: name), allowBootstrap: false)
    }

    func restartService(name: String) -> IPCResponse? {
        IPCClient.sendAndReceive(.restartService(name: name), allowBootstrap: false)
    }

    func requestQuit() {
        IPCClient.send(.quit)
    }
}

private func handleTerminalIntent(_ response: IPCResponse) {
    guard case .executeInTerminal(let cmd) = response else { return }
    DispatchQueue.main.async {
        guard let config = ConfigManager.load() else { return }
        let terminal = config.terminal ?? "terminal"
        TerminalLauncher.open(terminal: terminal, command: cmd.command)
    }
}
