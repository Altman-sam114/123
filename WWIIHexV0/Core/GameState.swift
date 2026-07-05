import Foundation

struct GameState: Codable, Equatable {
    var scenarioId: String
    var turn: Int
    var maxTurns: Int
    var activeFaction: Faction
    var phase: GamePhase
    var map: MapState
    var theaterState: TheaterState
    var frontLineState: FrontLineState
    var warDeploymentState: WarDeploymentState
    var economyState: EconomyState
    var diplomacyState: DiplomacyState
    var victoryConditions: [VictoryConditionDefinition]
    var turnOrder: [Faction]
    var humanControlledFactions: [Faction]
    var aiControlledFactions: [Faction]
    var divisions: [Division]
    var victoryState: VictoryState
    var selectedUnitSummary: String?
    var eventLog: [GameLogEntry]
    var warDirectiveRecords: [WarDirectiveRecord]
    var playerCommandState: PlayerCommandState

    init(
        scenarioId: String,
        turn: Int,
        maxTurns: Int,
        activeFaction: Faction,
        phase: GamePhase,
        map: MapState,
        theaterState: TheaterState = .empty,
        frontLineState: FrontLineState = .empty,
        warDeploymentState: WarDeploymentState = .empty,
        economyState: EconomyState = .empty,
        diplomacyState: DiplomacyState = .empty,
        victoryConditions: [VictoryConditionDefinition] = [],
        turnOrder: [Faction] = [.germany, .allies],
        humanControlledFactions: [Faction] = [.allies],
        aiControlledFactions: [Faction] = [.germany],
        divisions: [Division],
        victoryState: VictoryState,
        selectedUnitSummary: String?,
        eventLog: [GameLogEntry],
        warDirectiveRecords: [WarDirectiveRecord] = [],
        playerCommandState: PlayerCommandState = .empty
    ) {
        self.scenarioId = scenarioId
        self.turn = turn
        self.maxTurns = maxTurns
        self.activeFaction = activeFaction
        self.phase = phase
        self.map = map
        self.theaterState = theaterState
        self.frontLineState = frontLineState
        self.warDeploymentState = warDeploymentState
        self.economyState = economyState
        self.diplomacyState = diplomacyState
        self.victoryConditions = victoryConditions
        self.turnOrder = Self.normalizedFactionList(turnOrder)
        self.humanControlledFactions = Self.normalizedFactionList(humanControlledFactions)
        self.aiControlledFactions = Self.normalizedFactionList(aiControlledFactions)
        self.divisions = divisions
        self.victoryState = victoryState
        self.selectedUnitSummary = selectedUnitSummary
        self.eventLog = eventLog
        self.warDirectiveRecords = warDirectiveRecords
        self.playerCommandState = playerCommandState
    }

    static func initial() -> GameState {
        let map = MapState.ardennesV0()

        return GameState(
            scenarioId: "ardennes_v0",
            turn: 1,
            maxTurns: 8,
            activeFaction: .germany,
            phase: .germanAI,
            map: map,
            theaterState: .empty,
            frontLineState: .empty,
            warDeploymentState: .empty,
            economyState: .empty,
            diplomacyState: DiplomacyState.initial(for: Faction.legacyCases, turn: 1),
            turnOrder: [.germany, .allies],
            humanControlledFactions: [.allies],
            aiControlledFactions: [.germany],
            divisions: [
                .panzer(
                    id: "ger_panzer_1",
                    name: "1st Panzer Division",
                    faction: .germany,
                    coord: HexCoord(q: 9, r: 3)
                ),
                .motorized(
                    id: "ger_motorized_1",
                    name: "2nd Motorized Division",
                    faction: .germany,
                    coord: HexCoord(q: 9, r: 4)
                ),
                .infantry(
                    id: "ger_infantry_1",
                    name: "26th Infantry Division",
                    faction: .germany,
                    coord: HexCoord(q: 10, r: 5)
                ),
                .artillery(
                    id: "ger_artillery_1",
                    name: "7th Artillery Division",
                    faction: .germany,
                    coord: HexCoord(q: 10, r: 3)
                ),
                .infantry(
                    id: "all_infantry_1",
                    name: "101st Infantry Division",
                    faction: .allies,
                    coord: HexCoord(q: 4, r: 5)
                ),
                .infantry(
                    id: "all_anti_tank_1",
                    name: "9th Anti-Tank Battalion",
                    faction: .allies,
                    coord: HexCoord(q: 5, r: 5)
                ),
                .artillery(
                    id: "all_artillery_1",
                    name: "4th Allied Artillery Group",
                    faction: .allies,
                    coord: HexCoord(q: 3, r: 5)
                ),
                .infantry(
                    id: "all_garrison_1",
                    name: "Bastogne Garrison",
                    faction: .allies,
                    coord: HexCoord(q: 5, r: 6)
                )
            ],
            victoryState: .ongoing,
            selectedUnitSummary: nil,
            eventLog: [
                GameLogEntry(
                    turn: 1,
                    faction: .germany,
                    phase: .germanAI,
                    message: "Ardennes V0 scenario initialized."
                )
            ]
        )
    }

