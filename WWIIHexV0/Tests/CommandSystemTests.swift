import XCTest
@testable import WWIIHexV0

final class CommandSystemTests: XCTestCase {
    func testZoneDirectiveDecodesLLMStyleJSON() throws {
        let json = """
        {
          "zoneId": "germany_front",
          "type": "attack",
          "parameters": {
            "targetTheaterId": "france_front",
            "weightedRegions": ["sedan"],
            "intensity": "allOut"
          }
        }
        """

        let directive = try JSONDecoder().decode(ZoneDirective.self, from: Data(json.utf8))

        XCTAssertEqual(directive.zoneId, "germany_front")
        XCTAssertEqual(directive.type, .attack)
        XCTAssertEqual(directive.parameters.attack?.targetTheaterId, "france_front")
        XCTAssertEqual(directive.parameters.attack?.weightedRegions, ["sedan"])
        XCTAssertEqual(directive.parameters.attack?.intensity, .allOut)
        XCTAssertNil(directive.category)
        XCTAssertNil(directive.tactic)
    }

    func testV036ZoneDirectiveRoundTripsTacticFields() throws {
        let directive = ZoneDirective(
            zoneId: Self.germanFront,
            attack: AttackParameters(
                targetTheaterId: TheaterId(Self.frenchFront.rawValue),
                weightedRegions: ["sedan"],
                intensity: .limitedCounter
            ),
            category: .offense,
            tactic: .standardAttack,
            commandTarget: .theater(TheaterId(Self.frenchFront.rawValue))
        )

        let data = try JSONEncoder().encode(directive)
        let decoded = try JSONDecoder().decode(ZoneDirective.self, from: data)

        XCTAssertEqual(decoded.category, .offense)
        XCTAssertEqual(decoded.tactic, .standardAttack)
        XCTAssertEqual(decoded.commandTarget, .theater(TheaterId(Self.frenchFront.rawValue)))
    }

    func testV036BinaryTacticClassifierHandlesBoundaryInputs() {
        let config = ZoneCommanderAgentConfig(
            id: "classifier_test",
            name: "Classifier Test",
            faction: .germany,
            assignedZoneId: Self.germanFront,
            skills: [],
            commandStyle: .balanced
        )
        let classifier = BinaryTacticClassifier(attackThreshold: 1.2)

        let noEnemy = classifier.classify(
            friendlyStrength: 0,
            visibleEnemyStrength: 0,
            hasContestedForwardPresence: false,
            hasStaticDefense: false,
            config: config
        )
        let strong = classifier.classify(
            friendlyStrength: 100,
            visibleEnemyStrength: 0,
            hasContestedForwardPresence: false,
            hasStaticDefense: false,
            config: config
        )

        XCTAssertEqual(noEnemy.tactic, .holdPosition)
        XCTAssertEqual(strong.tactic, .standardAttack)
    }

    func testMingFactionDoctrineProfilesDriveDefaultTacticalBias() {
        let classifier = BinaryTacticClassifier(attackThreshold: 1.2)
        let mingConfig = TheaterCommanderPool.defaultConfig(
            for: FrontZone(id: "ming_zone", name: "畿辅防区", faction: .ming)
        )
        let qingConfig = TheaterCommanderPool.defaultConfig(
            for: FrontZone(id: "qing_zone", name: "关外旗营", faction: .qing)
        )
        let dashunConfig = TheaterCommanderPool.defaultConfig(
            for: FrontZone(id: "dashun_zone", name: "河南老营", faction: .dashun)
        )
        let daxiConfig = TheaterCommanderPool.defaultConfig(
            for: FrontZone(id: "daxi_zone", name: "湖广机动营", faction: .daxi)
        )
        let localConfig = TheaterCommanderPool.defaultConfig(
            for: FrontZone(id: "local_zone", name: "乡绅团练", faction: .localNeutral)
        )

        let mingChoice = classifier.classify(
            friendlyStrength: 8,
            visibleEnemyStrength: 7,
            hasContestedForwardPresence: false,
            hasStaticDefense: false,
            config: mingConfig
        )
        let qingChoice = classifier.classify(
            friendlyStrength: 8,
            visibleEnemyStrength: 7,
            hasContestedForwardPresence: false,
            hasStaticDefense: false,
            config: qingConfig
        )

        XCTAssertEqual(mingConfig.commandStyle, .cautious)
        XCTAssertTrue(mingConfig.skills.contains("capital_defense"))
        XCTAssertEqual(mingChoice.category, .defense)
        XCTAssertEqual(mingChoice.tactic, .holdPosition)
        XCTAssertEqual(qingConfig.commandStyle, .aggressive)
        XCTAssertTrue(qingConfig.skills.contains("banner_cavalry"))
        XCTAssertEqual(qingChoice.category, .offense)
        XCTAssertEqual(dashunConfig.commandStyle, .aggressive)
        XCTAssertTrue(dashunConfig.skills.contains("grain_expansion"))
        XCTAssertEqual(daxiConfig.commandStyle, .aggressive)
        XCTAssertTrue(daxiConfig.skills.contains("mobile_raiding"))
        XCTAssertEqual(localConfig.commandStyle, .cautious)
        XCTAssertTrue(localConfig.skills.contains("town_security"))
    }

