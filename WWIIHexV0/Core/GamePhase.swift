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
            return "German AI"
        case .alliedPlayer:
            return "Allied Player"
        case .aiAction:
            return "AI Action"
        case .humanAction:
            return "Human Action"
        case .resolution:
            return "Resolution"
        }
    }
}
