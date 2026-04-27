import Foundation

final class ProcessManager {
    private var running: [String: Process] = [:]

    func start(service: ServiceConfig) {
        guard let cmd = service.start else { return }
        stop(name: service.name)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", cmd]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        if let cwd = service.cwd {
            process.currentDirectoryURL = URL(fileURLWithPath: (cwd as NSString).expandingTildeInPath)
        }

        process.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async { self?.running.removeValue(forKey: service.name) }
        }

        do {
            try process.run()
            running[service.name] = process
        } catch {
            print("[ProcessManager] Failed to start \(service.name): \(error)")
        }
    }

    func stop(name: String) {
        guard let process = running[name] else { return }
        process.terminate()
        running.removeValue(forKey: name)
    }

    func restart(service: ServiceConfig) {
        stop(name: service.name)
        start(service: service)
    }

    func isRunning(name: String) -> Bool {
        running[name]?.isRunning ?? false
    }
}
