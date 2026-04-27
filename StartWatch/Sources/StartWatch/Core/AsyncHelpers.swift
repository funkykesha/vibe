// StartWatch — AsyncHelpers: запуск async кода из синхронного контекста CLI
import Foundation

func runSync<T>(_ block: @escaping () async -> T) -> T {
    let semaphore = DispatchSemaphore(value: 0)
    var result: T?
    Task {
        result = await block()
        semaphore.signal()
    }
    semaphore.wait()
    return result!
}
