import XCTest
@testable import WWIIHexV0

final class RuleEngineCoreTests: XCTestCase {
    func testHexDistanceNeighborsDirectionAndRange() {
        let origin = HexCoord(q: 0, r: 0)

        XCTAssertEqual(origin.distance(to: HexCoord(q: 2, r: -2)), 2)
        XCTAssertEqual(origin.neighbors.count, 6)
        XCTAssertTrue(origin.neighbors.contains(HexCoord(q: 1, r: 0)))
        XCTAssertEqual(origin.direction(to: HexCoord(q: 2, r: -2)), .northEast)
        XCTAssertEqual(origin.coordsWithin(distance: 1).count, 7)
    }

    func testTerrainMovementCostsAndFortressDefense() {
        let rules = MovementRules()
        let plainRoad = HexTile(coord: HexCoord(q: 0, r: 0), baseTerrain: .plain, hasRoad: true)
        let forestRoad = HexTile(coord: HexCoord(q: 1, r: 0), baseTerrain: .forest, hasRoad: true)
        let forest = HexTile(coord: HexCoord(q: 1, r: 0), baseTerrain: .forest)
        let riverPlain = HexTile(
            coord: HexCoord(q: 0, r: 0),
            baseTerrain: .plain,
            riverEdges: [.east]
        )
        let fortress = HexTile(coord: HexCoord(q: 1, r: 0), baseTerrain: .fortress)

        XCTAssertEqual(rules.movementCost(from: plainRoad, to: forestRoad, direction: .east), 1)
        XCTAssertEqual(rules.movementCost(from: plainRoad, to: forest, direction: .east), 2)
        XCTAssertEqual(rules.movementCost(from: riverPlain, to: forest, direction: .east), 4)
        XCTAssertEqual(fortress.baseTerrain.defenseBonus, 4)
    }

    func testLegalMoveChangesCoordFacingAndActedState() {
        let state = Self.testState(
            activeFaction: .allies,
            divisions: [
                Self.division(id: "a", faction: .allies, coord: HexCoord(q: 1, r: 1))
            ]
        )

        let result = RuleEngine().execute(
            .move(divisionId: "a", destination: HexCoord(q: 2, r: 1)),
            in: state
        )

        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(result.state.division(id: "a")?.coord, HexCoord(q: 2, r: 1))
        XCTAssertEqual(result.state.division(id: "a")?.facing, .east)
        XCTAssertEqual(result.state.division(id: "a")?.hasActed, true)
    }

    func testMovementCannotContinueAfterEnteringEnemyZoneOfControl() {
        let map = Self.basicMap(width: 5, height: 1)
        let allied = Self.division(id: "a", faction: .allies, coord: HexCoord(q: 0, r: 0))
        let german = Self.division(id: "g", faction: .germany, coord: HexCoord(q: 2, r: 0))
        let state = Self.testState(activeFaction: .allies, map: map, divisions: [allied, german])
        let movementRules = MovementRules()

        XCTAssertNotNil(movementRules.shortestPath(for: allied, to: HexCoord(q: 1, r: 0), in: state))
        XCTAssertNil(movementRules.shortestPath(for: allied, to: HexCoord(q: 3, r: 0), in: state))
    }

    func testIllegalMoveDoesNotChangeState() {
        let state = Self.testState(
            activeFaction: .allies,
            divisions: [
                Self.division(id: "a", faction: .allies, coord: HexCoord(q: 1, r: 1)),
                Self.division(id: "b", faction: .allies, coord: HexCoord(q: 2, r: 1))
            ]
        )

        let result = RuleEngine().execute(
            .move(divisionId: "a", destination: HexCoord(q: 2, r: 1)),
            in: state
        )

        XCTAssertFalse(result.succeeded)
        XCTAssertEqual(result.validation.errors, [.destinationOccupied])
        XCTAssertEqual(result.state, state)
    }

    func testFriendlyOccupiedHexCanBePassedThroughButNotStoppedOn() {
        let map = Self.basicMap(width: 4, height: 1)
        let mover = Self.division(id: "a", faction: .allies, coord: HexCoord(q: 0, r: 0))
        let friendlyBlocker = Self.division(id: "b", faction: .allies, coord: HexCoord(q: 1, r: 0))
        let state = Self.testState(activeFaction: .allies, map: map, divisions: [mover, friendlyBlocker])

        let path = MovementRules().shortestPath(for: mover, to: HexCoord(q: 2, r: 0), in: state)
        XCTAssertEqual(path?.coords, [
            HexCoord(q: 0, r: 0),
            HexCoord(q: 1, r: 0),
            HexCoord(q: 2, r: 0)
        ])
        XCTAssertFalse(MovementRules().movementRange(for: mover, in: state).contains(HexCoord(q: 1, r: 0)))

        let passThroughResult = RuleEngine().execute(.move(divisionId: "a", destination: HexCoord(q: 2, r: 0)), in: state)
        let stopOnFriendlyResult = RuleEngine().execute(.move(divisionId: "a", destination: HexCoord(q: 1, r: 0)), in: state)

        XCTAssertTrue(passThroughResult.succeeded)
        XCTAssertEqual(passThroughResult.state.division(id: "a")?.coord, HexCoord(q: 2, r: 0))
        XCTAssertFalse(stopOnFriendlyResult.succeeded)
        XCTAssertEqual(stopOnFriendlyResult.validation.errors, [.destinationOccupied])
    }

    func testMoveValidationDistinguishesOutOfBoundsNoPathAndInsufficientMovement() {
        let start = HexCoord(q: 0, r: 0)
        let isolatedDestination = HexCoord(q: 2, r: 2)
        let blockedMap = MapState(
            width: 3,
            height: 3,
            tiles: [
                start: HexTile(coord: start),
                isolatedDestination: HexTile(coord: isolatedDestination)
            ],
            supplySources: [],
            objectives: []
        )
        let noPathState = Self.testState(
            activeFaction: .allies,
            map: blockedMap,
            divisions: [
                Self.division(id: "a", faction: .allies, coord: start)
            ]
        )

        let noPath = RuleEngine().execute(
            .move(divisionId: "a", destination: isolatedDestination),
            in: noPathState
        )
        XCTAssertEqual(noPath.validation.errors, [.noPath])

        let insufficientState = Self.testState(
            activeFaction: .allies,
            divisions: [
                Self.division(id: "a", faction: .allies, coord: HexCoord(q: 0, r: 0))
            ]
        )
        let insufficient = RuleEngine().execute(
            .move(divisionId: "a", destination: HexCoord(q: 4, r: 0)),
            in: insufficientState
        )

        XCTAssertEqual(insufficient.validation.errors, [.insufficientMovement])

        let outOfBounds = RuleEngine().execute(
            .move(divisionId: "a", destination: HexCoord(q: 9, r: 9)),
            in: insufficientState
        )
        XCTAssertEqual(outOfBounds.validation.errors, [.destinationOutOfBounds])
    }

    func testAttackCausesDeterministicDamageAndCounterattack() {
        let attacker = Self.division(id: "a", faction: .allies, coord: HexCoord(q: 1, r: 1))
        let defender = Self.division(id: "g", faction: .germany, coord: HexCoord(q: 2, r: 1))
        let state = Self.testState(activeFaction: .allies, divisions: [attacker, defender])

        let result = RuleEngine().execute(.attack(attackerId: "a", targetId: "g"), in: state)

        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(result.state.division(id: "g")?.hp, 8)
        XCTAssertEqual(result.state.division(id: "a")?.hp, 9)
        XCTAssertEqual(result.state.division(id: "a")?.hasActed, true)
    }

