import Foundation

struct VictoryRules {
    func updateVictoryState(in state: inout GameState) {
        guard state.victoryState.winner == nil else {
            return
        }

        if state.scenarioId.hasPrefix("chongzhen_1642") {
            updateMingVictoryState(in: &state)
            return
        }

        updateLegacyArdennesVictoryState(in: &state)
    }

    private func updateLegacyArdennesVictoryState(in state: inout GameState) {
        let bastogneController = state.map.controllerOfObjective(named: "Bastogne")
        let stVithController = state.map.controllerOfObjective(named: "St. Vith")

        if bastogneController == .germany {
            if let heldSince = state.victoryState.germanBastogneHeldSinceTurn,
               state.turn > heldSince {
                state.victoryState.winner = .germany
                state.victoryState.reason = .bastogneHeldByGermany
                return
            } else if state.victoryState.germanBastogneHeldSinceTurn == nil {
                state.victoryState.germanBastogneHeldSinceTurn = state.turn
            }
        } else {
            state.victoryState.germanBastogneHeldSinceTurn = nil
        }

        if bastogneController == .germany && stVithController == .germany {
            state.victoryState.winner = .germany
            state.victoryState.reason = .bastogneAndStVithControlledByGermany
            return
        }

        if state.victoryState.eliminatedAlliedDivisions >= 3 {
            state.victoryState.winner = .germany
            state.victoryState.reason = .alliedUnitsDestroyed
            return
        }

        if state.victoryState.eliminatedGermanDivisions >= 3 {
            state.victoryState.winner = .allies
            state.victoryState.reason = .germanUnitsDestroyed
            return
        }

        let germanArmor = state.divisions.filter { $0.faction == .germany && $0.isArmor }
        if !germanArmor.isEmpty && germanArmor.allSatisfy({ $0.supplyState != .supplied }) {
            if let since = state.victoryState.germanArmorUnsuppliedSinceTurn,
               state.turn > since {
                state.victoryState.winner = .allies
                state.victoryState.reason = .germanArmorUnsupplied
                return
            } else if state.victoryState.germanArmorUnsuppliedSinceTurn == nil {
                state.victoryState.germanArmorUnsuppliedSinceTurn = state.turn
            }
        } else {
            state.victoryState.germanArmorUnsuppliedSinceTurn = nil
        }

        if state.turn >= state.maxTurns && bastogneController == .allies {
            state.victoryState.winner = .allies
            state.victoryState.reason = .bastogneHeldByAlliesAtFinalTurn
        }
    }

    private func updateMingVictoryState(in state: inout GameState) {
        if controls(["obj_shanhaiguan", "obj_beijing"], by: .qing, in: state) {
            state.victoryState.winner = .qing
            state.victoryState.reason = .qingBreaksPassAndCapital
            return
        }

        if controls(["obj_kaifeng", "obj_luoyang", "obj_xian"], by: .dashun, in: state) {
            state.victoryState.winner = .dashun
            state.victoryState.reason = .dashunControlsCentralPlain
            return
        }

        if controls(["obj_jingzhou", "obj_wuchang"], by: .daxi, in: state) {
            state.victoryState.winner = .daxi
            state.victoryState.reason = .daxiControlsHuguangBase
            return
        }

        guard state.turn >= state.maxTurns else {
            return
        }

        if controls(["obj_beijing", "obj_shanhaiguan", "obj_wuchang"], by: .ming, in: state) {
            state.victoryState.winner = .ming
            state.victoryState.reason = .mingHoldsMandateAtFinalTurn
            return
        }

        if let winner = leadingObjectiveScoreWinner(in: state) {
            state.victoryState.winner = winner
            state.victoryState.reason = winner == .ming
                ? .mingHoldsMostKeyObjectivesAtFinalTurn
                : .mingMandateCollapsedAtFinalTurn
        }
    }

    private func controls(_ objectiveIds: [String], by faction: Faction, in state: GameState) -> Bool {
        objectiveIds.allSatisfy { state.map.controllerOfObjective(id: $0) == faction }
    }

    private func leadingObjectiveScoreWinner(in state: GameState) -> Faction? {
        let eligibleFactions: [Faction] = [.ming, .qing, .dashun, .daxi]
        var scores = Dictionary(uniqueKeysWithValues: eligibleFactions.map { ($0, 0) })

        for objective in state.map.objectives {
            guard let controller = state.map.tile(at: objective.coord)?.controller,
                  eligibleFactions.contains(controller) else {
                continue
            }
            scores[controller, default: 0] += max(1, objective.points)
        }

        guard scores.values.max() ?? 0 > 0 else {
            return nil
        }

        return eligibleFactions.max { lhs, rhs in
            let lhsScore = scores[lhs, default: 0]
            let rhsScore = scores[rhs, default: 0]
            if lhsScore == rhsScore {
                return priority(of: lhs, in: eligibleFactions) > priority(of: rhs, in: eligibleFactions)
            }
            return lhsScore < rhsScore
        }
    }

    private func priority(of faction: Faction, in factions: [Faction]) -> Int {
        factions.firstIndex(of: faction) ?? factions.endIndex
    }
}