    func testMingFactionDoctrineProducesDistinctDirectiveTactics() throws {
        let qingDirective = try Self.directiveForDoctrine(friendly: .qing, enemy: .ming)
        let dashunDirective = try Self.directiveForDoctrine(friendly: .dashun, enemy: .ming)
        let daxiDirective = try Self.directiveForDoctrine(friendly: .daxi, enemy: .ming)
        let mingDirective = try Self.directiveForDoctrine(friendly: .ming, enemy: .qing)

        XCTAssertEqual(qingDirective.type, .attack)
        XCTAssertEqual(qingDirective.tactic, .spearhead)
        XCTAssertEqual(dashunDirective.type, .attack)
        XCTAssertEqual(dashunDirective.tactic, .breakthrough)
        XCTAssertEqual(daxiDirective.type, .attack)
        XCTAssertEqual(daxiDirective.tactic, .guerrillaWarfare)
        XCTAssertEqual(mingDirective.type, .attack)
        XCTAssertEqual(mingDirective.tactic, .fireCoverage)
    }

    func testSimulatedMarshalLLMUsesMingFactionDoctrineTactics() throws {
        let qingTactic = try Self.simulatedMarshalTactic(for: .qing)
        let dashunTactic = try Self.simulatedMarshalTactic(for: .dashun)
        let daxiTactic = try Self.simulatedMarshalTactic(for: .daxi)
        let mingTactic = try Self.simulatedMarshalTactic(for: .ming)

        XCTAssertEqual(qingTactic, .spearhead)
        XCTAssertEqual(dashunTactic, .breakthrough)
        XCTAssertEqual(daxiTactic, .guerrillaWarfare)
        XCTAssertEqual(mingTactic, .fireCoverage)
    }

    func testV036TacticConditionCheckerAlwaysAllowsCurrentTactics() throws {
        let state = Self.commandScenario(germanCount: 1, alliedCount: 1)
        let zone = try XCTUnwrap(state.warDeploymentState.frontZones[Self.germanFront])

        XCTAssertTrue(TacticConditionChecker().canUseTactic(.standardAttack, commander: nil, zone: zone, state: state))
        XCTAssertTrue(TacticConditionChecker().canUseTactic(.holdPosition, commander: nil, zone: zone, state: state))
    }

    func testV036WarDirectiveRecordDefaultsRemainNil() {
        let record = WarDirectiveRecord(
            id: "legacy_record",
            issuerId: "legacy",
            turn: 1,
            faction: .germany,
            zoneId: Self.germanFront,
            directiveType: .defend
        )

        XCTAssertNil(record.category)
        XCTAssertNil(record.tactic)
        XCTAssertNil(record.commanderAgentId)
        XCTAssertNil(record.commandTarget)
    }

    func testMockAICommanderAttacksWithAdvantageAndDefendsWhenWeak() throws {
        let attackScenario = Self.commandScenario(germanCount: 5, alliedCount: 1)
        let attackDirective = try XCTUnwrap(
            MockAICommander().directive(for: Self.germanFront, in: attackScenario)
        )
        XCTAssertEqual(attackDirective.type, .attack)
        XCTAssertEqual(attackDirective.parameters.attack?.targetTheaterId, TheaterId(Self.frenchFront.rawValue))
        XCTAssertEqual(attackDirective.parameters.attack?.weightedRegions.first, "sedan")

        let defenseScenario = Self.commandScenario(germanCount: 1, alliedCount: 5)
        let defenseDirective = try XCTUnwrap(
            MockAICommander().directive(for: Self.germanFront, in: defenseScenario)
        )
        XCTAssertEqual(defenseDirective.type, .defend)
        XCTAssertEqual(defenseDirective.parameters.defense?.stance, .holdLine)
    }

