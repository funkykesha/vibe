// StartWatch — IPCClient: CLI → Daemon коммуникация через файловый кэш
import Foundation

enum IPCClient {
    static func getLastResults() -> [CheckResult]? {
        guard let cached = StateManager.loadLastResults() else { return nil }

        // Данные старше 4 часов считаем невалидными
        if let first = cached.first,
           Date().timeIntervalSince(first.checkedAt) > 4 * 3600 {
            return nil
        }

        guard let config = ConfigManager.load() else { return nil }

        return cached.compactMap { item -> CheckResult? in
            guard let service = config.services.first(where: { $0.name == item.serviceName }) else {
                return nil
            }
            return CheckResult(
                service: service,
                isRunning: item.isRunning,
                detail: item.detail,
                checkedAt: item.checkedAt
            )
        }
    }

    static func isConnected() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        process.arguments = ["-f", "startwatch daemon"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
        return process.terminationStatus == 0
    }

    static func send(_ message: IPCMessage) {
        switch message {
        case .triggerCheck:
            let flagFile = StateManager.stateDir.appendingPathComponent("trigger_check")
            FileManager.default.createFile(atPath: flagFile.path, contents: nil)
        default:
            break
        }
    }
}
