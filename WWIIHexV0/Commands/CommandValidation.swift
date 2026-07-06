import Foundation

enum CommandValidationError: String, Codable, Equatable {
    case wrongPhase
    case wrongFaction
    case divisionNotFound
    case targetNotFound
    case alreadyActed
    case destinationOutOfBounds
    case destinationOccupied
    case noPath
    case insufficientMovement
    case targetOutOfRange
    case invalidTargetFaction
    case regionNotFound
    case invalidRegionForHex
    case insufficientResources

    var mingDisplayText: String {
        switch self {
        case .wrongPhase:
            return "当前阶段不可行令"
        case .wrongFaction:
            return "当前主事方不符"
        case .divisionNotFound:
            return "未找到军伍"
        case .targetNotFound:
            return "未找到目标"
        case .alreadyActed:
            return "该军伍本阶段已行动"
        case .destinationOutOfBounds:
            return "目标舆图格越界"
        case .destinationOccupied:
            return "目标舆图格已有军伍"
        case .noPath:
            return "未找到可行军路线"
        case .insufficientMovement:
            return "行军力不足"
        case .targetOutOfRange:
            return "目标超出攻击范围"
        case .invalidTargetFaction:
            return "目标阵营不合"
        case .regionNotFound:
            return "未找到州府"
        case .invalidRegionForHex:
            return "舆图格未归入有效州府"
        case .insufficientResources:
            return "钱粮物资不足"
        }
    }
}

struct CommandValidation: Codable, Equatable {
    var errors: [CommandValidationError]

    var isValid: Bool {
        errors.isEmpty
    }

    static let valid = CommandValidation(errors: [])

    static func invalid(_ error: CommandValidationError) -> CommandValidation {
        CommandValidation(errors: [error])
    }
}
