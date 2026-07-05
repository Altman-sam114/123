import Foundation

struct EconomyRules {
    private let baseManpowerReserve = 320
    private let baseIndustryReserve = 160
    private let baseSupplyReserve = 180
    private let maxAutomaticReinforcementPerDivision = 2

    func makeInitialState(map: MapState, factions: [Faction], turn: Int) -> EconomyState {
        var state = EconomyState(lastResolvedTurn: turn)
        let uniqueFactions = Set(factions).isEmpty ? Set(Faction.legacyCases) : Set(factions)

        for faction in uniqueFactions {
            let income = income(for: faction, map: map)
            state.updateLedger(
                FactionEconomyLedger(
                    faction: faction,
                    stockpile: EconomyResources(
                        manpower: baseManpowerReserve + income.manpower * 2,
                        industry: baseIndustryReserve + income.industry,
                        supplies: baseSupplyReserve + income.supplies
                    ),
                    lastIncome: income,
                    lastUpdatedTurn: turn
                )
            )
        }

        return state
    }

    func bootstrapIfNeeded(_ state: GameState) -> GameState {
        guard state.economyState.ledgers.isEmpty else {
            return state
        }

        var next = state
        let factions = next.divisions.map(\.faction)
            + next.turnOrder
            + next.humanControlledFactions
            + next.aiControlledFactions
        next.economyState = makeInitialState(map: next.map, factions: factions, turn: next.turn)
        next.appendEvent(
            "经济总账已从己控城镇、工坊、粮道和州府聚合生成。",
            category: .supply
        )
        return next
    }

    func canQueueProduction(kind: ProductionKind, faction: Faction, in state: GameState) -> Bool {
        state.economyState.ledger(for: faction).stockpile.canAfford(kind.cost)
    }

    func queueProduction(kind: ProductionKind, faction: Faction, in state: inout GameState) -> Bool {
        var ledger = state.economyState.ledger(for: faction)
        guard ledger.stockpile.canAfford(kind.cost) else {
            state.appendEvent(
                "\(faction.displayName) 民力/银两/粮草不足，无法执行\(kind.displayName)。",
                category: .supply
            )
            return false
        }

        ledger.stockpile.subtract(kind.cost)
        let order = ProductionOrder(
            id: productionOrderId(kind: kind, faction: faction, turn: state.turn, index: ledger.productionQueue.count),
            faction: faction,
            kind: kind,
            createdTurn: state.turn
        )
        ledger.productionQueue.append(order)
        ledger.lastUpdatedTurn = state.turn
        state.economyState.updateLedger(ledger)
        state.appendEvent(
            "\(faction.displayName) 排入\(kind.displayName)：耗费 \(resourceSummary(kind.cost))，需 \(kind.buildTurns) 回合。",
            category: .supply
        )
        return true
    }

    func canEnactCourtProject(kind: CourtProjectKind, faction: Faction, in state: GameState) -> Bool {
        state.economyState.ledger(for: faction).stockpile.canAfford(kind.cost)
    }

    func enactCourtProject(kind: CourtProjectKind, faction: Faction, in state: inout GameState) -> Bool {
        var ledger = state.economyState.ledger(for: faction)
        guard ledger.stockpile.canAfford(kind.cost) else {
            state.appendEvent(
                "\(faction.displayName) 民力/银两/粮草不足，无法施行\(kind.displayName)。",
                category: .supply
            )
            return false
        }

        ledger.stockpile.subtract(kind.cost)
        ledger.stockpile.add(kind.resourceGain)
        let effectSummary = applyCourtProjectEffect(kind, faction: faction, ledger: &ledger, state: &state)
        ledger.lastUpdatedTurn = state.turn
        state.economyState.updateLedger(ledger)
        state.appendEvent(
            "\(faction.displayName) 施行\(kind.displayName)：耗费 \(resourceSummary(kind.cost))；\(effectSummary)；库存 \(resourceSummary(ledger.stockpile))。",
            category: .supply
        )
        return true
    }

