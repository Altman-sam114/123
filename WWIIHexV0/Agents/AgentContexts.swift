import Foundation

// DEPRECATED as of v0.352 - kept for regression reference, not invoked by default. See WarPipelineMode.
// v0 agent context + summaries. v0 allows global visibility (no fog filtering yet);
// visibility field reserved so later versions can swap in fog-of-war.

enum AgentVisibilityState: String, Codable, Equatable {
    case visible
    case explored
    case unseen
}

struct TileSummary: Codable, Equatable {
    let coord: HexCoord
    let baseTerrain: BaseTerrain
    let hasRoad: Bool
    let controller: Faction?
    let cityName: String?
    let fortressName: String?
    let isPassable: Bool
    let visibility: AgentVisibilityState
}

struct DivisionSummary: Codable, Equatable {
    let id: String
    let name: String
    let faction: Faction
    let coord: HexCoord
    let regionId: RegionId?
    let strength: Int
    let maxStrength: Int
    let supplyState: SupplyState
    let hasActed: Bool
    let movement: Int
    let range: Int
    let isArmor: Bool
    let isArtillery: Bool
}

struct SupplySummary: Codable, Equatable {
    let friendlySupplied: Int
    let friendlyLowSupply: Int
    let friendlyEncircled: Int
    let enemySupplied: Int
    let enemyLowSupply: Int
    let enemyEncircled: Int
}

struct GovernanceAISummary: Codable, Equatable {
    let controlledRegions: Int
    let unstableRegions: Int
    let averageResistance: Int
    let averageCompliance: Int
    let lowestComplianceRegionId: RegionId?

    static var empty: GovernanceAISummary {
        GovernanceAISummary(
            controlledRegions: 0,
            unstableRegions: 0,
            averageResistance: 0,
            averageCompliance: 0,
            lowestComplianceRegionId: nil
        )
    }

    static func from(faction: Faction, map: MapState) -> GovernanceAISummary {
        let regions = map.regions.values
            .filter { $0.controller == faction && $0.isPassable }

        guard !regions.isEmpty else {
            return .empty
        }

        let states = regions.map { $0.occupationState ?? .stable }
        let resistanceTotal = states.reduce(0) { $0 + $1.resistance }
        let complianceTotal = states.reduce(0) { $0 + $1.compliance }
        let unstableCount = states.filter {
            $0.resistance >= 25 || $0.compliance < 55
        }.count
        let lowestComplianceRegionId = regions.min {
            let lhsState = $0.occupationState ?? .stable
            let rhsState = $1.occupationState ?? .stable
            if lhsState.compliance == rhsState.compliance {
                return $0.id.rawValue < $1.id.rawValue
            }
            return lhsState.compliance < rhsState.compliance
        }?.id

        return GovernanceAISummary(
            controlledRegions: regions.count,
            unstableRegions: unstableCount,
            averageResistance: resistanceTotal / regions.count,
            averageCompliance: complianceTotal / regions.count,
            lowestComplianceRegionId: lowestComplianceRegionId
        )
    }

    var displaySummary: String {
        let regionText = lowestComplianceRegionId?.mingDisplayTitle ?? "无"
        return "控制州府 \(controlledRegions)，不稳 \(unstableRegions)，平均民变 \(averageResistance)，平均行政 \(averageCompliance)，最低行政 \(regionText)"
    }
}

struct EconomyAISummary: Codable, Equatable {
    let stockpile: EconomyResources
    let lastIncome: EconomyResources
    let lastUpkeep: EconomyResources
    let lastReinforcementSpend: EconomyResources
    let grainShortfall: Int
    let silverShortfall: Int
    let manpowerShortfall: Int
    let governanceSummary: GovernanceAISummary

