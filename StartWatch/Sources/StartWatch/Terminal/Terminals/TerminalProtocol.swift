// StartWatch — TerminalProtocol: протокол для терминальных приложений
import AppKit

protocol TerminalApp {
    static var identifier: String { get }
    static var bundleID: String { get }

    static func open(command: String) throws
    static func isInstalled() -> Bool
}

extension TerminalApp {
    static func isInstalled() -> Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) != nil
    }
}
