import AppKit

final class ConfigEditorWindow: NSObject {
    private var panel: NSPanel?
    private var textView: NSTextView?

    func show() {
        if let existing = panel, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.title = "StartWatch — Config"
        panel.level = .floating
        panel.center()

        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 44, width: 620, height: 456))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true

        let textView = NSTextView(frame: scrollView.bounds)
        textView.autoresizingMask = [.width, .height]
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isRichText = false
        textView.allowsUndo = true

        scrollView.documentView = textView
        self.textView = textView

        let cancelButton = NSButton(frame: NSRect(x: 8, y: 8, width: 90, height: 28))
        cancelButton.title = "Отмена"
        cancelButton.bezelStyle = .rounded
        cancelButton.target = self
        cancelButton.action = #selector(cancelClicked)

        let saveButton = NSButton(frame: NSRect(x: 522, y: 8, width: 90, height: 28))
        saveButton.title = "Сохранить"
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"
        saveButton.target = self
        saveButton.action = #selector(saveClicked)

        let contentView = panel.contentView!
        contentView.addSubview(scrollView)
        contentView.addSubview(cancelButton)
        contentView.addSubview(saveButton)

        if let raw = try? String(contentsOf: ConfigManager.configURL, encoding: .utf8) {
            textView.string = raw
        }

        self.panel = panel
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func cancelClicked() {
        panel?.close()
    }

    @objc private func saveClicked() {
        guard let text = textView?.string,
              let data = text.data(using: .utf8) else { return }

        do {
            let decoded = try JSONDecoder().decode(AppConfig.self, from: data)
            try ConfigManager.save(decoded)
            panel?.close()
        } catch {
            let alert = NSAlert()
            alert.messageText = "Ошибка JSON"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            if let p = panel {
                alert.beginSheetModal(for: p)
            }
        }
    }
}