    static func from(
        ledger: FactionEconomyLedger,
        faction: Faction? = nil,
        map: MapState? = nil
    ) -> EconomyAISummary {
        let minimumActionCost = ProductionKind.allCases
            .map(\.cost)
            .reduce(EconomyResources(manpower: Int.max, industry: Int.max, supplies: Int.max)) { partial, cost in
                EconomyResources(
                    manpower: min(partial.manpower, cost.manpower),
                    industry: min(partial.industry, cost.industry),
                    supplies: min(partial.supplies, cost.supplies)
                )
            }
        let minimumRecruitmentCost = ProductionKind.allCases
            .filter { $0 != .supplyStockpile }
            .map(\.cost)
            .reduce(EconomyResources(manpower: Int.max, industry: Int.max, supplies: Int.max)) { partial, cost in
                EconomyResources(
                    manpower: min(partial.manpower, cost.manpower),
                    industry: min(partial.industry, cost.industry),
                    supplies: min(partial.supplies, cost.supplies)
                )
            }
        let governanceSummary: GovernanceAISummary
        if let faction, let map {
            governanceSummary = GovernanceAISummary.from(faction: faction, map: map)
        } else {
            governanceSummary = .empty
        }

        return EconomyAISummary(
            stockpile: ledger.stockpile,
            lastIncome: ledger.lastIncome,
            lastUpkeep: ledger.lastUpkeep,
            lastReinforcementSpend: ledger.lastReinforcementSpend,
            grainShortfall: max(0, ledger.lastUpkeep.supplies - ledger.stockpile.supplies),
            silverShortfall: max(0, minimumActionCost.industry - ledger.stockpile.industry),
            manpowerShortfall: max(0, minimumRecruitmentCost.manpower - ledger.stockpile.manpower),
            governanceSummary: governanceSummary
        )
    }

    var displaySummary: String {
        "库存 \(stockpile.displaySummary)；收入 \(lastIncome.displaySummary)；军粮维护 \(lastUpkeep.displaySummary)；补员 \(lastReinforcementSpend.displaySummary)；缺口 民力 \(manpowerShortfall), 银两 \(silverShortfall), 粮草 \(grainShortfall)；治理 \(governanceSummary.displaySummary)"
    }
}

enum CourtPolicyFocus: String, Codable, Equatable, CaseIterable, Identifiable {
    case raiseTax
    case relief
    case appeaseGentry
    case agrarianReform
    case fortify
    case trainMilitia
    case firearmReform
    case redCannonMaintenance
    case grainTransport

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .raiseTax:
            return "征饷"
        case .relief:
            return "赈济安民"
        case .appeaseGentry:
            return "招抚乡绅"
        case .agrarianReform:
            return "农政屯田"
        case .fortify:
            return "修城固守"
        case .trainMilitia:
            return "整训团练"
        case .firearmReform:
            return "火器整备"
        case .redCannonMaintenance:
            return "红衣炮维护"
        case .grainTransport:
            return "粮台驿道"
        }
    }

    var domainDisplayName: String {
        switch self {
        case .raiseTax:
            return "经济"
        case .relief:
            return "政策"
        case .appeaseGentry:
            return "政策"
        case .agrarianReform:
            return "经济/科技"
        case .fortify:
            return "军事"
        case .trainMilitia:
            return "政策/军事"
        case .firearmReform:
            return "科技"
        case .redCannonMaintenance:
            return "科技/军事"
        case .grainTransport:
            return "经济/科技/军事"
        }
    }

    var benefitSummary: String {
        switch self {
        case .raiseTax:
            return "短期补银，支撑募兵与军饷。"
        case .relief:
            return "压低民变，恢复行政掌控。"
        case .appeaseGentry:
            return "安抚地方中立、乡绅团练和新附州府。"
        case .agrarianReform:
            return "修水利、清屯田，提高后续粮草恢复。"
        case .fortify:
            return "提高城关承压能力，稳住要冲。"
        case .trainMilitia:
            return "补地方守备，压低民变并减少野战主力牵制。"
        case .firearmReform:
            return "提升火器与炮队价值，改善攻守质量。"
        case .redCannonMaintenance:
            return "校修红衣炮和攻城炮队，稳住城关火力。"
        case .grainTransport:
            return "优先保障粮道，整修驿道并缓解缺粮和被围风险。"
        }
    }

    var riskSummary: String {
        switch self {
        case .raiseTax:
            return "民变和行政压力上升。"
        case .relief:
            return "消耗银两/粮草，短期军费更紧。"
        case .appeaseGentry:
            return "见效依赖地方基础，不能直接改变归属。"
        case .agrarianReform:
            return "短期占用民力和银两，不能立刻解缺粮。"
        case .fortify:
            return "占用工坊与银两，进攻节奏放缓。"
        case .trainMilitia:
            return "守备提升有限，野战仍依赖主力。"
        case .firearmReform:
            return "维护成本上升，见效依赖军械供给。"
        case .redCannonMaintenance:
            return "耗银耗粮，必须依托现有炮队或军械工坊。"
        case .grainTransport:
            return "后方资源向粮台驿道倾斜，其他方向可能缺口扩大。"
        }
    }

    var systemImageName: String {
        switch self {
        case .raiseTax:
            return "banknote"
        case .relief:
            return "leaf"
        case .appeaseGentry:
            return "person.crop.circle.badge.checkmark"
        case .agrarianReform:
            return "sprout"
        case .fortify:
            return "shield"
        case .trainMilitia:
            return "person.3"
        case .firearmReform:
            return "scope"
        case .redCannonMaintenance:
            return "wrench.and.screwdriver"
        case .grainTransport:
            return "shippingbox"
        }
    }
}