    func resolveFactionTurn(for faction: Faction, in state: inout GameState) {
        ensureLedger(for: faction, in: &state)

        var ledger = state.economyState.ledger(for: faction)
        let turnIncome = income(for: faction, map: state.map)
        ledger.stockpile.add(turnIncome)
        ledger.lastIncome = turnIncome

        let upkeep = supplyUpkeep(for: faction, in: state)
        let paidUpkeep = EconomyResources(supplies: min(ledger.stockpile.supplies, upkeep.supplies))
        ledger.stockpile.subtract(paidUpkeep)
        ledger.lastUpkeep = upkeep
        let supplyShortfall = max(0, upkeep.supplies - paidUpkeep.supplies)

        if supplyShortfall > 0 {
            applyStrategicSupplyShortfall(for: faction, in: &state)
        }

        let reinforcementSpend = applyAutomaticReinforcement(for: faction, ledger: &ledger, in: &state)
        ledger.lastReinforcementSpend = reinforcementSpend

        advanceProduction(for: faction, ledger: &ledger, in: &state)

        ledger.lastUpdatedTurn = state.turn
        state.economyState.updateLedger(ledger)
        state.economyState.lastResolvedTurn = state.turn
        state.appendEvent(
            "\(faction.displayName) 经济结算：收入 \(resourceSummary(turnIncome))；军粮维护 \(resourceSummary(upkeep))；补员 \(resourceSummary(reinforcementSpend))；库存 \(resourceSummary(ledger.stockpile))。",
            category: .supply
        )
    }

    func cityLevel(for region: RegionNode, map: MapState) -> CityLevel {
        let hasHexCity = region.displayHexes.contains { hex in
            guard let tile = map.tile(at: hex) else {
                return false
            }
            return tile.baseTerrain == .city || tile.cityName != nil || tile.fortressName != nil
        }

        guard region.city != nil || hasHexCity || region.factories > 0 else {
            return .none
        }

        if region.city?.isCapital == true ||
            (region.city?.victoryPoints ?? 0) >= 5 ||
            region.factories >= 5 {
            return .metropolis
        }

        if (region.city?.victoryPoints ?? 0) >= 2 ||
            region.factories >= 2 ||
            region.supplyValue >= 3 {
            return .town
        }

        return .village
    }

    func income(for faction: Faction, map: MapState) -> EconomyResources {
        var income = EconomyResources()

        for region in map.regions.values where region.controller == faction && region.isPassable {
            guard hasControlledHex(in: region, faction: faction, map: map) else {
                continue
            }

            income.add(incomeContribution(for: region, faction: faction, map: map))
        }

        if map.regions.isEmpty {
            let controlledTiles = map.tiles.values.filter { $0.controller == faction }
            income.add(
                EconomyResources(
                    manpower: max(12, controlledTiles.count * 2),
                    industry: max(8, controlledTiles.filter { $0.baseTerrain == .city || $0.cityName != nil }.count * 4),
                    supplies: max(12, map.supplySources(for: faction).count * 12)
                )
            )
        }

        return income
    }

    func incomeContribution(for region: RegionNode, faction: Faction, map: MapState) -> EconomyResources {
        let level = cityLevel(for: region, map: map)
        let coreBonus = region.coreOf.isEmpty || region.coreOf.contains(faction) ? 1 : 0
        let base = EconomyResources(
            manpower: max(1, level.manpowerGrowth + coreBonus * 4 + region.infrastructure),
            industry: max(0, region.factories + level.industryValue + region.infrastructure / 3),
            supplies: max(1, region.supplyValue * 3 + region.factories + region.infrastructure / 2)
        )
        return applyGovernanceYield(to: base, occupationState: region.occupationState)
    }

    private func ensureLedger(for faction: Faction, in state: inout GameState) {
        if state.economyState.ledgers[faction] == nil {
            let income = income(for: faction, map: state.map)
            state.economyState.updateLedger(
                FactionEconomyLedger(
                    faction: faction,
                    stockpile: EconomyResources(
                        manpower: baseManpowerReserve + income.manpower,
                        industry: baseIndustryReserve + income.industry,
                        supplies: baseSupplyReserve + income.supplies
                    ),
                    lastIncome: income,
                    lastUpdatedTurn: state.turn
                )
            )
        }
    }