    private enum CodingKeys: String, CodingKey {
        case scenarioId
        case turn
        case maxTurns
        case activeFaction
        case phase
        case map
        case theaterState
        case frontLineState
        case warDeploymentState
        case economyState
        case diplomacyState
        case victoryConditions
        case turnOrder
        case humanControlledFactions
        case aiControlledFactions
        case divisions
        case victoryState
        case selectedUnitSummary
        case eventLog
        case warDirectiveRecords
        case playerCommandState
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            scenarioId: try container.decode(String.self, forKey: .scenarioId),
            turn: try container.decode(Int.self, forKey: .turn),
            maxTurns: try container.decode(Int.self, forKey: .maxTurns),
            activeFaction: try container.decode(Faction.self, forKey: .activeFaction),
            phase: try container.decode(GamePhase.self, forKey: .phase),
            map: try container.decode(MapState.self, forKey: .map),
            theaterState: try container.decodeIfPresent(TheaterState.self, forKey: .theaterState) ?? .empty,
            frontLineState: try container.decodeIfPresent(FrontLineState.self, forKey: .frontLineState) ?? .empty,
            warDeploymentState: try container.decodeIfPresent(WarDeploymentState.self, forKey: .warDeploymentState) ?? .empty,
            economyState: try container.decodeIfPresent(EconomyState.self, forKey: .economyState) ?? .empty,
            diplomacyState: try container.decodeIfPresent(DiplomacyState.self, forKey: .diplomacyState) ?? .empty,
            victoryConditions: try container.decodeIfPresent([VictoryConditionDefinition].self, forKey: .victoryConditions) ?? [],
            turnOrder: try container.decodeIfPresent([Faction].self, forKey: .turnOrder) ?? [.germany, .allies],
            humanControlledFactions: try container.decodeIfPresent([Faction].self, forKey: .humanControlledFactions) ?? [.allies],
            aiControlledFactions: try container.decodeIfPresent([Faction].self, forKey: .aiControlledFactions) ?? [.germany],
            divisions: try container.decode([Division].self, forKey: .divisions),
            victoryState: try container.decode(VictoryState.self, forKey: .victoryState),
            selectedUnitSummary: try container.decodeIfPresent(String.self, forKey: .selectedUnitSummary),
            eventLog: try container.decode([GameLogEntry].self, forKey: .eventLog),
            warDirectiveRecords: try container.decodeIfPresent([WarDirectiveRecord].self, forKey: .warDirectiveRecords) ?? [],
            playerCommandState: try container.decodeIfPresent(PlayerCommandState.self, forKey: .playerCommandState) ?? .empty
        )
    }

    func division(id: String) -> Division? {
        divisions.first { $0.id == id }
    }

    func divisionIndex(id: String) -> Int? {
        divisions.firstIndex { $0.id == id }
    }

    func division(at coord: HexCoord) -> Division? {
        divisions.first { $0.coord == coord }
    }

    mutating func updateDivision(_ division: Division) {
        guard let index = divisionIndex(id: division.id) else {
            return
        }
        divisions[index] = division
    }

    mutating func removeDivision(id: String) {
        divisions.removeAll { $0.id == id }
    }

    mutating func appendEvent(
        _ message: String,
        category: GameLogCategory = .event,
        relatedRecordId: String? = nil
    ) {
        eventLog.append(
            GameLogEntry(
                turn: turn,
                faction: activeFaction,
                phase: phase,
                category: category,
                relatedRecordId: relatedRecordId,
                message: message
            )
        )
    }

    var resolvedTurnOrder: [Faction] {
        let order = Self.normalizedFactionList(turnOrder)
        if !order.isEmpty {
            return order
        }

        let activeFactions = Self.normalizedFactionList(divisions.map(\.faction))
        if !activeFactions.isEmpty {
            return activeFactions
        }

        return [.germany, .allies]
    }

    func isHumanControlled(_ faction: Faction) -> Bool {
        humanControlledFactions.contains(faction)
    }

    func isAIControlled(_ faction: Faction) -> Bool {
        aiControlledFactions.contains(faction)
    }

    func actionPhase(for faction: Faction) -> GamePhase {
        if faction == .germany && isAIControlled(faction) {
            return .germanAI
        }
        if faction == .allies && isHumanControlled(faction) {
            return .alliedPlayer
        }
        if isHumanControlled(faction) {
            return .humanAction
        }
        return .aiAction
    }

    private static func normalizedFactionList(_ factions: [Faction]) -> [Faction] {
        var seen: Set<Faction> = []
        var result: [Faction] = []
        for faction in factions where !seen.contains(faction) {
            seen.insert(faction)
            result.append(faction)
        }
        return result
    }
}
