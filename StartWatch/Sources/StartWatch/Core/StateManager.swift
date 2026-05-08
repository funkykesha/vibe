// StartWatch — StateManager: персистенция состояния на диск
import Foundation

enum StateManager {
    static let stateDir: URL = {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/state/startwatch")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static let lastResultsURL = stateDir.appendingPathComponent("last_check.json")
    static let historyURL = stateDir.appendingPathComponent("history.log")
    static let socketURL = stateDir.appendingPathComponent("sock")
    static let defaultFlushIntervalSeconds: TimeInterval = 300

    struct Snapshot: Codable {
        let version: Int
        let timestamp: Date
        let services: [CodableCheckResult]
    }

    private static let stateQueue = DispatchQueue(label: "com.startwatch.state", attributes: .concurrent)
    private static var services: [String: CodableCheckResult] = [:]
    private static var lastCheckTime: Date?
    private static var generation: UInt64 = 0
    private static var lastFlushedGeneration: UInt64 = 0
    private static var flushIntervalSeconds: TimeInterval = defaultFlushIntervalSeconds

    static func saveLastResults(_ results: [CheckResult]) {
        updateInMemory(results.map { $0.toCodable() }, checkedAt: Date())
    }

    static func saveCodableResults(_ results: [CodableCheckResult]) {
        updateInMemory(results, checkedAt: Date())
    }

    static func loadLastResults() -> [CodableCheckResult]? {
        let snapshot = currentSnapshot()
        if !snapshot.services.isEmpty {
            return snapshot.services
        }
        return loadCheckpoint()?.services
    }

    static func restoreFromCheckpoint() {
        guard let checkpoint = loadCheckpoint() else {
            Logger.log(level: .info, component: "StateManager", event: "CHECKPOINT_RESTORE_EMPTY", details: ["path": .string(lastResultsURL.path)])
            return
        }
        applySnapshotToMemory(checkpoint)
    }

    static func setFlushInterval(seconds: TimeInterval?) {
        stateQueue.sync(flags: .barrier) {
            if let seconds, seconds > 0 {
                flushIntervalSeconds = seconds
            } else {
                flushIntervalSeconds = defaultFlushIntervalSeconds
            }
        }
    }

    static func configuredFlushIntervalSeconds() -> TimeInterval {
        stateQueue.sync { flushIntervalSeconds }
    }

    static func shouldFlush() -> Bool {
        stateQueue.sync { generation != lastFlushedGeneration }
    }

    static func flushIfNeeded() {
        guard shouldFlush() else { return }
        flushNow()
    }

    static func flushNow() {
        let snapshot = currentSnapshot()
        guard let data = encodeSnapshot(snapshot) else { return }
        writeCheckpointAtomically(data: data)
        stateQueue.sync(flags: .barrier) {
            lastFlushedGeneration = generation
        }
    }

    static func currentSnapshot() -> Snapshot {
        stateQueue.sync {
            let ordered = services.values.sorted { $0.serviceName < $1.serviceName }
            return Snapshot(version: 1, timestamp: lastCheckTime ?? Date(), services: ordered)
        }
    }

    static func updateInMemory(_ results: [CodableCheckResult], checkedAt: Date) {
        stateQueue.sync(flags: .barrier) {
            let incomingNames = Set(results.map { $0.serviceName })
            // prune removed services
            services = services.filter { incomingNames.contains($0.key) }
            for item in results {
                services[item.serviceName] = item
                generation &+= 1
            }
            lastCheckTime = checkedAt
        }
    }

    static func upsertService(_ result: CodableCheckResult) {
        stateQueue.sync(flags: .barrier) {
            services[result.serviceName] = result
            generation &+= 1
            lastCheckTime = result.checkedAt
        }
    }

    static func generationState() -> (generation: UInt64, lastFlushedGeneration: UInt64) {
        stateQueue.sync { (generation, lastFlushedGeneration) }
    }

    static func resetForTests() {
        stateQueue.sync(flags: .barrier) {
            services = [:]
            lastCheckTime = nil
            generation = 0
            lastFlushedGeneration = 0
            flushIntervalSeconds = defaultFlushIntervalSeconds
        }
    }

    private static func encodeSnapshot(_ snapshot: Snapshot) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(snapshot)
    }

    private static func writeCheckpointAtomically(data: Data) {
        let tmp = stateDir.appendingPathComponent("last_check.json.tmp")
        try? data.write(to: tmp, options: .atomic)
        try? FileManager.default.removeItem(at: lastResultsURL)
        try? FileManager.default.moveItem(at: tmp, to: lastResultsURL)
    }

    private static func loadCheckpoint() -> Snapshot? {
        guard let data = try? Data(contentsOf: lastResultsURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let snapshot = try? decoder.decode(Snapshot.self, from: data), snapshot.version == 1 {
            return snapshot
        }

        // backward-compat: old array payload
        if let old = try? decoder.decode([CodableCheckResult].self, from: data) {
            return Snapshot(version: 1, timestamp: old.first?.checkedAt ?? Date(), services: old)
        }
        return nil
    }

    private static func applySnapshotToMemory(_ snapshot: Snapshot) {
        stateQueue.sync(flags: .barrier) {
            services = Dictionary(uniqueKeysWithValues: snapshot.services.map { ($0.serviceName, $0) })
            lastCheckTime = snapshot.timestamp
            generation &+= UInt64(max(snapshot.services.count, 1))
            lastFlushedGeneration = generation
        }
    }
}