    func testAttackReducesDefenderStrengthOnly() throws {
        let attacker = Self.division(id: "a", faction: .allies, coord: HexCoord(q: 1, r: 1))
        let defender = Self.division(id: "g", faction: .germany, coord: HexCoord(q: 2, r: 1))
        let state = Self.testState(activeFaction: .allies, divisions: [attacker, defender])

        let result = RuleEngine().execute(.attack(attackerId: "a", targetId: "g"), in: state)

        let updatedDefender = try XCTUnwrap(result.state.division(id: "g"))
        XCTAssertTrue(result.succeeded)
        XCTAssertLessThan(updatedDefender.strength, defender.strength)
    }

    func testArtilleryDefenderCannotCounterattackWhenAttackedAtRangeOne() {
        let attacker = Self.division(id: "a", faction: .allies, coord: HexCoord(q: 1, r: 1))
        let defender = Division.artillery(
            id: "g_artillery",
            name: "g_artillery",
            faction: .germany,
            coord: HexCoord(q: 2, r: 1)
        )
        let state = Self.testState(activeFaction: .allies, divisions: [attacker, defender])

        let result = RuleEngine().execute(.attack(attackerId: "a", targetId: "g_artillery"), in: state)

        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(result.state.division(id: "g_artillery")?.hp, 7)
        XCTAssertEqual(result.state.division(id: "a")?.hp, 10)
    }

    func testOutOfRangeAttackIsRejected() {
        let state = Self.testState(
            activeFaction: .allies,
            divisions: [
                Self.division(id: "a", faction: .allies, coord: HexCoord(q: 0, r: 0)),
                Self.division(id: "g", faction: .germany, coord: HexCoord(q: 2, r: 0))
            ]
        )

        let result = RuleEngine().execute(.attack(attackerId: "a", targetId: "g"), in: state)

        XCTAssertFalse(result.succeeded)
        XCTAssertEqual(result.validation.errors, [.targetOutOfRange])
        XCTAssertEqual(result.state, state)
    }

    func testAlreadyActedUnitCannotActAgain() {
        let state = Self.testState(
            activeFaction: .allies,
            divisions: [
                Self.division(id: "a", faction: .allies, coord: HexCoord(q: 1, r: 1), hasActed: true)
            ]
        )

        let result = RuleEngine().execute(
            .hold(divisionId: "a"),
            in: state
        )

        XCTAssertFalse(result.succeeded)
        XCTAssertEqual(result.validation.errors, [.alreadyActed])
        XCTAssertEqual(result.state, state)
    }

    func testHoldCommandSetsHoldRetreatModeAndMarksActed() throws {
        let state = Self.testState(
            activeFaction: .allies,
            divisions: [
                Self.division(id: "a", faction: .allies, coord: HexCoord(q: 1, r: 1))
            ]
        )

        let result = RuleEngine().execute(.hold(divisionId: "a"), in: state)
        let updated = try XCTUnwrap(result.state.division(id: "a"))

        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(updated.retreatMode, .hold)
        XCTAssertEqual(updated.hasActed, true)
    }

    func testAllowRetreatCommandSetsRetreatableModeAndMarksActed() throws {
        let state = Self.testState(
            activeFaction: .allies,
            divisions: [
                Self.division(id: "a", faction: .allies, coord: HexCoord(q: 1, r: 1), retreatMode: .hold)
            ]
        )

        let result = RuleEngine().execute(.allowRetreat(divisionId: "a"), in: state)
        let updated = try XCTUnwrap(result.state.division(id: "a"))

        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(updated.retreatMode, .retreatable)
        XCTAssertEqual(updated.hasActed, true)
    }

    func testResupplyRestoresSuppliedUnitStrengthAndMarksActed() throws {
        let division = Self.division(
            id: "a",
            faction: .allies,
            coord: HexCoord(q: 0, r: 0),
            hp: 7,
            supplyState: .supplied
        )
        let state = Self.testState(activeFaction: .allies, divisions: [division])

        let result = RuleEngine().execute(.resupply(divisionId: "a"), in: state)
        let recovered = try XCTUnwrap(result.state.division(id: "a"))

        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(recovered.supplyState, .supplied)
        XCTAssertGreaterThan(recovered.hp, division.hp)
        XCTAssertLessThanOrEqual(recovered.hp, division.maxHP)
        XCTAssertEqual(recovered.hasActed, true)
    }

    func testLowSupplyAndEncircledUnitsDoNotReinforceStrength() throws {
        let lowSupply = Self.division(
            id: "a",
            faction: .allies,
            coord: HexCoord(q: 0, r: 0),
            hp: 7,
            supplyState: .lowSupply
        )
        let encircled = Self.division(
            id: "a",
            faction: .allies,
            coord: HexCoord(q: 0, r: 0),
            hp: 7,
            supplyState: .encircled
        )
        let strainedSupplyMap = Self.basicMap(
            width: 5,
            height: 3,
            supplySources: [
                SupplySource(id: "allied_supply", faction: .allies, coord: HexCoord(q: 3, r: 1))
            ]
        )
        let isolatedMap = Self.basicMap(width: 3, height: 3, supplySources: [])
        let lowSupplyState = Self.testState(activeFaction: .allies, map: strainedSupplyMap, divisions: [lowSupply])
        let encircledState = Self.testState(activeFaction: .allies, map: isolatedMap, divisions: [encircled])

        let lowSupplyResult = RuleEngine().execute(.resupply(divisionId: "a"), in: lowSupplyState)
        let encircledResult = RuleEngine().execute(.resupply(divisionId: "a"), in: encircledState)

        XCTAssertEqual(try XCTUnwrap(lowSupplyResult.state.division(id: "a")).hp, lowSupply.hp)
        XCTAssertEqual(try XCTUnwrap(encircledResult.state.division(id: "a")).hp, encircled.hp)
    }

    func testEndTurnSwitchesFactionAndResetsNewActiveFactionActions() {
        let german = Self.division(
            id: "g",
            faction: .germany,
            coord: HexCoord(q: 4, r: 4),
            hasActed: true
        )
        let allied = Self.division(
            id: "a",
            faction: .allies,
            coord: HexCoord(q: 0, r: 0),
            hasActed: true
        )
        let state = Self.testState(activeFaction: .germany, divisions: [german, allied])

        let result = RuleEngine().execute(.endTurn, in: state)

        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(result.state.activeFaction, .allies)
        XCTAssertEqual(result.state.phase, .alliedPlayer)
        XCTAssertEqual(result.state.turn, 1)
        XCTAssertEqual(result.state.division(id: "a")?.hasActed, false)
        XCTAssertEqual(result.state.division(id: "g")?.hasActed, true)
    }

