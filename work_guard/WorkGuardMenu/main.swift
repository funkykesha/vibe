import Cocoa
import Foundation

// MARK: - Paths

let kStatusFile = NSString("~/.config/work_guard/status.json").expandingTildeInPath
let kCommandFile = NSString("~/.config/work_guard/command.json").expandingTildeInPath
let kRefreshInterval: TimeInterval = 1.0

// MARK: - Models

struct MenuItemModel {
    let id: String
    let text: String
    let enabled: Bool
}

struct StatusModel {
    var title: String = "WG"
    var tooltip: String = ""
    var paused: Bool = false
    var items: [MenuItemModel] = []
}

// MARK: - Controller

final class StatusBarController: NSObject {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var refreshTimer: Timer?
    var lastModified: Date?
    var currentStatus = StatusModel()

    override init() {
        super.init()
        statusItem.button?.title = "WG"
        statusItem.button?.toolTip = "WorkGuard"
        rebuildMenu()

        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: kRefreshInterval,
            repeats: true
        ) { [weak self] _ in
            self?.refresh()
        }
        refresh()
    }

    // MARK: - Read status.json

    func refresh() {
        let fm = FileManager.default
        guard fm.fileExists(atPath: kStatusFile) else { return }

        guard let attrs = try? fm.attributesOfItem(atPath: kStatusFile),
              let mtime = attrs[.modificationDate] as? Date
        else { return }

        if let last = lastModified, mtime <= last { return }
        lastModified = mtime

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: kStatusFile)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }

        let title = json["title"] as? String ?? "WG"
        let tooltip = json["tooltip"] as? String ?? ""
        let paused = json["paused"] as? Bool ?? false
        var items: [MenuItemModel] = []

        if let rawItems = json["items"] as? [[String: Any]] {
            for raw in rawItems {
                let id = raw["id"] as? String ?? ""
                let text = raw["text"] as? String ?? ""
                let enabled = raw["enabled"] as? Bool ?? true
                items.append(MenuItemModel(id: id, text: text, enabled: enabled))
            }
        }

        let newStatus = StatusModel(
            title: title,
            tooltip: tooltip,
            paused: paused,
            items: items
        )

        DispatchQueue.main.async {
            self.currentStatus = newStatus
            self.statusItem.button?.title = newStatus.title
            self.statusItem.button?.toolTip = newStatus.tooltip.isEmpty ? "WorkGuard" : newStatus.tooltip
            self.rebuildMenu()
        }
    }

    // MARK: - NSMenu

    func rebuildMenu() {
        let menu = NSMenu()

        for item in currentStatus.items {
            let mi = NSMenuItem(
                title: item.text,
                action: item.enabled ? #selector(menuItemClicked(_:)) : nil,
                keyEquivalent: ""
            )
            mi.representedObject = item.id
            mi.target = self
            mi.isEnabled = item.enabled
            menu.addItem(mi)
        }

        if !currentStatus.items.isEmpty {
            menu.addItem(NSMenuItem.separator())
        }

        let quit = NSMenuItem(
            title: "Выйти",
            action: #selector(quitClicked(_:)),
            keyEquivalent: "q"
        )
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    // MARK: - Commands → Python

    @objc func menuItemClicked(_ sender: NSMenuItem) {
        guard let actionId = sender.representedObject as? String else { return }
        writeCommand(action: actionId)
    }

    @objc func quitClicked(_: NSMenuItem) {
        writeCommand(action: "quit")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApplication.shared.terminate(nil)
        }
    }

    func writeCommand(action: String) {
        let command: [String: Any] = [
            "action": action,
            "ts": Date().timeIntervalSince1970,
        ]
        guard let data = try? JSONSerialization.data(
            withJSONObject: command,
            options: [.prettyPrinted]
        ) else { return }

        let tmpPath = kCommandFile + ".tmp"
        let fm = FileManager.default
        do {
            try data.write(to: URL(fileURLWithPath: tmpPath))
            if fm.fileExists(atPath: kCommandFile) {
                try fm.removeItem(atPath: kCommandFile)
            }
            try fm.moveItem(atPath: tmpPath, toPath: kCommandFile)
        } catch {
            try? fm.removeItem(atPath: tmpPath)
        }
    }
}

// MARK: - App delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    var controller: StatusBarController?

    func applicationDidFinishLaunching(_: Notification) {
        controller = StatusBarController()
    }
}

// MARK: - Entry

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = AppDelegate()
app.delegate = delegate
app.run()