    func testMockAICommanderUsesNamedAttackThresholdBoundary() throws {
        let defendScenario = Self.thresholdScenario(friendlyStrength: 7, enemyStrength: 7)
        let defendDirective = try XCTUnwrap(
            MockAICommander().directive(for: Self.germanFront, in: defendScenario)
        )
        XCTAssertEqual(defendDirective.type, .defend)

        let attackScenario = Self.thresholdScenario(friendlyStrength: 9, enemyStrength: 7)
        let attackDirective = try XCTUnwrap(
            MockAICommander().directive(for: Self.germanFront, in: attackScenario)
        )
        XCTAssertEqual(attackDirective.type, .attack)
        XCTAssertEqual(MockAICommanderConfig.attackThreshold, 1.2)
    }

    func testAttackDirectiveProducesBottomLevelAttackCommand() throws {
        let state = Self.commandScenario(germanCount: 2, alliedCount: 1)
        let directive = ZoneDirective(
            zoneId: Self.germanFront,
            attack: AttackParameters(
                targetTheaterId: TheaterId(Self.frenchFront.rawValue),
                weightedRegions: ["sedan"],
                intensity: .allOut
            )
        )

        let result = WarCommandExecutor().execute(directive, in: state)

        XCTAssertTrue(result.generatedCommands.contains { command in
            if case .attack = command {
                return true
            }
            return false
        })
        XCTAssertTrue(Self.isDamagedOrDestroyed("allied_0", in: result.finalState))
    }

    func testAttackDirectiveCanMoveIntoUnoccupiedEnemyRegion() throws {
        let state = Self.commandScenario(germanCount: 1, alliedCount: 0)
        let directive = ZoneDirective(
            zoneId: Self.germanFront,
            attack: AttackParameters(
                targetTheaterId: TheaterId(Self.frenchFront.rawValue),
                weightedRegions: ["sedan"],
                intensity: .limitedCounter
            )
        )

        let result = WarCommandExecutor().execute(directive, in: state)

        XCTAssertTrue(result.generatedCommands.contains { command in
            if case .move = command {
                return true
            }
            return false
        })
        XCTAssertEqual(result.finalState.division(id: "german_0")?.location(in: result.finalState.map), "sedan")
    }

    func testAttackDirectiveMovesTowardEnemyControlledHexInsteadOfCurrentHex() throws {
        var state = Self.commandScenario(germanCount: 1, alliedCount: 0)
        state.divisions[0].coord = HexCoord(q: 3, r: 0)
        if var occupied = state.map.tile(at: HexCoord(q: 3, r: 0)) {
            occupied.controller = .germany
            state.map.setTile(occupied)
        }
        state.frontLineState = FrontLineManager().makeInitialState(
            map: state.map,
            theaterState: state.theaterState,
            divisions: state.divisions,
            turn: state.turn
        )
        state.warDeploymentState = WarDeploymentManager().makeInitialState(
            map: state.map,
            theaterState: state.theaterState,
            divisions: state.divisions,
            turn: state.turn
        )
        let directive = ZoneDirective(
            zoneId: Self.germanFront,
            attack: AttackParameters(
                targetTheaterId: TheaterId(Self.frenchFront.rawValue),
                weightedRegions: ["sedan"],
                intensity: .limitedCounter
            )
        )

        let result = WarCommandExecutor().execute(directive, in: state)

        let moveDestination = result.generatedCommands.compactMap { command -> HexCoord? in
            if case .move(_, let destination) = command {
                return destination
            }
            return nil
        }.first
        XCTAssertNotEqual(moveDestination, HexCoord(q: 3, r: 0))
        XCTAssertEqual(result.finalState.division(id: "german_0")?.location(in: result.finalState.map), "sedan")
    }

