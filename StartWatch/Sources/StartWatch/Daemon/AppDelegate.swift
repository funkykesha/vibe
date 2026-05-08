// StartWatch — DaemonCoordinator: логика проверок, IPC (без UI, без уведомлений)
import Foundation

final class DaemonCoordinator {
    enum StartOutcome: Equatable {
        case owner
        case nonOwner
        case failed
    }

    private var scheduler: CheckScheduler?
    private var ipcServer: IPCServer!
    private var _config: AppConfig?
    private var config: AppConfig? {
        get {
            configQueue.sync { _config }
        }
        set {
            configQueue.sync(flags: .barrier) {
                _config = newValue
            }
        }
    }
    private var processManager = ProcessManager()
    private var fileWatcher: FileWatcher?
    private let configQueue = DispatchQueue(label: "com.startwatch.config", attributes: .concurrent)
    private var workItems: [DispatchWorkItem] = []
    private let startTime = Date()
    private var termSignalSource: DispatchSourceSignal?
    private let shutdownQueue = DispatchQueue(label: "com.startwatch.shutdown")
    private var isShuttingDown = false
    private var lastBroadcastEffectiveState: [String: EffectiveServiceState] = [:]
    private var flushTimer: DispatchSourceTimer?

    func start(noMenu: Bool = false) -> StartOutcome {
        let pid = getpid()
        let workingDir = FileManager.default.currentDirectoryPath
        Logger.log(level: .info, component: "DaemonCoordinator", event: "DAEMON_START", details: ["pid": .int(Int(pid)), "workingDir": .string(workingDir), "noMenu": .bool(noMenu)])

        ipcServer = IPCServer()
        let ownership = acquireOwnership()
        guard ownership == .owner else {
            return ownership
        }
        setupSignalHandlers()
        loadConfig()
        StateManager.restoreFromCheckpoint()
        watchConfigFile()
        startAutostartServices()
        StateManager.setFlushInterval(seconds: nil)
        setupFlushTimer()

        let interval = TimeInterval((config?.checkIntervalMinutes ?? 180) * 60)
        scheduler = CheckScheduler(interval: interval) { [weak self] in
            self?.runCheck()
        }

        configureIPCHandlers()
        Logger.log(level: .info, component: "DaemonCoordinator", event: "MONITORING_START", details: ["serviceCount": .int(config?.services.count ?? 0)])

        Logger.log(level: .info, component: "DaemonCoordinator", event: "MENU_AGENT_DISABLED", details: ["reason": .string("daemon is headless owner; menu-agent launched by app bundle")])

        let initialCheckItem = DispatchWorkItem { [weak self] in
            self?.runCheck()
        }
        workItems.append(initialCheckItem)
        DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: initialCheckItem)
        return .owner
    }

    func shutdown() {
        let shouldContinue = shutdownQueue.sync { () -> Bool in
            if isShuttingDown { return false }
            isShuttingDown = true
            return true
        }
        guard shouldContinue else { return }

        Logger.log(level: .info, component: "DaemonCoordinator", event: "DAEMON_SHUTDOWN_START", details: [:])

        // Clear isStarting state from cache
        if let config = config {
            let clearingResults = config.services.map { service in
                CodableCheckResult(
                    serviceName: service.name,
                    isRunning: false,
                    detail: "stopped",
                    checkedAt: Date(),
                    isStarting: false
                )
            }
            StateManager.saveCodableResults(clearingResults)
        }

        // Stop all running services
        if let config = config {
            for service in config.services {
                processManager.stop(service: service)
            }
            Logger.log(level: .info, component: "DaemonCoordinator", event: "SERVICES_STOPPED", details: ["serviceCount": .int(config.services.count)])
        }

        // Stop scheduler
        scheduler = nil
        Logger.log(level: .info, component: "DaemonCoordinator", event: "SCHEDULER_STOPPED", details: [:])

        // Stop file watcher
        fileWatcher?.stop()
        fileWatcher = nil
        Logger.log(level: .info, component: "DaemonCoordinator", event: "FILE_WATCHER_STOPPED", details: [:])

        // Stop IPC server
        ipcServer.stop()
        Logger.log(level: .info, component: "DaemonCoordinator", event: "IPC_SERVER_STOPPED", details: [:])

        flushTimer?.cancel()
        flushTimer = nil
        StateManager.flushNow()

        // Cancel all pending dispatch queue operations
        for item in workItems {
            item.cancel()
        }
        workItems.removeAll()
        Logger.log(level: .info, component: "DaemonCoordinator", event: "DISPATCH_ITEMS_CANCELLED", details: [:])
        termSignalSource?.cancel()
        termSignalSource = nil

        Logger.log(level: .info, component: "DaemonCoordinator", event: "TIMERS_CANCELLED", details: [:])

        Logger.log(level: .info, component: "DaemonCoordinator", event: "DAEMON_SHUTDOWN_COMPLETE", details: [:])

        let uptime = Int(Date().timeIntervalSince(startTime))
        Logger.log(level: .info, component: "DaemonCoordinator", event: "DAEMON_STOP", details: ["uptime": .int(uptime), "reason": .string("user_request")])

        exit(0)
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
        fileWatcher = FileWatcher(configDirectoryURL: ConfigManager.configDirectoryURL) { [weak self] in
            print("[Daemon] Config file changed, reloading...")
            self?.reloadConfig()
        }
        do {
            try fileWatcher?.start()
        } catch {
            print("[Daemon] Failed to start config file watcher: \(error)")
        }
    }

    private func setupSignalHandlers() {
        signal(SIGTERM, SIG_IGN)
        let source = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        source.setEventHandler { [weak self] in
            self?.shutdown()
        }
        source.resume()
        termSignalSource = source
    }

    private func startAutostartServices() {
        guard let config = config else { return }
        for service in config.services where service.autostart == true {
            guard service.start != nil else { continue }
            Logger.log(level: .info, component: "DaemonCoordinator", event: "SERVICE_AUTOSTART", details: ["serviceName": .string(service.name)])
            processManager.start(service: service)
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
                StateManager.flushIfNeeded()
                HistoryLogger.log(results)

                let codable = results.map { $0.toCodable() }
                for item in codable {
                    let effective = EffectiveServiceState(
                        isRunning: item.isRunning,
                        isStarting: item.isStarting,
                        detail: item.detail
                    )
                    let previous = self.lastBroadcastEffectiveState[item.serviceName]
                    if previous != effective {
                        self.lastBroadcastEffectiveState[item.serviceName] = effective
                        self.ipcServer.broadcastServiceChanged(item)
                    }
                }
            }
        }
    }

    private func setupFlushTimer() {
        let timer = DispatchSource.makeTimerSource(queue: .main)
        let interval = StateManager.configuredFlushIntervalSeconds()
        timer.schedule(deadline: .now() + interval, repeating: interval)
        timer.setEventHandler {
            StateManager.flushIfNeeded()
        }
        timer.resume()
        flushTimer = timer
    }

    private func acquireOwnership() -> StartOutcome {
        switch ipcServer.start() {
        case .started:
            return .owner
        case .addressInUse:
            if isDaemonReachable() {
                Logger.log(level: .info, component: "DaemonCoordinator", event: "NON_OWNER_MODE", details: ["reason": .string("daemon already reachable")])
                return .nonOwner
            }

            try? FileManager.default.removeItem(at: StateManager.socketURL)
            switch ipcServer.start() {
            case .started:
                Logger.log(level: .info, component: "DaemonCoordinator", event: "STALE_SOCKET_RECOVERED", details: [:])
                return .owner
            case .addressInUse:
                return Self.resolveAddressInUseRetryOutcome(isReachableAfterRetry: isDaemonReachable())
            case .failed:
                return .failed
            }
        case .failed:
            return .failed
        }
    }

    static func resolveAddressInUseRetryOutcome(isReachableAfterRetry: Bool) -> StartOutcome {
        isReachableAfterRetry ? .nonOwner : .failed
    }

    private func isDaemonReachable() -> Bool {
        IPCClient.getStatusSnapshot(allowBootstrap: false) != nil
    }

    private func configureIPCHandlers() {
        ipcServer.onTriggerCheck = { [weak self] in self?.runCheck() }

        ipcServer.onQuit = { [weak self] in
            self?.shutdown()
        }
        ipcServer.onSubscribeSnapshot = { [weak self] in
            guard let self else { return [] }
            let live = StateManager.currentSnapshot().services
            if !live.isEmpty { return live }
            guard let config = self.config else { return [] }
            return config.services.map { service in
                CodableCheckResult(
                    serviceName: service.name,
                    isRunning: false,
                    detail: "unknown",
                    checkedAt: Date.distantPast,
                    isStarting: false
                )
            }
        }
        ipcServer.onGetStatusSnapshot = {
            StateManager.currentSnapshot().services
        }

        ipcServer.onStartService = { [weak self] name in
            guard let svc = self?.config?.services.first(where: { $0.name == name }) else {
                return .error("Service not found")
            }
            if svc.background == true {
                StateManager.upsertService(
                    CodableCheckResult(
                        serviceName: svc.name,
                        isRunning: false,
                        detail: "starting",
                        checkedAt: Date(),
                        isStarting: true
                    )
                )
                self?.ipcServer.broadcastServiceChanged(
                    CodableCheckResult(
                        serviceName: svc.name,
                        isRunning: false,
                        detail: "starting",
                        checkedAt: Date(),
                        isStarting: true
                    )
                )
                self?.processManager.start(service: svc)
                let item = DispatchWorkItem { self?.runCheck() }
                self?.workItems.append(item)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: item)
                return .ok
            } else {
                return Self.interactiveResponse(for: svc, command: svc.start, missingCommandError: "No start command")
            }
        }
        ipcServer.onStopService = { [weak self] name in
            guard let svc = self?.config?.services.first(where: { $0.name == name }) else { return }
            self?.processManager.stop(service: svc)
            let item = DispatchWorkItem { self?.runCheck() }
            self?.workItems.append(item)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: item)
        }
        ipcServer.onRestartService = { [weak self] name in
            guard let svc = self?.config?.services.first(where: { $0.name == name }) else {
                return .error("Service not found")
            }
            if svc.background == true {
                StateManager.upsertService(
                    CodableCheckResult(
                        serviceName: svc.name,
                        isRunning: false,
                        detail: "starting",
                        checkedAt: Date(),
                        isStarting: true
                    )
                )
                self?.ipcServer.broadcastServiceChanged(
                    CodableCheckResult(
                        serviceName: svc.name,
                        isRunning: false,
                        detail: "starting",
                        checkedAt: Date(),
                        isStarting: true
                    )
                )
                self?.processManager.restart(service: svc)
                let item = DispatchWorkItem { self?.runCheck() }
                self?.workItems.append(item)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: item)
                return .ok
            } else {
                return Self.interactiveResponse(for: svc, command: svc.restart, missingCommandError: "No restart command")
            }
        }
    }

    static func interactiveResponse(for service: ServiceConfig, command: String?, missingCommandError: String) -> IPCServiceResponse {
        guard let value = command, !value.isEmpty else {
            return .error(missingCommandError)
        }
        let terminalCommand = service.cwd != nil ? "cd \(service.cwd!) && \(value)" : value
        return .executeInTerminal(TerminalCommand(serviceName: service.name, command: terminalCommand))
    }
}

private struct EffectiveServiceState: Equatable {
    let isRunning: Bool
    let isStarting: Bool
    let detail: String
}