    func testAttackCanEliminateUnitAndRecordVictoryCounter() {
        let state = Self.testState(
            activeFaction: .allies,
            divisions: [
                Self.division(id: "a", faction: .allies, coord: HexCoord(q: 1, r: 1)),
                Self.division(id: "g", faction: .germany, coord: HexCoord(q: 2, r: 1), hp: 1)
            ]
        )

        let result = RuleEngine().execute(.attack(attackerId: "a", targetId: "g"), in: state)

        XCTAssertTrue(result.succeeded)
        XCTAssertNil(result.state.division(id: "g"))
        XCTAssertEqual(result.state.victoryState.eliminatedGermanDivisions, 1)
    }

    func testCaptureCityChangesController() {
        var map = Self.basicMap(width: 5, height: 5)
        let cityCoord = HexCoord(q: 2, r: 1)
        if var tile = map.tile(at: cityCoord) {
            tile.baseTerrain = .city
            tile.controller = .germany
            tile.cityName = "Test City"
            map.setTile(tile)
        }

        let state = Self.testState(
            activeFaction: .allies,
            map: map,
            divisions: [
                Self.division(id: "a", faction: .allies, coord: HexCoord(q: 1, r: 1))
            ]
        )

        let result = RuleEngine().execute(.move(divisionId: "a", destination: cityCoord), in: state)

        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(result.state.map.tile(at: cityCoord)?.controller, .allies)
    }

    func testAlliedMoveCapturesEnemyControlledPlainHex() {
        var map = Self.basicMap(width: 4, height: 1)
        let target = HexCoord(q: 1, r: 0)
        if var tile = map.tile(at: target) {
            tile.controller = .germany
            map.setTile(tile)
        }
        let state = Self.testState(
            activeFaction: .allies,
            map: map,
            divisions: [
                Self.division(id: "a", faction: .allies, coord: HexCoord(q: 0, r: 0))
            ]
        )

        let result = RuleEngine().execute(.move(divisionId: "a", destination: target), in: state)

        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(result.state.map.tile(at: target)?.controller, .allies)
    }

    func testCaptureSynchronizesRegionTheaterVisibilityAndFrontLineInSameTurn() throws {
        let fixture = FrontLineTestFixtures.mapAndTheaters(specs: [
            .init(id: "allied_home", faction: .allies, theaterId: FrontLineTestFixtures.theaterA, neighbors: ["front_city"]),
            .init(id: "front_city", faction: .germany, theaterId: FrontLineTestFixtures.theaterB, neighbors: ["allied_home", "german_depth"]),
            .init(id: "german_depth", faction: .germany, theaterId: FrontLineTestFixtures.theaterB, neighbors: ["front_city"])
        ])
        var map = fixture.map
        let target = HexCoord(q: 1, r: 0)
        if var targetTile = map.tile(at: target) {
            targetTile.baseTerrain = .city
            targetTile.cityName = "Front City"
            targetTile.controller = .germany
            map.setTile(targetTile)
        }

        let allied = Self.division(id: "a", faction: .allies, coord: HexCoord(q: 0, r: 0))
        let german = Self.division(id: "g", faction: .germany, coord: HexCoord(q: 2, r: 0))
        var state = Self.testState(activeFaction: .allies, map: map, divisions: [allied, german])
        state.theaterState = fixture.theaterState
        state.theaterState.initialSnapshot = TheaterInitialSnapshot.capture(from: state.theaterState)
        state.theaterState = TheaterSystem().updateTheaters(
            state: state.theaterState,
            map: state.map,
            divisions: state.divisions,
            turn: state.turn,
            force: true
        )
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

        let result = RuleEngine().execute(.move(divisionId: "a", destination: target), in: state)

        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(result.state.map.tile(at: target)?.controller, .allies)
        XCTAssertEqual(result.state.map.region(id: "front_city")?.controller, .allies)
        XCTAssertEqual(result.state.theaterState.regionToTheater["front_city"], FrontLineTestFixtures.theaterB)
        XCTAssertEqual(result.state.theaterState.dynamicTheaterId(for: target, map: result.state.map), FrontLineTestFixtures.theaterA)
        XCTAssertEqual(result.state.theaterState.initialSnapshot?.regionToTheater["front_city"], FrontLineTestFixtures.theaterB)
        XCTAssertGreaterThan(result.state.theaterState.theaters[FrontLineTestFixtures.theaterA]?.controlRatios[.allies] ?? 0, 0)
        XCTAssertEqual(result.state.frontLineState.diagnostics.updateMode, .eventDriven)
        XCTAssertTrue(result.state.frontLineState.diagnostics.updatedRegionIds.contains("front_city"))
        XCTAssertEqual(result.state.frontLineState.regionStates["front_city"]?.dirtyFlag, true)
        XCTAssertLessThan(
            RegionVisibilityRules().visibleRegions(for: .allies, in: result.state, radius: 0).count,
            result.state.map.regions.count
        )
    }

    func testAgentContextDoesNotTreatEmptyVisibilityAsAllVisible() {
        let fixture = FrontLineTestFixtures.mapAndTheaters(specs: [
            .init(id: "a", faction: .allies, theaterId: FrontLineTestFixtures.theaterA, neighbors: ["b"]),
            .init(id: "b", faction: .germany, theaterId: FrontLineTestFixtures.theaterB, neighbors: ["a"])
        ])
        let state = Self.testState(activeFaction: .allies, map: fixture.map, divisions: [])
        let agent = GameAgent.sample(id: "observer", name: "Observer", faction: .allies, role: .armyCommander)

        let context = AgentContextBuilder().agentContext(for: agent, state: state, playerDirective: nil)

        XCTAssertFalse(context.visibleRegions.contains { $0.visible })
    }

    func testUnsuppliedUnitBecomesLowSupplyOrEncircled() throws {
        var map = Self.basicMap(width: 7, height: 7)
        map.supplySources = [SupplySource(id: "allied_supply", faction: .allies, coord: HexCoord(q: 0, r: 0))]

        let state = Self.testState(
            activeFaction: .germany,
            map: map,
            divisions: [
                Self.division(id: "a", faction: .allies, coord: HexCoord(q: 6, r: 6)),
                Self.division(id: "g", faction: .germany, coord: HexCoord(q: 5, r: 6))
            ]
        )

        var next = state
        SupplyRules().updateSupplyStates(in: &next)

        let supplyState = try XCTUnwrap(next.division(id: "a")?.supplyState)
        XCTAssertTrue([SupplyState.lowSupply, .encircled].contains(supplyState))
    }

    func testSupplyModifiersReduceDerivedStatsAndEncirclementAttritionPreservesOneHP() {
        var lowSupply = Self.division(id: "low", faction: .allies, coord: HexCoord(q: 1, r: 1))
        lowSupply.supplyState = .lowSupply
        XCTAssertEqual(lowSupply.attack, 3)
        XCTAssertEqual(lowSupply.defense, 4)
        XCTAssertEqual(lowSupply.movement, 2)

        var encircled = Self.division(id: "encircled", faction: .allies, coord: HexCoord(q: 2, r: 2), hp: 1)
        encircled.supplyState = .encircled
        XCTAssertEqual(encircled.attack, 2)
        XCTAssertEqual(encircled.defense, 3)
        XCTAssertEqual(encircled.movement, 1)

        var state = Self.testState(activeFaction: .allies, divisions: [encircled])
        SupplyRules().applyEncirclementAttrition(in: &state)
        XCTAssertEqual(state.division(id: "encircled")?.hp, 1)
    }

