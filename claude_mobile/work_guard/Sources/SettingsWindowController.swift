import Cocoa

class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private var config: Config
    private var startPicker: NSDatePicker!
    private var endPicker: NSDatePicker!
    private var dayCheckboxes: [NSButton] = []
    private var notificationField: NSTextField!
    private var overlayField: NSTextField!

    init(config: Config) {
        self.config = config
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 360),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "WorkGuard — Настройки"
        window.level = .floating
        super.init(window: window)
        window.delegate = self
        setupUI()
        window.center()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        guard let cv = window?.contentView else { return }

        let bg = NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)
        let fg = NSColor(red: 0.83, green: 0.83, blue: 0.83, alpha: 1.0)
        let accent = NSColor(red: 0.0, green: 1.0, blue: 0.25, alpha: 1.0)
        let fieldBg = NSColor(calibratedRed: 0.18, green: 0.18, blue: 0.18, alpha: 1.0)
        let monoFont = NSFont(name: "Menlo", size: 12)!
        let boldFont = NSFont(name: "Menlo-Bold", size: 13)!

        cv.wantsLayer = true
        cv.layer?.backgroundColor = bg.cgColor

        var y: CGFloat = 310

        func label(_ text: String, bold: Bool = false) {
            let f = NSTextField(frame: NSRect(x: 20, y: y, width: 440, height: 22))
            f.stringValue = text
            f.font = bold ? boldFont : monoFont
            f.textColor = bold ? accent : fg
            f.isBezeled = false; f.drawsBackground = false
            f.isEditable = false; f.isSelectable = false
            cv.addSubview(f)
            y -= 28
        }

        func timePicker(time: String) -> NSDatePicker {
            let parts = time.split(separator: ":").map { Int($0) ?? 0 }
            let cal = Calendar.current
            var comps = cal.dateComponents([.year, .month, .day], from: Date())
            comps.hour = parts.count > 0 ? parts[0] : 9
            comps.minute = parts.count > 1 ? parts[1] : 0
            let date = cal.date(from: comps) ?? Date()

            let picker = NSDatePicker(frame: NSRect(x: 150, y: y, width: 120, height: 26))
            picker.datePickerStyle = .textFieldAndStepper
            picker.datePickerElements = [.hourMinute]
            picker.dateValue = date
            picker.isBezeled = true
            picker.font = monoFont
            cv.addSubview(picker)
            return picker
        }

        // ── Work hours ──
        label("Рабочие часы", bold: true)
        label("С:")
        startPicker = timePicker(time: config.workStart)
        startPicker.frame.origin.y = y + 2
        y -= 32

        label("До:")
        endPicker = timePicker(time: config.workEnd)
        endPicker.frame.origin.y = y + 2
        y -= 38

        // ── Work days ──
        label("Рабочие дни", bold: true)
        let dayNames = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
        var dx: CGFloat = 20
        for (i, name) in dayNames.enumerated() {
            let cb = NSButton(frame: NSRect(x: dx, y: y, width: 48, height: 22))
            cb.setButtonType(.switch)
            cb.title = name
            cb.font = monoFont
            cb.state = config.workDays.contains(i + 1) ? .on : .off
            cb.contentTintColor = accent
            cv.addSubview(cb)
            dayCheckboxes.append(cb)
            dx += 52
        }
        y -= 42

        // ── Intervals ──
        label("Интервалы", bold: true)

        func intervalRow(labelText: String, value: Int) -> NSTextField {
            let lbl = NSTextField(frame: NSRect(x: 20, y: y, width: 220, height: 22))
            lbl.stringValue = labelText
            lbl.font = monoFont; lbl.textColor = fg
            lbl.isBezeled = false; lbl.drawsBackground = false
            lbl.isEditable = false; lbl.isSelectable = false
            cv.addSubview(lbl)

            let field = NSTextField(frame: NSRect(x: 250, y: y, width: 60, height: 22))
            field.stringValue = String(value)
            field.font = monoFont; field.textColor = fg
            field.backgroundColor = fieldBg
            field.isBezeled = true; field.isEditable = true
            cv.addSubview(field)
            y -= 30
            return field
        }

        notificationField = intervalRow(labelText: "Пуш каждые N мин:", value: config.notificationIntervalMin)
        overlayField = intervalRow(labelText: "Оверлей каждые N мин:", value: config.overlayDelayMin)

        y -= 10

        // ── Save button ──
        let saveBtn = NSButton(frame: NSRect(x: 140, y: y - 10, width: 200, height: 36))
        saveBtn.title = "Сохранить"
        saveBtn.bezelStyle = .rounded
        saveBtn.font = monoFont
        saveBtn.target = self
        saveBtn.action = #selector(saveAndClose)
        cv.addSubview(saveBtn)
    }

    @objc private func saveAndClose() {
        let cal = Calendar.current
        let startH = cal.component(.hour, from: startPicker.dateValue)
        let startM = cal.component(.minute, from: startPicker.dateValue)
        let endH = cal.component(.hour, from: endPicker.dateValue)
        let endM = cal.component(.minute, from: endPicker.dateValue)

        config.workStart = String(format: "%02d:%02d", startH, startM)
        config.workEnd = String(format: "%02d:%02d", endH, endM)
        config.workDays = dayCheckboxes.enumerated().compactMap { i, cb in
            cb.state == .on ? i + 1 : nil
        }
        if let v = Int(notificationField.stringValue), v > 0 { config.notificationIntervalMin = v }
        if let v = Int(overlayField.stringValue), v > 0 { config.overlayDelayMin = v }
        config.save()

        let alert = NSAlert()
        alert.messageText = "WorkGuard"
        alert.informativeText = "Настройки сохранены!"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "ОК")
        alert.runModal()

        window?.close()
    }
}
