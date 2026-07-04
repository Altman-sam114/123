import Foundation

enum Faction: String, Codable, Equatable, CaseIterable {
    case germany
    case allies
    case ming
    case qing
    case dashun
    case daxi
    case localNeutral

    /// Legacy WWII two-side fallback. New multi-power rules should use DiplomacyState.
    var opponent: Faction {
        switch self {
        case .germany:
            return .allies
        case .allies,
             .ming,
             .qing,
             .dashun,
             .daxi,
             .localNeutral:
            return .germany
        }
    }

    var displayName: String {
        switch self {
        case .germany:
            return "Germany"
        case .allies:
            return "Allies"
        case .ming:
            return "明廷"
        case .qing:
            return "后金/清"
        case .dashun:
            return "大顺"
        case .daxi:
            return "大西"
        case .localNeutral:
            return "地方中立"
        }
    }

    static var legacyCases: [Faction] {
        [.germany, .allies]
    }

    static var mingLaunchCases: [Faction] {
        [.ming, .qing, .dashun, .daxi, .localNeutral]
    }

    var isLegacyWWIIFaction: Bool {
        Self.legacyCases.contains(self)
    }

    var isLocalNeutral: Bool {
        self == .localNeutral
    }
}
