import Cocoa
import UserNotifications
import Darwin

// MARK: - Single-instance lock

let lockPath = NSString("~/.config/work_guard/work_guard.lock").expandingTildeInPath
var lockFD: Int32 = -1

func acquireLock() -> Bool {
    let configDir = NSString("~/.config/work_guard").expandingTildeInPath
    let fm = FileManager.default
    do {
        try fm.createDirectory(atPath: configDir, withIntermediateDirectories: true)
    } catch {
        NSLog("Failed to create config dir: %@", error as NSError)
    }

    lockFD = open(lockPath, O_CREAT | O_RDWR, 0o644)
    guard lockFD >= 0 else { return false }

    let result = flock(lockFD, LOCK_EX | LOCK_NB)
    guard result == 0 else {
        close(lockFD)
        lockFD = -1
        return false
    }

    let pidStr = "\(getpid())\n"
    _ = write(lockFD, pidStr, pidStr.count)
    fsync(lockFD)
    return true
}

func releaseLock() {
    if lockFD >= 0 {
        flock(lockFD, LOCK_UN)
        close(lockFD)
        lockFD = -1
    }
}

// MARK: - App delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusWriter: StatusWriter?
    var activityMonitor: ActivityMonitor?
    var overlay: OverlayController?
    var monitoringLoop: MonitoringLoop?
    var menuProcess: Process?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Notifier.requestPermission { }

        let activityMonitor = ActivityMonitor()
        activityMonitor.startKeyboardMonitoring()
        self.activityMonitor = activityMonitor

        let overlay = OverlayController()
        self.overlay = overlay

        let statusWriter = StatusWriter(overlay: overlay)
        self.statusWriter = statusWriter

        let monitoringLoop = MonitoringLoop(monitor: activityMonitor, overlay: overlay)
        monitoringLoop.onStatusChanged = { [weak statusWriter] state in
            statusWriter?.updateStatus(state)
        }
        monitoringLoop.start()
        self.monitoringLoop = monitoringLoop

        launchMenuAgent()

        NSLog("WorkGuard started successfully")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        menuProcess?.terminate()
        statusWriter?.stop()
    }

    private func launchMenuAgent() {
        guard let execPath = Bundle.main.executablePath else {
            NSLog("WorkGuardMenu: cannot resolve executable path")
            return
        }
        let menuBinary = URL(fileURLWithPath: execPath)
            .deletingLastPathComponent()
            .appendingPathComponent("WorkGuardMenu")
            .path

        guard FileManager.default.fileExists(atPath: menuBinary) else {
            NSLog("WorkGuardMenu binary not found at %@", menuBinary)
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: menuBinary)
        process.terminationHandler = { [weak self] _ in
            NSLog("WorkGuardMenu terminated unexpectedly")
            self?.menuProcess = nil
        }

        do {
            try process.run()
            menuProcess = process
            NSLog("WorkGuardMenu launched PID=%d", process.processIdentifier)
        } catch {
            NSLog("Failed to launch WorkGuardMenu: %@", error.localizedDescription)
        }
    }
}

// MARK: - Main entry

let app = NSApplication.shared

if !acquireLock() {
    app.setActivationPolicy(.regular)
    NSApp.activate(ignoringOtherApps: true)

    let alert = NSAlert()
    alert.messageText = "WorkGuard"
    alert.informativeText = "Уже запущен — смотрите строку меню (WG)."
    alert.alertStyle = .informational
    alert.addButton(withTitle: "ОК")
    alert.runModal()
    exit(0)
}

app.setActivationPolicy(.accessory)

let delegate = AppDelegate()
app.delegate = delegate

atexit(releaseLock)

app.run()
