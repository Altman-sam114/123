import Foundation

struct SupplyRules {
    let maxSupplyPathCost = 7
    let suppliedResupplyHPRecovery = 2
    let encircledHPLoss = 1
    let failedRetreatHPLoss = 1
    private let movementRules = MovementRules()

    func updateSupplyStates(in state: inout GameState) {
        let snapshot = state
        for index in state.divisions.indices {
            let division = state.divisions[index]
            state.divisions[index].supplyState = supplyState(for: division, in: snapshot)
        }
    }

    func applyResupplyRest(to divisionId: String, in state: inout GameState) {
        guard let index = state.divisionIndex(id: divisionId) else {
            return
        }

        state.divisions[index].supplyState = supplyState(for: state.divisions[index], in: state)
        let before = state.divisions[index]

        switch before.supplyState {
        case .supplied:
            recoverDivision(
                at: index,
                hp: suppliedResupplyHPRecovery,
                in: &state
            )
        case .lowSupply:
            break
        case .encircled:
            break
        }

        let after = state.divisions[index]
        let hpRecovered = after.hp - before.hp

        if hpRecovered > 0 {
            state.appendEvent(
                "\(after.name)就地补给，粮草状态\(after.supplyState.reportDisplayName)，兵力 +\(hpRecovered)。",
                category: .reinforce
            )
        } else {
            state.appendEvent(
                "\(after.name)当前\(after.supplyState.reportDisplayName)，暂不能恢复兵力。",
                category: after.supplyState == .supplied ? .reinforce : .supply
            )
        }
    }

    func resolveRetreat(for divisionId: String, in state: inout GameState) {
        guard let index = state.divisionIndex(id: divisionId) else {
            return
        }

        let division = state.divisions[index]
        if let destination = retreatDestination(for: division, in: state) {
            let origin = division.coord
            state.divisions[index].coord = destination
            if let direction = origin.direction(to: destination) {
                state.divisions[index].facing = direction
            }
            state.divisions[index].beginRetreat(to: destination)
            state.appendEvent(
                "\(division.name)自舆图格 \(origin.q),\(origin.r) 退守至 \(destination.q),\(destination.r)。",
                category: .retreat
            )
        } else {
            state.divisions[index].hp = max(1, state.divisions[index].hp - failedRetreatHPLoss)
            state.appendEvent(
                "\(division.name)退守失败，兵力 -\(failedRetreatHPLoss)。",
                category: .retreat
            )
        }
    }

    func advanceRetreats(in state: inout GameState) {
        let retreatingIds = state.divisions
            .filter(\.isRetreating)
            .map(\.id)

        for divisionId in retreatingIds {
            _ = advanceRetreatStatusIfNeeded(for: divisionId, in: &state)
        }
    }

    func applyEncirclementAttrition(in state: inout GameState) {
        for index in state.divisions.indices where state.divisions[index].supplyState == .encircled {
            let beforeHP = state.divisions[index].hp

            state.divisions[index].hp = max(1, beforeHP - encircledHPLoss)

            let hpLost = beforeHP - state.divisions[index].hp
            if hpLost > 0 {
                state.appendEvent(
                    "\(state.divisions[index].name)遭合围消耗，兵力 -\(hpLost)。",
                    category: .encircle
                )
            }
        }
    }

    func hasSupplyLine(for division: Division, in state: GameState) -> Bool {
        supplyPath(for: division, in: state) != nil
    }

    func supplyState(for division: Division, in state: GameState) -> SupplyState {
        if hasSupplyLine(for: division, in: state) {
            return .supplied
        }

        if isEncircled(division, in: state) {
            return .encircled
        }

        return .lowSupply
    }

    func isEncircled(_ division: Division, in state: GameState) -> Bool {
        guard !hasSupplyLine(for: division, in: state) else {
            return false
        }

        let safeExits = division.coord.neighbors.filter {
            isSafeRetreatTile($0, for: division.faction, in: state)
        }
        return safeExits.count < 2
    }

