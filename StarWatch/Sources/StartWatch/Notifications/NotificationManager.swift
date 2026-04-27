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

    private override init() {
        super.init()
        // UNUserNotificationCenter crashes without .app bundle (no bundleIdentifier)
        guard Bundle.main.bundleIdentifier != nil else { return }
        setupCategories()
    }

    // MARK: - Setup

    func requestAuthorization() {
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
        let category = UNNotificationCategory(
            identifier: categoryID,
            actions: [openAction, restartAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // MARK: - Send

    func sendAlert(failedServices: [CheckResult]) {
        let names = failedServices.map(\.service.name).joined(separator: ", ")
        let content = UNMutableNotificationContent()
        content.title = "Services Down"
        content.body = "Not running: \(names)"
        content.categoryIdentifier = categoryID
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[Notifications] Send error: \(error.localizedDescription)")
            }
        }
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
