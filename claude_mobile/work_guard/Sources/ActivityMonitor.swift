import Cocoa

class ActivityMonitor {
    private(set) var isScreenAsleep = false
    private var lastKeypressDate: Date?
    private let keypressLock = NSLock()
    private var eventTap: CFMachPort?
    private var eventTapSource: CFRunLoopSource?

    init() {
        setupScreenSleepNotifications()
    }

    deinit {
        stopKeyboardMonitoring()
    }

    private func setupScreenSleepNotifications() {
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(
            self,
            selector: #selector(screenDidSleep),
            name: NSWorkspace.screensDidSleepNotification,
            object: nil
        )
        nc.addObserver(
            self,
            selector: #selector(screenDidWake),
            name: NSWorkspace.screensDidWakeNotification,
            object: nil
        )
    }

    @objc private func screenDidSleep() {
        isScreenAsleep = true
        NSLog("Screen asleep")
    }

    @objc private func screenDidWake() {
        isScreenAsleep = false
        lastKeypressDate = nil
        NSLog("Screen awake")
    }

    func startKeyboardMonitoring() {
        guard AXIsProcessTrusted() else {
            NSLog("Accessibility not granted — keyboard monitoring disabled")
            return
        }

        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { proxy, type, event, userInfo -> Unmanaged<CGEvent>? in
                guard let userInfo = userInfo else { return Unmanaged.passRetained(event) }
                let monitor = Unmanaged<ActivityMonitor>.fromOpaque(userInfo).takeUnretainedValue()
                monitor.keypressLock.lock()
                monitor.lastKeypressDate = Date()
                monitor.keypressLock.unlock()
                return Unmanaged.passRetained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            NSLog("Failed to create event tap")
            return
        }

        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.eventTapSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        NSLog("Keyboard monitoring started")
    }

    func stopKeyboardMonitoring() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = eventTapSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        eventTapSource = nil
    }

    func isKeyboardActive(idleThresholdSec: Int = 300) -> Bool {
        keypressLock.lock()
        defer { keypressLock.unlock() }

        guard let lastKeypress = lastKeypressDate else {
            return false
        }
        let elapsed = Date().timeIntervalSince(lastKeypress)
        return elapsed < Double(idleThresholdSec)
    }

    func getActiveApp() -> String? {
        if let app = NSWorkspace.shared.frontmostApplication?.localizedName {
            return app
        }
        return nil
    }

    func isWorkAppActive(config: Config) -> Bool {
        guard let app = getActiveApp() else {
            return false
        }
        let appLower = app.lowercased()
        return config.workApps.contains { workApp in
            let workAppLower = workApp.lowercased()
            return workAppLower.contains(appLower) || appLower.contains(workAppLower)
        }
    }

    func isWorkHappening(config: Config) -> Bool {
        if isScreenAsleep {
            return false
        }
        return isWorkAppActive(config: config) || isKeyboardActive()
    }

    func isWorkTime(config: Config) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        var weekdayComponent = calendar.component(.weekday, from: now)
        weekdayComponent = weekdayComponent == 1 ? 7 : weekdayComponent - 1

        if !config.workDays.contains(weekdayComponent) {
            return false
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        guard let startDate = formatter.date(from: config.workStart),
              let endDate = formatter.date(from: config.workEnd) else {
            return false
        }

        let startSeconds = calendar.component(.hour, from: startDate) * 3600 + calendar.component(.minute, from: startDate) * 60
        let endSeconds = calendar.component(.hour, from: endDate) * 3600 + calendar.component(.minute, from: endDate) * 60
        let nowSeconds = calendar.component(.hour, from: now) * 3600 + calendar.component(.minute, from: now) * 60

        return nowSeconds >= startSeconds && nowSeconds <= endSeconds
    }

    func isPaused(config: inout Config) -> Bool {
        guard let pauseUntilStr = config.pauseUntil else {
            return false
        }

        let formatter = ISO8601DateFormatter()
        guard let pauseDate = formatter.date(from: pauseUntilStr) else {
            config.pauseUntil = nil
            config.save()
            return false
        }

        if Date() < pauseDate {
            return true
        }

        config.pauseUntil = nil
        config.save()
        return false
    }
}
