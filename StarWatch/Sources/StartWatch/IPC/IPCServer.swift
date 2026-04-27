// StartWatch — IPCServer: daemon мониторит flag-файлы от CLI и menu-agent
import Foundation

final class IPCServer {
    private var timer: Timer?
    var onTriggerCheck: (() -> Void)?

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.pollFlags()
        }
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func pollFlags() {
        // CLI trigger_check flag
        let flagFile = StateManager.stateDir.appendingPathComponent("trigger_check")
        if FileManager.default.fileExists(atPath: flagFile.path) {
            try? FileManager.default.removeItem(at: flagFile)
            onTriggerCheck?()
        }

        // Menu agent commands
        let commandFile = StateManager.stateDir.appendingPathComponent("menu_command.json")
        guard FileManager.default.fileExists(atPath: commandFile.path),
              let data = try? Data(contentsOf: commandFile),
              let cmd = try? JSONDecoder().decode(MenuAgentIPCCommand.self, from: data) else { return }
        try? FileManager.default.removeItem(at: commandFile)
        switch cmd.action {
        case "check_now":
            onTriggerCheck?()
        case "quit":
            exit(0)
        default:
            break
        }
    }

    deinit {
        stop()
    }
}

private struct MenuAgentIPCCommand: Codable {
    let action: String
}