    func testV037WarCommandExecutorExecutesManualDirectiveWithoutIssuer() throws {
        let state = Self.commandScenario(germanCount: 2, alliedCount: 1)
        let playerAuthoredDirective = ZoneDirective(
            zoneId: Self.germanFront,
            attack: AttackParameters(
                targetTheaterId: TheaterId(Self.frenchFront.rawValue),
                weightedRegions: ["sedan"],
                intensity: .limitedCounter
            ),
            category: .offense,
            tactic: .standardAttack,
            commandTarget: .theater(TheaterId(Self.frenchFront.rawValue))
        )

        let result = WarCommandExecutor(commandHandler: RuleEngine()).execute(playerAuthoredDirective, in: state)

        XCTAssertFalse(result.generatedCommands.isEmpty)
        XCTAssertTrue(result.commandResults.contains { $0.succeeded })
        XCTAssertTrue(
            result.generatedCommands.contains {
                if case .attack = $0 {
                    return true
                }
                return false
            }
        )
        XCTAssertTrue(Self.isDamagedOrDestroyed("allied_0", in: result.finalState))
    }

    func testTurnManagerCanRunDirectivePipeline() async throws {
        let state = Self.commandScenario(germanCount: 5, alliedCount: 1)
        let manager = TurnManager(
            agent: GameAgent.guderianFallback(
                assignedDivisionIds: (0..<5).map { "german_\($0)" }
            ),
            provider: MockAIClient(),
            providerName: "MockAI",
            commandHandler: RuleEngine(),
            commanderPool: TheaterCommanderPool.automatic(for: state)
        )

        let outcome = await manager.runGermanAITurn(state: state)

        XCTAssertEqual(outcome.state.activeFaction, .allies)
        XCTAssertEqual(outcome.record.parsedIntent, "v0.352 zone directives")
        XCTAssertTrue(outcome.record.rawJSON?.contains("\"directives\"") == true)
        XCTAssertTrue(outcome.record.rawJSON?.contains("\"orders\"") == false)
        XCTAssertTrue(outcome.directiveRecords.contains { $0.tactic == .standardAttack })
        XCTAssertTrue(Self.isDamagedOrDestroyed("allied_0", in: outcome.state))
    }

    func testV036TurnManagerRecordsTacticFromCommanderPool() async throws {
        let state = Self.commandScenario(germanCount: 5, alliedCount: 1)
        let manager = TurnManager(
            agent: GameAgent.guderianFallback(
                assignedDivisionIds: (0..<5).map { "german_\($0)" }
            ),
            provider: MockAIClient(),
            providerName: "MockAI",
            commandHandler: RuleEngine(),
            commanderPool: TheaterCommanderPool.automatic(for: state)
        )

        let outcome = await manager.runGermanAITurn(state: state)

        XCTAssertTrue(outcome.directiveRecords.contains { $0.tactic == .standardAttack })
    }

    func testZoneDirectivePipelineDoesNotFallbackWhenFrontZonesMissing() async throws {
        var state = Self.commandScenario(germanCount: 1, alliedCount: 1)
        state.warDeploymentState = .empty
        let manager = TurnManager(
            agent: GameAgent.guderianFallback(assignedDivisionIds: ["german_0"]),
            provider: MockAIClient(),
            providerName: "MockAI",
            commandHandler: RuleEngine()
        )

        let outcome = await manager.runGermanAITurn(state: state, pipelineMode: .zoneDirective)

        XCTAssertEqual(outcome.state.activeFaction, .allies)
        XCTAssertEqual(outcome.record.parsedIntent, "v0.352 zone directives")
        XCTAssertTrue(outcome.record.rawJSON?.contains("\"directives\"") == true)
        XCTAssertTrue(outcome.record.rawJSON?.contains("\"orders\"") == false)
        XCTAssertTrue(outcome.record.errors.contains {
            $0.contains("legacy pipeline was not invoked")
        })
        XCTAssertTrue(outcome.directiveRecords.contains {
            $0.diagnostics.contains { $0.contains("legacy pipeline was not invoked") }
        })
    }

    func testZoneDirectivePipelineLogsUnassignedUnitDiagnostic() async throws {
        var state = Self.commandScenario(germanCount: 1, alliedCount: 1)
        let stray = Division.infantry(
            id: "german_stray",
            name: "german_stray",
            faction: .germany,
            coord: HexCoord(q: 99, r: 99)
        )
        state.divisions.append(stray)
        let manager = TurnManager(
            agent: GameAgent.guderianFallback(assignedDivisionIds: ["german_0", "german_stray"]),
            provider: MockAIClient(),
            providerName: "MockAI",
            commandHandler: RuleEngine()
        )

        let outcome = await manager.runGermanAITurn(state: state, pipelineMode: .zoneDirective)

        XCTAssertTrue(outcome.record.errors.contains {
            $0.contains("german_stray") && $0.contains("not assigned to any FrontZone")
        })
        XCTAssertTrue(outcome.directiveRecords.contains {
            $0.diagnostics.contains { $0.contains("german_stray") }
        })
    }