struct CourtStrategySummary: Codable, Equatable {
    let policyPressure: Int
    let economyPressure: Int
    let technologyPressure: Int
    let militaryPressure: Int
    let recommendedFocus: CourtPolicyFocus
    let secondaryFocuses: [CourtPolicyFocus]
    let controlledRegions: Int
    let unstableRegions: Int
    let fireSupportUnits: Int
    let activeFronts: Int
    let rationale: String

    static var empty: CourtStrategySummary {
        CourtStrategySummary(
            policyPressure: 0,
            economyPressure: 0,
            technologyPressure: 0,
            militaryPressure: 0,
            recommendedFocus: .trainMilitia,
            secondaryFocuses: [],
            controlledRegions: 0,
            unstableRegions: 0,
            fireSupportUnits: 0,
            activeFronts: 0,
            rationale: "尚无足够朝议资料。"
        )
    }

    static func from(faction: Faction, state: GameState) -> CourtStrategySummary {
        let ledger = state.economyState.ledger(for: faction)
        let economy = EconomyAISummary.from(ledger: ledger, faction: faction, map: state.map)
        let governance = economy.governanceSummary
        let friendlyDivisions = state.divisions.filter { $0.faction == faction && !$0.isDestroyed }
        let lowSupplyCount = friendlyDivisions.filter { $0.supplyState == .lowSupply }.count
        let encircledCount = friendlyDivisions.filter { $0.supplyState == .encircled }.count
        let fireSupportCount = friendlyDivisions.filter { $0.hasFireSupport || $0.isSiegeCapable }.count
        let damagedSiegeGunCount = friendlyDivisions.filter {
            $0.isSiegeCapable && $0.strength < $0.maxStrength
        }.count
        let activeFrontZones = state.warDeploymentState.frontZones.values
            .filter { $0.faction == faction && !$0.frontSegments.isEmpty }
        let averagePressure = activeFrontZones.isEmpty
            ? 0
            : activeFrontZones.reduce(0) { $0 + $1.pressure } / activeFrontZones.count

        let policyPressure = clamp(governance.unstableRegions * 18 + governance.averageResistance)
        let economyPressure = clamp(
            economy.silverShortfall * 6 +
                economy.manpowerShortfall * 4 +
                economy.grainShortfall * 8 +
                (ledger.stockpile.industry < 10 ? 25 : 0)
        )
        let routeRepairNeed = supplyRouteRepairNeed(for: faction, state: state)
        let technologyPressure = clamp(
            technologyNeed(
                friendlyCount: friendlyDivisions.count,
                fireSupportCount: fireSupportCount,
                activeFrontCount: activeFrontZones.count
            ) + routeRepairNeed * 10
        )
        let militaryPressure = clamp(
            averagePressure * 18 +
                lowSupplyCount * 12 +
                encircledCount * 22 +
                activeFrontZones.count * 6
        )
        let grainTransportPressure = clamp(
            economy.grainShortfall * 10 +
                lowSupplyCount * 18 +
                encircledCount * 25 +
                routeRepairNeed * 32
        )
        let agrarianPressure = clamp(
            economy.grainShortfall * 6 +
                lowAgrarianNeed(for: faction, state: state) * 24
        )
        let localPacificationPressure = governance.controlledRegions == 0
            ? 0
            : clamp(
                governance.unstableRegions * 14 +
                    max(0, 70 - governance.averageCompliance) +
                    localPacificationNeed(for: faction, state: state) * 28
            )
        let trainingPressure = clamp(max(25, 55 - min(policyPressure, militaryPressure)))
        let redCannonPressure = clamp(damagedSiegeGunCount * 36 + activeFrontZones.count * 4)
        let campaignPressure = campaignPolicyPressure(from: state)

        let ranked = [
            (CourtPolicyFocus.grainTransport, clamp(grainTransportPressure + campaignPressure.grainTransport)),
            (.relief, clamp(policyPressure + campaignPressure.relief)),
            (.appeaseGentry, clamp(localPacificationPressure + campaignPressure.appeaseGentry)),
            (.agrarianReform, clamp(agrarianPressure + campaignPressure.agrarianReform)),
            (.fortify, clamp(militaryPressure + campaignPressure.fortify)),
            (.raiseTax, clamp(economyPressure + campaignPressure.raiseTax)),
            (.firearmReform, clamp(technologyPressure + campaignPressure.firearmReform)),
            (.redCannonMaintenance, clamp(redCannonPressure + campaignPressure.redCannonMaintenance)),
            (.trainMilitia, trainingPressure)
        ]
        .sorted {
            if $0.1 == $1.1 {
                return $0.0.rawValue < $1.0.rawValue
            }
            return $0.1 > $1.1
        }
        let recommended = ranked.first?.0 ?? .trainMilitia
        let secondary = ranked
            .map(\.0)
            .filter { $0 != recommended }
            .prefix(2)
            .map { $0 }

        return CourtStrategySummary(
            policyPressure: policyPressure,
            economyPressure: economyPressure,
            technologyPressure: technologyPressure,
            militaryPressure: militaryPressure,
            recommendedFocus: recommended,
            secondaryFocuses: secondary,
            controlledRegions: governance.controlledRegions,
            unstableRegions: governance.unstableRegions,
            fireSupportUnits: fireSupportCount,
            activeFronts: activeFrontZones.count,
            rationale: rationale(
                focus: recommended,
                economy: economy,
                governance: governance,
                lowSupplyCount: lowSupplyCount,
                encircledCount: encircledCount,
                averagePressure: averagePressure,
                campaignPressure: campaignPressure
            )
        )
    }

