// StartWatch — CheckResult: модель результата проверки сервиса
import Foundation

struct CheckResult {
    let service: ServiceConfig
    let isRunning: Bool
    let detail: String
    let checkedAt: Date

    init(service: ServiceConfig, isRunning: Bool, detail: String, checkedAt: Date = Date()) {
        self.service = service
        self.isRunning = isRunning
        self.detail = detail
        self.checkedAt = checkedAt
    }

    func toCodable() -> CodableCheckResult {
        CodableCheckResult(
            serviceName: service.name,
            isRunning: isRunning,
            detail: detail,
            checkedAt: checkedAt
        )
    }

    func toJSON() -> [String: Any] {
        [
            "name": service.name,
            "isRunning": isRunning,
            "detail": detail,
            "checkedAt": ISO8601DateFormatter().string(from: checkedAt)
        ]
    }
}

struct CodableCheckResult: Codable {
    let serviceName: String
    let isRunning: Bool
    let detail: String
    let checkedAt: Date
}