    func testEncircledEndTurnAppliesStrengthAttrition() throws {
        let encircled = Self.division(
            id: "a",
            faction: .allies,
            coord: HexCoord(q: 1, r: 1),
            hp: 6,
            supplyState: .encircled
        )
        let isolatedMap = Self.basicMap(width: 3, height: 3, supplySources: [])
        let state = Self.testState(activeFaction: .allies, map: isolatedMap, divisions: [encircled])

        let result = RuleEngine().execute(.endTurn, in: state)

        let updated = try XCTUnwrap(result.state.division(id: "a"))
        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(updated.supplyState, .encircled)
        XCTAssertLessThan(updated.hp, encircled.hp)
        XCTAssertGreaterThanOrEqual(updated.hp, 1)
    }

    func testRetreatableDivisionAutoRetreatsAfterSevereLoss() throws {
        var map = Self.basicMap(
            width: 5,
            height: 5,
            supplySources: [
                SupplySource(id: "german_supply", faction: .germany, coord: HexCoord(q: 4, r: 2)),
                SupplySource(id: "allied_supply", faction: .allies, coord: HexCoord(q: 0, r: 2))
            ]
        )
        if var germanSupplyTile = map.tile(at: HexCoord(q: 4, r: 2)) {
            germanSupplyTile.hasRoad = true
            map.setTile(germanSupplyTile)
        }
        let attacker = Self.division(id: "a", faction: .allies, coord: HexCoord(q: 1, r: 2))
        let defender = Self.division(id: "g", faction: .germany, coord: HexCoord(q: 2, r: 2), hp: 4)
        let state = Self.testState(activeFaction: .allies, map: map, divisions: [attacker, defender])
        let expectedDestination = try XCTUnwrap(SupplyRules().retreatDestination(for: defender, in: state))

        let result = RuleEngine().execute(.attack(attackerId: "a", targetId: "g"), in: state)

        let retreated = try XCTUnwrap(result.state.division(id: "g"))
        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(retreated.coord, expectedDestination)
        XCTAssertTrue(result.state.eventLog.contains { $0.message.localizedCaseInsensitiveContains("retreat") })
    }

    func testRetreatableDivisionDoesNotRetreatAfterMinorLoss() throws {
        let attacker = Self.division(id: "a", faction: .allies, coord: HexCoord(q: 1, r: 1))
        let defender = Self.division(id: "g", faction: .germany, coord: HexCoord(q: 2, r: 1), hp: 10)
        let state = Self.testState(activeFaction: .allies, divisions: [attacker, defender])

        let result = RuleEngine().execute(.attack(attackerId: "a", targetId: "g"), in: state)

        let updated = try XCTUnwrap(result.state.division(id: "g"))
        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(updated.coord, defender.coord)
        XCTAssertFalse(updated.isRetreating)
    }

    func testHoldModeDoesNotRetreatAndTakesExtraLosses() throws {
        let attacker = Self.division(id: "a", faction: .allies, coord: HexCoord(q: 1, r: 1))
        let retreatable = Self.division(id: "r", faction: .germany, coord: HexCoord(q: 2, r: 1), hp: 10)
        let hold = Self.division(id: "h", faction: .germany, coord: HexCoord(q: 2, r: 1), hp: 10, retreatMode: .hold)
        let retreatableState = Self.testState(activeFaction: .allies, divisions: [attacker, retreatable])
        let holdState = Self.testState(activeFaction: .allies, divisions: [attacker, hold])

        let retreatableResult = RuleEngine().execute(.attack(attackerId: "a", targetId: "r"), in: retreatableState)
        let holdResult = RuleEngine().execute(.attack(attackerId: "a", targetId: "h"), in: holdState)

        let retreatableAfter = try XCTUnwrap(retreatableResult.state.division(id: "r"))
        let holdAfter = try XCTUnwrap(holdResult.state.division(id: "h"))
        XCTAssertEqual(holdAfter.coord, hold.coord)
        XCTAssertFalse(holdAfter.isRetreating)
        XCTAssertLessThanOrEqual(holdAfter.hp, retreatableAfter.hp)
    }

    func testRetreatFailureLogsAndAppliesStrengthPenalty() throws {
        let attacker = Self.division(id: "a", faction: .allies, coord: HexCoord(q: 1, r: 1))
        let defender = Self.division(id: "g", faction: .germany, coord: HexCoord(q: 2, r: 1), hp: 4)
        let isolatedMap = Self.basicMap(width: 4, height: 4, supplySources: [])
        let state = Self.testState(activeFaction: .allies, map: isolatedMap, divisions: [attacker, defender])

        let result = RuleEngine().execute(.attack(attackerId: "a", targetId: "g"), in: state)

        let updated = try XCTUnwrap(result.state.division(id: "g"))
        let logText = result.state.eventLog.map(\.message).joined(separator: "\n").lowercased()

        XCTAssertEqual(updated.coord, defender.coord)
        XCTAssertLessThan(updated.hp, defender.hp)
        XCTAssertTrue(logText.contains("failed to retreat"))
    }

    func testBastogneGermanControlRequiresFullTurnBeforeVictory() {
        var state = Self.testState(
            activeFaction: .germany,
            map: MapState.ardennesV0(),
            divisions: []
        )
        if var bastogne = state.map.tile(at: HexCoord(q: 5, r: 4)) {
            bastogne.controller = .germany
            state.map.setTile(bastogne)
        }

        VictoryRules().updateVictoryState(in: &state)
        XCTAssertNil(state.victoryState.winner)
        XCTAssertEqual(state.victoryState.germanBastogneHeldSinceTurn, 1)

        VictoryRules().updateVictoryState(in: &state)
        XCTAssertNil(state.victoryState.winner)

        state.turn = 2
        VictoryRules().updateVictoryState(in: &state)
        XCTAssertEqual(state.victoryState.winner, .germany)
        XCTAssertEqual(state.victoryState.reason, .bastogneHeldByGermany)
    }

    func testGermanArmorUnsuppliedRequiresFullTurnBeforeAlliedVictory() {
        var panzer = Division.panzer(
            id: "g_panzer",
            name: "g_panzer",
            faction: .germany,
            coord: HexCoord(q: 2, r: 2)
        )
        panzer.supplyState = .lowSupply
        var state = Self.testState(activeFaction: .allies, divisions: [panzer])

        VictoryRules().updateVictoryState(in: &state)
        XCTAssertNil(state.victoryState.winner)
        XCTAssertEqual(state.victoryState.germanArmorUnsuppliedSinceTurn, 1)

        VictoryRules().updateVictoryState(in: &state)
        XCTAssertNil(state.victoryState.winner)

        state.turn = 2
        VictoryRules().updateVictoryState(in: &state)
        XCTAssertEqual(state.victoryState.winner, .allies)
        XCTAssertEqual(state.victoryState.reason, .germanArmorUnsupplied)
    }

    func testMingScenarioQingWinsByBreakingPassAndCapital() {
        var state = Self.mingVictoryState(
            objectiveControllers: [
                "obj_shanhaiguan": .qing,
                "obj_beijing": .qing
            ]
        )

        VictoryRules().updateVictoryState(in: &state)

        XCTAssertEqual(state.victoryState.winner, .qing)
        XCTAssertEqual(state.victoryState.reason, .qingBreaksPassAndCapital)
    }