    var displaySummary: String {
        let secondaryText = secondaryFocuses.map(\.displayName).joined(separator: "、")
        let suffix = secondaryText.isEmpty ? "" : "；备议 \(secondaryText)"
        return "主议 \(recommendedFocus.displayName)；政策 \(policyPressure)，经济 \(economyPressure)，科技 \(technologyPressure)，军事 \(militaryPressure)\(suffix)"
    }

    private static func technologyNeed(
        friendlyCount: Int,
        fireSupportCount: Int,
        activeFrontCount: Int
    ) -> Int {
        guard friendlyCount > 0 else {
            return 0
        }
        let expectedFireSupport = max(1, friendlyCount / 4)
        let shortage = max(0, expectedFireSupport - fireSupportCount)
        return clamp(25 + shortage * 25 + activeFrontCount * 5)
    }

    private static func rationale(
        focus: CourtPolicyFocus,
        economy: EconomyAISummary,
        governance: GovernanceAISummary,
        lowSupplyCount: Int,
        encircledCount: Int,
        averagePressure: Int,
        campaignPressure: CampaignPolicyPressure
    ) -> String {
        if campaignPressure.hasSignal {
            return "\(campaignPressure.rationale)；\(baseRationale(focus: focus, economy: economy, governance: governance, lowSupplyCount: lowSupplyCount, encircledCount: encircledCount, averagePressure: averagePressure))"
        }

        return baseRationale(
            focus: focus,
            economy: economy,
            governance: governance,
            lowSupplyCount: lowSupplyCount,
            encircledCount: encircledCount,
            averagePressure: averagePressure
        )
    }

