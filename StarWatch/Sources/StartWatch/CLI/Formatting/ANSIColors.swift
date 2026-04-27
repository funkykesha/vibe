// StartWatch — ANSIColors: ANSI escape codes для цветного вывода
import Foundation

enum ANSIColors {
    static let reset   = "\u{001B}[0m"
    static let bold    = "\u{001B}[1m"
    static let dim     = "\u{001B}[2m"
    static let red     = "\u{001B}[31m"
    static let green   = "\u{001B}[32m"
    static let yellow  = "\u{001B}[33m"
    static let cyan    = "\u{001B}[36m"
    static let white   = "\u{001B}[37m"
    static let bgRed   = "\u{001B}[41m"
    static let bgGreen = "\u{001B}[42m"

    static var isEnabled: Bool = {
        guard isatty(STDOUT_FILENO) != 0 else { return false }
        return !CommandLine.arguments.contains("--no-color")
    }()

    static func colored(_ text: String, _ color: String) -> String {
        isEnabled ? "\(color)\(text)\(reset)" : text
    }
}
