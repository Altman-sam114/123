import Foundation

// DEPRECATED as of v0.352 - kept for regression reference, not invoked by default. See WarPipelineMode.
// Legacy mock decision provider. Heuristic: skip acted; low/encircled supply -> resupply;
// in-range vulnerable enemy -> attack; else advance toward the current objective; else hold.

struct MockAIClient: DecisionProvider {
    func decide(context: AgentContext) async throws -> AgentDecisionEnvelope {
        if !context.frontZones.isEmpty,
           let envelope = frontDeploymentDecision(context: context) {
            return envelope
        }

        var orders: [AgentOrder] = []
        var reservedDestinations = Set(context.friendlyDivisions.compactMap(\.regionId) + context.enemyDivisions.compactMap(\.regionId))
        let objective = primaryObjective(in: context)
        let isLegacy = context.faction.isLegacyWWIIFaction

        for division in context.friendlyDivisions.sorted(by: orderPriority) {
            guard !division.hasActed else {
                continue
            }

            if division.supplyState == .lowSupply || division.supplyState == .encircled {
                orders.append(
                    AgentOrder(
                        type: .resupply,
                        divisionId: division.id,
                        toRegionId: division.regionId,
                        stance: "recover",
                        reason: isLegacy
                            ? "Unit is \(division.supplyState.rawValue); recover supply before continuing the attack."
                            : "\(division.name) 粮草状态为 \(mingSupplyText(division.supplyState))，先整粮再续攻守。"
                    )
                )
                continue
            }

            if let attackTarget = bestAttackTarget(for: division, context: context) {
                orders.append(
                    AgentOrder(
                        type: .attack,
                        divisionId: division.id,
                        targetDivisionId: attackTarget.id,
                        stance: division.isArtillery ? "fireSupport" : "breakthrough",
                        reason: attackReason(attacker: division, target: attackTarget, context: context)
                    )
                )
                continue
            }

            if let objective,
               let objectiveRegionId = objective.regionId,
               let destination = bestMoveDestination(
                for: division,
                toward: objectiveRegionId,
                context: context,
                reservedDestinations: reservedDestinations
               ) {
                if let regionId = division.regionId {
                    reservedDestinations.remove(regionId)
                }
                reservedDestinations.insert(destination)
                orders.append(
                    AgentOrder(
                        type: .move,
                        divisionId: division.id,
                        toRegionId: destination,
                        stance: division.isArmor ? "roadAdvance" : "advance",
                        reason: isLegacy
                            ? "Advance toward \(objective.name), preferring road movement and open routes."
                            : "向 \(objective.name) 推进，优先走驿道和开阔州府，稳住要冲压力。"
                    )
                )
                continue
            }

            orders.append(
                AgentOrder(
                    type: .hold,
                    divisionId: division.id,
                    toRegionId: division.regionId,
                    stance: "hold",
                    reason: isLegacy
                        ? "No useful visible move or attack is available."
                        : "当前没有合适进军或攻击窗口，暂守本处州府。"
                )
            )
        }

        return AgentDecisionEnvelope(
            schemaVersion: context.visibleRegions.isEmpty ? 1 : 2,
            agentId: context.agentId,
            turn: context.turn,
            intent: mockIntent(context: context, objective: objective),
            orders: orders
        )
    }

    private func primaryObjective(in context: AgentContext) -> ObjectiveSummary? {
        if context.faction.isLegacyWWIIFaction {
            return context.objectives.first { $0.name == "Bastogne" } ?? context.objectives.first
        }

        return context.objectives.first { $0.controller != context.faction } ?? context.objectives.first
    }

    private func mockIntent(context: AgentContext, objective: ObjectiveSummary?) -> String {
        if context.faction.isLegacyWWIIFaction {
            return "Break through toward Bastogne using armor on roads and artillery support."
        }

        let objectiveText = objective.map { "，当前要冲 \($0.name)" } ?? ""
        let taskText = context.campaignSummary.activeTasks.first.map { "；当旬急务 \($0)" } ?? ""
        return "\(context.faction.displayName)军机按粮道、城关和火器态势拟定本轮军令\(objectiveText)\(taskText)。"
    }

