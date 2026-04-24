import UserNotifications

class Notifier {
    static func requestPermission(completion: @escaping () -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                NSLog("Notification permission granted")
            } else if let error = error {
                NSLog("Notification permission error: %@", error as NSError)
            }
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    static func sendOvertimeNotification(minutes: Int) {
        var level = 0
        if minutes >= 10 && minutes < 20 {
            level = 1
        } else if minutes >= 20 {
            level = 2
        }

        let (_, message) = getEntry(level: level)

        let titles = [
            "Рабочий день закончился",
            "Уже пора заканчивать",
            "ХВАТИТ РАБОТАТЬ!",
        ]
        let title = titles[level]

        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeStr = formatter.string(from: now)

        let body = "\(timeStr) — \(message)"

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body

        if level >= 1 {
            content.sound = .default
        }

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                NSLog("Failed to send notification: %@", error as NSError)
            }
        }
    }
}