    func testMingScenarioDashunWinsByCentralPlainChain() {
        var state = Self.mingVictoryState(
            objectiveControllers: [
                "obj_kaifeng": .dashun,
                "obj_luoyang": .dashun,
                "obj_xian": .dashun
            ]
        )

        VictoryRules().updateVictoryState(in: &state)

        XCTAssertEqual(state.victoryState.winner, .dashun)
        XCTAssertEqual(state.victoryState.reason, .dashunControlsCentralPlain)
    }

    func testMingScenarioDaxiWinsByHuguangBase() {
        var state = Self.mingVictoryState(
            objectiveControllers: [
                "obj_jingzhou": .daxi,
                "obj_wuchang": .daxi
            ]
        )

        VictoryRules().updateVictoryState(in: &state)

        XCTAssertEqual(state.victoryState.winner, .daxi)
        XCTAssertEqual(state.victoryState.reason, .daxiControlsHuguangBase)
    }

    func testMingScenarioMingWinsAtFinalTurnByHoldingMandateLine() {
        var state = Self.mingVictoryState(
            objectiveControllers: [
                "obj_beijing": .ming,
                "obj_shanhaiguan": .ming,
                "obj_wuchang": .ming
            ],
            turn: 20
        )

        VictoryRules().updateVictoryState(in: &state)

        XCTAssertEqual(state.victoryState.winner, .ming)
        XCTAssertEqual(state.victoryState.reason, .mingHoldsMandateAtFinalTurn)
    }

    func testMingBattleObjectiveSummaryTracksPassAndCapitalProgress() {
        let state = Self.mingVictoryState(
            objectiveControllers: [
                "obj_shanhaiguan": .qing,
                "obj_beijing": .ming
            ]
        )

        let summary = BattleObjectiveSummary.from(state: state)
        let qingTrack = summary.track(id: .qingPassCapital)

        XCTAssertTrue(summary.isMingScenario)
        XCTAssertEqual(qingTrack?.controlledCount, 1)
        XCTAssertEqual(qingTrack?.requiredCount, 2)
        XCTAssertEqual(qingTrack?.isSatisfied, false)
        XCTAssertEqual(qingTrack?.targets.first { $0.objectiveId == "obj_shanhaiguan" }?.controller, .qing)
        XCTAssertEqual(qingTrack?.targets.first { $0.objectiveId == "obj_beijing" }?.controller, .ming)
        XCTAssertEqual(summary.leadingFaction, .ming)
    }

    func testMingBattleObjectiveSummaryUsesScenarioVictoryConditions() {
        let state = Self.mingVictoryState(
            objectiveControllers: [
                "obj_shanhaiguan": .qing,
                "obj_beijing": .ming
            ],
            victoryConditions: Self.mingVictoryConditions
        )

        let summary = BattleObjectiveSummary.from(state: state)
        let tracks = summary.tracks
        let qingTrack = summary.track(id: .qingPassCapital)

        XCTAssertEqual(tracks.map(\.id), [.mingMandateLine, .qingPassCapital, .dashunCentralPlain, .daxiHuguang])
        XCTAssertEqual(qingTrack?.subtitle, "清军夺取山海关并打开北京方向。")
        XCTAssertEqual(qingTrack?.targets.map(\.objectiveId), ["obj_shanhaiguan", "obj_beijing"])
        XCTAssertEqual(qingTrack?.timing, .immediate)
    }

    func testMingBattleObjectiveSummaryRecognizesDashunCentralPlainTrack() {
        let state = Self.mingVictoryState(
            objectiveControllers: [
                "obj_kaifeng": .dashun,
                "obj_luoyang": .dashun,
                "obj_xian": .dashun
            ]
        )

        let summary = BattleObjectiveSummary.from(state: state)
        let dashunTrack = summary.track(id: .dashunCentralPlain)

        XCTAssertEqual(dashunTrack?.isSatisfied, true)
        XCTAssertEqual(dashunTrack?.reason, .dashunControlsCentralPlain)
        XCTAssertEqual(dashunTrack?.statusText, "据中原秦陕已成")
    }

    func testMingBattleObjectiveSummaryShowsOpeningScenarioCues() {
        let state = Self.mingVictoryState(objectiveControllers: [:])

        let summary = BattleObjectiveSummary.from(state: state)

        XCTAssertEqual(summary.cues.first?.id, "songjin_aftershock")
        XCTAssertTrue(summary.cues.contains { $0.id == "chongzhen_revenue_pressure" })
        XCTAssertEqual(summary.cues.first?.kind, .history)
    }

    func testMingBattleObjectiveSummaryShowsSupplyAndObjectivePressureCues() {
        let state = Self.mingVictoryState(
            objectiveControllers: [
                "obj_shanhaiguan": .qing
            ],
            turn: 3,
            divisions: [
                Self.division(
                    id: "ming_low_supply",
                    faction: .ming,
                    coord: HexCoord(q: 1, r: 0),
                    supplyState: .lowSupply
                )
            ]
        )

        let summary = BattleObjectiveSummary.from(state: state)

        XCTAssertTrue(summary.cues.contains { $0.id == "supply_warning_ming_low_supply" })
        XCTAssertTrue(summary.cues.contains { $0.id == "objective_pressure_qingPassCapital" })
        XCTAssertEqual(summary.cues.first?.kind, .economy)
    }

    func testMingBattleObjectiveSummaryShowsCampaignStageChain() {
        let state = Self.mingVictoryState(objectiveControllers: [:])

        let summary = BattleObjectiveSummary.from(state: state)

        XCTAssertEqual(
            summary.stages.map(\.id),
            [
                "pass_capital_screen",
                "central_plain_grain_chain",
                "huguang_grain_base",
                "court_four_line_balance",
                "firearms_fortification",
                "final_mandate_line"
            ]
        )
        XCTAssertEqual(summary.stages.first?.line, .military)
        XCTAssertEqual(summary.stages.first { $0.id == "court_four_line_balance" }?.line, .policy)
        XCTAssertEqual(summary.stages.first { $0.id == "firearms_fortification" }?.status, .warning)
    }

    func testMingCampaignStageChainReflectsPressureAndFireSupport() {
        var artillery = Self.division(
            id: "ming_fire_support",
            faction: .ming,
            coord: HexCoord(q: 1, r: 0)
        )
        artillery.components = [
            DivisionComponent(type: .firearm, weight: 0.6),
            DivisionComponent(type: .siegeEngine, weight: 0.4)
        ]
        let state = Self.mingVictoryState(
            objectiveControllers: [
                "obj_shanhaiguan": .qing,
                "obj_kaifeng": .dashun,
                "obj_luoyang": .dashun
            ],
            divisions: [artillery]
        )

        let summary = BattleObjectiveSummary.from(state: state)

        XCTAssertEqual(summary.stages.first { $0.id == "pass_capital_screen" }?.status, .warning)
        XCTAssertEqual(summary.stages.first { $0.id == "central_plain_grain_chain" }?.status, .warning)
        XCTAssertEqual(summary.stages.first { $0.id == "firearms_fortification" }?.status, .focus)
        XCTAssertTrue(summary.stages.first { $0.id == "central_plain_grain_chain" }?.detail.contains("大顺已取得部分") == true)
    }

