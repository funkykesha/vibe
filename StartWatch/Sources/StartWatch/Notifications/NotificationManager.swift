// StartWatch — NotificationManager: нативные macOS нотификации
import Foundation
import UserNotifications

final class NotificationManager: NSObject {
    static let shared = NotificationManager()

    var onOpenReport: (() -> Void)?
    var onRestartFailed: (() -> Void)?

    private let categoryID = "STARTWATCH_ALERT"
    private let actionOpenID = "OPEN_CLI"
    private let actionRestartID = "RESTART_ALL"

    // Notification identifiers
    private let alertIdentifier = "startwatch-services-down"
    private let recoveredIdentifier = "startwatch-services-recovered"
    private let configInvalidIdentifier = "startwatch-config-invalid"

    // MARK: - Notification Categories

    private enum NotificationCategory {
        case alert
        case recovered
        case configInvalid

        var categoryIdentifier: String {
            switch self {
            case .alert:
                return "STARTWATCH_ALERT"
            case .recovered:
                return "STARTWATCH_RECOVERED"
            case .configInvalid:
                return "STARTWATCH_CONFIG_INVALID"
            }
        }
    }

    // MARK: - Delivery Tracking

    private enum DeliveryStatus: String {
        case sent = "sent"
        case delivered = "delivered"
        case failed = "failed"
    }

    private struct NotificationDelivery {
        let identifier: String
        let timestamp: Date
        var status: DeliveryStatus
        var error: String?

        init(identifier: String, status: DeliveryStatus, error: String? = nil) {
            self.identifier = identifier
            self.timestamp = Date()
            self.status = status
            self.error = error
        }
    }

    private var deliveryHistory: [NotificationDelivery] = []

    // MARK: - Notification Content History

    private struct NotificationHistoryEntry {
        let identifier: String
        let timestamp: Date
        let title: String
        let body: String
        let category: String

        init(identifier: String, title: String, body: String, category: String) {
            self.identifier = identifier
            self.timestamp = Date()
            self.title = title
            self.body = body
            self.category = category
        }
    }

    private let maxHistoryCount = 100
    private var notificationHistory: [NotificationHistoryEntry] = []

    // MARK: - Notification Identifiers

    private enum NotificationIdentifier {
        static let alert = "com.startwatch.service-alert"
        static let recovered = "com.startwatch.service-recovered"
        static let configInvalid = "com.startwatch.config-invalid"
    }

    private override init() {
        super.init()
        // UNUserNotificationCenter crashes without .app bundle
        guard Self.isAppBundleContext() else { return }
        setupCategories()
    }

    internal init(
        onOpenReport: (() -> Void)? = nil,
        onRestartFailed: (() -> Void)? = nil,
        skipSetup: Bool = false
    ) {
        super.init()
        self.onOpenReport = onOpenReport
        self.onRestartFailed = onRestartFailed

        // UNUserNotificationCenter crashes without .app bundle
        guard Self.isAppBundleContext() else { return }
        setupCategories()
    }

    // MARK: - Setup

