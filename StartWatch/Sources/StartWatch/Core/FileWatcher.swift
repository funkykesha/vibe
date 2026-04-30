// StartWatch — FileWatcher: мониторит изменения файла через polling mtime
import Foundation

final class FileWatcher {
    private let filePath: String
    private var timer: Timer?
    private var lastModified: Date?
    private let pollInterval: TimeInterval = 0.5

    init(filePath: String) {
        self.filePath = filePath
    }

    func start(onChange: @escaping () -> Void) {
        guard FileManager.default.fileExists(atPath: filePath) else {
            print("[FileWatcher] File not found: \(filePath)")
            return
        }

        updateLastModified()

        let logMsg = "[FW] Timer started\n"
        let logPath = URL(fileURLWithPath: NSHomeDirectory() + "/.config/startwatch/fw.log")
        if let data = logMsg.data(using: .utf8) {
            try? data.write(to: logPath, options: .atomic)
        }

        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.checkForChanges(onChange: onChange)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func updateLastModified() {
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: filePath)
            lastModified = attrs[.modificationDate] as? Date
        } catch {
            print("[FileWatcher] Failed to get file attributes: \(error)")
        }
    }

    private func checkForChanges(onChange: @escaping () -> Void) {
        let logPath = URL(fileURLWithPath: NSHomeDirectory() + "/.config/startwatch/fw.log")

        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: filePath)
            guard let modified = attrs[.modificationDate] as? Date else { return }

            if let last = lastModified, modified > last {
                let msg = "[FW] Changed: reload\n"
                if let data = msg.data(using: .utf8) {
                    try? data.write(to: logPath, options: .atomic)
                }
                lastModified = modified
                onChange()
            } else if lastModified == nil {
                lastModified = modified
            }
        } catch {
            print("[FileWatcher] Error checking file: \(error)")
        }
    }

    deinit {
        stop()
    }
}
