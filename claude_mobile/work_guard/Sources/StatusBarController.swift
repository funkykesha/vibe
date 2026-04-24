import Cocoa
import UserNotifications

// TODO: Migrate JSON file IPC to NSXPCConnection or DistributedNotificationCenter
//       for proper Swift-to-Swift communication without filesystem polling.

class StatusWriter: NSObject {
    static let statusPath = NSString("~/.config/work_guard/status.json").expandingTildeInPath
    static let commandPath = NSString("~/.config/work_guard/command.json").expandingTildeInPath

    private let overlay: OverlayController
    private var currentConfig = Config.load()
    private var commandCheckTimer: Timer?
    private var lastCommandTS: Double = Date().timeIntervalSince1970
    private var settingsWindowController: SettingsWindowController?

    init(overlay: OverlayController) {
        self.overlay = overlay
        super.init()
        writeStatus(title: "WG", statusText: "Загрузка...", paused: false)
        startCommandPolling()
    }

    func updateStatus(_ state: MonitoringLoop.StatusState) {
        currentConfig = Config.load()
        switch state {
        case .workTime:
            writeStatus(title: "WG 🟢", statusText: "🟢 Рабочее время", paused: false)
        case .idle:
            writeStatus(title: "WG", statusText: "⚪ Нерабочее время — отдыхаешь", paused: false)
        case .paused(let until):
            let fmt = DateFormatter()
            fmt.dateFormat = "HH:mm"
            writeStatus(title: "WG ⏸", statusText: "⏸ Пауза до \(fmt.string(from: until))", paused: true)
        case .overtime(let minutes, let app):
            writeStatus(title: "WG 🔴", statusText: "🔴 Переработка: \(minutes) мин | \(app)", paused: false)
        }
    }

    private func writeStatus(title: String, statusText: String, paused: Bool) {
        let items: [[String: Any]] = [
            ["id": "status_label", "text": statusText, "enabled": false],
            ["id": "settings",     "text": "Настройки...", "enabled": true],
            ["id": paused ? "resume" : "pause",
             "text": paused ? "⏸ Снять паузу" : "Пауза на 1 ч", "enabled": true],
            ["id": "test_overlay", "text": "Показать оверлей (тест)", "enabled": true],
        ]
        let payload: [String: Any] = ["title": title, "tooltip": "WorkGuard", "paused": paused, "items": items]
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted]) else { return }
        let tmp = StatusWriter.statusPath + ".tmp"
        do {
            try data.write(to: URL(fileURLWithPath: tmp))
            let fm = FileManager.default
            if fm.fileExists(atPath: StatusWriter.statusPath) { try? fm.removeItem(atPath: StatusWriter.statusPath) }
            try fm.moveItem(atPath: tmp, toPath: StatusWriter.statusPath)
        } catch {
            NSLog("StatusWriter: write failed: %@", error.localizedDescription)
            try? FileManager.default.removeItem(atPath: tmp)
        }
    }

    private func startCommandPolling() {
        commandCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkCommand()
        }
    }

    private func checkCommand() {
        let fm = FileManager.default
        guard fm.fileExists(atPath: StatusWriter.commandPath),
              let data = try? Data(contentsOf: URL(fileURLWithPath: StatusWriter.commandPath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let action = json["action"] as? String,
              let ts = json["ts"] as? Double,
              ts > lastCommandTS
        else { return }

        lastCommandTS = ts
        try? fm.removeItem(atPath: StatusWriter.commandPath)
        NSLog("StatusWriter: command=%@", action)

        switch action {
        case "settings":
            openSettings()
        case "pause":
            applyPause(enable: true)
        case "resume":
            applyPause(enable: false)
        case "test_overlay":
            let (art, msg) = getEntry(level: 2)
            DispatchQueue.main.async { [weak self] in
                self?.overlay.show(art: art, message: msg, lockSecs: 30)
            }
        case "quit":
            overlay.close()
            NSApp.terminate(nil)
        default:
            break
        }
    }

    private func openSettings() {
        settingsWindowController = SettingsWindowController(config: Config.load())
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func applyPause(enable: Bool) {
        currentConfig = Config.load()
        if !enable {
            currentConfig.pauseUntil = nil
            currentConfig.save()
            NSLog("Pause cancelled")
        } else {
            let until = Date().addingTimeInterval(3600)
            let fmt = ISO8601DateFormatter()
            currentConfig.pauseUntil = fmt.string(from: until)
            currentConfig.save()

            let displayFmt = DateFormatter()
            displayFmt.dateFormat = "HH:mm"
            let timeStr = displayFmt.string(from: until)

            let content = UNMutableNotificationContent()
            content.title = "WorkGuard"
            content.body = "Пауза на 1 ч до \(timeStr)"
            UNUserNotificationCenter.current().add(
                UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            )
            NSLog("Paused until %@", timeStr)
        }
    }

    func stop() {
        commandCheckTimer?.invalidate()
        commandCheckTimer = nil
        try? FileManager.default.removeItem(atPath: StatusWriter.statusPath)
    }
}
