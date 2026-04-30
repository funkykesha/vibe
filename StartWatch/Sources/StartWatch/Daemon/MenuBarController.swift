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

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateIcon(allOk: true)
        buildMenu()
    }

    func updateConfig(_ config: AppConfig) {
        self.config = config
    }

    func update(results: [CheckResult]) {
        self.lastResults = results
        let allOk = results.allSatisfy(\.isRunning)
        updateIcon(allOk: allOk)
        buildMenu()
    }

    // MARK: - Private

    private func updateIcon(allOk: Bool) {
        guard let button = statusItem.button else { return }
        button.image = makeStatusIcon(emoji: allOk ? "♻️" : "⚠️")
        button.title = ""
        button.toolTip = "StartWatch"
    }

    private func makeStatusIcon(emoji: String) -> NSImage {
        let size = NSSize(width: 28, height: 20)
        let image = NSImage(size: size)
        image.lockFocus()

        let bg = NSRect(x: 1, y: 1, width: size.width - 2, height: size.height - 2)
        NSColor.windowBackgroundColor.setFill()
        NSBezierPath(roundedRect: bg, xRadius: 5, yRadius: 5).fill()

        let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 12)]
        let str = NSAttributedString(string: emoji, attributes: attrs)
        let sz = str.size()
        str.draw(at: NSPoint(x: (size.width - sz.width) / 2, y: (size.height - sz.height) / 2))

        image.unlockFocus()
        return image
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
            let item = NSMenuItem(title: "  No checks yet", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        } else {
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
        menu.addItem(checkNow)

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