    private func frontDeploymentIntent(context: AgentContext) -> String {
        if context.faction.isLegacyWWIIFaction {
            return "Use v0.33 FrontZone deployment: front units hold or attack, depth reserves reinforce, garrisons hold."
        }

        return "\(context.faction.displayName)按前线、纵深和驻防三层调度军伍：前线接敌，纵深增援，驻防守城。"
    }

    private func frontReason(context: AgentContext, legacy: String, ming: String) -> String {
        context.faction.isLegacyWWIIFaction ? legacy : ming
    }

    private func mingSupplyText(_ state: SupplyState) -> String {
        switch state {
        case .supplied:
            return "有粮"
        case .lowSupply:
            return "缺粮"
        case .encircled:
            return "断粮被围"
        }
    }

    private func frontDeploymentDecision(context: AgentContext) -> AgentDecisionEnvelope? {
        let divisionById = Dictionary(uniqueKeysWithValues: context.friendlyDivisions.map { ($0.id, $0) })
        let regionControllers = Dictionary(uniqueKeysWithValues: context.visibleRegions.map { ($0.id, $0.controller) })
        let frontRegionIds = Set(context.frontZones.flatMap { zone in
            zone.frontSegments.map(\.regionId)
        })
        var orders: [AgentOrder] = []
        var usedDivisionIds: Set<String> = []

        for division in context.friendlyDivisions.sorted(by: orderPriority) {
            guard !division.hasActed else { continue }
            if division.supplyState == .lowSupply || division.supplyState == .encircled {
                orders.append(
                    AgentOrder(
                        type: .resupply,
                        divisionId: division.id,
                        toRegionId: division.regionId,
                        stance: "frontRecovery",
                        reason: frontReason(
                            context: context,
                            legacy: "v0.33 deployment: unit supply is \(division.supplyState.rawValue), recover before front action.",
                            ming: "\(division.name) 粮草为 \(mingSupplyText(division.supplyState))，先回粮整备再入前线。"
                        )
                    )
                )
                usedDivisionIds.insert(division.id)
            }
        }

        for zone in context.frontZones.sorted(by: { $0.id.rawValue < $1.id.rawValue }) {
            for segment in zone.frontSegments.sorted(by: { $0.regionId.rawValue < $1.regionId.rawValue }) {
                for unitId in segment.assignedUnitIds.sorted() {
                    guard !usedDivisionIds.contains(unitId),
                          let division = divisionById[unitId],
                          !division.hasActed else {
                        continue
                    }
                    if let target = frontAttackTarget(for: division, segment: segment, context: context) {
                        orders.append(
                            AgentOrder(
                                type: .attack,
                                divisionId: unitId,
                                targetDivisionId: target.id,
                                stance: segment.isEncircled ? "closePocket" : "frontAttack",
                                reason: frontReason(
                                    context: context,
                                    legacy: "v0.33 deployment: FRONT unit acts on segment \(segment.regionId.rawValue).",
                                    ming: "前线军伍在 \(segment.regionId.rawValue) 接敌，按当前防区命令出击。"
                                )
                            )
                        )
                    } else {
                        orders.append(
                            AgentOrder(
                                type: .hold,
                                divisionId: unitId,
                                toRegionId: division.regionId,
                                stance: segment.isEncircled ? "containPocket" : "holdFront",
                                reason: frontReason(
                                    context: context,
                                    legacy: "v0.33 deployment: FRONT unit holds assigned segment \(segment.regionId.rawValue).",
                                    ming: "前线军伍守 \(segment.regionId.rawValue) 接敌面，先稳城关粮道。"
                                )
                            )
                        )
                    }
                    usedDivisionIds.insert(unitId)
                }
            }
        }

        for zone in context.frontZones.sorted(by: { $0.id.rawValue < $1.id.rawValue }) {
            for unitId in zone.depthUnitIds.sorted() {
                guard !usedDivisionIds.contains(unitId),
                      let division = divisionById[unitId],
                      !division.hasActed else {
                    continue
                }
                let targetRegion = reinforcementTarget(for: division, context: context)
                if let targetRegion,
                   division.regionId != targetRegion,
                   regionControllers[targetRegion] == context.faction {
                    orders.append(
                        AgentOrder(
                            type: .move,
                            divisionId: unitId,
                            toRegionId: targetRegion,
                            stance: "depthReinforce",
                            reason: frontReason(
                                context: context,
                                legacy: "v0.33 deployment: DEPTH reserve reinforces nearest FRONT segment.",
                                ming: "纵深预备军前出增援最近接敌州府。"
                            )
                        )
                    )
                } else {
                    orders.append(
                        AgentOrder(
                            type: .hold,
                            divisionId: unitId,
                            toRegionId: division.regionId,
                            stance: "depthReserve",
                            reason: frontReason(
                                context: context,
                                legacy: "v0.33 deployment: DEPTH reserve has no adjacent safe front target.",
                                ming: "纵深预备军暂无可安全增援的接敌州府，留营待命。"
                            )
                        )
                    )
                }
                usedDivisionIds.insert(unitId)
            }
        }

        for unitId in context.frontZones.flatMap(\.garrisonUnitIds).sorted() {
            guard !usedDivisionIds.contains(unitId),
                  let division = divisionById[unitId],
                  !division.hasActed else {
                continue
            }
            orders.append(
                AgentOrder(
                    type: .hold,
                    divisionId: unitId,
                    toRegionId: division.regionId,
                    stance: "garrison",
                    reason: frontReason(
                        context: context,
                        legacy: "v0.33 deployment: GARRISON unit does not leave core or city region.",
                        ming: "驻防军守核心州府和城池，不擅离本防。"
                    )
                )
            )
            usedDivisionIds.insert(unitId)
        }

        for division in context.friendlyDivisions.sorted(by: orderPriority) {
            guard !usedDivisionIds.contains(division.id),
                  !division.hasActed,
                  let regionId = division.regionId else {
                continue
            }
            let stance = frontRegionIds.contains(regionId) ? "frontUnassigned" : "operationalReserve"
            orders.append(
                AgentOrder(
                    type: .hold,
                    divisionId: division.id,
                    toRegionId: regionId,
                    stance: stance,
                    reason: frontReason(
                        context: context,
                        legacy: "v0.33 deployment: unit outside deployment pool holds.",
                        ming: "未编入当前防区池的军伍暂守原地，等待下一道军令。"
                    )
                )
            )
        }

        guard !orders.isEmpty else { return nil }
        return AgentDecisionEnvelope(
            schemaVersion: 2,
            agentId: context.agentId,
            turn: context.turn,
            intent: frontDeploymentIntent(context: context),
            orders: orders
        )
    }