    private static let germanFront = FrontZoneId("germany_front")
    private static let frenchFront = FrontZoneId("france_front")

    private static func isDamagedOrDestroyed(_ divisionId: String, in state: GameState) -> Bool {
        guard let division = state.division(id: divisionId) else {
            return true
        }
        return division.strength < division.maxStrength
    }

    private static func commandScenario(germanCount: Int, alliedCount: Int) -> GameState {
        var divisions: [Division] = []
        let germanHexes = [
            HexCoord(q: 2, r: 0),
            HexCoord(q: 2, r: 1),
            HexCoord(q: 1, r: 0),
            HexCoord(q: 1, r: 1),
            HexCoord(q: 0, r: 1)
        ]
        let alliedHexes = [
            HexCoord(q: 3, r: 0),
            HexCoord(q: 3, r: 1),
            HexCoord(q: 4, r: 0),
            HexCoord(q: 4, r: 1),
            HexCoord(q: 5, r: 0)
        ]

        for index in 0..<germanCount {
            divisions.append(
                Division.infantry(
                    id: "german_\(index)",
                    name: "german_\(index)",
                    faction: .germany,
                    coord: germanHexes[index]
                )
            )
        }

        for index in 0..<alliedCount {
            divisions.append(
                Division.infantry(
                    id: "allied_\(index)",
                    name: "allied_\(index)",
                    faction: .allies,
                    coord: alliedHexes[index]
                )
            )
        }

        let map = commandMap()
        let theaterState = commandTheaters()
        let deployment = WarDeploymentManager().makeInitialState(
            map: map,
            theaterState: theaterState,
            divisions: divisions,
            turn: 1
        )
        let frontLineState = FrontLineManager().makeInitialState(
            map: map,
            theaterState: theaterState,
            divisions: divisions,
            turn: 1
        )

        return GameState(
            scenarioId: "v0_351_command_system",
            turn: 1,
            maxTurns: 8,
            activeFaction: .germany,
            phase: .germanAI,
            map: map,
            theaterState: theaterState,
            frontLineState: frontLineState,
            warDeploymentState: deployment,
            divisions: divisions,
            victoryState: .ongoing,
            selectedUnitSummary: nil,
            eventLog: []
        )
    }

    private static func thresholdScenario(friendlyStrength: Int, enemyStrength: Int) -> GameState {
        var state = commandScenario(germanCount: 1, alliedCount: 1)
        state.divisions = []
        var german = Division.infantry(
            id: "german_0",
            name: "german_0",
            faction: .germany,
            coord: HexCoord(q: 2, r: 0)
        )
        german.strength = friendlyStrength
        var allied = Division.infantry(
            id: "allied_0",
            name: "allied_0",
            faction: .allies,
            coord: HexCoord(q: 3, r: 0)
        )
        allied.strength = enemyStrength
        state.divisions = [german, allied]
        state.warDeploymentState = WarDeploymentManager().makeInitialState(
            map: state.map,
            theaterState: state.theaterState,
            divisions: state.divisions,
            turn: 1
        )
        state.frontLineState = FrontLineManager().makeInitialState(
            map: state.map,
            theaterState: state.theaterState,
            divisions: state.divisions,
            turn: 1
        )
        return state
    }

    private static func directiveForDoctrine(friendly: Faction, enemy: Faction) throws -> ZoneDirective {
        let state = doctrineScenario(friendly: friendly, enemy: enemy)
        let zone = try XCTUnwrap(state.warDeploymentState.frontZones[Self.germanFront])
        let agent = ZoneCommanderAgent(config: TheaterCommanderPool.defaultConfig(for: zone))
        return try XCTUnwrap(agent.makeDirective(for: zone, in: state))
    }