    private static func baseRationale(
        focus: CourtPolicyFocus,
        economy: EconomyAISummary,
        governance: GovernanceAISummary,
        lowSupplyCount: Int,
        encircledCount: Int,
        averagePressure: Int
    ) -> String {
        switch focus {
        case .raiseTax:
            return "银两缺口 \(economy.silverShortfall)，民力缺口 \(economy.manpowerShortfall)，需先补军费。"
        case .relief:
            return "不稳州府 \(governance.unstableRegions)，平均民变 \(governance.averageResistance)，需安抚地方。"
        case .appeaseGentry:
            return "平均行政 \(governance.averageCompliance)，地方中立和新附州府需招抚稳住。"
        case .agrarianReform:
            return "粮草缺口 \(economy.grainShortfall)，己控州府粮田水利不足，需清屯兴修。"
        case .fortify:
            return "前线均压 \(averagePressure)，缺粮 \(lowSupplyCount)，被围 \(encircledCount)，需守住城关。"
        case .trainMilitia:
            return "局势暂可维持，适合补地方守备与预备力量。"
        case .firearmReform:
            return "火器/炮队支撑不足，需补军械质量。"
        case .redCannonMaintenance:
            return "红衣炮和攻城炮队受损，需先校修火力支点。"
        case .grainTransport:
            return "粮草缺口 \(economy.grainShortfall)，缺粮 \(lowSupplyCount)，被围 \(encircledCount)，需优先保粮道与整修驿道。"
        }
    }

    private static func clamp(_ value: Int) -> Int {
        max(0, min(100, value))
    }

    private static func localPacificationNeed(for faction: Faction, state: GameState) -> Int {
        state.map.regions.values.filter { region in
            region.controller == faction &&
                region.isPassable &&
                (
                    region.owner == .localNeutral ||
                        (!region.coreOf.isEmpty && !region.coreOf.contains(faction))
                )
        }.count
    }

    private static func lowAgrarianNeed(for faction: Faction, state: GameState) -> Int {
        state.map.regions.values.filter { region in
            region.controller == faction &&
                region.isPassable &&
                (region.supplyValue < 3 || region.infrastructure < 2)
        }.count
    }

    private static func supplyRouteRepairNeed(for faction: Faction, state: GameState) -> Int {
        state.map.regions.values.filter { region in
            region.controller == faction &&
                region.isPassable &&
                region.infrastructure < 2 &&
                regionHasControlledHex(region, faction: faction, map: state.map) &&
                isSupplyRouteRegion(region, map: state.map)
        }.count
    }

    private static func regionHasControlledHex(
        _ region: RegionNode,
        faction: Faction,
        map: MapState
    ) -> Bool {
        regionHexes(for: region).contains { coord in
            map.tile(at: coord)?.controller == faction
        }
    }

    private static func isSupplyRouteRegion(_ region: RegionNode, map: MapState) -> Bool {
        let hexes = Set(regionHexes(for: region))
        return region.supplyValue > 0 ||
            region.city != nil ||
            map.supplySources.contains { hexes.contains($0.coord) } ||
            map.objectives.contains { hexes.contains($0.coord) } ||
            hexes.contains { coord in
                map.tile(at: coord)?.hasRoad == true
            }
    }

    private static func regionHexes(for region: RegionNode) -> [HexCoord] {
        Array(Set([region.representativeHex] + region.displayHexes))
    }

    private struct CampaignPolicyPressure {
        var grainTransport: Int = 0
        var relief: Int = 0
        var appeaseGentry: Int = 0
        var agrarianReform: Int = 0
        var fortify: Int = 0
        var raiseTax: Int = 0
        var firearmReform: Int = 0
        var redCannonMaintenance: Int = 0
        var rationale: String = ""

