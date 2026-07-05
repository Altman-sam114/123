import Foundation

struct ScenarioDataSet: Equatable {
    let scenario: ScenarioDefinition
    let terrainRules: TerrainRuleDefinition
    let unitTemplates: [UnitTemplateDefinition]
    let generalAgents: [GeneralAgentDefinition]
}

struct ScenarioDefinition: Codable, Equatable {
    let schemaVersion: Int
    let id: String
    let displayName: String
    let map: ScenarioMapDefinition
    let factions: [String]
    let maxTurns: Int
    let initialTurn: Int
    let initialPhase: String
    let playerFaction: String
    let aiFaction: String
    let turnOrder: [String]?
    let humanControlledFactions: [String]?
    let aiControlledFactions: [String]?
    let keyLocations: [KeyLocationDefinition]
    let objectives: [ObjectiveDefinition]
    let initialUnits: [InitialUnitDefinition]
    let victoryConditions: [VictoryConditionDefinition]
    let dataNotes: [String]
}

struct ScenarioMapDefinition: Codable, Equatable {
    let width: Int
    let height: Int
    let coordinateSystem: String
    let isSparse: Bool
    let tiles: [ScenarioTileDefinition]
}

struct ScenarioTileDefinition: Codable, Equatable {
    let q: Int
    let r: Int
    let terrain: String
    let hasRoad: Bool
    let riverEdges: [String]
    let controller: String
    let cityName: String?
    let fortressName: String?
    let isSupplySource: Bool
    let supplyFaction: String?
    let objectiveId: String?
    let regionId: String?

    var coord: HexCoordDefinition {
        HexCoordDefinition(q: q, r: r)
    }
}

struct HexCoordDefinition: Codable, Hashable, Equatable {
    let q: Int
    let r: Int
}

struct KeyLocationDefinition: Codable, Equatable {
    let id: String
    let name: String
    let kind: String
    let coord: HexCoordDefinition
    let faction: String?
    let objectiveId: String?
}

struct ObjectiveDefinition: Codable, Equatable {
    let id: String
    let name: String
    let kind: String
    let coord: HexCoordDefinition
    let points: Int

    init(id: String, name: String, kind: String, coord: HexCoordDefinition, points: Int = 0) {
        self.id = id
        self.name = name
        self.kind = kind
        self.coord = coord
        self.points = max(0, points)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case kind
        case coord
        case points
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(String.self, forKey: .id),
            name: try container.decode(String.self, forKey: .name),
            kind: try container.decode(String.self, forKey: .kind),
            coord: try container.decode(HexCoordDefinition.self, forKey: .coord),
            points: try container.decodeIfPresent(Int.self, forKey: .points) ?? 0
        )
    }
}

struct InitialUnitDefinition: Codable, Equatable {
    let id: String
    let name: String
    let faction: String
    let templateId: String
    let coord: HexCoordDefinition
    let facing: String
    let hp: Int
    let retreatMode: String?
    let supplyState: String
    let assignedAgentId: String?
}

struct VictoryConditionDefinition: Codable, Equatable {
    let id: String
    let type: String
    let faction: String
    let objectiveId: String?
    let objectiveIds: [String]?
    let targetFaction: String?
    let targetTemplateIds: [String]?
    let turns: Int?
    let turn: Int?
    let count: Int?
    let status: String
    let description: String
}

struct TerrainRuleDefinition: Codable, Equatable {
    let terrain: [String: TerrainRuleEntryDefinition]
    let roadMovementCost: Int
    let riverCrossingExtraCost: Int
}

struct TerrainRuleEntryDefinition: Codable, Equatable {
    let movementCost: Int
    let defenseBonus: Int
}

struct UnitTemplateCatalogDefinition: Codable, Equatable {
    let schemaVersion: Int
    let templates: [UnitTemplateDefinition]
}

struct UnitTemplateDefinition: Codable, Equatable {
    let id: String
    let displayName: String
    let maxHP: Int
    let components: [DivisionComponentDefinition]
}

struct DivisionComponentDefinition: Codable, Equatable {
    let type: String
    let weight: Double
}

struct GeneralAgentCatalogDefinition: Codable, Equatable {
    let schemaVersion: Int
    let agents: [GeneralAgentDefinition]
}

struct GeneralAgentDefinition: Codable, Equatable {
    let id: String
    let name: String
    let faction: String
    let role: String
    let commandStyle: String
    let personalityPrompt: String
    let assignedDivisionIds: [String]
}

struct DataValidationError: Error, Equatable, CustomStringConvertible {
    let message: String

    var description: String {
        message
    }
}

enum DataLoaderError: Error, CustomStringConvertible, LocalizedError {
    case missingResource(String)
    case validationFailed([DataValidationError])

    var description: String {
        switch self {
        case .missingResource(let resourceName):
            return "Missing data resource: \(resourceName).json"
        case .validationFailed(let errors):
            return errors.map(\.description).joined(separator: "\n")
        }
    }

    var errorDescription: String? {
        description
    }
}
