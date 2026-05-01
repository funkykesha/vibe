// StartWatch — CheckResult: модель результата проверки сервиса
import Foundation

struct CheckResult {
    let service: ServiceConfig
    let isRunning: Bool
    let detail: String
    let checkedAt: Date
    let isStarting: Bool

    init(service: ServiceConfig, isRunning: Bool, detail: String, checkedAt: Date = Date(), isStarting: Bool = false) {
        self.service = service
        self.isRunning = isRunning
        self.detail = detail
        self.checkedAt = checkedAt
        self.isStarting = isStarting
    }

    func toCodable() -> CodableCheckResult {
        CodableCheckResult(
            serviceName: service.name,
            isRunning: isRunning,
            detail: detail,
            checkedAt: checkedAt,
            isStarting: isStarting
        )
    }

    func toJSON() -> [String: Any] {
        var dict: [String: Any] = [
            "name": service.name,
            "isRunning": isRunning,
            "detail": detail,
            "checkedAt": ISO8601DateFormatter().string(from: checkedAt)
        ]
        if isStarting {
            dict["isStarting"] = true
        }
        return dict
    }
}

struct CodableCheckResult: Codable {
    let serviceName: String
    let isRunning: Bool
    let detail: String
    let checkedAt: Date
    let isStarting: Bool

    init(serviceName: String, isRunning: Bool, detail: String, checkedAt: Date, isStarting: Bool = false) {
        self.serviceName = serviceName
        self.isRunning = isRunning
        self.detail = detail
        self.checkedAt = checkedAt
        self.isStarting = isStarting
    }
}
