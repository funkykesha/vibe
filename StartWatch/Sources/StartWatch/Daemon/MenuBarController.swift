// StartWatch — MenuBarController: иконка в menu bar и меню сервисов
import AppKit

final class MenuBarController {
    private var statusItem: NSStatusItem!
    private var lastResults: [CheckResult] = []
    private var config: AppConfig?

    var onCheckNow: (() -> Void)?
    var onOpenCLI: (() -> Void)?
    var onOpenConfig: (() -> Void)?
    var onQuit: (() -> Void)?
    var onStartService: ((String) -> Void)?
    var onStopService: ((String) -> Void)?
    var onRestartService: ((String) -> Void)?
    var onSetTerminal: ((String) -> Void)?
    var onStartDaemon: (() -> Void)?
    private var isDaemonOffline = false
    private var staleSeconds: Int?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateIcon(state: .allOk)
        buildMenu()
    }

    func updateConfig(_ config: AppConfig) {
        self.config = config
    }

    func update(results: [CheckResult]) {
        isDaemonOffline = false
        staleSeconds = nil
        self.lastResults = results
        let iconState = determineIconState(results: results)
        updateIcon(state: iconState)
        buildMenu()
    }

    func showDaemonOffline() {
        isDaemonOffline = true
        lastResults = []
        staleSeconds = nil
        updateIcon(state: .failed)
        buildMenu()
    }

    func showDaemonOffline(lastKnown: [CheckResult], staleSeconds: Int?) {
        isDaemonOffline = true
        self.lastResults = lastKnown
        self.staleSeconds = staleSeconds
        updateIcon(state: .failed)
        buildMenu()
    }

    // MARK: - Private

    private enum IconState {
        case starting
        case mixed
        case failed
        case allOk
    }

    private func determineIconState(results: [CheckResult]) -> IconState {
        guard !results.isEmpty else { return .allOk }

        let anyStarting = results.contains { $0.isStarting }
        let anyRunning = results.contains { $0.isRunning }
        let anyNotRunning = results.contains { !$0.isRunning && !$0.isStarting }

        if anyStarting {
            return .starting
        }

        if anyRunning && anyNotRunning {
            return .mixed
        }

        if anyNotRunning {
            return .failed
        }

        return .allOk
    }

    private func updateIcon(state: IconState) {
        guard let button = statusItem.button else { return }
        let title: String
        switch state {
        case .starting:
            title = "SW..."
        case .mixed:
            title = "SW?"
        case .failed:
            title = "SW!"
        case .allOk:
            title = "SW"
        }
        button.image = nil
        button.attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: NSColor.labelColor
            ]
        )
        button.toolTip = "StartWatch"
    }

    private func buildMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let header = NSMenuItem(title: "StartWatch", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        if let date = lastResults.first?.checkedAt {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            let timeItem = NSMenuItem(
                title: "  Last check: \(formatter.string(from: date))",
                action: nil, keyEquivalent: ""
            )
            timeItem.isEnabled = false
            menu.addItem(timeItem)
        }

        menu.addItem(NSMenuItem.separator())

        if lastResults.isEmpty {
            let text = isDaemonOffline ? "  Daemon not running" : "  No checks yet"
            let item = NSMenuItem(title: text, action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        } else {
            if isDaemonOffline {
                let staleText: String
                if let seconds = staleSeconds, seconds >= 30 {
                    staleText = "  ⚠️ Daemon offline. Last state from \(seconds)s ago"
                } else {
                    staleText = "  Daemon offline. Showing last known state"
                }
                let staleItem = NSMenuItem(title: staleText, action: nil, keyEquivalent: "")
                staleItem.isEnabled = false
                menu.addItem(staleItem)
                menu.addItem(NSMenuItem.separator())
            }
            for result in lastResults {
                let menuItem = NSMenuItem()
                menuItem.isEnabled = true
                let rowView = ServiceMenuItemView(result: result)

                rowView.onOpen = { [weak self] in
                    self?.openService(result.service)
                }
                rowView.onStart = { [weak self] in self?.onStartService?(result.service.name) }
                rowView.onStop = { [weak self] in self?.onStopService?(result.service.name) }
                rowView.onRestart = { [weak self] in self?.onRestartService?(result.service.name) }

                menuItem.view = rowView
                menu.addItem(menuItem)
            }
        }

        menu.addItem(NSMenuItem.separator())

        let terminalName = config?.terminal?.capitalized ?? "Terminal"
        let openCLI = NSMenuItem(
            title: "★ Open CLI in \(terminalName)",
            action: #selector(openCLIClicked),
            keyEquivalent: "t"
        )
        openCLI.keyEquivalentModifierMask = [.command]
        openCLI.target = self
        menu.addItem(openCLI)

        let checkNow = NSMenuItem(
            title: "Check Now",
            action: #selector(checkNowClicked),
            keyEquivalent: "r"
        )
        checkNow.keyEquivalentModifierMask = [.command]
        checkNow.target = self
        checkNow.isEnabled = !isDaemonOffline
        menu.addItem(checkNow)

        if isDaemonOffline {
            let startDaemon = NSMenuItem(
                title: "Start Daemon",
                action: #selector(startDaemonClicked),
                keyEquivalent: ""
            )
            startDaemon.target = self
            menu.addItem(startDaemon)
        }

        menu.addItem(NSMenuItem.separator())

        let terminalMenu = buildTerminalSubmenu()
        let terminalItem = NSMenuItem(title: "Terminal", action: nil, keyEquivalent: "")
        terminalItem.submenu = terminalMenu
        menu.addItem(terminalItem)

        let openConfig = NSMenuItem(
            title: "Open Config…",
            action: #selector(openConfigClicked),
            keyEquivalent: ","
        )
        openConfig.keyEquivalentModifierMask = [.command]
        openConfig.target = self
        menu.addItem(openConfig)

        menu.addItem(NSMenuItem.separator())

        let quit = NSMenuItem(
            title: "Quit StartWatch",
            action: #selector(quitClicked),
            keyEquivalent: "q"
        )
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    @objc private func openCLIClicked() { onOpenCLI?() }
    @objc private func checkNowClicked() { onCheckNow?() }
    @objc private func startDaemonClicked() { onStartDaemon?() }
    @objc private func openConfigClicked() { onOpenConfig?() }
    @objc private func quitClicked() { onQuit?() }

    @objc private func terminalSelected(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        onSetTerminal?(id)
    }

    private func buildTerminalSubmenu() -> NSMenu {
        let current = config?.terminal ?? "terminal"
        let candidates: [(id: String, label: String)] = [
            ("terminal", "Terminal"),
            ("warp",     "Warp"),
            ("iterm",    "iTerm2"),
            ("alacritty","Alacritty"),
            ("kitty",    "Kitty"),
        ]
        let sub = NSMenu()
        for (id, label) in candidates where TerminalLauncher.isAvailable(terminal: id) {
            let item = NSMenuItem(title: label, action: #selector(terminalSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = id
            item.state = (id == current) ? .on : .off
            sub.addItem(item)
        }
        return sub
    }

    private func openService(_ service: ServiceConfig) {
        guard let openValue = service.open else { return }
        if openValue.hasPrefix("http://") || openValue.hasPrefix("https://"),
           let url = URL(string: openValue) {
            NSWorkspace.shared.open(url)
        } else if let config = config {
            TerminalLauncher.open(terminal: config.terminal ?? "terminal", command: openValue)
        } else {
            TerminalLauncher.open(terminal: "terminal", command: openValue)
        }
    }
}
