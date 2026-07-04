import Foundation

struct CountryId: Hashable, Codable, Equatable, RawRepresentable, ExpressibleByStringLiteral {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(stringLiteral value: StringLiteralType) {
        self.rawValue = value
    }

    init(_ value: String) {
        self.rawValue = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

struct DiplomaticBlocId: Hashable, Codable, Equatable, RawRepresentable, ExpressibleByStringLiteral {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(stringLiteral value: StringLiteralType) {
        self.rawValue = value
    }

    init(_ value: String) {
        self.rawValue = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum DiplomaticStatus: String, Codable, Equatable, CaseIterable {
    case allied
    case coBelligerent
    case neutral
    case vassal
    case truce
    case passage
    case hostile
    case atWar

    var isHostile: Bool {
        self == .hostile || self == .atWar
    }

    var displayName: String {
        switch self {
        case .allied:
            return "同盟"
        case .coBelligerent:
            return "共同作战"
        case .neutral:
            return "观望"
        case .vassal:
            return "臣属"
        case .truce:
            return "停战"
        case .passage:
            return "借道"
        case .hostile:
            return "敌对"
        case .atWar:
            return "交战"
        }
    }
}

struct CountryProfile: Identifiable, Codable, Equatable {
    let id: CountryId
    var name: String
    var faction: Faction
    var blocId: DiplomaticBlocId
    var rulerAgentId: String
    var isPrimaryBelligerent: Bool
    var capitalRegionId: RegionId?
    var surrenderProgress: Int
    var warSupport: Int

    init(
        id: CountryId,
        name: String,
        faction: Faction,
        blocId: DiplomaticBlocId,
        rulerAgentId: String,
        isPrimaryBelligerent: Bool = false,
        capitalRegionId: RegionId? = nil,
        surrenderProgress: Int = 0,
        warSupport: Int = 70
    ) {
        self.id = id
        self.name = name
        self.faction = faction
        self.blocId = blocId
        self.rulerAgentId = rulerAgentId
        self.isPrimaryBelligerent = isPrimaryBelligerent
        self.capitalRegionId = capitalRegionId
        self.surrenderProgress = max(0, min(100, surrenderProgress))
        self.warSupport = max(0, min(100, warSupport))
    }
}

struct DiplomaticBloc: Identifiable, Codable, Equatable {
    let id: DiplomaticBlocId
    var name: String
    var faction: Faction
    var memberCountryIds: [CountryId]

    init(id: DiplomaticBlocId, name: String, faction: Faction, memberCountryIds: [CountryId]) {
        self.id = id
        self.name = name
        self.faction = faction
        self.memberCountryIds = memberCountryIds.sorted { $0.rawValue < $1.rawValue }
    }
}

struct DiplomaticRelation: Identifiable, Codable, Equatable {
    let firstCountryId: CountryId
    let secondCountryId: CountryId
    var status: DiplomaticStatus
    var tension: Int
    var sinceTurn: Int

    var id: String {
        "\(firstCountryId.rawValue):\(secondCountryId.rawValue)"
    }

    init(
        firstCountryId: CountryId,
        secondCountryId: CountryId,
        status: DiplomaticStatus,
        tension: Int = 0,
        sinceTurn: Int = 1
    ) {
        if firstCountryId.rawValue <= secondCountryId.rawValue {
            self.firstCountryId = firstCountryId
            self.secondCountryId = secondCountryId
        } else {
            self.firstCountryId = secondCountryId
            self.secondCountryId = firstCountryId
        }
        self.status = status
        self.tension = max(0, min(100, tension))
        self.sinceTurn = max(1, sinceTurn)
    }

    func contains(_ countryId: CountryId) -> Bool {
        firstCountryId == countryId || secondCountryId == countryId
    }
}

enum RulerStrategicPosture: String, Codable, Equatable, CaseIterable {
    case offensive
    case defensive
    case coalitionMaintenance
    case stabilizeFront

    var displayName: String {
        switch self {
        case .offensive:
            return "进取"
        case .defensive:
            return "守势"
        case .coalitionMaintenance:
            return "维系盟局"
        case .stabilizeFront:
            return "稳住战线"
        }
    }
}

struct RulerDecisionRecord: Identifiable, Codable, Equatable {
    let id: String
    let turn: Int
    let faction: Faction
    let countryId: CountryId?
    let rulerAgentId: String
    let posture: RulerStrategicPosture
    let preferredFrontZoneId: FrontZoneId?
    let targetRegionIds: [RegionId]
    let attackThresholdAdjustment: Double
    let reserveBias: Int
    let diplomacySummary: String
    let rationale: String
}

struct DiplomacyState: Codable, Equatable {
    var countries: [CountryProfile]
    var blocs: [DiplomaticBloc]
    var relations: [DiplomaticRelation]
    var rulerRecords: [RulerDecisionRecord]
    var lastUpdatedTurn: Int?

    init(
        countries: [CountryProfile] = [],
        blocs: [DiplomaticBloc] = [],
        relations: [DiplomaticRelation] = [],
        rulerRecords: [RulerDecisionRecord] = [],
        lastUpdatedTurn: Int? = nil
    ) {
        self.countries = countries.sorted { $0.id.rawValue < $1.id.rawValue }
        self.blocs = blocs.sorted { $0.id.rawValue < $1.id.rawValue }
        self.relations = relations.sorted { $0.id < $1.id }
        self.rulerRecords = rulerRecords
        self.lastUpdatedTurn = lastUpdatedTurn
    }

    static var empty: DiplomacyState {
        DiplomacyState()
    }

    static func initial(for factions: [Faction], turn: Int) -> DiplomacyState {
        var countries: [CountryProfile] = []
        var blocs: [DiplomaticBloc] = []

        let uniqueFactions = stableUnique(factions)

        if uniqueFactions.contains(.germany) {
            countries.append(
                CountryProfile(
                    id: "germany",
                    name: "German Reich",
                    faction: .germany,
                    blocId: "axis",
                    rulerAgentId: "ruler_germany",
                    isPrimaryBelligerent: true,
                    warSupport: 82
                )
            )
            blocs.append(DiplomaticBloc(id: "axis", name: "Axis", faction: .germany, memberCountryIds: ["germany"]))
        }

        if uniqueFactions.contains(.allies) {
            countries.append(
                CountryProfile(
                    id: "united_states",
                    name: "United States",
                    faction: .allies,
                    blocId: "allied_coalition",
                    rulerAgentId: "ruler_allies",
                    isPrimaryBelligerent: true,
                    warSupport: 78
                )
            )
            countries.append(
                CountryProfile(
                    id: "united_kingdom",
                    name: "United Kingdom",
                    faction: .allies,
                    blocId: "allied_coalition",
                    rulerAgentId: "ruler_uk",
                    warSupport: 74
                )
            )
            countries.append(
                CountryProfile(
                    id: "belgium",
                    name: "Belgium",
                    faction: .allies,
                    blocId: "allied_coalition",
                    rulerAgentId: "ruler_belgium",
                    warSupport: 68
                )
            )
            blocs.append(
                DiplomaticBloc(
                    id: "allied_coalition",
                    name: "Allied Coalition",
                    faction: .allies,
                    memberCountryIds: ["belgium", "united_kingdom", "united_states"]
                )
            )
        }

        for faction in uniqueFactions where !faction.isLegacyWWIIFaction {
            let profile = defaultCountryProfile(for: faction)
            countries.append(profile)
            blocs.append(
                DiplomaticBloc(
                    id: profile.blocId,
                    name: profile.name,
                    faction: faction,
                    memberCountryIds: [profile.id]
                )
            )
        }

        return DiplomacyState(
            countries: countries,
            blocs: blocs,
            relations: makeInitialRelations(countries: countries, turn: turn),
            lastUpdatedTurn: turn
        )
    }

    static func initial(from factionStrings: [String], turn: Int) -> DiplomacyState {
        let factions = factionStrings.compactMap(Faction.init(rawValue:))
        return initial(for: factions.isEmpty ? Faction.legacyCases : factions, turn: turn)
    }

    var latestRulerRecord: RulerDecisionRecord? {
        rulerRecords.last
    }

    func countries(for faction: Faction) -> [CountryProfile] {
        countries.filter { $0.faction == faction }
    }

    func primaryCountry(for faction: Faction) -> CountryProfile? {
        countries(for: faction).first(where: \.isPrimaryBelligerent) ?? countries(for: faction).first
    }

    func relation(between lhs: CountryId, and rhs: CountryId) -> DiplomaticRelation? {
        let key = DiplomaticRelation(firstCountryId: lhs, secondCountryId: rhs, status: .neutral).id
        return relations.first { $0.id == key }
    }

    func relationStatus(between lhs: Faction, and rhs: Faction) -> DiplomaticStatus {
        guard lhs != rhs else {
            return .allied
        }
        guard !lhs.isLocalNeutral, !rhs.isLocalNeutral else {
            return .neutral
        }

        let lhsCountries = countries(for: lhs).map(\.id)
        let rhsCountries = countries(for: rhs).map(\.id)
        for lhsCountry in lhsCountries {
            for rhsCountry in rhsCountries {
                if let relation = relation(between: lhsCountry, and: rhsCountry) {
                    return relation.status
                }
            }
        }

        if lhs.isLegacyWWIIFaction && rhs.isLegacyWWIIFaction {
            return .atWar
        }
        return .neutral
    }

    func isHostile(_ lhs: Faction, _ rhs: Faction) -> Bool {
        relationStatus(between: lhs, and: rhs).isHostile
    }

    func isFriendly(_ lhs: Faction, _ rhs: Faction) -> Bool {
        switch relationStatus(between: lhs, and: rhs) {
        case .allied, .coBelligerent, .vassal, .passage:
            return true
        case .neutral, .truce, .hostile, .atWar:
            return false
        }
    }

    func canAttack(attacker: Faction, target: Faction?) -> Bool {
        guard let target else {
            return false
        }
        return isHostile(attacker, target)
    }

    func canEnterTerritory(faction: Faction, controller: Faction?) -> Bool {
        guard let controller else {
            return true
        }
        if controller == faction {
            return true
        }
        return !isHostile(faction, controller)
    }

    func hostileCountryIds(to faction: Faction) -> [CountryId] {
        let ownCountryIds = Set(countries(for: faction).map(\.id))
        var hostileCountryIds: Set<CountryId> = []
        for relation in relations where relation.status.isHostile {
            let touchesOwnCountry = ownCountryIds.contains(relation.firstCountryId) ||
                ownCountryIds.contains(relation.secondCountryId)
            guard touchesOwnCountry else {
                continue
            }
            if !ownCountryIds.contains(relation.firstCountryId) {
                hostileCountryIds.insert(relation.firstCountryId)
            }
            if !ownCountryIds.contains(relation.secondCountryId) {
                hostileCountryIds.insert(relation.secondCountryId)
            }
        }
        return hostileCountryIds.sorted { $0.rawValue < $1.rawValue }
    }

    func summary(for faction: Faction) -> String {
        let countryNames = countries(for: faction).map(\.name).joined(separator: "、")
        let hostileCount = hostileCountryIds(to: faction).count
        return "\(faction.displayName)：\(countryNames.isEmpty ? "未登记政治主体" : countryNames)；敌对关系 \(hostileCount)"
    }

    mutating func appendRulerRecord(_ record: RulerDecisionRecord) {
        rulerRecords.append(record)
        if rulerRecords.count > 40 {
            rulerRecords.removeFirst(rulerRecords.count - 40)
        }
        lastUpdatedTurn = record.turn
    }

    private static func makeInitialRelations(countries: [CountryProfile], turn: Int) -> [DiplomaticRelation] {
        var relations: [DiplomaticRelation] = []
        for lhsIndex in countries.indices {
            for rhsIndex in countries.indices where rhsIndex > lhsIndex {
                let lhs = countries[lhsIndex]
                let rhs = countries[rhsIndex]
                let status = initialStatus(lhs: lhs.faction, rhs: rhs.faction)
                relations.append(
                    DiplomaticRelation(
                        firstCountryId: lhs.id,
                        secondCountryId: rhs.id,
                        status: status,
                        tension: status == .atWar ? 100 : 10,
                        sinceTurn: turn
                    )
                )
            }
        }
        return relations
    }

    private static func initialStatus(lhs: Faction, rhs: Faction) -> DiplomaticStatus {
        if lhs == rhs {
            return .allied
        }
        if lhs.isLocalNeutral || rhs.isLocalNeutral {
            return .neutral
        }
        return .atWar
    }

    private static func defaultCountryProfile(for faction: Faction) -> CountryProfile {
        switch faction {
        case .ming:
            return CountryProfile(
                id: "ming",
                name: "明廷",
                faction: .ming,
                blocId: "ming_court",
                rulerAgentId: "ruler_chongzhen",
                isPrimaryBelligerent: true,
                warSupport: 61
            )
        case .qing:
            return CountryProfile(
                id: "qing",
                name: "后金/清",
                faction: .qing,
                blocId: "qing_banners",
                rulerAgentId: "ruler_huangtaiji",
                isPrimaryBelligerent: true,
                warSupport: 78
            )
        case .dashun:
            return CountryProfile(
                id: "dashun",
                name: "大顺",
                faction: .dashun,
                blocId: "dashun_camp",
                rulerAgentId: "ruler_li_zicheng",
                isPrimaryBelligerent: true,
                warSupport: 72
            )
        case .daxi:
            return CountryProfile(
                id: "daxi",
                name: "大西",
                faction: .daxi,
                blocId: "daxi_camp",
                rulerAgentId: "ruler_zhang_xianzhong",
                isPrimaryBelligerent: true,
                warSupport: 68
            )
        case .localNeutral:
            return CountryProfile(
                id: "local_neutral",
                name: "地方中立",
                faction: .localNeutral,
                blocId: "local_neutral",
                rulerAgentId: "ruler_local_neutral",
                warSupport: 35
            )
        case .germany, .allies:
            return CountryProfile(
                id: CountryId(faction.rawValue),
                name: faction.displayName,
                faction: faction,
                blocId: DiplomaticBlocId(faction.rawValue),
                rulerAgentId: "ruler_\(faction.rawValue)"
            )
        }
    }

    private static func stableUnique(_ factions: [Faction]) -> [Faction] {
        var seen: Set<Faction> = []
        var result: [Faction] = []
        for faction in factions where !seen.contains(faction) {
            seen.insert(faction)
            result.append(faction)
        }
        return result
    }
}
