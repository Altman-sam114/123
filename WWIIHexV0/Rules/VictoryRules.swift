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
        let summary = BattleObjectiveSummary.from(state: state)
        if let winningTrack = summary.tracks.first(where: { $0.timing == .immediate && $0.isSatisfied }) {
            state.victoryState.winner = winningTrack.faction
            state.victoryState.reason = winningTrack.reason
            return
        }

        guard state.turn >= state.maxTurns else {
            return
        }

        if summary.track(id: .mingMandateLine)?.isSatisfied == true {
            state.victoryState.winner = .ming
            state.victoryState.reason = .mingHoldsMandateAtFinalTurn
            return
        }

        if let winner = summary.leadingFaction {
            state.victoryState.winner = winner
            state.victoryState.reason = winner == .ming
                ? .mingHoldsMostKeyObjectivesAtFinalTurn
                : .mingMandateCollapsedAtFinalTurn
        }
    }
}