    private func applyCourtProjectEffect(
        _ kind: CourtProjectKind,
        faction: Faction,
        ledger: inout FactionEconomyLedger,
        state: inout GameState
    ) -> String {
        switch kind {
        case .raiseTax:
            let affected = adjustGovernance(
                faction: faction,
                resistanceDelta: 8,
                complianceDelta: -4,
                limit: 3,
                state: &state
            )
            let governanceText = affected.isEmpty ? "未找到可征州府" : "\(affected.joined(separator: "、")) 民变上升"
            return "银两 +\(kind.resourceGain.industry)，\(governanceText)"
        case .relief:
            let affected = adjustGovernance(
                faction: faction,
                resistanceDelta: -14,
                complianceDelta: 8,
                limit: 3,
                state: &state
            )
            return affected.isEmpty ? "未找到可赈州府" : "\(affected.joined(separator: "、")) 民变下降"
        case .appeaseGentry:
            let affected = appeaseLocalGentry(faction: faction, limit: 3, state: &state)
            return affected.isEmpty ? "未找到可招抚州府" : "\(affected.joined(separator: "、")) 乡绅归附，行政恢复"
        case .agrarianReform:
            let affected = cultivateControlledRegions(faction: faction, limit: 2, state: &state)
            return affected.isEmpty ? "未找到可屯田州府" : "\(affected.joined(separator: "、")) 屯田水利兴修，粮草产出提升"
        case .fortify:
            let affected = fortifyControlledRegions(faction: faction, limit: 2, state: &state)
            return affected.isEmpty ? "未找到可修城州府" : "\(affected.joined(separator: "、")) 城防和粮道提升"
        case .trainMilitia:
            let order = ProductionOrder(
                id: productionOrderId(kind: .infantryDivision, faction: faction, turn: state.turn, index: ledger.productionQueue.count),
                faction: faction,
                kind: .infantryDivision,
                remainingTurns: 1,
                totalTurns: 1,
                createdTurn: state.turn
            )
            ledger.productionQueue.append(order)
            return "地方守备排入队列，1 回合后可部署"
        case .firearmReform:
            let restored = restoreFireSupportUnits(faction: faction, limit: 3, state: &state)
            if restored > 0 {
                return "\(restored) 支火器/炮队整备，兵力小幅恢复"
            }
            let order = ProductionOrder(
                id: productionOrderId(kind: .artilleryDivision, faction: faction, turn: state.turn, index: ledger.productionQueue.count),
                faction: faction,
                kind: .artilleryDivision,
                remainingTurns: 1,
                totalTurns: 1,
                createdTurn: state.turn
            )
            ledger.productionQueue.append(order)
            return "军械工坊转入造炮队，1 回合后可部署"
        case .redCannonMaintenance:
            let maintained = maintainRedCannonUnits(faction: faction, limit: 2, state: &state)
            if !maintained.isEmpty {
                return "\(maintained.joined(separator: "、")) 红衣炮队校修，守城/攻城火力恢复"
            }
            let order = ProductionOrder(
                id: productionOrderId(kind: .artilleryDivision, faction: faction, turn: state.turn, index: ledger.productionQueue.count),
                faction: faction,
                kind: .artilleryDivision,
                remainingTurns: 1,
                totalTurns: 1,
                createdTurn: state.turn
            )
            ledger.productionQueue.append(order)
            return "军械工坊校铸红衣炮，1 回合后可部署"
        case .grainTransport:
            let supplied = restoreLowSupplyUnits(faction: faction, limit: 3, state: &state)
            let supplyText = supplied > 0 ? "，\(supplied) 支缺粮部队恢复有粮" : ""
            return "粮草 +\(kind.resourceGain.supplies)\(supplyText)"
        }
    }