    private func frontAttackTarget(
        for division: DivisionSummary,
        segment: AgentFrontSegmentSnapshot,
        context: AgentContext
    ) -> DivisionSummary? {
        context.enemyDivisions
            .filter { target in
                guard let targetRegion = target.regionId,
                      context.visibleRegions.first(where: { $0.id == segment.regionId })?.neighbors.contains(targetRegion) == true else {
                    return false
                }
                return division.coord.distance(to: target.coord) <= division.range
            }
            .sorted { $0.strength < $1.strength }
            .first
    }

    private func reinforcementTarget(
        for division: DivisionSummary,
        context: AgentContext
    ) -> RegionId? {
        guard let currentRegion = division.regionId else { return nil }
        let visibleById = Dictionary(uniqueKeysWithValues: context.visibleRegions.map { ($0.id, $0) })
        let frontRegions = context.frontZones
            .flatMap { $0.frontSegments.map(\.regionId) }
            .filter { regionId in
                visibleById[currentRegion]?.neighbors.contains(regionId) == true
            }
            .sorted { $0.rawValue < $1.rawValue }
        return frontRegions.first
    }

    private func orderPriority(_ lhs: DivisionSummary, _ rhs: DivisionSummary) -> Bool {
        if lhs.isArtillery != rhs.isArtillery {
            return !lhs.isArtillery
        }
        if lhs.isArmor != rhs.isArmor {
            return lhs.isArmor
        }
        return lhs.id < rhs.id
    }

    private func bestAttackTarget(
        for division: DivisionSummary,
        context: AgentContext
    ) -> DivisionSummary? {
        context.enemyDivisions
            .filter { canAttack(attacker: division, target: $0, context: context) }
            .sorted { lhs, rhs in
                let lhsScore = attackScore(attacker: division, target: lhs, context: context)
                let rhsScore = attackScore(attacker: division, target: rhs, context: context)
                if lhsScore != rhsScore {
                    return lhsScore > rhsScore
                }
                return lhs.strength < rhs.strength
            }
            .first
    }