        var hasSignal: Bool {
            grainTransport > 0 ||
                relief > 0 ||
                appeaseGentry > 0 ||
                agrarianReform > 0 ||
                fortify > 0 ||
                raiseTax > 0 ||
                firearmReform > 0 ||
                redCannonMaintenance > 0
        }
    }

    private static func campaignPolicyPressure(from state: GameState) -> CampaignPolicyPressure {
        let objectiveSummary = BattleObjectiveSummary.from(state: state)
        guard objectiveSummary.isMingScenario else {
            return CampaignPolicyPressure()
        }

        var pressure = CampaignPolicyPressure()
        var reasons: [String] = []

        if let qingTrack = objectiveSummary.track(id: .qingPassCapital),
           qingTrack.controlledCount > 0 {
            pressure.fortify += 42
            pressure.grainTransport += 24
            pressure.firearmReform += 18
            pressure.redCannonMaintenance += 20
            reasons.append("破关入京线已动")
        }

        if let dashunTrack = objectiveSummary.track(id: .dashunCentralPlain),
           dashunTrack.controlledCount > 0 {
            let bonus = dashunTrack.progress >= 0.5 ? 36 : 24
            pressure.grainTransport += bonus
            pressure.relief += 18
            pressure.appeaseGentry += 14
            pressure.agrarianReform += 12
            pressure.raiseTax += 12
            reasons.append("河南秦陕粮链承压")
        }

        if let daxiTrack = objectiveSummary.track(id: .daxiHuguang),
           daxiTrack.controlledCount > 0 {
            pressure.grainTransport += daxiTrack.progress >= 0.5 ? 32 : 20
            pressure.fortify += 14
            pressure.appeaseGentry += 12
            pressure.agrarianReform += 10
            reasons.append("湖广粮道承压")
        }

        if state.turn >= max(1, state.maxTurns - 3),
           let mingTrack = objectiveSummary.track(id: .mingMandateLine),
           !mingTrack.isSatisfied {
            pressure.fortify += 36
            pressure.firearmReform += 16
            pressure.redCannonMaintenance += 16
            reasons.append("终局名分线未稳")
        }

        pressure.rationale = reasons.isEmpty ? "" : "战役线提示：" + reasons.joined(separator: "、")
        return pressure
    }
}

struct CampaignLineAISummary: Codable, Equatable {
    let line: String
    let status: String
    let pressure: Int
    let title: String
    let detail: String
    let activeTaskCount: Int
    let urgentTaskCount: Int
}

struct CampaignAISummary: Codable, Equatable {
    let isMingScenario: Bool
    let leadingFaction: Faction?
    let lineBriefs: [CampaignLineAISummary]
    let activeTasks: [String]
    let displaySummary: String

    static var empty: CampaignAISummary {
        CampaignAISummary(
            isMingScenario: false,
            leadingFaction: nil,
            lineBriefs: [],
            activeTasks: [],
            displaySummary: "旧剧本目标摘要未启用明末五线态势。"
        )
    }

    static func from(state: GameState) -> CampaignAISummary {
        let summary = BattleObjectiveSummary.from(state: state)
        guard summary.isMingScenario else {
            return .empty
        }

        let lineBriefs = summary.lineBriefs.map { brief in
            CampaignLineAISummary(
                line: brief.line.displayName,
                status: brief.status.displayName,
                pressure: brief.pressure,
                title: brief.title,
                detail: brief.detail,
                activeTaskCount: brief.activeTaskCount,
                urgentTaskCount: brief.urgentTaskCount
            )
        }
        let activeTasks = summary.tasks
            .filter { $0.priority != .watch }
            .map { "\($0.line.displayName)·\($0.priority.displayName)·\($0.title)" }
        let leaderText = summary.leadingFaction?.displayName ?? "未定"
        let lineText = lineBriefs
            .map { "\($0.line) \($0.status) \($0.pressure)" }
            .joined(separator: "；")

        return CampaignAISummary(
            isMingScenario: true,
            leadingFaction: summary.leadingFaction,
            lineBriefs: lineBriefs,
            activeTasks: activeTasks,
            displaySummary: "要冲领先 \(leaderText)；五线 \(lineText)"
        )
    }
}

