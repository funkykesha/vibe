// StartWatch — CheckScheduler: таймер периодических проверок
import Foundation

final class CheckScheduler {
    private var timer: Timer?

    init(interval: TimeInterval, action: @escaping () -> Void) {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            action()
        }
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    deinit {
        timer?.invalidate()
    }
}
