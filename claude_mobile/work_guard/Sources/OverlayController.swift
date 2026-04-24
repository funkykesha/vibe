import Cocoa

class OverlayController {
    private var panels: [NSPanel] = []
    private var isActive = false
    private let lock = NSLock()
    private var countdownTimer: Timer?
    private var countdownLabels: [NSTextField] = []
    private var closeButtons: [NSButton] = []
    private var remainingSeconds = 0

    // Saved to rebuild after screen wake or display change
    private var currentArt: String = ""
    private var currentMessage: String = ""

    init() {
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(self, selector: #selector(screensDidWake), name: NSWorkspace.screensDidWakeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(screenConfigChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    func show(art: String, message: String, lockSecs: Int) {
        lock.lock()
        if isActive {
            lock.unlock()
            return
        }
        isActive = true
        currentArt = art
        currentMessage = message
        lock.unlock()

        DispatchQueue.main.async { [weak self] in
            self?.launchOverlay(art: art, message: message, lockSecs: lockSecs)
        }
    }

    func close() {
        DispatchQueue.main.async { [weak self] in
            self?.closeOverlayPanels()
        }
    }

    private func closeOverlayPanels() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        for panel in panels {
            panel.close()
        }
        panels.removeAll()
        countdownLabels.removeAll()
        closeButtons.removeAll()

        lock.lock()
        isActive = false
        lock.unlock()
    }

    // Rebuild overlay panels on all current screens (called after wake/display change)
    private func rebuildPanels() {
        guard isActive else { return }

        for panel in panels { panel.close() }
        panels.removeAll()
        countdownLabels.removeAll()
        closeButtons.removeAll()

        buildPanels(art: currentArt, message: currentMessage)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func screensDidWake() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.rebuildPanels()
        }
    }

    @objc private func screenConfigChanged() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.rebuildPanels()
        }
    }

    private func launchOverlay(art: String, message: String, lockSecs: Int) {
        self.remainingSeconds = lockSecs
        buildPanels(art: art, message: message)
        NSApp.activate(ignoringOtherApps: true)

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func buildPanels(art: String, message: String) {
        let greenColor = NSColor(calibratedRed: 0.0, green: 1.0, blue: 0.25, alpha: 1.0)
        let orangeColor = NSColor(calibratedRed: 1.0, green: 0.27, blue: 0.0, alpha: 1.0)
        let grayColor = NSColor(calibratedRed: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        let darkGrayColor = NSColor(calibratedRed: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        let bgColor = NSColor(calibratedRed: 0.04, green: 0.04, blue: 0.04, alpha: 1.0)

        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm, dd MMMM yyyy"
        let timeStr = formatter.string(from: now)

        let countdownText = remainingSeconds > 0
            ? "Можно закрыть через \(remainingSeconds) сек..."
            : ""

        for screen in NSScreen.screens {
            let frame = screen.frame

            let panel = NSPanel(
                contentRect: frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            panel.level = NSWindow.Level.screenSaver
            panel.collectionBehavior = [NSWindow.CollectionBehavior.canJoinAllSpaces, NSWindow.CollectionBehavior.stationary]
            panel.backgroundColor = bgColor
            panel.isOpaque = true
            panel.hidesOnDeactivate = false

            let cv = panel.contentView!

            @discardableResult
            func addLabel(_ text: String, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, color: NSColor, fontName: String, fontSize: CGFloat) -> NSTextField {
                let label = NSTextField(frame: NSRect(x: x, y: y, width: width, height: height))
                label.stringValue = text
                label.textColor = color
                label.font = NSFont(name: fontName, size: fontSize)
                label.alignment = .center
                label.isBezeled = false
                label.drawsBackground = false
                label.isEditable = false
                label.isSelectable = false
                cv.addSubview(label)
                return label
            }

            addLabel(art, x: 0, y: frame.height * 0.25, width: frame.width, height: frame.height * 0.5, color: greenColor, fontName: "Menlo", fontSize: 13)
            addLabel(message, x: frame.width * 0.1, y: frame.height * 0.18, width: frame.width * 0.8, height: frame.height * 0.08, color: orangeColor, fontName: "Menlo-Bold", fontSize: 20)
            addLabel(timeStr, x: 0, y: frame.height * 0.13, width: frame.width, height: frame.height * 0.04, color: grayColor, fontName: "Menlo", fontSize: 13)

            let countdown = addLabel(
                countdownText,
                x: 0, y: frame.height * 0.08, width: frame.width, height: frame.height * 0.04,
                color: darkGrayColor, fontName: "Menlo", fontSize: 13
            )
            countdown.isHidden = remainingSeconds <= 0
            countdownLabels.append(countdown)

            let button = NSButton(frame: NSRect(x: frame.width / 2 - 150, y: frame.height * 0.05, width: 300, height: 44))
            button.title = "  Закрыть  (я понял)  "
            button.target = self
            button.action = #selector(closeButtonClicked)
            button.isHidden = remainingSeconds > 0
            cv.addSubview(button)
            closeButtons.append(button)

            panel.makeKeyAndOrderFront(self)
            panels.append(panel)
        }
    }

    private func tick() {
        remainingSeconds -= 1

        if remainingSeconds <= 0 {
            countdownTimer?.invalidate()
            countdownTimer = nil
            for label in countdownLabels { label.isHidden = true }
            for button in closeButtons { button.isHidden = false }
        } else {
            let text = "Можно закрыть через \(remainingSeconds) сек..."
            for label in countdownLabels { label.stringValue = text }

            if remainingSeconds % 5 == 0 {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    @objc private func closeButtonClicked() {
        close()
    }
}