struct EventSummary: Codable, Equatable {
    let turn: Int
    let faction: Faction?
    let phase: GamePhase?
    let message: String
}

struct ObjectiveSummary: Codable, Equatable {
    let id: String
    let name: String
    let coord: HexCoord
    let regionId: RegionId?
    let controller: Faction?
    let type: ObjectiveType
}

struct RegionSnapshot: Codable, Equatable {
    let id: RegionId
    let name: String
    let controller: Faction
    let terrain: BaseTerrain
    let neighbors: [RegionId]
    let cityName: String?
    let supplyValue: Int
    let visible: Bool
}

struct AgentFrontSegmentSnapshot: Codable, Equatable {
    let regionId: RegionId
    let enemyZoneId: FrontZoneId
    let assignedUnitIds: [String]
    let isEncircled: Bool
    let pressure: Int
}

struct AgentFrontZoneSnapshot: Codable, Equatable {
    let id: FrontZoneId
    let faction: Faction
    let regionIds: [RegionId]
    let neighborZoneIds: [FrontZoneId]
    let frontSegments: [AgentFrontSegmentSnapshot]
    let frontUnitIds: [String]
    let depthUnitIds: [String]
    let garrisonUnitIds: [String]
    let pressure: Int
    let state: WarState
}

struct AgentContext: Codable, Equatable {
    let agentId: String
    let faction: Faction
    let turn: Int
    let phase: GamePhase
    let personality: String
    let visibleTiles: [TileSummary]
    let visibleRegions: [RegionSnapshot]
    let friendlyDivisions: [DivisionSummary]
    let enemyDivisions: [DivisionSummary]
    let objectives: [ObjectiveSummary]
    let supplySummary: SupplySummary
    let economySummary: EconomyAISummary
    let courtSummary: CourtStrategySummary
    let campaignSummary: CampaignAISummary
    let recentEvents: [EventSummary]
    let frontZones: [AgentFrontZoneSnapshot]
    let playerDirective: String?
}

struct AgentContextBuilder {
    let maxRecentEvents: Int

    init(maxRecentEvents: Int = 8) {
        self.maxRecentEvents = maxRecentEvents
    }

    func agentContext(
        for agent: GameAgent,
        state: GameState,
        playerDirective: String?
    ) -> AgentContext {
        let assignedIds = Set(agent.assignedDivisionIds)
        let friendlyDivisions = state.divisions
            .filter { $0.faction == agent.faction && (assignedIds.isEmpty || assignedIds.contains($0.id)) }
            .map { divisionSummary($0, state: state) }
            .sorted { $0.id < $1.id }
        let enemyDivisions = state.divisions
            .filter { state.diplomacyState.isHostile(agent.faction, $0.faction) }
            .map { divisionSummary($0, state: state) }
            .sorted { $0.id < $1.id }

        return AgentContext(
            agentId: agent.id,
            faction: agent.faction,
            turn: state.turn,
            phase: state.phase,
            personality: agent.personality.prompt,
            visibleTiles: tileSummaries(state: state),
            visibleRegions: regionSnapshots(for: agent.faction, state: state),
            friendlyDivisions: friendlyDivisions,
            enemyDivisions: enemyDivisions,
            objectives: objectiveSummaries(state: state),
            supplySummary: supplySummary(for: agent.faction, state: state),
            economySummary: economySummary(for: agent.faction, state: state),
            courtSummary: CourtStrategySummary.from(faction: agent.faction, state: state),
            campaignSummary: CampaignAISummary.from(state: state),
            recentEvents: recentEvents(state: state),
            frontZones: frontZoneSnapshots(for: agent.faction, state: state),
            playerDirective: playerDirective
        )
    }

    private func objectiveSummaries(state: GameState) -> [ObjectiveSummary] {
        state.map.objectives.map { objective in
            ObjectiveSummary(
                id: objective.id,
                name: objective.name,
                coord: objective.coord,
                regionId: state.map.region(for: objective.coord),
                controller: state.map.tile(at: objective.coord)?.controller,
                type: objective.type
            )
        }
    }