    private func adjustGovernance(
        faction: Faction,
        resistanceDelta: Int,
        complianceDelta: Int,
        limit: Int,
        state: inout GameState
    ) -> [String] {
        let regions = controlledRegions(for: faction, in: state)
            .sorted {
                let lhs = $0.occupationState ?? .stable
                let rhs = $1.occupationState ?? .stable
                if resistanceDelta < 0, lhs.resistance != rhs.resistance {
                    return lhs.resistance > rhs.resistance
                }
                if lhs.compliance != rhs.compliance {
                    return lhs.compliance < rhs.compliance
                }
                return $0.id.rawValue < $1.id.rawValue
            }
            .prefix(limit)

        var names: [String] = []
        for region in regions {
            guard var current = state.map.regions[region.id] else {
                continue
            }
            let occupation = current.occupationState ?? .stable
            current.occupationState = OccupationState(
                resistance: occupation.resistance + resistanceDelta,
                compliance: occupation.compliance + complianceDelta
            )
            state.map.regions[region.id] = current
            names.append(current.name)
        }
        return names
    }

    private func appeaseLocalGentry(
        faction: Faction,
        limit: Int,
        state: inout GameState
    ) -> [String] {
        let regions = controlledRegions(for: faction, in: state)
            .filter { region in
                let occupation = region.occupationState ?? .stable
                return region.owner == .localNeutral ||
                    (!region.coreOf.isEmpty && !region.coreOf.contains(faction)) ||
                    occupation.resistance >= 15 ||
                    occupation.compliance < 70
            }
            .sorted {
                let lhsScore = pacificationScore(for: $0, faction: faction)
                let rhsScore = pacificationScore(for: $1, faction: faction)
                if lhsScore != rhsScore {
                    return lhsScore > rhsScore
                }
                return $0.id.rawValue < $1.id.rawValue
            }
            .prefix(limit)

        var names: [String] = []
        for region in regions {
            guard var current = state.map.regions[region.id] else {
                continue
            }
            let occupation = current.occupationState ?? .stable
            current.occupationState = OccupationState(
                resistance: occupation.resistance - 10,
                compliance: occupation.compliance + 12
            )
            state.map.regions[region.id] = current
            names.append(current.name)
        }
        return names
    }

    private func pacificationScore(for region: RegionNode, faction: Faction) -> Int {
        let occupation = region.occupationState ?? .stable
        let localBonus = region.owner == .localNeutral ? 40 : 0
        let nonCoreBonus = !region.coreOf.isEmpty && !region.coreOf.contains(faction) ? 20 : 0
        return localBonus + nonCoreBonus + occupation.resistance + max(0, 70 - occupation.compliance)
    }

    private func cultivateControlledRegions(
        faction: Faction,
        limit: Int,
        state: inout GameState
    ) -> [String] {
        let regions = controlledRegions(for: faction, in: state)
            .filter { $0.supplyValue < 4 || $0.infrastructure < 3 }
            .sorted {
                let lhsScore = agrarianScore(for: $0)
                let rhsScore = agrarianScore(for: $1)
                if lhsScore != rhsScore {
                    return lhsScore > rhsScore
                }
                return $0.id.rawValue < $1.id.rawValue
            }
            .prefix(limit)

        var names: [String] = []
        for region in regions {
            guard var current = state.map.regions[region.id] else {
                continue
            }
            current.supplyValue += 2
            current.infrastructure += 1
            if let occupation = current.occupationState {
                current.occupationState = OccupationState(
                    resistance: occupation.resistance,
                    compliance: occupation.compliance + 3
                )
            }
            state.map.regions[region.id] = current
            names.append(current.name)
        }
        return names
    }

