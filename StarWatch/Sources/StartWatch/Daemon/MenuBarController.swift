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
        if #available(macOS 11.0, *) {
            let symbolName = allOk
                ? "checkmark.circle.fill"
                : "exclamationmark.triangle.fill"
            let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "StartWatch")
            image?.isTemplate = true
            button.image = image
        } else {
            button.title = allOk ? "●" : "◐"
        }
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
                let icon = result.isRunning ? "✅" : "❌"
                let header = NSMenuItem(
                    title: "\(icon)  \(result.service.name)",
                    action: nil, keyEquivalent: ""
                )
                header.toolTip = "\(result.detail)\n\(result.service.check.type.rawValue): \(result.service.check.value)"

                let submenu = NSMenu()

                let startItem = NSMenuItem(title: "Запустить", action: #selector(serviceActionClicked(_:)), keyEquivalent: "")
                startItem.target = self
                startItem.representedObject = ("start", result.service.name)
                startItem.isEnabled = !result.isRunning

                let stopItem = NSMenuItem(title: "Остановить", action: #selector(serviceActionClicked(_:)), keyEquivalent: "")
                stopItem.target = self
                stopItem.representedObject = ("stop", result.service.name)
                stopItem.isEnabled = result.isRunning

                let restartItem = NSMenuItem(title: "Перезапустить", action: #selector(serviceActionClicked(_:)), keyEquivalent: "")
                restartItem.target = self
                restartItem.representedObject = ("restart", result.service.name)

                submenu.addItem(startItem)
                submenu.addItem(stopItem)
                submenu.addItem(restartItem)

                header.submenu = submenu
                menu.addItem(header)
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

    @objc private func serviceActionClicked(_ sender: NSMenuItem) {
        guard let (action, name) = sender.representedObject as? (String, String) else { return }
        switch action {
        case "start":   onStartService?(name)
        case "stop":    onStopService?(name)
        case "restart": onRestartService?(name)
        default: break
        }
    }
}