    private func attackScore(
        attacker: DivisionSummary,
        target: DivisionSummary,
        context: AgentContext
    ) -> Int {
        let targetTile = context.visibleTiles.first { $0.coord == target.coord }
        let objectiveTileBonus = targetTile?.baseTerrain == .city || targetTile?.baseTerrain == .fortress ? 20 : 0
        let lowHPBonus = max(0, 12 - target.strength)
        let distanceBonus = max(0, 4 - attacker.coord.distance(to: target.coord))
        let artilleryBonus = attacker.isArtillery ? objectiveTileBonus : 0
        return lowHPBonus + distanceBonus + artilleryBonus
    }

    private func canAttack(
        attacker: DivisionSummary,
        target: DivisionSummary,
        context: AgentContext
    ) -> Bool {
        if let attackerRegion = attacker.regionId,
           let targetRegion = target.regionId,
           !context.visibleRegions.isEmpty {
            return RegionGraph(
                regions: Dictionary(uniqueKeysWithValues: context.visibleRegions.map {
                    ($0.id, RegionNode(
                        id: $0.id,
                        name: $0.name,
                        owner: $0.controller,
                        controller: $0.controller,
                        terrain: $0.terrain,
                        neighbors: $0.neighbors,
                        displayHexes: [attacker.coord],
                        representativeHex: attacker.coord,
                        city: $0.cityName.map { CityInfo(name: $0) },
                        supplyValue: $0.supplyValue
                    ))
                }),
                edges: []
            ).distance(from: attackerRegion, to: targetRegion).map { $0 <= attacker.range } ?? false
        }

        return attacker.coord.distance(to: target.coord) <= attacker.range
    }

    private func attackReason(
        attacker: DivisionSummary,
        target: DivisionSummary,
        context: AgentContext
    ) -> String {
        let targetTile = context.visibleTiles.first { $0.coord == target.coord }
        if attacker.isArtillery,
           targetTile?.baseTerrain == .city || targetTile?.baseTerrain == .fortress {
            return context.faction.isLegacyWWIIFaction
                ? "Artillery fires on defender in a city or fortress hex."
                : "火器/炮队压制城关守军，支援破城或守线。"
        }
        return context.faction.isLegacyWWIIFaction
            ? "Target is within range and vulnerable enough for a local attack."
            : "敌军在攻击范围内且兵势可乘，适合局部进取。"
    }

    private func bestMoveDestination(
        for division: DivisionSummary,
        toward objectiveRegion: RegionId,
        context: AgentContext,
        reservedDestinations: Set<RegionId>
    ) -> RegionId? {
        guard let currentRegion = division.regionId else {
            return nil
        }
        let snapshotById = Dictionary(uniqueKeysWithValues: context.visibleRegions.map { ($0.id, $0) })
        let graph = RegionGraph(
            regions: Dictionary(uniqueKeysWithValues: context.visibleRegions.map {
                ($0.id, RegionNode(
                    id: $0.id,
                    name: $0.name,
                    owner: $0.controller,
                    controller: $0.controller,
                    terrain: $0.terrain,
                    neighbors: $0.neighbors,
                    displayHexes: [division.coord],
                    representativeHex: division.coord,
                    city: $0.cityName.map { CityInfo(name: $0) },
                    supplyValue: $0.supplyValue
                ))
            }),
            edges: []
        )
        let currentDistance = graph.distance(from: currentRegion, to: objectiveRegion) ?? Int.max

        return graph.neighbors(of: currentRegion)
            .compactMap { regionId -> RegionSnapshot? in
                guard let snapshot = snapshotById[regionId],
                      snapshot.visible,
                      !reservedDestinations.contains(regionId),
                      (graph.distance(from: regionId, to: objectiveRegion) ?? Int.max) <= currentDistance else {
                    return nil
                }
                return snapshot
            }
            .sorted { lhs, rhs in
                let lhsDistance = graph.distance(from: lhs.id, to: objectiveRegion) ?? Int.max
                let rhsDistance = graph.distance(from: rhs.id, to: objectiveRegion) ?? Int.max
                if lhsDistance != rhsDistance {
                    return lhsDistance < rhsDistance
                }
                return terrainMoveCost(lhs.terrain) < terrainMoveCost(rhs.terrain)
            }
            .first?
            .id
    }

    private func terrainMoveCost(_ terrain: BaseTerrain) -> Int {
        terrain.movementCost
    }
}