    private func agrarianScore(for region: RegionNode) -> Int {
        let terrainBonus: Int
        switch region.terrain {
        case .plain:
            terrainBonus = 40
        case .city:
            terrainBonus = 24
        case .hill:
            terrainBonus = 20
        case .forest:
            terrainBonus = 12
        case .fortress:
            terrainBonus = 8
        case .mountain:
            terrainBonus = 4
        }
        let supplyNeed = max(0, 4 - region.supplyValue) * 12
        let infrastructureNeed = max(0, 3 - region.infrastructure) * 8
        return terrainBonus + supplyNeed + infrastructureNeed
    }

    private func fortifyControlledRegions(
        faction: Faction,
        limit: Int,
        state: inout GameState
    ) -> [String] {
        let regions = controlledRegions(for: faction, in: state)
            .sorted {
                let lhsScore = deploymentRegionScore($0, map: state.map)
                let rhsScore = deploymentRegionScore($1, map: state.map)
                if lhsScore != rhsScore {
                    return lhsScore > rhsScore
                }
                return $0.id.rawValue < $1.id.rawValue
            }
            .prefix(limit)

        var names: [String] = []
        for region in regions {
            guard var current = state.map.regions[region.id] else {
                continue
            }
            current.infrastructure += 1
            current.supplyValue += 1
            state.map.regions[region.id] = current
            names.append(current.name)
        }
        return names
    }

    private func restoreFireSupportUnits(
        faction: Faction,
        limit: Int,
        state: inout GameState
    ) -> Int {
        var restored = 0
        let candidateIds = state.divisions
            .filter {
                $0.faction == faction &&
                    ($0.hasFireSupport || $0.isSiegeCapable) &&
                    $0.strength < $0.maxStrength &&
                    !$0.isDestroyed
            }
            .sorted { $0.strength < $1.strength }
            .prefix(limit)
            .map(\.id)

        for divisionId in candidateIds {
            guard let index = state.divisionIndex(id: divisionId) else {
                continue
            }
            state.divisions[index].reinforceStrength(1)
            restored += 1
        }
        return restored
    }

    private func maintainRedCannonUnits(
        faction: Faction,
        limit: Int,
        state: inout GameState
    ) -> [String] {
        let candidateIds = state.divisions
            .filter {
                $0.faction == faction &&
                    $0.isSiegeCapable &&
                    $0.strength < $0.maxStrength &&
                    !$0.isDestroyed
            }
            .sorted {
                let lhsMissing = $0.maxStrength - $0.strength
                let rhsMissing = $1.maxStrength - $1.strength
                if lhsMissing != rhsMissing {
                    return lhsMissing > rhsMissing
                }
                return $0.id < $1.id
            }
            .prefix(limit)
            .map(\.id)

        var maintained: [String] = []
        for divisionId in candidateIds {
            guard let index = state.divisionIndex(id: divisionId) else {
                continue
            }
            let before = state.divisions[index].strength
            state.divisions[index].reinforceStrength(2)
            if state.divisions[index].strength > before {
                maintained.append(state.divisions[index].name)
            }
        }
        return maintained
    }

    private func restoreLowSupplyUnits(
        faction: Faction,
        limit: Int,
        state: inout GameState
    ) -> Int {
        var restored = 0
        let candidateIds = state.divisions
            .filter { $0.faction == faction && $0.supplyState == .lowSupply && !$0.isDestroyed }
            .sorted { $0.id < $1.id }
            .prefix(limit)
            .map(\.id)

        for divisionId in candidateIds {
            guard let index = state.divisionIndex(id: divisionId) else {
                continue
            }
            state.divisions[index].supplyState = .supplied
            restored += 1
        }
        return restored
    }

    private func controlledRegions(for faction: Faction, in state: GameState) -> [RegionNode] {
        state.map.regions.values.filter {
            $0.controller == faction &&
                $0.isPassable &&
                hasControlledHex(in: $0, faction: faction, map: state.map)
        }
    }

    private func applyGovernanceYield(
        to resources: EconomyResources,
        occupationState: OccupationState?
    ) -> EconomyResources {
        guard let occupationState else {
            return resources
        }
        let percent = occupationState.economicYieldPercent
        return EconomyResources(
            manpower: max(1, resources.manpower * percent / 100),
            industry: max(0, resources.industry * percent / 100),
            supplies: max(1, resources.supplies * percent / 100)
        )
    }