    private func regionSnapshots(for faction: Faction, state: GameState) -> [RegionSnapshot] {
        let visible = RegionVisibilityRules().visibleRegions(for: faction, in: state, radius: 2)
        return state.map.regions.values
            .sorted { $0.id.rawValue < $1.id.rawValue }
            .map { region in
                RegionSnapshot(
                    id: region.id,
                    name: region.name,
                    controller: region.controller,
                    terrain: region.terrain,
                    neighbors: region.neighbors,
                    cityName: region.city?.name,
                    supplyValue: region.supplyValue,
                    visible: visible.contains(region.id)
                )
            }
    }

    private func tileSummaries(state: GameState) -> [TileSummary] {
        state.map.tiles.values
            .sorted {
                if $0.coord.q != $1.coord.q {
                    return $0.coord.q < $1.coord.q
                }
                return $0.coord.r < $1.coord.r
            }
            .map { tile in
                TileSummary(
                    coord: tile.coord,
                    baseTerrain: tile.baseTerrain,
                    hasRoad: tile.hasRoad,
                    controller: tile.controller,
                    cityName: tile.cityName,
                    fortressName: tile.fortressName,
                    isPassable: tile.isPassable,
                    visibility: .visible
                )
            }
    }

    private func divisionSummary(_ division: Division, state: GameState) -> DivisionSummary {
        DivisionSummary(
            id: division.id,
            name: division.name,
            faction: division.faction,
            coord: division.coord,
            regionId: division.location(in: state.map),
            strength: division.strength,
            maxStrength: division.maxStrength,
            supplyState: division.supplyState,
            hasActed: division.hasActed,
            movement: division.movement,
            range: division.range,
            isArmor: division.isArmor,
            isArtillery: division.isArtillery
        )
    }

    private func supplySummary(for faction: Faction, state: GameState) -> SupplySummary {
        let friendly = state.divisions.filter { $0.faction == faction }
        let enemy = state.divisions.filter { state.diplomacyState.isHostile(faction, $0.faction) }

        return SupplySummary(
            friendlySupplied: friendly.filter { $0.supplyState == .supplied }.count,
            friendlyLowSupply: friendly.filter { $0.supplyState == .lowSupply }.count,
            friendlyEncircled: friendly.filter { $0.supplyState == .encircled }.count,
            enemySupplied: enemy.filter { $0.supplyState == .supplied }.count,
            enemyLowSupply: enemy.filter { $0.supplyState == .lowSupply }.count,
            enemyEncircled: enemy.filter { $0.supplyState == .encircled }.count
        )
    }

    private func economySummary(for faction: Faction, state: GameState) -> EconomyAISummary {
        EconomyAISummary.from(
            ledger: state.economyState.ledger(for: faction),
            faction: faction,
            map: state.map
        )
    }

    private func recentEvents(state: GameState) -> [EventSummary] {
        Array(state.eventLog.suffix(maxRecentEvents))
            .map { entry in
                EventSummary(
                    turn: entry.turn,
                    faction: entry.faction,
                    phase: entry.phase,
                    message: entry.message
                )
            }
    }

    private func frontZoneSnapshots(for faction: Faction, state: GameState) -> [AgentFrontZoneSnapshot] {
        state.warDeploymentState.frontZones.values
            .filter { $0.faction == faction }
            .sorted { $0.id.rawValue < $1.id.rawValue }
            .map { zone in
                AgentFrontZoneSnapshot(
                    id: zone.id,
                    faction: zone.faction,
                    regionIds: zone.regionIds,
                    neighborZoneIds: zone.neighbors,
                    frontSegments: zone.frontSegments.map {
                        AgentFrontSegmentSnapshot(
                            regionId: $0.regionId,
                            enemyZoneId: $0.neighborEnemyZone,
                            assignedUnitIds: $0.assignedFrontUnitIds,
                            isEncircled: $0.isEncircled,
                            pressure: $0.strength
                        )
                    },
                    frontUnitIds: zone.unitsFront,
                    depthUnitIds: zone.unitsDepth,
                    garrisonUnitIds: zone.unitsGarrison,
                    pressure: zone.pressure,
                    state: zone.state
                )
            }
    }
}
