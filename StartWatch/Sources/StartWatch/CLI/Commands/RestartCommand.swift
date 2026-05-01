// StartWatch — RestartCommand: перезапуск одного или всех упавших сервисов с live выводом
import Foundation

enum RestartCommand {
    static func run(args: [String]) {
        let target = args.first ?? "all"

        guard let config = ConfigManager.load() else {
            fputs("\(ANSIColors.red)No config found\(ANSIColors.reset)\n", stderr)
            exit(1)
        }

        if target == "all" || target == "failed" {
            print("\(ANSIColors.dim)Checking services...\(ANSIColors.reset)")
            let results = runSync {
                await ServiceChecker.checkAll(services: config.services)
            }

            let failed = results.filter { !$0.isRunning }
            if failed.isEmpty {
                print("\(ANSIColors.green)All services are running!\(ANSIColors.reset)")
                exit(0)
            }

            if ANSIColors.isTTY {
                runLiveRestart(services: failed, config: config)
            } else {
                runAppendOnlyRestart(services: failed, config: config)
            }
        } else {
            StartCommand.run(args: args)
        }
    }

    private static func runLiveRestart(services: [CheckResult], config: AppConfig) {
        let defaults = UserDefaults(suiteName: "com.user.startwatch")
        let defaultTimeout = defaults?.integer(forKey: "startupTimeout") ?? 10

        var renderer = RestartLiveRenderer()
        var results: [String: (status: String, elapsed: Double, detail: String)] = [:]
        var completed: Set<String> = []
        let startTime = Date()

        let startingResults = services.map { service in
            CodableCheckResult(
                serviceName: service.service.name,
                isRunning: false,
                detail: "starting",
                checkedAt: startTime,
                isStarting: true
            )
        }
        StateManager.saveCodableResults(startingResults)

        for service in services {
            let timeout = service.service.startupTimeout ?? defaultTimeout

            results[service.service.name] = ("starting", 0.0, "")

            renderer.renderStarting(name: service.service.name, elapsed: 0.0)

            ProcessManager().restart(service: service.service)

            Thread.sleep(forTimeInterval: 0.1)
        }

        let processManager = ProcessManager()
        var totalFailed = 0

        while completed.count < services.count {
            Thread.sleep(forTimeInterval: 0.5)
            let now = Date()

            for service in services {
                let name = service.service.name
                if completed.contains(name) { continue }

                let elapsed = now.timeIntervalSince(startTime)

                let checkResult = runSync {
                    await ServiceChecker.check(service: service.service)
                }

                let timeout = service.service.startupTimeout ?? defaultTimeout

                if checkResult.isRunning {
                    completed.insert(name)
                    renderer.finalizeRow(
                        name: name,
                        status: "running",
                        elapsed: elapsed,
                        detail: checkResult.detail
                    )
                    results[name] = ("running", elapsed, checkResult.detail)
                } else if elapsed >= Double(timeout) {
                    completed.insert(name)
                    totalFailed += 1
                    renderer.finalizeRow(
                        name: name,
                        status: "failed",
                        elapsed: elapsed,
                        detail: "timeout (\(timeout)s)"
                    )
                    results[name] = ("failed", elapsed, "timeout")
                } else {
                    renderer.updateStarting(
                        name: name,
                        elapsed: elapsed
                    )
                    results[name] = ("starting", elapsed, "")
                }
            }
        }

        print()
        if totalFailed > 0 {
            print("\(ANSIColors.red)Restarted \(services.count) services, \(totalFailed) failed\(ANSIColors.reset)")
            exit(Int32(totalFailed))
        } else {
            print("\(ANSIColors.green)Restarted \(services.count) services successfully\(ANSIColors.reset)")
            exit(0)
        }
    }

    private static func runAppendOnlyRestart(services: [CheckResult], config: AppConfig) {
        let defaults = UserDefaults(suiteName: "com.user.startwatch")
        let defaultTimeout = defaults?.integer(forKey: "startupTimeout") ?? 10

        var totalFailed = 0

        for service in services {
            let timeout = service.service.startupTimeout ?? defaultTimeout
            let startTime = Date()

            print("Restarting \(service.service.name)...")

            ProcessManager().restart(service: service.service)

            Thread.sleep(forTimeInterval: 0.1)

            let processManager = ProcessManager()
            var succeeded = false

            while Date().timeIntervalSince(startTime) < Double(timeout) {
                Thread.sleep(forTimeInterval: 0.5)

                let checkResult = runSync {
                    await ServiceChecker.check(service: service.service)
                }

                if checkResult.isRunning {
                    succeeded = true
                    break
                }
            }

            let elapsed = Date().timeIntervalSince(startTime)

            if succeeded {
                print("  \(ANSIColors.green)✓\(ANSIColors.reset) running after \(String(format: "%.1f", elapsed))s")
            } else {
                totalFailed += 1
                print("  \(ANSIColors.red)✗\(ANSIColors.reset) failed after \(String(format: "%.1f", elapsed))s (timeout \(timeout)s)")
            }
            print()
        }

        if totalFailed > 0 {
            print("\(ANSIColors.red)Restarted \(services.count) services, \(totalFailed) failed\(ANSIColors.reset)")
            exit(Int32(totalFailed))
        } else {
            print("\(ANSIColors.green)Restarted \(services.count) services successfully\(ANSIColors.reset)")
            exit(0)
        }
    }
}

struct RestartLiveRenderer {
    private var rows: [String: Int] = [:]
    private var startingRows: [String] = []
    private var finalizedCount = 0

    mutating func renderStarting(name: String, elapsed: Double) {
        let elapsedStr = String(format: "starting... %.1fs", elapsed)
        let row = "⏳  \(name.padRight(30)) \(ANSIColors.dim)\(elapsedStr)\(ANSIColors.reset)"

        print(row)
        rows[name] = finalizedCount + startingRows.count
        startingRows.append(name)
    }

    mutating func updateStarting(name: String, elapsed: Double) {
        guard rows[name] != nil else { return }
        let elapsedStr = String(format: "starting... %.1fs", elapsed)
        let line = "⏳  \(name.padRight(30)) \(ANSIColors.dim)\(elapsedStr)\(ANSIColors.reset)"

        print("\(ANSIColors.cursorUp(1))\(ANSIColors.clearLine)\(line)", terminator: "")
        fflush(stdout)
    }

    mutating func finalizeRow(name: String, status: String, elapsed: Double, detail: String) {
        guard rows[name] != nil else { return }

        let icon: String
        let color: String
        switch status {
        case "running":
            icon = "✓"
            color = ANSIColors.green
        case "failed":
            icon = "✗"
            color = ANSIColors.red
        default:
            icon = "?"
            color = ANSIColors.yellow
        }

        let elapsedStr = String(format: "%.1fs", elapsed)
        let line = "\(icon)  \(name.padRight(30)) \(color)\(status.padRight(10))\(ANSIColors.reset) \(ANSIColors.dim)\(elapsedStr)\(ANSIColors.reset)"

        if let index = startingRows.firstIndex(of: name) {
            startingRows.remove(at: index)
        }

        print("\(ANSIColors.cursorUp(1))\(ANSIColors.clearLine)\(line)")
        finalizedCount += 1
    }
}

extension String {
    func padRight(_ length: Int) -> String {
        return self.padding(toLength: max(self.count, length), withPad: " ", startingAt: 0)
    }
}
