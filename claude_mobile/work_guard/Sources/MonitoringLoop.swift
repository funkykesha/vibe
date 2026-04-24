import Foundation

class MonitoringLoop {
    enum StatusState {
        case workTime
        case idle
        case paused(until: Date)
        case overtime(minutes: Int, app: String)
    }

    private let checkInterval: TimeInterval = 60.0
    private let pauseDurationHours: Int = 1
    private let idleThresholdSec: Int = 300

    private var minutesOvertime = 0
    private var lastNotificationMinute = -1
    private var lastOverlayMinute = -1
    private var overlayShowCount = 0
    private var isRunning = false

    private let monitor: ActivityMonitor
    private let overlay: OverlayController
    var onStatusChanged: ((StatusState) -> Void)?

    init(monitor: ActivityMonitor, overlay: OverlayController) {
        self.monitor = monitor
        self.overlay = overlay
    }

    func start() {
        isRunning = true
        DispatchQueue.global().async { [weak self] in
            self?.runLoop()
        }
    }

    func stop() {
        isRunning = false
    }

    private func runLoop() {
        while isRunning {
            tick()
            Thread.sleep(forTimeInterval: checkInterval)
        }
    }

    private func tick() {
        var config = Config.load()

        if monitor.isPaused(config: &config) {
            let pauseUntilStr = config.pauseUntil ?? ""
            let formatter = ISO8601DateFormatter()
            let pauseDate = formatter.date(from: pauseUntilStr) ?? Date()
            DispatchQueue.main.async { [weak self] in
                self?.onStatusChanged?(.paused(until: pauseDate))
            }
            return
        }

        if monitor.isWorkTime(config: config) {
            minutesOvertime = 0
            lastNotificationMinute = -1
            lastOverlayMinute = -1
            overlayShowCount = 0
            DispatchQueue.main.async { [weak self] in
                self?.onStatusChanged?(.workTime)
            }
            return
        }

        if !monitor.isWorkHappening(config: config) {
            minutesOvertime = 0
            overlayShowCount = 0
            DispatchQueue.main.async { [weak self] in
                self?.onStatusChanged?(.idle)
            }
            return
        }

        minutesOvertime += 1
        let m = minutesOvertime
        let activeApp = monitor.getActiveApp() ?? "—"

        let interval = config.notificationIntervalMin
        let overlayDelay = config.overlayDelayMin

        if m % interval == 0 && m != lastNotificationMinute {
            lastNotificationMinute = m
            Notifier.sendOvertimeNotification(minutes: m)
        }

        if m % overlayDelay == 0 && m != lastOverlayMinute {
            lastOverlayMinute = m
            let level = min(2, m / 20)
            let (art, msg) = getEntry(level: level)
            // Exponential lock: 30s → 60s → 120s → 240s (max 5 min)
            let lockSecs = min(30 * (1 << overlayShowCount), 300)
            overlayShowCount += 1
            DispatchQueue.main.async { [weak self] in
                self?.overlay.show(art: art, message: msg, lockSecs: lockSecs)
            }
            NSLog("Overlay triggered at %d min overtime, lockSecs=%d", m, lockSecs)
        }

        DispatchQueue.main.async { [weak self] in
            self?.onStatusChanged?(.overtime(minutes: m, app: activeApp))
        }
    }
}
