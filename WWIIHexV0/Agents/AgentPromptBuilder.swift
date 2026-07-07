import Foundation

// DEPRECATED as of v0.352 - kept for regression reference, not invoked by default. See WarPipelineMode.
// Builds LLM prompt from AgentContext. v0 keeps it simple; mostly for LocalLLMDecisionProvider.

struct AgentPromptBuilder {
    func makeRequest(
        context: AgentContext,
        model: String,
        temperature: Double = 0.2,
        maxTokens: Int = 1200
    ) -> LLMRequest {
        LLMRequest(
            model: model,
            systemPrompt: systemPrompt(context: context),
            userPrompt: userPrompt(context: context),
            temperature: temperature,
            maxTokens: maxTokens,
            responseFormat: "json_object"
        )
    }

    private func systemPrompt(context: AgentContext) -> String {
        let setting = context.faction.isLegacyWWIIFaction
            ? "a turn-based WWII hex strategy prototype"
            : "明末多势力历史策略战棋，重点是中华世界局势、军政钱粮、火器城防和方面军调度"
        return """
        You are the local LLM decision layer for \(setting).
        Agent: \(context.agentId)
        Faction: \(context.faction.displayName)
        Personality: \(context.personality)

        Return only valid JSON matching the schema. Do not include prose, markdown, comments, or extra keys.
        Keep JSON keys and command enum values exactly as specified, even when reasons are written in Chinese.
        You must not assume invisible information, modify game rules, invent units, or bypass command validation.
        """
    }

    private func userPrompt(context: AgentContext) -> String {
        let isMingScenario = !context.faction.isLegacyWWIIFaction
        let objectives = context.objectives
            .map { objectiveSummary($0, ming: isMingScenario) }
            .joined(separator: "\n")
        let friendly = context.friendlyDivisions
            .map { divisionSummary($0, ming: isMingScenario) }
            .joined(separator: "\n")
        let enemies = context.enemyDivisions
            .map { divisionSummary($0, ming: isMingScenario, includeActed: false) }
            .joined(separator: "\n")
        let regions = context.visibleRegions
            .filter(\.visible)
            .map { regionSummary($0, ming: isMingScenario) }
            .joined(separator: "\n")
        let recentEvents = context.recentEvents.map(\.message).joined(separator: "\n")

        return """
        \(currentTaskText(context: context))

        Available commands:
        - move: requires divisionId and toRegionId
        - attack: requires divisionId and targetDivisionId
        - hold: requires divisionId
        - resupply: requires divisionId

        Battlefield summary:
        Friendly divisions:
        \(friendly)

        Known enemy divisions:
        \(enemies)

        Objectives:
        \(objectives)

        Visible regions:
        \(regions)

        Supply and grain state:
        \(supplySummary(context.supplySummary, ming: isMingScenario))

        Money, pay, and grain:
        \(context.economySummary.displaySummary)

        Court policy, technology, and military debate:
        \(context.courtSummary.displaySummary)

        Campaign mandate and five-line pressure:
        \(context.campaignSummary.displaySummary)

        Recent events:
        \(recentEvents)

        Player directive:
        \(context.playerDirective ?? "无")

        JSON schema:
        {
          "schemaVersion": 2,
          "agentId": "\(context.agentId)",
          "turn": \(context.turn),
          "intent": "short operational intent",
          "orders": [
            {
              "type": "move|attack|hold|resupply",
              "divisionId": "existing division id",
              "toRegionId": "existing visible region id",
              "targetDivisionId": null,
              "stance": null,
              "reason": "short reason"
            }
          ]
        }
        """
    }

    private func currentTaskText(context: AgentContext) -> String {
        if context.faction.isLegacyWWIIFaction {
            return "Current task:\nIssue operational orders for this agent's assigned divisions on turn \(context.turn), phase \(context.phase.rawValue)."
        }

        return """
        当前任务：
        为 \(context.faction.displayName) 在第 \(context.turn) 回合、\(context.phase.displayName)阶段拟定本轮军令。优先解释粮草、城关、州府、火器和天下五线压力；只给已分配军伍下令。
        """
    }

    private func objectiveSummary(_ objective: ObjectiveSummary, ming: Bool) -> String {
        let region = ming
            ? objective.regionId?.mingDisplayTitle ?? "未明州府"
            : objective.regionId?.rawValue ?? "unknown"
        let controller = objective.controller?.displayName ?? "中立"
        if ming {
            return "\(objective.name) 州府:\(region)，控制:\(controller)"
        }
        return "\(objective.name) region:\(region), controller: \(objective.controller?.rawValue ?? "neutral")"
    }

    private func divisionSummary(_ division: DivisionSummary, ming: Bool, includeActed: Bool = true) -> String {
        let region = ming
            ? division.regionId?.mingDisplayTitle ?? "未明州府"
            : division.regionId?.rawValue ?? "unknown"
        if ming {
            let actedText = includeActed ? " 已行:\(division.hasActed)" : ""
            return "\(division.id) \(division.name) 兵力:\(division.strength)/\(division.maxStrength) 州府:\(region) 粮草:\(supplyStateText(division.supplyState))\(actedText)"
        }
        let actedText = includeActed ? " acted:\(division.hasActed)" : ""
        return "\(division.id) \(division.name) str:\(division.strength)/\(division.maxStrength) region:\(region) supply:\(division.supplyState.rawValue)\(actedText)"
    }

    private func supplySummary(_ summary: SupplySummary, ming: Bool) -> String {
        if ming {
            return "本方有粮 \(summary.friendlySupplied)，缺粮 \(summary.friendlyLowSupply)，断粮被围 \(summary.friendlyEncircled)"
        }
        return "friendly supplied \(summary.friendlySupplied), low supply \(summary.friendlyLowSupply), encircled \(summary.friendlyEncircled)"
    }

    private func supplyStateText(_ state: SupplyState) -> String {
        switch state {
        case .supplied:
            return "有粮"
        case .lowSupply:
            return "缺粮"
        case .encircled:
            return "断粮被围"
        }
    }

    private func regionSummary(_ region: RegionSnapshot, ming: Bool) -> String {
        if ming {
            let neighbors = region.neighbors.map(\.mingDisplayTitle).joined(separator: "、")
            return "\(region.id.mingDisplayTitle)（\(region.name)）地形:\(region.terrain.displayName) 控制:\(region.controller.displayName) 邻接:\(neighbors)"
        }
        let neighbors = region.neighbors.map(\.rawValue).joined(separator: ",")
        return "\(region.id.rawValue) \(region.name) terrain:\(region.terrain.rawValue) controller:\(region.controller.rawValue) neighbors:\(neighbors)"
    }
}
