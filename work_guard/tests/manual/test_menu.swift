import Cocoa

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
statusItem.button?.title = "SW"

DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
    let btn = statusItem.button
    let wf = btn?.window?.frame ?? .zero
    print("[3s] Button: \(btn?.frame ?? .zero)")
    print("[3s] Window: \(wf)")
    print("[3s] Visible: \(btn?.window?.isVisible ?? false)")
}

app.run()