    func isSafeRetreatTile(_ coord: HexCoord, for faction: Faction, in state: GameState) -> Bool {
        guard let tile = state.map.tile(at: coord),
              state.map.contains(coord),
              tile.isPassable,
              state.division(at: coord) == nil else {
            return false
        }

        if tile.isCapturable && !state.diplomacyState.canEnterTerritory(faction: faction, controller: tile.controller) {
            return false
        }

        if movementRules.isEnemyZoneOfControl(coord, for: faction, in: state) {
            return false
        }

        return state.map.supplySources(for: faction).contains { source in
            supplyPathCost(from: coord, to: source.coord, for: faction, in: state) <= maxSupplyPathCost
        }
    }

    func retreatDestination(for division: Division, in state: GameState) -> HexCoord? {
        let candidates = division.coord.neighbors.filter {
            isSafeRetreatTile($0, for: division.faction, in: state)
        }

        return candidates.min {
            retreatSortKey(for: $0, faction: division.faction, in: state) <
                retreatSortKey(for: $1, faction: division.faction, in: state)
        }
    }

    func supplyPathCost(from start: HexCoord, to goal: HexCoord, for faction: Faction, in state: GameState) -> Int {
        shortestSupplyPath(from: start, to: goal, for: faction, in: state)?.cost ?? Int.max
    }

    func supplyPath(from start: HexCoord, to goal: HexCoord, for faction: Faction, in state: GameState) -> [HexCoord]? {
        shortestSupplyPath(from: start, to: goal, for: faction, in: state)?.coords
    }

    func supplyPath(for division: Division, in state: GameState) -> [HexCoord]? {
        state.map.supplySources(for: division.faction)
            .compactMap { source -> SupplyPathCandidate? in
                guard let result = shortestSupplyPath(
                    from: division.coord,
                    to: source.coord,
                    for: division.faction,
                    in: state
                ) else {
                    return nil
                }
                return SupplyPathCandidate(
                    coords: result.coords,
                    cost: result.cost,
                    distance: division.coord.distance(to: source.coord),
                    sourceCoord: source.coord
                )
            }
            .min()
            .map(\.coords)
    }

    private func shortestSupplyPath(from start: HexCoord, to goal: HexCoord, for faction: Faction, in state: GameState) -> SupplyPathSearchResult? {
        guard state.map.contains(start), state.map.contains(goal) else {
            return nil
        }

        var bestCost: [HexCoord: Int] = [start: 0]
        var previous: [HexCoord: HexCoord] = [:]
        var frontier: [(coord: HexCoord, cost: Int)] = [(start, 0)]

        while !frontier.isEmpty {
            frontier.sort { $0.cost < $1.cost }
            let current = frontier.removeFirst()

            guard current.cost == bestCost[current.coord] else {
                continue
            }

            if current.coord == goal {
                return SupplyPathSearchResult(
                    coords: reconstructSupplyPath(to: goal, previous: previous),
                    cost: current.cost
                )
            }

            guard let fromTile = state.map.tile(at: current.coord) else {
                continue
            }

            for direction in HexDirection.ordered {
                let next = current.coord.neighbor(in: direction)
                guard let toTile = state.map.tile(at: next),
                      state.map.contains(next),
                      toTile.isPassable,
                      canSupplyPass(through: next, tile: toTile, for: faction, in: state) else {
                    continue
                }

                var nextCost = current.cost + supplyCost(entering: toTile)
                if movementRules.hasRiverCrossing(from: fromTile, to: toTile, direction: direction) {
                    nextCost += 2
                }

                guard nextCost <= maxSupplyPathCost,
                      nextCost < bestCost[next, default: Int.max] else {
                    continue
                }

                bestCost[next] = nextCost
                previous[next] = current.coord
                frontier.append((next, nextCost))
            }
        }

        return nil
    }