    private static func simulatedMarshalTactic(for faction: Faction) throws -> TacticName? {
        let raw = try SimulatedMarshalLLMClient().completeTheaterDirectiveJSON(
            summary: marshalDoctrineSummary(for: faction),
            config: marshalDoctrineConfig(for: faction)
        )
        let state = doctrineScenario(friendly: faction, enemy: .ming)
        let envelope = try TheaterDirectiveDecoder().parse(
            raw,
            expectedIssuerId: "marshal_\(faction.rawValue)",
            expectedTurn: 1,
            expectedFaction: faction,
            state: state
        )
        return try XCTUnwrap(envelope.directives.first).tactic
    }

    private static func marshalDoctrineConfig(for faction: Faction) -> MarshalAgentConfig {
        let bias: MarshalAgentConfig.StrategicBias
        switch faction {
        case .ming,
             .localNeutral:
            bias = .defensive
        case .germany,
             .qing,
             .dashun,
             .daxi:
            bias = .offensive
        case .allies:
            bias = .balanced
        }
        return MarshalAgentConfig(
            id: "marshal_\(faction.rawValue)",
            name: "\(faction.displayName) doctrine marshal",
            faction: faction,
            personality: "Doctrine test marshal.",
            strategicBias: bias
        )
    }

    private static func marshalDoctrineSummary(for faction: Faction) -> MarshalBattlefieldSummary {
        MarshalBattlefieldSummary(
            schemaVersion: 9,
            turn: 1,
            faction: faction,
            marshalId: "marshal_\(faction.rawValue)",
            marshalName: "\(faction.displayName) doctrine marshal",
            personality: "Doctrine test marshal.",
            strategicBias: marshalDoctrineConfig(for: faction).strategicBias,
            overallSupply: "adequate",
            friendlyLowSupplyCount: 0,
            friendlyEncircledCount: 0,
            economySummary: EconomyAISummary(
                stockpile: EconomyResources(manpower: 100, industry: 100, supplies: 100),
                lastIncome: EconomyResources(manpower: 0, industry: 0, supplies: 0),
                lastUpkeep: EconomyResources(manpower: 0, industry: 0, supplies: 0),
                lastReinforcementSpend: EconomyResources(manpower: 0, industry: 0, supplies: 0),
                grainShortfall: 0,
                silverShortfall: 0,
                manpowerShortfall: 0,
                governanceSummary: .empty
            ),
            courtSummary: .empty,
            campaignSummary: .empty,
            objectivesHeld: [],
            objectivesLost: [],
            fronts: [
                MarshalFrontSummary(
                    id: Self.germanFront,
                    name: "Doctrine Front",
                    state: .highIntensity,
                    pressure: 0,
                    frontRegionIds: ["ardennes"],
                    enemyRegionIds: ["sedan"],
                    enemyZoneIds: [Self.frenchFront],
                    friendlyFrontStrength: 18,
                    friendlyDepthStrength: 6,
                    visibleEnemyStrength: 10,
                    strengthRatio: 1.8,
                    frontUnitCount: 3,
                    depthUnitCount: 1,
                    garrisonUnitCount: 0,
                    supplyWarningCount: 0,
                    keyObjectivesHeld: [],
                    keyObjectivesLost: ["Enemy city"],
                    status: "advantage"
                )
            ],
            recentEvents: []
        )
    }