    private func supplyUpkeep(for faction: Faction, in state: GameState) -> EconomyResources {
        let upkeep = state.divisions
            .filter { $0.faction == faction && !$0.isDestroyed }
            .reduce(0) { partial, division in
                partial + 2 + (division.isMobileUnit ? 1 : 0) + (division.isArmor ? 1 : 0) + (division.isArtillery ? 1 : 0)
            }
        return EconomyResources(supplies: upkeep)
    }

    private func applyStrategicSupplyShortfall(for faction: Faction, in state: inout GameState) {
        for index in state.divisions.indices
            where state.divisions[index].faction == faction &&
            state.divisions[index].supplyState == .supplied {
            state.divisions[index].supplyState = .lowSupply
        }

        state.appendEvent(
            "\(faction.displayName) 粮草库存不足，本回合有粮部队降为缺粮。",
            category: .supply
        )
    }

    private func applyAutomaticReinforcement(
        for faction: Faction,
        ledger: inout FactionEconomyLedger,
        in state: inout GameState
    ) -> EconomyResources {
        var spend = EconomyResources()
        let candidateIds = state.divisions
            .filter { division in
                division.faction == faction &&
                    !division.isDestroyed &&
                    !division.isRetreating &&
                    division.supplyState == .supplied &&
                    division.strength < division.maxStrength &&
                    !isAdjacentToEnemy(division, in: state)
            }
            .sorted { lhs, rhs in
                let lhsMissing = lhs.maxStrength - lhs.strength
                let rhsMissing = rhs.maxStrength - rhs.strength
                if lhsMissing != rhsMissing {
                    return lhsMissing > rhsMissing
                }
                return lhs.id < rhs.id
            }
            .map(\.id)

        for divisionId in candidateIds {
            guard let index = state.divisionIndex(id: divisionId) else {
                continue
            }

            let missing = state.divisions[index].maxStrength - state.divisions[index].strength
            let desired = min(maxAutomaticReinforcementPerDivision, missing)
            let perStrengthCost = reinforcementCostPerStrength(for: state.divisions[index])
            var restored = 0

            for _ in 0..<desired where ledger.stockpile.canAfford(perStrengthCost) {
                ledger.stockpile.subtract(perStrengthCost)
                spend.add(perStrengthCost)
                restored += 1
            }

            if restored > 0 {
                state.divisions[index].reinforceStrength(restored)
                state.appendEvent(
                    "\(state.divisions[index].name) 获得自动补员：兵力 +\(restored)。",
                    category: .reinforce
                )
            }
        }

        return spend
    }

    private func reinforcementCostPerStrength(for division: Division) -> EconomyResources {
        let armorWeight = division.components
            .filter { $0.type == .tank || $0.type == .bannerCavalry }
            .reduce(0.0) { $0 + $1.weight }
        let motorizedWeight = division.components
            .filter { $0.type == .motorizedInfantry || $0.type == .cavalry }
            .reduce(0.0) { $0 + $1.weight }
        let firearmWeight = division.components
            .filter { $0.type == .firearm }
            .reduce(0.0) { $0 + $1.weight }
        let artilleryWeight = division.components
            .filter { $0.type == .artillery || $0.type == .siegeEngine }
            .reduce(0.0) { $0 + $1.weight }

        return EconomyResources(
            manpower: max(4, Int((8 + 6 * (1 - armorWeight)).rounded())),
            industry: max(1, Int((1 + armorWeight * 5 + motorizedWeight * 2 + firearmWeight * 2 + artilleryWeight * 3).rounded())),
            supplies: 1
        )
    }

