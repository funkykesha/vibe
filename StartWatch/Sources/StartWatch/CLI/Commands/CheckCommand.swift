// StartWatch — CheckCommand: принудительная живая проверка
import Foundation

enum CheckCommand {
    static func run(args: [String]) {
        if IPCClient.isConnected() {
            IPCClient.send(.triggerCheck)
            print("\(ANSIColors.green)✓\(ANSIColors.reset) Check triggered via daemon")
            Thread.sleep(forTimeInterval: 3)
        }
        // Всегда показываем live результат
        guard let config = ConfigManager.load() else {
            fputs("\(ANSIColors.red)Error: No config found.\(ANSIColors.reset)\n", stderr)
            exit(1)
        }

        print("\(ANSIColors.dim)Checking services...\(ANSIColors.reset)")
        let results = runSync {
            await ServiceChecker.checkAll(services: config.services)
        }
        ReportBuilder.printStatusReport(results)

        let failCount = results.filter { !$0.isRunning }.count
        exit(Int32(failCount))
    }
}
