// StartWatch — ReportBuilder: генерация красивого статус-отчёта
import Foundation

enum ReportBuilder {
    static func printStatusReport(_ results: [CheckResult]) {
        let c = ANSIColors.self

        print()
        print("\(c.bold)  StartWatch Status\(c.reset)")
        print("  \(c.dim)\(formatDate(Date()))\(c.reset)")
        print()

        let maxName = results.map(\.service.name.count).max() ?? 10

        for result in results {
            let icon = result.isRunning
                ? c.colored("✅", c.green)
                : c.colored("❌", c.red)

            let name = result.service.name
                .padding(toLength: maxName, withPad: " ", startingAt: 0)

            let status = result.isRunning
                ? c.colored("running", c.green)
                : c.colored("down   ", c.red)

            let detail = c.colored(result.detail, c.dim)

            print("  \(icon)  \(name)  \(status)  \(detail)")

            if !result.isRunning, let start = result.service.start {
                print("  \(c.dim)     ➜ \(start)\(c.reset)")
            }
        }

        let running = results.filter(\.isRunning).count
        let total = results.count
        print()

        if running == total {
            print("  \(c.colored("All \(total) services running ✓", c.green))")
        } else {
            let failed = total - running
            print("  \(c.colored("\(failed) of \(total) services down", c.red))")
            print("  \(c.dim)Run: startwatch restart all\(c.reset)")
        }
        print()
    }

    private static func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f.string(from: date)
    }
}