    func testMingBattleObjectiveSummaryShowsFiveLineBriefs() {
        let state = Self.mingVictoryState(
            objectiveControllers: [
                "obj_shanhaiguan": .qing,
                "obj_kaifeng": .dashun,
                "obj_luoyang": .dashun
            ]
        )

        let summary = BattleObjectiveSummary.from(state: state)
        let militaryBrief = summary.lineBriefs.first { $0.line == .military }
        let economyBrief = summary.lineBriefs.first { $0.line == .economy }

        XCTAssertEqual(summary.lineBriefs.map(\.line), [.world, .policy, .economy, .technology, .military])
        XCTAssertEqual(militaryBrief?.status, .warning)
        XCTAssertGreaterThanOrEqual(militaryBrief?.pressure ?? 0, 90)
        XCTAssertEqual(militaryBrief?.urgentTaskCount, 1)
        XCTAssertTrue(militaryBrief?.detail.contains("破关入京") == true)
        XCTAssertEqual(economyBrief?.status, .warning)
        XCTAssertGreaterThanOrEqual(economyBrief?.pressure ?? 0, 90)
        XCTAssertTrue(economyBrief?.detail.contains("河南秦陕粮链") == true)
    }

    func testMingCampaignSummaryEntersAgentAndMarshalSummaries() {
        let state = Self.mingVictoryState(
            objectiveControllers: [
                "obj_shanhaiguan": .qing,
                "obj_kaifeng": .dashun,
                "obj_luoyang": .dashun
            ]
        )
        let agent = GameAgent.sample(
            id: "ming_court_agent",
            name: "明廷督师",
            faction: .ming,
            role: .fieldMarshal
        )

        let context = AgentContextBuilder().agentContext(for: agent, state: state, playerDirective: nil)
        let prompt = AgentPromptBuilder().makeRequest(context: context, model: "test-model")
        let marshalSummary = MarshalBattlefieldSummarizer().summary(
            for: .automatic(for: .ming, state: state),
            in: state
        )

        XCTAssertTrue(context.campaignSummary.isMingScenario)
        XCTAssertTrue(context.campaignSummary.displaySummary.contains("五线"))
        XCTAssertTrue(context.campaignSummary.lineBriefs.contains { $0.line == "军事" && $0.status == "告急" })
        XCTAssertTrue(context.campaignSummary.activeTasks.contains { $0.contains("截断河南秦陕粮链") })
        XCTAssertTrue(prompt.userPrompt.contains("Campaign mandate and five-line pressure"))
        XCTAssertTrue(prompt.userPrompt.contains("五线"))
        XCTAssertTrue(TurnManager.contextSummary(context).contains("五线"))
        XCTAssertEqual(marshalSummary.schemaVersion, 9)
        XCTAssertTrue(marshalSummary.campaignSummary.isMingScenario)
        XCTAssertTrue(marshalSummary.campaignSummary.activeTasks.contains { $0.contains("堵住破关入京") })
    }

    func testMingCampaignPressureInfluencesCourtFocus() {
        let state = Self.mingVictoryState(
            objectiveControllers: [
                "obj_shanhaiguan": .qing
            ]
        )

        let summary = CourtStrategySummary.from(faction: .ming, state: state)

        XCTAssertEqual(summary.recommendedFocus, .fortify)
        XCTAssertTrue(summary.secondaryFocuses.contains(.grainTransport))
        XCTAssertTrue(summary.rationale.contains("破关入京线已动"))
    }

    func testLocalGentryPressureInfluencesCourtFocus() {
        let state = Self.mingLocalGentryState()

        let summary = CourtStrategySummary.from(faction: .ming, state: state)

        XCTAssertEqual(summary.recommendedFocus, .appeaseGentry)
        XCTAssertTrue(summary.rationale.contains("乡绅"))
        XCTAssertEqual(CourtProjectKind.appeaseGentry.displayName, "招抚乡绅")
        XCTAssertTrue(CourtProjectKind.appeaseGentry.domains.contains(.policy))
    }

    func testAppeaseGentryCourtProjectImprovesLocalGovernance() {
        let state = Self.mingLocalGentryState()
        let result = RuleEngine().execute(.enactCourtProject(kind: .appeaseGentry), in: state)
        let region = result.state.map.region(id: "region_weihui_gentry")
        let stockpile = result.state.economyState.ledger(for: .ming).stockpile

        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(region?.controller, .ming)
        XCTAssertEqual(region?.owner, .localNeutral)
        XCTAssertEqual(region?.occupationState?.resistance, 32)
        XCTAssertEqual(region?.occupationState?.compliance, 47)
        XCTAssertEqual(stockpile.manpower, 40)
        XCTAssertEqual(stockpile.industry, 50)
        XCTAssertEqual(stockpile.supplies, 40)
        XCTAssertTrue(result.state.eventLog.last?.message.contains("招抚乡绅") == true)
        XCTAssertTrue(result.state.eventLog.last?.message.contains("乡绅归附") == true)
    }

    func testLowAgrarianBaseInfluencesCourtFocus() {
        let state = Self.mingAgrarianState()

        let summary = CourtStrategySummary.from(faction: .ming, state: state)

        XCTAssertEqual(summary.recommendedFocus, .agrarianReform)
        XCTAssertTrue(summary.rationale.contains("屯田"))
        XCTAssertEqual(CourtProjectKind.agrarianReform.displayName, "农政屯田")
        XCTAssertTrue(CourtProjectKind.agrarianReform.domains.contains(.economy))
        XCTAssertTrue(CourtProjectKind.agrarianReform.domains.contains(.technology))
    }

    func testAgrarianCourtProjectImprovesFutureGrainBase() {
        let state = Self.mingAgrarianState()
        let result = RuleEngine().execute(.enactCourtProject(kind: .agrarianReform), in: state)
        let huaiqing = result.state.map.region(id: "region_huaiqing_tuntian")
        let weihui = result.state.map.region(id: "region_weihui_tuntian")
        let stockpile = result.state.economyState.ledger(for: .ming).stockpile

        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(huaiqing?.controller, .ming)
        XCTAssertEqual(weihui?.controller, .ming)
        XCTAssertEqual(huaiqing?.supplyValue, 3)
        XCTAssertEqual(huaiqing?.infrastructure, 2)
        XCTAssertEqual(huaiqing?.occupationState?.compliance, 68)
        XCTAssertEqual(weihui?.supplyValue, 2)
        XCTAssertEqual(weihui?.infrastructure, 1)
        XCTAssertEqual(stockpile.manpower, 55)
        XCTAssertEqual(stockpile.industry, 45)
        XCTAssertEqual(stockpile.supplies, 40)
        XCTAssertTrue(result.state.eventLog.last?.message.contains("农政屯田") == true)
        XCTAssertTrue(result.state.eventLog.last?.message.contains("屯田水利兴修") == true)
    }

    func testMingBattleObjectiveSummaryShowsCurrentTaskChain() {
        let state = Self.mingVictoryState(objectiveControllers: [:])

        let summary = BattleObjectiveSummary.from(state: state)

        XCTAssertEqual(
            summary.tasks.map(\.id),
            [
                "hold_pass_capital",
                "settle_revenue_and_relief",
                "guard_grain_chain",
                "ready_firearms_forts"
            ]
        )
        XCTAssertEqual(summary.tasks.map(\.line), [.military, .policy, .economy, .technology])
        XCTAssertEqual(summary.tasks.first?.priority, .main)
        XCTAssertEqual(summary.tasks.first?.targetObjectiveId, "obj_shanhaiguan")
        XCTAssertTrue(summary.tasks.contains { $0.detail.contains("征饷") && $0.detail.contains("赈济") })
    }

