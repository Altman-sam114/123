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

struct EconomyAISummary: Codable, Equatable {
    let stockpile: EconomyResources
    let lastIncome: EconomyResources
    let lastUpkeep: EconomyResources
    let lastReinforcementSpend: EconomyResources
    let grainShortfall: Int
    let silverShortfall: Int
    let manpowerShortfall: Int

    static func from(ledger: FactionEconomyLedger) -> EconomyAISummary {
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

        return EconomyAISummary(
            stockpile: ledger.stockpile,
            lastIncome: ledger.lastIncome,
            lastUpkeep: ledger.lastUpkeep,
            lastReinforcementSpend: ledger.lastReinforcementSpend,
            grainShortfall: max(0, ledger.lastUpkeep.supplies - ledger.stockpile.supplies),
            silverShortfall: max(0, minimumActionCost.industry - ledger.stockpile.industry),
            manpowerShortfall: max(0, minimumRecruitmentCost.manpower - ledger.stockpile.manpower)
        )
    }

    var displaySummary: String {
        "库存 \(stockpile.displaySummary)；收入 \(lastIncome.displaySummary)；军粮维护 \(lastUpkeep.displaySummary)；补员 \(lastReinforcementSpend.displaySummary)；缺口 民力 \(manpowerShortfall), 银两 \(silverShortfall), 粮草 \(grainShortfall)"
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
        EconomyAISummary.from(ledger: state.economyState.ledger(for: faction))
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