    private func advanceProduction(
        for faction: Faction,
        ledger: inout FactionEconomyLedger,
        in state: inout GameState
    ) {
        var remainingOrders: [ProductionOrder] = []

        for var order in ledger.productionQueue {
            guard order.faction == faction else {
                remainingOrders.append(order)
                continue
            }

            if order.remainingTurns > 0 {
                order.remainingTurns -= 1
            }

            guard order.isReady else {
                remainingOrders.append(order)
                continue
            }

            if order.kind == .supplyStockpile {
                ledger.stockpile.add(EconomyResources(supplies: order.kind.supplyOutput))
                state.appendEvent(
                    "\(faction.displayName) 完成\(order.kind.displayName)：粮草 +\(order.kind.supplyOutput)。",
                    category: .supply
                )
                continue
            }

            if let deployment = deploymentHex(for: faction, preferredRegionId: order.deploymentRegionId, in: state) {
                let division = makeProducedDivision(
                    order: order,
                    faction: faction,
                    coord: deployment.coord,
                    index: state.divisions.count
                )
                state.divisions.append(division)
                order.deploymentRegionId = deployment.regionId
                state.appendEvent(
                    "\(faction.displayName) 在 \(deployment.coord.q),\(deployment.coord.r) 部署\(division.name)。",
                    category: .reinforce
                )
            } else {
                remainingOrders.append(order)
                state.appendEvent(
                    "\(order.kind.displayName)已完成，但当前没有安全后方部署 hex。",
                    category: .reinforce
                )
            }
        }

        ledger.productionQueue = remainingOrders
    }

    private func deploymentHex(
        for faction: Faction,
        preferredRegionId: RegionId?,
        in state: GameState
    ) -> (coord: HexCoord, regionId: RegionId?)? {
        let preferredRegions = (preferredRegionId
            .flatMap { state.map.region(id: $0).map { [$0] } } ?? [])
            .filter {
                $0.controller == faction &&
                    hasControlledHex(in: $0, faction: faction, map: state.map) &&
                    deploymentRegionIsQualified($0, map: state.map)
            }
        let controlledRegions = state.map.regions.values
            .filter {
                $0.controller == faction &&
                    hasControlledHex(in: $0, faction: faction, map: state.map) &&
                    deploymentRegionIsQualified($0, map: state.map)
            }
            .sorted {
                deploymentRegionScore($0, map: state.map) == deploymentRegionScore($1, map: state.map)
                    ? $0.id.rawValue < $1.id.rawValue
                    : deploymentRegionScore($0, map: state.map) > deploymentRegionScore($1, map: state.map)
            }
        let regions = preferredRegions + controlledRegions

        for region in regions {
            let hexes = ([region.representativeHex] + region.displayHexes)
                .filter { state.map.tile(at: $0)?.isPassable == true }
                .filter { state.map.tile(at: $0)?.controller == faction }
                .filter { state.division(at: $0) == nil }
                .filter { !isEnemyAdjacent(to: $0, faction: faction, in: state) }
                .sorted {
                    if $0 == region.representativeHex {
                        return true
                    }
                    if $1 == region.representativeHex {
                        return false
                    }
                    if $0.q == $1.q {
                        return $0.r < $1.r
                    }
                    return $0.q < $1.q
                }

            if let hex = hexes.first {
                return (hex, region.id)
            }
        }

        let supplyHexes = state.map.supplySources(for: faction)
            .map(\.coord)
            .filter { state.map.tile(at: $0)?.isPassable == true }
            .filter { state.division(at: $0) == nil }
            .filter { !isEnemyAdjacent(to: $0, faction: faction, in: state) }
        if let hex = supplyHexes.first {
            return (hex, state.map.region(for: hex))
        }

        return nil
    }

    private func hasControlledHex(in region: RegionNode, faction: Faction, map: MapState) -> Bool {
        regionHexes(for: region).contains { coord in
            map.tile(at: coord)?.controller == faction
        }
    }

    private func regionHexes(for region: RegionNode) -> [HexCoord] {
        Array(Set([region.representativeHex] + region.displayHexes))
    }