    private static func doctrineScenario(friendly: Faction, enemy: Faction) -> GameState {
        let friendlyHexes = [
            HexCoord(q: 2, r: 0),
            HexCoord(q: 2, r: 1)
        ]
        let enemyHexes = [
            HexCoord(q: 3, r: 0)
        ]
        let friendlyComponents = [
            DivisionComponent(type: .cavalry, weight: 0.65),
            DivisionComponent(type: .firearm, weight: 0.20),
            DivisionComponent(type: .infantry, weight: 0.15)
        ]
        let enemyComponents = [
            DivisionComponent(type: .infantry, weight: 0.80),
            DivisionComponent(type: .militia, weight: 0.20)
        ]
        let divisions: [Division] = friendlyHexes.enumerated().map { index, hex in
            Division(
                id: "friendly_\(index)",
                name: "friendly_\(index)",
                faction: friendly,
                coord: hex,
                components: friendlyComponents
            )
        } + enemyHexes.enumerated().map { index, hex in
            Division(
                id: "enemy_\(index)",
                name: "enemy_\(index)",
                faction: enemy,
                coord: hex,
                components: enemyComponents
            )
        }

        var map = commandMap()
        for regionId in map.regions.keys {
            let faction = regionId == "ardennes" ? friendly : enemy
            map.regions[regionId]?.owner = faction
            map.regions[regionId]?.controller = faction
        }
        for coord in map.tiles.keys {
            guard let regionId = map.hexToRegion[coord] else {
                continue
            }
            map.tiles[coord]?.controller = regionId == "ardennes" ? friendly : enemy
        }

        var theaterState = commandTheaters()
        theaterState.theaters[TheaterId(Self.germanFront.rawValue)]?.controllingFaction = friendly
        theaterState.theaters[TheaterId(Self.frenchFront.rawValue)]?.controllingFaction = enemy
        let deployment = WarDeploymentManager().makeInitialState(
            map: map,
            theaterState: theaterState,
            divisions: divisions,
            turn: 1
        )
        let frontLineState = FrontLineManager().makeInitialState(
            map: map,
            theaterState: theaterState,
            divisions: divisions,
            turn: 1
        )

        return GameState(
            scenarioId: "v4_7_doctrine",
            turn: 1,
            maxTurns: 8,
            activeFaction: friendly,
            phase: .aiAction,
            map: map,
            theaterState: theaterState,
            frontLineState: frontLineState,
            warDeploymentState: deployment,
            diplomacyState: DiplomacyState.initial(for: [friendly, enemy], turn: 1),
            turnOrder: [friendly, enemy],
            humanControlledFactions: [],
            aiControlledFactions: [friendly, enemy],
            divisions: divisions,
            victoryState: .ongoing,
            selectedUnitSummary: nil,
            eventLog: []
        )
    }

    private static func commandMap() -> MapState {
        let specs: [(RegionId, Faction, [RegionId], [HexCoord])] = [
            (
                "ardennes",
                .germany,
                ["sedan"],
                (0..<5).flatMap { r in
                    [HexCoord(q: 0, r: r), HexCoord(q: 1, r: r), HexCoord(q: 2, r: r)]
                }
            ),
            (
                "sedan",
                .allies,
                ["ardennes", "paris"],
                (0..<5).flatMap { r in
                    [HexCoord(q: 3, r: r), HexCoord(q: 4, r: r)]
                }
            ),
            (
                "paris",
                .allies,
                ["sedan"],
                (0..<5).map { HexCoord(q: 5, r: $0) }
            )
        ]
        var regions: [RegionId: RegionNode] = [:]
        var tiles: [HexCoord: HexTile] = [:]
        var hexToRegion: [HexCoord: RegionId] = [:]
        var edges: Set<RegionEdge> = []

        for (regionId, faction, neighbors, hexes) in specs {
            regions[regionId] = RegionNode(
                id: regionId,
                name: regionId.rawValue,
                owner: faction,
                controller: faction,
                terrain: .plain,
                neighbors: neighbors,
                displayHexes: hexes,
                representativeHex: hexes[0]
            )
            for hex in hexes {
                tiles[hex] = HexTile(coord: hex, baseTerrain: .plain, controller: faction, regionId: regionId)
                hexToRegion[hex] = regionId
            }
            edges.formUnion(neighbors.map { RegionEdge(from: regionId, to: $0) })
        }

        return MapState(
            width: 6,
            height: 5,
            tiles: tiles,
            supplySources: [],
            objectives: [],
            regions: regions,
            hexToRegion: hexToRegion,
            regionEdges: edges
        )
    }

    private static func commandTheaters() -> TheaterState {
        TheaterState(
            theaters: [
                TheaterId(germanFront.rawValue): TheaterNode(
                    id: TheaterId(germanFront.rawValue),
                    name: germanFront.rawValue,
                    status: .active,
                    regionIds: ["ardennes"],
                    controllingFaction: .germany,
                    frontWeight: 1
                ),
                TheaterId(frenchFront.rawValue): TheaterNode(
                    id: TheaterId(frenchFront.rawValue),
                    name: frenchFront.rawValue,
                    status: .active,
                    regionIds: ["sedan", "paris"],
                    controllingFaction: .allies,
                    frontWeight: 2
                )
            ],
            regionToTheater: [
                "ardennes": TheaterId(germanFront.rawValue),
                "sedan": TheaterId(frenchFront.rawValue),
                "paris": TheaterId(frenchFront.rawValue)
            ]
        )
    }
}
