import Foundation

enum VictoryReason: String, Codable, Equatable {
    case bastogneHeldByGermany
    case bastogneAndStVithControlledByGermany
    case alliedUnitsDestroyed
    case bastogneHeldByAlliesAtFinalTurn
    case germanUnitsDestroyed
    case germanArmorUnsupplied
    case mingHoldsMandateAtFinalTurn
    case qingBreaksPassAndCapital
    case dashunControlsCentralPlain
    case daxiControlsHuguangBase
    case mingHoldsMostKeyObjectivesAtFinalTurn
    case mingMandateCollapsedAtFinalTurn

    var displayName: String {
        switch self {
        case .bastogneHeldByGermany:
            return "巴斯托涅失守"
        case .bastogneAndStVithControlledByGermany:
            return "双城失守"
        case .alliedUnitsDestroyed:
            return "盟军重创"
        case .bastogneHeldByAlliesAtFinalTurn:
            return "巴斯托涅守住"
        case .germanUnitsDestroyed:
            return "德军重创"
        case .germanArmorUnsupplied:
            return "装甲断补"
        case .mingHoldsMandateAtFinalTurn:
            return "守住京师关口"
        case .qingBreaksPassAndCapital:
            return "破关入京"
        case .dashunControlsCentralPlain:
            return "据中原秦陕"
        case .daxiControlsHuguangBase:
            return "据湖广粮区"
        case .mingHoldsMostKeyObjectivesAtFinalTurn:
            return "保有要冲"
        case .mingMandateCollapsedAtFinalTurn:
            return "明廷失势"
        }
    }
}

struct VictoryState: Codable, Equatable {
    var winner: Faction?
    var reason: VictoryReason?
    var eliminatedGermanDivisions: Int
    var eliminatedAlliedDivisions: Int
    var germanBastogneHeldSinceTurn: Int?
    var germanArmorUnsuppliedSinceTurn: Int?

    static var ongoing: VictoryState {
        VictoryState(
            winner: nil,
            reason: nil,
            eliminatedGermanDivisions: 0,
            eliminatedAlliedDivisions: 0,
            germanBastogneHeldSinceTurn: nil,
            germanArmorUnsuppliedSinceTurn: nil
        )
    }

    mutating func recordEliminatedDivision(faction: Faction) {
        switch faction {
        case .germany:
            eliminatedGermanDivisions += 1
        case .allies:
            eliminatedAlliedDivisions += 1
        case .ming, .qing, .dashun, .daxi, .localNeutral:
            break
        }
    }
}