    private func deploymentRegionIsQualified(_ region: RegionNode, map: MapState) -> Bool {
        let level = cityLevel(for: region, map: map)
        if region.city?.isCapital == true {
            return true
        }

        switch level {
        case .metropolis,
             .town:
            return true
        case .none,
             .village:
            break
        }

        return region.factories >= 2 ||
            region.infrastructure >= 4 ||
            region.supplyValue >= 3
    }

    private func deploymentRegionScore(_ region: RegionNode, map: MapState) -> Int {
        let level = cityLevel(for: region, map: map)
        return level.industryValue * 3 + region.factories * 2 + region.supplyValue + region.infrastructure
    }

    private func makeProducedDivision(
        order: ProductionOrder,
        faction: Faction,
        coord: HexCoord,
        index: Int
    ) -> Division {
        let id = "prod_\(faction.rawValue)_\(order.kind.rawValue)_\(order.createdTurn)_\(index)"
        let name = "\(faction.displayName)\(order.kind.producedUnitBaseName) \(order.createdTurn)-\(index)"

        guard !faction.isLegacyWWIIFaction else {
            switch order.kind {
            case .infantryDivision:
                return .infantry(id: id, name: name, faction: faction, coord: coord)
            case .panzerDivision:
                return .panzer(id: id, name: name, faction: faction, coord: coord)
            case .motorizedDivision:
                return .motorized(id: id, name: name, faction: faction, coord: coord)
            case .artilleryDivision:
                return .artillery(id: id, name: name, faction: faction, coord: coord)
            case .supplyStockpile:
                return .infantry(id: id, name: name, faction: faction, coord: coord)
            }
        }

        switch order.kind {
        case .infantryDivision:
            return Division(
                id: id,
                name: name,
                faction: faction,
                coord: coord,
                facing: .west,
                hp: 10,
                maxHP: 10,
                components: [
                    DivisionComponent(type: .infantry, weight: 0.55),
                    DivisionComponent(type: .firearm, weight: 0.25),
                    DivisionComponent(type: .cavalry, weight: 0.20)
                ]
            )
        case .panzerDivision:
            return Division(
                id: id,
                name: name,
                faction: faction,
                coord: coord,
                facing: .west,
                hp: 10,
                maxHP: 10,
                components: [
                    DivisionComponent(type: .bannerCavalry, weight: 0.65),
                    DivisionComponent(type: .cavalry, weight: 0.25),
                    DivisionComponent(type: .firearm, weight: 0.10)
                ]
            )
        case .motorizedDivision:
            return Division(
                id: id,
                name: name,
                faction: faction,
                coord: coord,
                facing: .west,
                hp: 10,
                maxHP: 10,
                components: [
                    DivisionComponent(type: .cavalry, weight: 0.55),
                    DivisionComponent(type: .infantry, weight: 0.30),
                    DivisionComponent(type: .militia, weight: 0.15)
                ]
            )
        case .artilleryDivision:
            return Division(
                id: id,
                name: name,
                faction: faction,
                coord: coord,
                facing: .west,
                hp: 8,
                maxHP: 8,
                components: [
                    DivisionComponent(type: .artillery, weight: 0.45),
                    DivisionComponent(type: .siegeEngine, weight: 0.35),
                    DivisionComponent(type: .infantry, weight: 0.20)
                ]
            )
        case .supplyStockpile:
            return .infantry(id: id, name: name, faction: faction, coord: coord)
        }
    }

    private func isAdjacentToEnemy(_ division: Division, in state: GameState) -> Bool {
        isEnemyAdjacent(to: division.coord, faction: division.faction, in: state)
    }

    private func isEnemyAdjacent(to coord: HexCoord, faction: Faction, in state: GameState) -> Bool {
        state.divisions.contains { other in
            other.faction != faction && !other.isDestroyed && other.coord.distance(to: coord) <= 1
        }
    }

    private func productionOrderId(kind: ProductionKind, faction: Faction, turn: Int, index: Int) -> String {
        "order_\(faction.rawValue)_\(kind.rawValue)_\(turn)_\(index)"
    }

    private func resourceSummary(_ resources: EconomyResources) -> String {
        resources.displaySummary
    }
}