    func requestAuthorization() {
        guard Self.isAppBundleContext() else { return }

        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
                print("[Notifications] Auth error: \(error.localizedDescription)")
            }
        }
        UNUserNotificationCenter.current().delegate = self
    }

    private func setupCategories() {
        guard Self.isAppBundleContext() else { return }

        let openAction = UNNotificationAction(
            identifier: actionOpenID,
            title: "Open in Terminal",
            options: .foreground
        )
        let restartAction = UNNotificationAction(
            identifier: actionRestartID,
            title: "Restart All",
            options: .foreground
        )

        // Alert category: open + restart actions
        let alertCategory = UNNotificationCategory(
            identifier: NotificationCategory.alert.categoryIdentifier,
            actions: [openAction, restartAction],
            intentIdentifiers: [],
            options: []
        )

        // Recovered category: open action only
        let recoveredCategory = UNNotificationCategory(
            identifier: NotificationCategory.recovered.categoryIdentifier,
            actions: [openAction],
            intentIdentifiers: [],
            options: []
        )

        // Config invalid category: no actions
        let configInvalidCategory = UNNotificationCategory(
            identifier: NotificationCategory.configInvalid.categoryIdentifier,
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([alertCategory, recoveredCategory, configInvalidCategory])
    }

    // MARK: - Send

    private func send(content: UNMutableNotificationContent, identifier: String, sound: UNNotificationSound? = .default) {
        if let sound = sound {
            content.sound = sound
        }

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        let historyEntry = NotificationHistoryEntry(
            identifier: identifier,
            title: content.title,
            body: content.body,
            category: content.categoryIdentifier
        )
        notificationHistory.append(historyEntry)
        if notificationHistory.count > maxHistoryCount {
            notificationHistory.removeFirst(notificationHistory.count - maxHistoryCount)
        }

        let delivery = NotificationDelivery(identifier: identifier, status: .sent)
        deliveryHistory.append(delivery)

        guard Self.isAppBundleContext() else { return }

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                print("[Notifications] Send error: \(error.localizedDescription)")
                if let index = self.deliveryHistory.firstIndex(where: { $0.identifier == identifier && $0.status == .sent }) {
                    self.deliveryHistory[index].status = .failed
                    self.deliveryHistory[index].error = error.localizedDescription
                }
            } else {
                if let index = self.deliveryHistory.firstIndex(where: { $0.identifier == identifier && $0.status == .sent }) {
                    self.deliveryHistory[index].status = .delivered
                }
            }
        }
    }

    static func isAppBundleContext(bundlePathExtension: String = Bundle.main.bundleURL.pathExtension) -> Bool {
        bundlePathExtension == "app"
    }

    private func getRecentDeliveries(limit: Int = 10) -> [NotificationDelivery] {
        return Array(deliveryHistory.suffix(limit))
    }

    private func getRecentNotifications(limit: Int = 10) -> [NotificationHistoryEntry] {
        return Array(notificationHistory.suffix(limit))
    }

    func sendAlert(failedServices: [CheckResult], showDetails: Bool, sound: Bool = false) {
        let content = UNMutableNotificationContent()
        content.categoryIdentifier = categoryID

        if failedServices.count == 1 {
            let service = failedServices[0]
            content.title = "Service Down: \(service.service.name)"
            if showDetails {
                content.body = service.detail
            } else {
                content.body = "Not running"
            }
        } else {
            let names = failedServices.map { $0.service.name }.joined(separator: "; ")
            content.title = "Services Down (\(failedServices.count))"
            if showDetails {
                let details = failedServices.map { "\($0.service.name): \($0.detail)" }.joined(separator: "; ")
                content.body = details
            } else {
                content.body = names
            }
        }

        let soundOption: UNNotificationSound? = sound ? .default : nil
        send(content: content, identifier: alertIdentifier, sound: soundOption)
    }

    func sendRecovered(services: [CheckResult], sound: Bool = false) {
        let content = UNMutableNotificationContent()
        content.categoryIdentifier = NotificationCategory.recovered.categoryIdentifier

        if services.count == 1 {
            content.title = "Service Recovered"
            content.body = services[0].service.name
        } else {
            content.title = "Services Recovered"
            content.body = services.map { $0.service.name }.joined(separator: "; ")
        }

        let soundOption: UNNotificationSound? = sound ? .default : nil
        send(content: content, identifier: recoveredIdentifier, sound: soundOption)
    }

    func sendConfigInvalid(errors: [String], sound: Bool = false) {
        let content = UNMutableNotificationContent()
        content.title = "Config Error"
        content.body = errors.joined(separator: "; ")
        content.categoryIdentifier = NotificationCategory.configInvalid.categoryIdentifier

        let soundOption: UNNotificationSound? = sound ? .default : nil
        send(content: content, identifier: configInvalidIdentifier, sound: soundOption)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        switch response.actionIdentifier {
        case actionOpenID, UNNotificationDefaultActionIdentifier:
            onOpenReport?()
        case actionRestartID:
            onRestartFailed?()
        default:
            break
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
