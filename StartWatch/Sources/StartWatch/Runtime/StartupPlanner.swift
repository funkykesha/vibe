import Foundation

enum StartupAction: Equatable {
    case ownerWithMenu
    case ownerHeadless
    case clientWithMenu
    case duplicateHeadlessExit
    case fatalExit
}

func resolveStartupAction(showMenu: Bool, outcome: DaemonCoordinator.StartOutcome) -> StartupAction {
    switch outcome {
    case .owner:
        return showMenu ? .ownerWithMenu : .ownerHeadless
    case .nonOwner:
        return showMenu ? .clientWithMenu : .duplicateHeadlessExit
    case .failed:
        return .fatalExit
    }
}
