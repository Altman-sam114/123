import Foundation

enum GamePhase: String, Codable, Equatable, CaseIterable {
    case germanAI
    case alliedPlayer
    case aiAction
    case humanAction
    case resolution

    var displayName: String {
        switch self {
        case .germanAI:
            return "军机行动"
        case .alliedPlayer:
            return "玩家行令"
        case .aiAction:
            return "军机行动"
        case .humanAction:
            return "玩家行令"
        case .resolution:
            return "结算"
        }
    }

    var allowsHumanCommands: Bool {
        switch self {
        case .alliedPlayer,
             .humanAction:
            return true
        case .germanAI,
             .aiAction,
             .resolution:
            return false
        }
    }
}
