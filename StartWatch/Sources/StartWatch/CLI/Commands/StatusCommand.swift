// StartWatch — StatusCommand: показ текущего статуса сервисов
import Foundation

enum StatusCommand {
    static func run(args: [String]) {
        let jsonOutput = args.contains("--json")
        let tagFilter = extractTag(from: args)

        if IPCClient.isConnected(), let live = IPCClient.getStatusSnapshot() {
            let mapped = mapToResults(live)
            let filtered = filterByTag(mapped, tag: tagFilter)
            if jsonOutput {
                printJSON(filtered)
            } else {
                ReportBuilder.printStatusReport(filtered)
            }
            exit(Int32(filtered.filter { !$0.isRunning }.count))
        }

        // Daemon offline: checkpoint fallback
        if let checkpoint = IPCClient.getLastResults() {
            let filtered = filterByTag(checkpoint, tag: tagFilter)
            if !jsonOutput, let checkedAt = filtered.first?.checkedAt {
                let seconds = Int(Date().timeIntervalSince(checkedAt))
                print("⚠️ Daemon offline. Last state from \(seconds)s ago:")
            }
            if jsonOutput {
                printJSON(filtered)
            } else {
                ReportBuilder.printStatusReport(filtered)
            }
            exit(Int32(filtered.filter { !$0.isRunning }.count))
        }

        // No checkpoint -> live check fallback
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

    private static func mapToResults(_ items: [CodableCheckResult]) -> [CheckResult] {
        guard let config = ConfigManager.load() else { return [] }
        let byName = Dictionary(uniqueKeysWithValues: items.map { ($0.serviceName, $0) })
        return config.services.compactMap { service in
            guard let item = byName[service.name] else { return nil }
            return CheckResult(
                service: service,
                isRunning: item.isRunning,
                detail: item.detail,
                checkedAt: item.checkedAt,
                isStarting: item.isStarting
            )
        }
    }
}