    func testMingTaskChainReflectsObjectivePressure() {
        let state = Self.mingVictoryState(
            objectiveControllers: [
                "obj_shanhaiguan": .qing,
                "obj_kaifeng": .dashun,
                "obj_luoyang": .dashun
            ]
        )

        let summary = BattleObjectiveSummary.from(state: state)
        let militaryTask = summary.tasks.first { $0.id == "hold_pass_capital" }
        let economyTask = summary.tasks.first { $0.id == "block_central_plain_grain_chain" }

        XCTAssertEqual(militaryTask?.priority, .urgent)
        XCTAssertEqual(militaryTask?.targetObjectiveId, "obj_beijing")
        XCTAssertEqual(economyTask?.priority, .urgent)
        XCTAssertEqual(economyTask?.targetObjectiveId, "obj_xian")
        XCTAssertTrue(militaryTask?.detail.contains("破关入京") == true)
        XCTAssertTrue(economyTask?.detail.contains("大顺已取 2 / 3") == true)
    }

    func testMingEndTurnRecordsBattleCuesAsReports() {
        let state = Self.mingVictoryState(objectiveControllers: [:])

        let result = RuleEngine().execute(.endTurn, in: state)

        XCTAssertTrue(result.succeeded)
        XCTAssertTrue(result.state.eventLog.contains {
            $0.relatedRecordId == "battle-cue-1-ming-songjin_aftershock"
                && $0.message.contains("松锦余波")
        })
        XCTAssertTrue(result.state.eventLog.contains {
            $0.relatedRecordId == "battle-cue-1-ming-chongzhen_revenue_pressure"
                && $0.message.contains("催饷与安民")
        })
    }

    func testMingEndTurnRecordsBattleTasksAsReports() {
        let state = Self.mingVictoryState(
            objectiveControllers: [
                "obj_shanhaiguan": .qing,
                "obj_kaifeng": .dashun,
                "obj_luoyang": .dashun
            ]
        )

        let result = RuleEngine().execute(.endTurn, in: state)

        XCTAssertTrue(result.succeeded)
        XCTAssertTrue(result.state.eventLog.contains {
            $0.category == .frontChange
                && $0.relatedRecordId == "battle-task-1-ming-hold_pass_capital"
                && $0.message.contains("堵住破关入京")
                && $0.message.contains("急务")
        })
        XCTAssertTrue(result.state.eventLog.contains {
            $0.category == .supply
                && $0.relatedRecordId == "battle-task-1-ming-block_central_plain_grain_chain"
                && $0.message.contains("截断河南秦陕粮链")
        })
        XCTAssertFalse(result.state.eventLog.contains {
            $0.relatedRecordId == "battle-task-1-ming-ready_firearms_forts"
        })
    }

    func testMingObjectiveCaptureRecordsControlChangeReport() {
        var state = Self.mingVictoryState(
            objectiveControllers: [
                "obj_shanhaiguan": .qing
            ],
            divisions: [
                Self.division(id: "qing_vanguard", faction: .qing, coord: HexCoord(q: 0, r: 0))
            ]
        )
        state.activeFaction = .qing
        state.phase = .aiAction
        state.diplomacyState = DiplomacyState.initial(for: [.ming, .qing, .dashun, .daxi], turn: state.turn)

        let result = RuleEngine().execute(
            .move(divisionId: "qing_vanguard", destination: HexCoord(q: 1, r: 0)),
            in: state
        )

        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(result.state.map.controllerOfObjective(id: "obj_beijing"), .qing)
        XCTAssertTrue(result.state.eventLog.contains {
            $0.category == .regionOwnerChange
                && $0.relatedRecordId == "objective-control-1-obj_beijing-ming-qing"
                && $0.message.contains("北京易手")
                && $0.message.contains("后金/清")
        })
    }

    func testInvalidCommandDoesNotModifyGameState() {
        let state = Self.testState(
            activeFaction: .allies,
            divisions: [
                Self.division(id: "a", faction: .allies, coord: HexCoord(q: 1, r: 1)),
                Self.division(id: "g", faction: .germany, coord: HexCoord(q: 2, r: 1))
            ]
        )

        let result = RuleEngine().execute(.attack(attackerId: "missing", targetId: "g"), in: state)

        XCTAssertFalse(result.succeeded)
        XCTAssertEqual(result.validation.errors, [.divisionNotFound])
        XCTAssertEqual(result.state, state)
    }

    private static func division(
        id: String,
        faction: Faction,
        coord: HexCoord,
        hp: Int = 10,
        supplyState: SupplyState = .supplied,
        hasActed: Bool = false,
        retreatMode: RetreatMode = .retreatable
    ) -> Division {
        Division(
            id: id,
            name: id,
            faction: faction,
            coord: coord,
            facing: faction == .germany ? .west : .east,
            hp: hp,
            maxHP: 10,
            components: [
                DivisionComponent(type: .infantry, weight: 1.0)
            ],
            supplyState: supplyState,
            hasActed: hasActed,
            retreatMode: retreatMode
        )
    }

    private static func testState(
        activeFaction: Faction,
        divisions: [Division]
    ) -> GameState {
        testState(activeFaction: activeFaction, map: basicMap(width: 5, height: 5), divisions: divisions)
    }

    private static func testState(
        activeFaction: Faction,
        map: MapState,
        divisions: [Division]
    ) -> GameState {
        GameState(
            scenarioId: "test",
            turn: 1,
            maxTurns: 8,
            activeFaction: activeFaction,
            phase: activeFaction == .germany ? .germanAI : .alliedPlayer,
            map: map,
            divisions: divisions,
            victoryState: .ongoing,
            selectedUnitSummary: nil,
            eventLog: []
        )
    }

    private static func basicMap(
        width: Int,
        height: Int,
        supplySources: [SupplySource]? = nil
    ) -> MapState {
        var tiles: [HexCoord: HexTile] = [:]
        for q in 0..<width {
            for r in 0..<height {
                let coord = HexCoord(q: q, r: r)
                tiles[coord] = HexTile(coord: coord)
            }
        }

        return MapState(
            width: width,
            height: height,
            tiles: tiles,
            supplySources: supplySources ?? [
                SupplySource(id: "allied_supply", faction: .allies, coord: HexCoord(q: 0, r: 0)),
                SupplySource(id: "german_supply", faction: .germany, coord: HexCoord(q: width - 1, r: height - 1))
            ],
            objectives: []
        )
    }

