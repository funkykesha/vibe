// StartWatch — StatusCommand: показ текущего статуса сервисов
import Foundation

enum StatusCommand {
    static func run(args: [String]) {
        let jsonOutput = args.contains("--json")
        let tagFilter = extractTag(from: args)

        // Попробовать кэш от daemon
        if let cached = IPCClient.getLastResults() {
            let filtered = filterByTag(cached, tag: tagFilter)
            if jsonOutput {
                printJSON(filtered)
            } else {
                ReportBuilder.printStatusReport(filtered)
            }
            exit(Int32(filtered.filter { !$0.isRunning }.count))
        }

        // Daemon не запущен — live проверка
        guard let config = ConfigManager.load() else {
            fputs("\(ANSIColors.red)Error: No config found.\(ANSIColors.reset)\n", stderr)
            fputs("Run: startwatch config\n", stderr)
            exit(1)
        }

        print("\(ANSIColors.dim)Checking services...\(ANSIColors.reset)")

        let results = runSync {
            await ServiceChecker.checkAll(services: config.services)
        }

        let filtered = filterByTag(results, tag: tagFilter)

        if jsonOutput {
            printJSON(filtered)
        } else {
            ReportBuilder.printStatusReport(filtered)
        }

        exit(Int32(filtered.filter { !$0.isRunning }.count))
    }

    private static func extractTag(from args: [String]) -> String? {
        guard let idx = args.firstIndex(of: "--tag"), idx + 1 < args.count else { return nil }
        return args[idx + 1]
    }

    private static func filterByTag(_ results: [CheckResult], tag: String?) -> [CheckResult] {
        guard let tag = tag else { return results }
        return results.filter { $0.service.tags?.contains(tag) ?? false }
    }

    private static func printJSON(_ results: [CheckResult]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
        let codable = results.map { $0.toCodable() }
        if let data = try? encoder.encode(codable),
           let str = String(data: data, encoding: .utf8) {
            print(str)
        }
    }
}
