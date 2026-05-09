// StartWatch — MenuAgentDelegate: AppDelegate menu agent, владеет NSStatusItem + уведомления
import AppKit

final class MenuAgentDelegate: NSObject, NSApplicationDelegate {
    private let controlPlane: MenuControlPlane
    private var menuBar: MenuBarController!
    private var subscription: IPCEventSubscription?
    private var previousFailedNames: Set<String> = []
    private var reconnectDelay: TimeInterval = 2
    private let reconnectMaxDelay: TimeInterval = 60
    private var latestByService: [String: CheckResult] = [:]
    private var offlineSince: Date?
    private var staleTimer: Timer?

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
        }
        menuBar.onStopService  = { name in self.controlPlane.stopService(name: name) }
        menuBar.onRestartService = { name in
            guard let response = self.controlPlane.restartService(name: name) else { return }
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
            Logger.log(level: .info, component: "MenuAgentDelegate", event: "QUIT_CLICKED", details: ["action": .string("Requesting quit via control plane")])
            self.controlPlane.requestQuit()
            Logger.log(level: .info, component: "MenuAgentDelegate", event: "QUIT_SENT", details: ["action": .string("Quit requested, waiting for daemon shutdown")])
            
            // Дать daemon время для graceful shutdown (1 секунда)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                NSApplication.shared.terminate(nil)
            }
        }
        menuBar.onStartDaemon = { [weak self] in
            self?.startDaemonViaLaunchctl()
        }

        if let config = ConfigManager.load() {
            menuBar.updateConfig(config)
        }

        startSubscription()
    }

    // MARK: - Private

    private func startSubscription() {
        subscription?.close()
        subscription = IPCClient.subscribe(
            onMessage: { [weak self] message in
                DispatchQueue.main.async {
                    self?.handleIPCMessage(message)
                }
            },
            onDisconnect: { [weak self] in
                DispatchQueue.main.async {
                    self?.handleDisconnected()
                }
            }
        )

        if subscription == nil {
            handleDisconnected()
        } else {
            reconnectDelay = 2
            offlineSince = nil
            staleTimer?.invalidate()
            staleTimer = nil
        }
    }

    private func scheduleReconnect() {
        let delay = reconnectDelay
        reconnectDelay = min(reconnectDelay * 2, reconnectMaxDelay)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.startSubscription()
        }
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
        scheduleReconnect()
    }

    private func refreshOfflineStaleness() {
        let ordered = orderedLatestResults()
        guard let since = offlineSince else {
            menuBar.showDaemonOffline(lastKnown: ordered, staleSeconds: nil)
            return
        }
        let seconds = Int(Date().timeIntervalSince(since))
        menuBar.showDaemonOffline(lastKnown: ordered, staleSeconds: seconds)
    }

    private func handleIPCMessage(_ message: IPCMessage) {
        switch message {
        case .statusSnapshot(let snapshot):
            offlineSince = nil
            staleTimer?.invalidate()
            staleTimer = nil
            applySnapshot(snapshot.services)
        case .serviceChanged(let change):
            offlineSince = nil
            staleTimer?.invalidate()
            staleTimer = nil
            applyServiceChange(change.service)
        default:
            break
        }

        if let config = ConfigManager.load() {
            menuBar.updateConfig(config)
        }
    }

    private func applySnapshot(_ items: [CodableCheckResult]) {
        let results = mapToCheckResults(items)
        latestByService = Dictionary(uniqueKeysWithValues: results.map { ($0.service.name, $0) })
        menuBar.update(results: results)
        sendNotificationsIfNeeded(results: results)
    }

    private func applyServiceChange(_ item: CodableCheckResult) {
        guard let config = ConfigManager.load(),
              let service = config.services.first(where: { $0.name == item.serviceName })
        else { return }

        latestByService[item.serviceName] = CheckResult(
            service: service,
            isRunning: item.isRunning,
            detail: item.detail,
            checkedAt: item.checkedAt,
            isStarting: item.isStarting
        )
        let results = config.services.compactMap { latestByService[$0.name] }
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
        let plistPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist").path

        let kickstartStatus = runProcess("/bin/launchctl", ["kickstart", "-k", "\(domain)/\(label)"])
        if kickstartStatus == 0 { return }

        let bootstrapStatus = runProcess("/bin/launchctl", ["bootstrap", domain, plistPath])
        guard bootstrapStatus == 0 else {
            Logger.log(level: .error, component: "MenuAgentDelegate", event: "DAEMON_BOOTSTRAP_FAILED", details: [
                "status": .int(Int(bootstrapStatus)),
                "plistPath": .string(plistPath)
            ])
            return
        }

        let retryStatus = runProcess("/bin/launchctl", ["kickstart", "-k", "\(domain)/\(label)"])
        if retryStatus != 0 {
            Logger.log(level: .error, component: "MenuAgentDelegate", event: "DAEMON_KICKSTART_FAILED", details: ["status": .int(Int(retryStatus))])
        }
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
    func startService(name: String) -> IPCServiceResponse?
    func stopService(name: String)
    func restartService(name: String) -> IPCServiceResponse?
    func requestQuit()
}

enum QuitDispatchMode: Equatable {
    case local
    case remote
}

func resolveQuitDispatchMode(hasLocalCoordinator: Bool) -> QuitDispatchMode {
    hasLocalCoordinator ? .local : .remote
}

enum QuitDispatchAction: Equatable {
    case localShutdown
    case remoteIPC
}

func resolveQuitDispatchAction(hasLocalCoordinator: Bool) -> QuitDispatchAction {
    switch resolveQuitDispatchMode(hasLocalCoordinator: hasLocalCoordinator) {
    case .local:
        return .localShutdown
    case .remote:
        return .remoteIPC
    }
}

struct RemoteMenuControlPlane: MenuControlPlane {
    func triggerCheck() {
        if IPCClient.isConnected() {
            IPCClient.send(.triggerCheck)
        }
    }

    func startService(name: String) -> IPCServiceResponse? {
        IPCClient.sendAndReceive(.startService(name: name))
    }

    func stopService(name: String) {
        IPCClient.send(.stopService(name: name))
    }

    func restartService(name: String) -> IPCServiceResponse? {
        IPCClient.sendAndReceive(.restartService(name: name))
    }

    func requestQuit() {
        IPCClient.send(.quit)
    }
}

final class LocalMenuControlPlane: MenuControlPlane {
    let coordinator: DaemonCoordinator?

    init(coordinator: DaemonCoordinator?) {
        self.coordinator = coordinator
    }

    func triggerCheck() {
        if IPCClient.isConnected() {
            IPCClient.send(.triggerCheck)
        }
    }

    func startService(name: String) -> IPCServiceResponse? {
        IPCClient.sendAndReceive(.startService(name: name))
    }

    func stopService(name: String) {
        IPCClient.send(.stopService(name: name))
    }

    func restartService(name: String) -> IPCServiceResponse? {
        IPCClient.sendAndReceive(.restartService(name: name))
    }

    func requestQuit() {
        switch resolveQuitDispatchAction(hasLocalCoordinator: coordinator != nil) {
        case .localShutdown:
            coordinator?.shutdown()
        case .remoteIPC:
            IPCClient.send(.quit)
        }
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