    private func canSupplyPass(through coord: HexCoord, tile: HexTile, for faction: Faction, in state: GameState) -> Bool {
        if let division = state.division(at: coord), division.faction != faction {
            return false
        }

        if tile.isCapturable && !state.diplomacyState.canEnterTerritory(faction: faction, controller: tile.controller) {
            return false
        }

        if movementRules.isEnemyZoneOfControl(coord, for: faction, in: state) {
            if state.division(at: coord)?.faction == faction {
                return true
            }
            return false
        }

        return true
    }

    private func retreatSortKey(for coord: HexCoord, faction: Faction, in state: GameState) -> RetreatSortKey {
        let supplySources = state.map.supplySources(for: faction)
        let pathCost = supplySources
            .map { supplyPathCost(from: coord, to: $0.coord, for: faction, in: state) }
            .min() ?? Int.max
        let sourceDistance = supplySources
            .map { coord.distance(to: $0.coord) }
            .min() ?? Int.max
        let tileCost = state.map.tile(at: coord).map(supplyCost(entering:)) ?? Int.max

        return RetreatSortKey(
            pathCost: pathCost,
            sourceDistance: sourceDistance,
            tileCost: tileCost,
            q: coord.q,
            r: coord.r
        )
    }

    private func recoverDivision(at index: Int, hp: Int, in state: inout GameState) {
        state.divisions[index].reinforceStrength(hp)
    }

    private func advanceRetreatStatusIfNeeded(for divisionId: String, in state: inout GameState) -> Bool {
        guard let index = state.divisionIndex(id: divisionId),
              state.divisions[index].isRetreating else {
            return false
        }

        let wasRetreating = state.divisions[index].isRetreating
        state.divisions[index].advanceRetreatTurn()
        if wasRetreating && !state.divisions[index].isRetreating {
            state.appendEvent(
                "\(state.divisions[index].name)退守整顿完毕。",
                category: .retreat
            )
        }

        return true
    }

    private func supplyCost(entering tile: HexTile) -> Int {
        if tile.hasRoad {
            return 1
        }

        switch tile.baseTerrain {
        case .mountain:
            return 3
        default:
            return 2
        }
    }

    private func reconstructSupplyPath(to goal: HexCoord, previous: [HexCoord: HexCoord]) -> [HexCoord] {
        var path: [HexCoord] = [goal]
        var cursor = goal

        while let next = previous[cursor] {
            path.append(next)
            cursor = next
        }

        return path.reversed()
    }
}

private extension SupplyState {
    var reportDisplayName: String {
        switch self {
        case .supplied:
            return "有粮"
        case .lowSupply:
            return "缺粮"
        case .encircled:
            return "被围"
        }
    }
}

private struct SupplyPathSearchResult {
    let coords: [HexCoord]
    let cost: Int
}

private struct SupplyPathCandidate: Comparable {
    let coords: [HexCoord]
    let cost: Int
    let distance: Int
    let sourceCoord: HexCoord

    static func < (lhs: SupplyPathCandidate, rhs: SupplyPathCandidate) -> Bool {
        if lhs.cost != rhs.cost {
            return lhs.cost < rhs.cost
        }

        if lhs.distance != rhs.distance {
            return lhs.distance < rhs.distance
        }

        if lhs.sourceCoord.q != rhs.sourceCoord.q {
            return lhs.sourceCoord.q < rhs.sourceCoord.q
        }

        return lhs.sourceCoord.r < rhs.sourceCoord.r
    }
}

private struct RetreatSortKey: Comparable {
    let pathCost: Int
    let sourceDistance: Int
    let tileCost: Int
    let q: Int
    let r: Int

    static func < (lhs: RetreatSortKey, rhs: RetreatSortKey) -> Bool {
        if lhs.pathCost != rhs.pathCost {
            return lhs.pathCost < rhs.pathCost
        }

        if lhs.sourceDistance != rhs.sourceDistance {
            return lhs.sourceDistance < rhs.sourceDistance
        }

        if lhs.tileCost != rhs.tileCost {
            return lhs.tileCost < rhs.tileCost
        }

        if lhs.q != rhs.q {
            return lhs.q < rhs.q
        }

        return lhs.r < rhs.r
    }
}