    private static func mingVictoryState(
        objectiveControllers: [String: Faction],
        turn: Int = 1,
        maxTurns: Int = 20,
        victoryConditions: [VictoryConditionDefinition] = Self.mingVictoryConditions,
        divisions: [Division] = []
    ) -> GameState {
        let objectives: [Objective] = [
            Objective(id: "obj_shanhaiguan", name: "山海关", coord: HexCoord(q: 0, r: 0), type: .fortress, points: 7),
            Objective(id: "obj_beijing", name: "北京", coord: HexCoord(q: 1, r: 0), type: .city, points: 9),
            Objective(id: "obj_kaifeng", name: "开封", coord: HexCoord(q: 2, r: 0), type: .city, points: 6),
            Objective(id: "obj_luoyang", name: "洛阳", coord: HexCoord(q: 3, r: 0), type: .city, points: 5),
            Objective(id: "obj_xian", name: "西安", coord: HexCoord(q: 4, r: 0), type: .city, points: 6),
            Objective(id: "obj_jingzhou", name: "荆州", coord: HexCoord(q: 5, r: 0), type: .city, points: 4),
            Objective(id: "obj_wuchang", name: "武昌", coord: HexCoord(q: 6, r: 0), type: .city, points: 5)
        ]
        let tiles = Dictionary(uniqueKeysWithValues: objectives.map { objective in
            (
                objective.coord,
                HexTile(
                    coord: objective.coord,
                    baseTerrain: objective.type == .fortress ? .fortress : .city,
                    controller: objectiveControllers[objective.id] ?? .ming
                )
            )
        })

        return GameState(
            scenarioId: "chongzhen_1642_collapse",
            turn: turn,
            maxTurns: maxTurns,
            activeFaction: .ming,
            phase: .humanAction,
            map: MapState(
                width: 7,
                height: 1,
                tiles: tiles,
                supplySources: [],
                objectives: objectives
            ),
            victoryConditions: victoryConditions,
            turnOrder: [.ming, .qing, .dashun, .daxi],
            humanControlledFactions: [.ming],
            aiControlledFactions: [.qing, .dashun, .daxi],
            divisions: divisions,
            victoryState: .ongoing,
            selectedUnitSummary: nil,
            eventLog: []
        )
    }

    private static func mingLocalGentryState() -> GameState {
        let coord = HexCoord(q: 0, r: 0)
        let regionId = RegionId("region_weihui_gentry")
        var map = basicMap(width: 2, height: 1, supplySources: [])
        var tile = map.tiles[coord] ?? HexTile(coord: coord)
        tile.controller = .ming
        map.tiles[coord] = tile
        map.hexToRegion[coord] = regionId
        map.regions[regionId] = RegionNode(
            id: regionId,
            name: "卫辉乡绅",
            owner: .localNeutral,
            controller: .ming,
            terrain: .plain,
            neighbors: [],
            displayHexes: [coord],
            representativeHex: coord,
            occupationState: OccupationState(resistance: 42, compliance: 35)
        )

        var economyState = EconomyState()
        economyState.updateLedger(
            FactionEconomyLedger(
                faction: .ming,
                stockpile: EconomyResources(manpower: 50, industry: 80, supplies: 60)
            )
        )

        return GameState(
            scenarioId: "chongzhen_1642_collapse",
            turn: 1,
            maxTurns: 20,
            activeFaction: .ming,
            phase: .humanAction,
            map: map,
            economyState: economyState,
            turnOrder: [.ming],
            humanControlledFactions: [.ming],
            aiControlledFactions: [],
            divisions: [],
            victoryState: .ongoing,
            selectedUnitSummary: nil,
            eventLog: []
        )
    }

    private static func mingAgrarianState() -> GameState {
        let huaiqingCoord = HexCoord(q: 0, r: 0)
        let weihuiCoord = HexCoord(q: 1, r: 0)
        let huaiqingId = RegionId("region_huaiqing_tuntian")
        let weihuiId = RegionId("region_weihui_tuntian")
        var map = basicMap(width: 2, height: 1, supplySources: [])
        var huaiqingTile = map.tiles[huaiqingCoord] ?? HexTile(coord: huaiqingCoord)
        huaiqingTile.controller = .ming
        map.tiles[huaiqingCoord] = huaiqingTile
        map.hexToRegion[huaiqingCoord] = huaiqingId
        map.regions[huaiqingId] = RegionNode(
            id: huaiqingId,
            name: "怀庆屯田",
            owner: .ming,
            controller: .ming,
            terrain: .plain,
            neighbors: [weihuiId],
            displayHexes: [huaiqingCoord],
            representativeHex: huaiqingCoord,
            infrastructure: 1,
            supplyValue: 1,
            coreOf: [.ming],
            occupationState: OccupationState(resistance: 10, compliance: 65)
        )

        var weihuiTile = map.tiles[weihuiCoord] ?? HexTile(coord: weihuiCoord)
        weihuiTile.controller = .ming
        map.tiles[weihuiCoord] = weihuiTile
        map.hexToRegion[weihuiCoord] = weihuiId
        map.regions[weihuiId] = RegionNode(
            id: weihuiId,
            name: "卫辉屯田",
            owner: .ming,
            controller: .ming,
            terrain: .plain,
            neighbors: [huaiqingId],
            displayHexes: [weihuiCoord],
            representativeHex: weihuiCoord,
            infrastructure: 0,
            supplyValue: 0,
            coreOf: [.ming]
        )

        var economyState = EconomyState()
        economyState.updateLedger(
            FactionEconomyLedger(
                faction: .ming,
                stockpile: EconomyResources(manpower: 80, industry: 80, supplies: 50)
            )
        )

        return GameState(
            scenarioId: "chongzhen_1642_collapse",
            turn: 1,
            maxTurns: 20,
            activeFaction: .ming,
            phase: .humanAction,
            map: map,
            economyState: economyState,
            turnOrder: [.ming],
            humanControlledFactions: [.ming],
            aiControlledFactions: [],
            divisions: [],
            victoryState: .ongoing,
            selectedUnitSummary: nil,
            eventLog: []
        )
    }

    private static let mingVictoryConditions: [VictoryConditionDefinition] = [
        VictoryConditionDefinition(
            id: "ming_hold_north",
            type: "holdObjectives",
            faction: "ming",
            objectiveId: nil,
            objectiveIds: ["obj_beijing", "obj_shanhaiguan", "obj_wuchang"],
            targetFaction: nil,
            targetTemplateIds: nil,
            turns: nil,
            turn: 20,
            count: nil,
            status: "planned",
            description: "明廷坚持到第 20 回合并守住北京、山海关、武昌。"
        ),
        VictoryConditionDefinition(
            id: "qing_break_pass",
            type: "controlObjectives",
            faction: "qing",
            objectiveId: nil,
            objectiveIds: ["obj_shanhaiguan", "obj_beijing"],
            targetFaction: nil,
            targetTemplateIds: nil,
            turns: nil,
            turn: nil,
            count: nil,
            status: "planned",
            description: "清军夺取山海关并打开北京方向。"
        ),
        VictoryConditionDefinition(
            id: "dashun_grain_chain",
            type: "controlObjectives",
            faction: "dashun",
            objectiveId: nil,
            objectiveIds: ["obj_kaifeng", "obj_luoyang", "obj_xian"],
            targetFaction: nil,
            targetTemplateIds: nil,
            turns: nil,
            turn: nil,
            count: nil,
            status: "planned",
            description: "大顺控制河南和秦陕粮道核心。"
        ),
        VictoryConditionDefinition(
            id: "daxi_huguang_base",
            type: "controlObjectives",
            faction: "daxi",
            objectiveId: nil,
            objectiveIds: ["obj_jingzhou", "obj_wuchang"],
            targetFaction: nil,
            targetTemplateIds: nil,
            turns: nil,
            turn: nil,
            count: nil,
            status: "planned",
            description: "大西夺取湖广粮区立足点。"
        )
    ]
}
