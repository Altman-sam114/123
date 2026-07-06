import Combine
import Foundation

struct SavedGameInfo: Equatable {
    let scenarioId: String
    let turn: Int
    let activeFaction: Faction
    let savedAt: Date
}

private struct SavedGameSnapshot: Codable {
    let schemaVersion: Int
    let savedAt: Date
    let state: GameState

    var info: SavedGameInfo {
        SavedGameInfo(
            scenarioId: state.scenarioId,
            turn: state.turn,
            activeFaction: state.activeFaction,
            savedAt: savedAt
        )
    }
}

private enum SavedGameStore {
    private static let key = "wwiihexv0.ming.savedGame.v1"
    private static let schemaVersion = 1

    static func loadSnapshot() -> SavedGameSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }

        guard let snapshot = try? JSONDecoder().decode(SavedGameSnapshot.self, from: data),
              snapshot.schemaVersion == schemaVersion else {
            return nil
        }
        return snapshot
    }

    @discardableResult
    static func save(_ state: GameState) -> SavedGameInfo? {
        let snapshot = SavedGameSnapshot(
            schemaVersion: schemaVersion,
            savedAt: Date(),
            state: state
        )

        guard let data = try? JSONEncoder().encode(snapshot) else {
            return nil
        }

        UserDefaults.standard.set(data, forKey: key)
        return snapshot.info
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

final class AppContainer: ObservableObject {
    @Published private(set) var gameState: GameState
    @Published private(set) var savedGameInfo: SavedGameInfo?
    @Published private(set) var selectedUnitId: String?
    @Published private(set) var selectedHex: HexCoord?
    @Published private(set) var selectedRegionId: RegionId?
    @Published private(set) var focusedObjectiveId: String?
    @Published private(set) var movementHighlights: Set<HexCoord>
    @Published private(set) var attackHighlights: Set<HexCoord>
    @Published private(set) var interactionLog: [GameLogEntry]
    @Published private(set) var lastCommandMessage: String?
    @Published private(set) var lastAgentDecisionRecord: AgentDecisionRecord?
    @Published private(set) var lastWarDirectiveRecords: [WarDirectiveRecord]
    @Published private(set) var observerModeEnabled: Bool
    @Published private(set) var mapDisplayLayer: MapDisplayLayer
    @Published private(set) var showsSupplyRoutes: Bool

    let commandHandler: GameCommandHandling
    let dataLoader: DataLoader
    let generalRegistry: GeneralRegistry
    @Published private(set) var playerFaction: Faction
    let warPipelineMode: WarPipelineMode
    let turnManager: TurnManager?
    private var isRunningAI = false
    private var aiRunToken = UUID()

    init(
        gameState: GameState,
        commandHandler: GameCommandHandling,
        dataLoader: DataLoader,
        generalRegistry: GeneralRegistry = .empty,
        playerFaction: Faction = .allies,
        turnManager: TurnManager? = nil,
        warPipelineMode: WarPipelineMode = .marshalDirective,
        observerModeEnabled: Bool = false,
        mapDisplayLayer: MapDisplayLayer = .hex,
        showsSupplyRoutes: Bool = true,
        savedGameInfo: SavedGameInfo? = nil
    ) {
        let bootstrappedState = StrategicStateBootstrapper().bootstrapIfNeeded(gameState)
        self.gameState = Self.refreshGeneralAssignments(in: bootstrappedState, registry: generalRegistry)
        self.savedGameInfo = savedGameInfo
        self.commandHandler = commandHandler
        self.dataLoader = dataLoader
        self.generalRegistry = generalRegistry
        self.playerFaction = playerFaction
        self.warPipelineMode = warPipelineMode
        self.turnManager = turnManager
        self.selectedUnitId = nil
        self.selectedHex = nil
        self.selectedRegionId = nil
        self.focusedObjectiveId = nil
        self.movementHighlights = []
        self.attackHighlights = []
        self.interactionLog = []
        self.lastCommandMessage = nil
        self.lastAgentDecisionRecord = nil
        self.lastWarDirectiveRecords = []
        self.observerModeEnabled = observerModeEnabled
        self.mapDisplayLayer = mapDisplayLayer
        self.showsSupplyRoutes = showsSupplyRoutes
    }

    static func bootstrap() -> AppContainer {
        let dataLoader = DataLoader()
        let gameState = dataLoader.loadInitialGameState()
        let savedSnapshot = SavedGameStore.loadSnapshot()
        let commandHandler = RuleEngine()
        let generalRegistry = (try? dataLoader.loadGeneralRegistry()) ?? .empty
        let guderian = GameAgent.guderian(from: dataLoader, state: gameState)
        let bootstrappedState = Self.refreshGeneralAssignments(
            in: StrategicStateBootstrapper().bootstrapIfNeeded(gameState),
            registry: generalRegistry
        )
        let turnManager = TurnManager(
            agent: guderian,
            provider: MockAIClient(),
            providerName: "MockAI",
            commandHandler: commandHandler,
            commanderPool: Self.buildCommanderPool(state: bootstrappedState, registry: generalRegistry),
            marshalAgent: Self.buildMarshalAgent(faction: .germany, state: bootstrappedState)
        )
        return AppContainer(
            gameState: bootstrappedState,
            commandHandler: commandHandler,
            dataLoader: dataLoader,
            generalRegistry: generalRegistry,
            playerFaction: bootstrappedState.humanControlledFactions.first ?? .allies,
            turnManager: turnManager,
            warPipelineMode: .marshalDirective,
            savedGameInfo: savedSnapshot?.info
        )
    }

    func submit(_ command: Command) {
        let stateBeforeCommand = gameState
        let commandText = commandInteractionText(command, in: stateBeforeCommand)
        let result = commandHandler.execute(command, in: gameState)
        var nextState = StrategicStateBootstrapper().bootstrapIfNeeded(result.state)
        if result.succeeded {
            nextState = applyPlayerCommandBookkeeping(
                command,
                to: nextState,
                previousState: stateBeforeCommand
            )
        }
        gameState = refreshGeneralAssignments(in: nextState)
        lastCommandMessage = commandResultMessage(result, commandText: commandText)

        let status = result.succeeded ? "军令已受理" : "军令被驳回"
        appendInteractionEvent("\(status)：\(commandText)。\(lastCommandMessage ?? "")")
        refreshSelectionAfterStateChange()
        if result.succeeded {
            saveCurrentGame()
        }
        runAIIfNeeded()
    }

    func runAIIfNeeded() {
        guard !isRunningAI else {
            return
        }

        gameState = refreshedRuntimeState(gameState)
        guard shouldRunAI(for: gameState.activeFaction, phase: gameState.phase) else {
            return
        }

        isRunningAI = true
        let runToken = UUID()
        aiRunToken = runToken
        let stateSnapshot = gameState
        let pipelineMode = warPipelineMode
        let observerEnabled = observerModeEnabled

        Task {
            let outcome = await self.runAISequence(
                from: stateSnapshot,
                pipelineMode: pipelineMode,
                observerEnabled: observerEnabled
            )
            await MainActor.run {
                guard runToken == self.aiRunToken else {
                    return
                }
                self.gameState = self.refreshedRuntimeState(outcome.state)
                self.lastAgentDecisionRecord = outcome.record
                self.lastWarDirectiveRecords = outcome.directiveRecords
                self.lastCommandMessage = outcome.record.errors.isEmpty
                    ? "军机推演已结算。"
                    : "军机推演已结算，留有 \(outcome.record.errors.count) 条待核事项。"
                self.appendInteractionEvent("军机已结算 \(outcome.record.commandResults.count) 道命令回执。")
                self.isRunningAI = false
                self.refreshSelectionAfterStateChange()
                self.saveCurrentGame()
            }
        }
    }

    func handleBoardTap(_ coord: HexCoord) {
        guard gameState.map.contains(coord) else {
            return
        }

        focusedObjectiveId = nil
        selectedHex = coord
        selectedRegionId = mapDisplayAdapter.regionId(for: coord)
        appendInteractionEvent(selectionMessage(for: coord))

        let displayedDivisions = mapDisplayAdapter.divisions(displayedAt: coord, viewerFaction: playerFaction)
        if let attacker = selectedActionDivision,
           let enemy = displayedDivisions.first(where: { $0.faction != attacker.faction }) {
            submit(.attack(attackerId: attacker.id, targetId: enemy.id))
            return
        }

        if let tappedDivision = displayedDivisions.first {
            handleDivisionTap(tappedDivision)
            return
        }

        if let division = selectedActionDivision {
            submitMove(division: division, tappedHex: coord)
        } else {
            selectedUnitId = nil
            clearHighlights()
        }
    }

    func holdSelected() {
        guard let division = selectedActionDivision else {
            appendInteractionEvent("固守被驳回：未选中可行令的本方军伍。")
            return
        }

        submit(.hold(divisionId: division.id))
    }

    func allowRetreatSelected() {
        guard let division = selectedActionDivision else {
            appendInteractionEvent("退却许可被驳回：未选中可行令的本方军伍。")
            return
        }

        submit(.allowRetreat(divisionId: division.id))
    }

    func resupplySelected() {
        guard let division = selectedActionDivision else {
            appendInteractionEvent("补给整备被驳回：未选中可行令的本方军伍。")
            return
        }

        submit(.resupply(divisionId: division.id))
    }

    func orderSelectedGeneralHoldLine() {
        guard let zone = selectedGeneralCommandZone else {
            appendInteractionEvent("将令被驳回：未选中本方防区。")
            return
        }

        let directive = ZoneDirective(
            zoneId: zone.id,
            defense: DefenseParameters(
                targetReserves: max(1, min(2, zone.unitsDepth.count)),
                stance: .holdLine
            ),
            category: .defense,
            tactic: .holdPosition
        )
        submitPlayerDirective(
            directive,
            sourceRegionId: sourceRegionId(for: zone, targetZoneId: nil),
            targetRegionId: nil
        )
    }

    func orderSelectedGeneralAttackRegion() {
        guard let target = selectedAttackTarget else {
            appendInteractionEvent("将令被驳回：请先点选可攻的敌方州府。")
            return
        }
        guard let zone = selectedGeneralCommandZone else {
            appendInteractionEvent("将令被驳回：未找到可出兵的本方防区。")
            return
        }

        let directive = ZoneDirective(
            zoneId: zone.id,
            attack: AttackParameters(
                targetTheaterId: TheaterId(target.zone.id.rawValue),
                weightedRegions: [target.region.id],
                intensity: .limitedCounter,
                focusRegionId: target.region.id,
                maxCommittedUnits: max(1, min(3, zone.unitsFront.count + zone.unitsDepth.count))
            ),
            category: .offense,
            tactic: .standardAttack,
            commandTarget: .region(target.region.id)
        )
        submitPlayerDirective(
            directive,
            sourceRegionId: sourceRegionId(for: zone, targetZoneId: target.zone.id),
            targetRegionId: target.region.id
        )
    }

    func queueProduction(_ kind: ProductionKind) {
        guard !observerModeEnabled else {
            appendInteractionEvent("筹造被驳回：旁观模式只读。")
            return
        }

        submit(.queueProduction(kind: kind))
    }

    func enactCourtProject(_ kind: CourtProjectKind) {
        guard !observerModeEnabled else {
            appendInteractionEvent("朝廷工程被驳回：旁观模式只读。")
            return
        }

        submit(.enactCourtProject(kind: kind))
    }

    func endTurn() {
        submit(.endTurn)
    }

    func advanceOrRunAI() {
        if shouldRunAI(for: gameState.activeFaction, phase: gameState.phase) {
            runAIIfNeeded()
        } else {
            endTurn()
        }
    }

    func setObserverModeEnabled(_ enabled: Bool) {
        observerModeEnabled = enabled
    }

    func setMapDisplayLayer(_ layer: MapDisplayLayer) {
        mapDisplayLayer = layer
    }

    func setShowsSupplyRoutes(_ enabled: Bool) {
        showsSupplyRoutes = enabled
    }

    func continueSavedGame() {
        guard let snapshot = SavedGameStore.loadSnapshot() else {
            savedGameInfo = nil
            appendInteractionEvent("续战失败：未找到可用存档。")
            return
        }

        isRunningAI = false
        aiRunToken = UUID()
        gameState = refreshGeneralAssignments(
            in: StrategicStateBootstrapper().bootstrapIfNeeded(snapshot.state)
        )
        playerFaction = gameState.humanControlledFactions.first ?? playerFaction
        savedGameInfo = snapshot.info
        selectedUnitId = nil
        selectedHex = nil
        selectedRegionId = nil
        focusedObjectiveId = nil
        movementHighlights = []
        attackHighlights = []
        interactionLog = []
        lastCommandMessage = "已续读第 \(gameState.turn) 回合战局。"
        lastAgentDecisionRecord = nil
        lastWarDirectiveRecords = Array(gameState.warDirectiveRecords.suffix(12))
        appendInteractionEvent("已续读存档：第 \(gameState.turn) 回合，当前 \(gameState.activeFaction.displayName)。")
    }

    func focusObjective(_ objectiveId: String) {
        guard let objective = gameState.map.objective(id: objectiveId) else {
            appendInteractionEvent("要冲定位失败：缺少目标记录。")
            return
        }

        selectedUnitId = nil
        focusedObjectiveId = objective.id
        selectedHex = objective.coord
        selectedRegionId = mapDisplayAdapter.regionId(for: objective.coord)
        clearHighlights()
        appendInteractionEvent("已定位要冲：\(objective.name)。")
    }

    func resetGame() {
        isRunningAI = false
        aiRunToken = UUID()
        SavedGameStore.clear()
        gameState = refreshGeneralAssignments(
            in: StrategicStateBootstrapper().bootstrapIfNeeded(dataLoader.loadInitialGameState())
        )
        playerFaction = gameState.humanControlledFactions.first ?? playerFaction
        savedGameInfo = nil
        selectedUnitId = nil
        selectedHex = nil
        selectedRegionId = nil
        focusedObjectiveId = nil
        movementHighlights = []
        attackHighlights = []
        interactionLog = []
        lastCommandMessage = nil
        lastAgentDecisionRecord = nil
        lastWarDirectiveRecords = []
    }

    var selectedDivision: Division? {
        guard let selectedUnitId else {
            return nil
        }
        return gameState.division(id: selectedUnitId)
    }

    var selectedRegionInspectorState: RegionInspectorState? {
        guard let selectedRegionId else {
            return nil
        }
        return mapDisplayAdapter.inspectorState(for: selectedRegionId, selectedHex: selectedHex, viewerFaction: playerFaction)
    }

    var selectedUnitInspectorStrategicState: UnitInspectorStrategicState? {
        guard let selectedDivision else {
            return nil
        }
        return mapDisplayAdapter.unitInspectorState(for: selectedDivision)
    }

    var selectedGeneralCommandZone: FrontZone? {
        inferredPlayerCommandZone()
    }

    var selectedGeneral: GeneralData? {
        generalRegistry.general(id: selectedGeneralAssignment?.generalId)
    }

    var selectedGeneralAssignment: GeneralAssignment? {
        selectedGeneralCommandZone?.generalAssignment
    }

    var selectedGeneralAssignedDivisions: [Division] {
        guard let assignment = selectedGeneralAssignment else {
            return []
        }
        let assignedIds = Set(assignment.assignedDivisionIds)
        return gameState.divisions
            .filter { assignedIds.contains($0.id) }
            .sorted { $0.id < $1.id }
    }

    var selectedGeneralHQUnderAttack: Bool {
        guard let zone = selectedGeneralCommandZone else {
            return false
        }
        return GeneralDispatcher(registry: generalRegistry).isHQUnderAttack(
            zone: zone,
            map: gameState.map
        )
    }

    var selectedGeneralTargetRegion: RegionNode? {
        selectedRegionId.flatMap { gameState.map.region(id: $0) }
    }

    var selectedGeneralTargetZone: FrontZone? {
        guard let selectedRegionId else {
            return nil
        }
        return gameState.warDeploymentState.zone(for: selectedRegionId)
    }

    var selectedGeneralPlannedOperations: [PlayerPlannedOperation] {
        let zoneId = selectedGeneralCommandZone?.id
        return Array(gameState.playerCommandState.plannedOperations
            .filter { operation in
                operation.turn == gameState.turn &&
                    (zoneId == nil || operation.zoneId == zoneId)
            }
            .suffix(5))
    }

    var canOrderSelectedGeneralHoldLine: Bool {
        canIssuePlayerDirective && selectedGeneralCommandZone != nil
    }

    var canOrderSelectedGeneralAttackRegion: Bool {
        canIssuePlayerDirective && selectedAttackTarget != nil && selectedGeneralCommandZone != nil
    }

    var displayEventLog: [GameLogEntry] {
        Array((gameState.eventLog + interactionLog).suffix(80))
    }

    var selectedUnitCanAct: Bool {
        selectedActionDivision != nil
    }

    private var selectedActionDivision: Division? {
        guard !observerModeEnabled else {
            return nil
        }
        guard let division = selectedDivision,
              division.faction == playerFaction,
              gameState.activeFaction == playerFaction,
              gameState.phase.allowsHumanCommands,
              !division.hasActed else {
            return nil
        }

        return division
    }

    private var canIssuePlayerDirective: Bool {
        !observerModeEnabled &&
            gameState.activeFaction == playerFaction &&
            gameState.phase.allowsHumanCommands
    }

    private var selectedAttackTarget: (region: RegionNode, zone: FrontZone)? {
        guard let selectedRegionId,
              let region = gameState.map.region(id: selectedRegionId),
              let targetZone = gameState.warDeploymentState.zone(for: selectedRegionId),
              targetZone.faction != playerFaction else {
            return nil
        }
        return (region, targetZone)
    }

    private var mapDisplayAdapter: MapDisplayAdapter {
        MapDisplayAdapter(state: gameState, revealAll: observerModeEnabled)
    }

    private func refreshedRuntimeState(_ state: GameState) -> GameState {
        refreshGeneralAssignments(
            in: StrategicStateBootstrapper().refreshRuntimeState(state)
        )
    }

    private func refreshGeneralAssignments(in state: GameState) -> GameState {
        Self.refreshGeneralAssignments(in: state, registry: generalRegistry)
    }

    private static func refreshGeneralAssignments(
        in state: GameState,
        registry: GeneralRegistry
    ) -> GameState {
        guard !registry.allGenerals.isEmpty else {
            return state
        }
        var next = state
        next.warDeploymentState = GeneralDispatcher(registry: registry).assignGenerals(
            to: state.warDeploymentState,
            map: state.map
        )
        return next
    }

    private func applyPlayerCommandBookkeeping(
        _ command: Command,
        to state: GameState,
        previousState: GameState
    ) -> GameState {
        var next = state
        if command == .endTurn || next.activeFaction != previousState.activeFaction || next.turn != previousState.turn {
            next.playerCommandState.clearTurnLocks()
            return next
        }

        guard let divisionId = command.actingDivisionId,
              previousState.activeFaction == playerFaction,
              previousState.phase.allowsHumanCommands,
              previousState.division(id: divisionId)?.faction == playerFaction else {
            return next
        }

        next.playerCommandState.lockDivision(divisionId)
        return registerPlayerIntervention(for: divisionId, in: next)
    }

    private func registerPlayerIntervention(for divisionId: String, in state: GameState) -> GameState {
        guard let zoneId = logicalZoneId(for: divisionId, in: state.warDeploymentState),
              var zone = state.warDeploymentState.frontZones[zoneId],
              let assignment = zone.generalAssignment else {
            return state
        }

        var next = state
        zone.generalAssignment = assignment.registeringPlayerIntervention(cost: 2)
        next.warDeploymentState.frontZones[zoneId] = zone
        return next
    }

    private func inferredPlayerCommandZone() -> FrontZone? {
        if let division = selectedDivision,
           division.faction == playerFaction,
           let zoneId = gameState.warDeploymentState.zoneId(for: division.coord, map: gameState.map),
           let zone = gameState.warDeploymentState.frontZones[zoneId],
           zone.faction == playerFaction {
            return zone
        }

        if let selectedRegionId,
           let zone = gameState.warDeploymentState.zone(for: selectedRegionId),
           zone.faction == playerFaction {
            return zone
        }

        guard let targetZone = selectedGeneralTargetZone,
              targetZone.faction != playerFaction else {
            return nil
        }

        return playerZonesAdjacent(to: targetZone.id).first
    }

    private func playerZonesAdjacent(to targetZoneId: FrontZoneId) -> [FrontZone] {
        gameState.warDeploymentState.frontZones.values
            .filter { zone in
                zone.faction == playerFaction &&
                    zone.frontSegments.contains { $0.neighborEnemyZone == targetZoneId }
            }
            .sorted { $0.id.rawValue < $1.id.rawValue }
    }

    private func sourceRegionId(for zone: FrontZone, targetZoneId: FrontZoneId?) -> RegionId? {
        if let selectedDivision,
           selectedDivision.faction == zone.faction,
           let regionId = selectedDivision.location(in: gameState.map),
           zone.regionIds.contains(regionId) {
            return regionId
        }

        if let selectedRegionId,
           zone.regionIds.contains(selectedRegionId) {
            return selectedRegionId
        }

        if let targetZoneId,
           let segment = zone.frontSegments
            .filter({ $0.neighborEnemyZone == targetZoneId })
            .sorted(by: { $0.regionId.rawValue < $1.regionId.rawValue })
            .first {
            return segment.regionId
        }

        return zone.generalAssignment?.hqRegionId ?? zone.regionIds.first
    }

    private func logicalZoneId(for divisionId: String, in deploymentState: WarDeploymentState) -> FrontZoneId? {
        deploymentState.frontZones.values
            .sorted { $0.id.rawValue < $1.id.rawValue }
            .first {
                $0.unitsFront.contains(divisionId)
                    || $0.unitsDepth.contains(divisionId)
                    || $0.unitsGarrison.contains(divisionId)
            }?
            .id
    }

    private func submitPlayerDirective(
        _ directive: ZoneDirective,
        sourceRegionId: RegionId?,
        targetRegionId: RegionId?
    ) {
        guard canIssuePlayerDirective else {
            appendInteractionEvent("将令被驳回：当前不在玩家行令阶段。")
            return
        }
        guard gameState.warDeploymentState.frontZones[directive.zoneId]?.faction == playerFaction else {
            appendInteractionEvent("将令被驳回：发令防区不属本方。")
            return
        }

        let startState = refreshedRuntimeState(gameState)
        guard let refreshedZone = startState.warDeploymentState.frontZones[directive.zoneId],
              refreshedZone.faction == playerFaction else {
            appendInteractionEvent("将令被驳回：刷新后发令防区已变。")
            return
        }
        let lockedIds = startState.playerCommandState.micromanagedDivisionIds
        let execution = WarCommandExecutor(commandHandler: commandHandler).execute(
            directive,
            in: startState,
            excluding: lockedIds
        )

        var nextState = refreshGeneralAssignments(in: execution.finalState)
        let commandSummaries = execution.commandResults.enumerated().map { index, result in
            CommandResultSummary.directiveCommand(
                directiveIndex: 0,
                commandIndex: index,
                directive: directive,
                command: execution.generatedCommands[index],
                result: result
            )
        }
        var diagnostics: [String] = []
        if execution.generatedCommands.isEmpty {
            diagnostics.append("玩家将令未生成可执行军令。")
        }
        let blockedSummaries = commandSummaries.filter { !$0.executed }
        if !blockedSummaries.isEmpty {
            diagnostics.append("\(blockedSummaries.count) 道军令被规则驳回。")
        }
        if !lockedIds.isEmpty {
            diagnostics.append("\(lockedIds.count) 支已由玩家亲控军伍跳过。")
        }

        let record = WarDirectiveRecord(
            id: "player_directive_turn_\(startState.turn)_\(directive.zoneId.rawValue)_\(directive.type.rawValue)_\(targetRegionId?.rawValue ?? "hold")",
            issuerId: "player",
            turn: startState.turn,
            faction: playerFaction,
            zoneId: directive.zoneId,
            directiveType: directive.type,
            targetRegionIds: targetRegionId.map { [$0] } ?? directive.targetRegionIds,
            commandResults: commandSummaries,
            diagnostics: diagnostics,
            category: directive.category,
            tactic: directive.tactic,
            commanderAgentId: refreshedZone.generalAssignment?.generalId,
            commandTarget: directive.commandTarget
        )

        nextState.warDirectiveRecords.append(record)
        nextState.playerCommandState.recordOperation(
            PlayerPlannedOperation(
                id: "player_operation_turn_\(startState.turn)_\(directive.zoneId.rawValue)_\(directive.type.rawValue)_\(targetRegionId?.rawValue ?? "hold")",
                turn: startState.turn,
                zoneId: directive.zoneId,
                faction: playerFaction,
                directiveType: directive.type,
                sourceRegionId: sourceRegionId,
                targetRegionId: targetRegionId,
                createdByGeneralId: refreshedZone.generalAssignment?.generalId
            )
        )

        gameState = nextState
        lastWarDirectiveRecords = Array((lastWarDirectiveRecords + [record]).suffix(12))
        lastCommandMessage = playerDirectiveMessage(for: execution, diagnostics: diagnostics)
        appendInteractionEvent(
            "将令已提交：\(directiveTypeText(directive.type)) \(MingMapLabelFormat.frontZoneTitle(directive.zoneId))。"
        )
        refreshSelectionAfterStateChange()
        saveCurrentGame()
    }

    private func playerDirectiveMessage(
        for execution: WarCommandExecutionResult,
        diagnostics: [String]
    ) -> String {
        let completedCount = execution.commandResults.filter(\.succeeded).count
        let totalCount = execution.generatedCommands.count
        if totalCount == 0 {
            return diagnostics.first ?? "将令未生成可执行军令。"
        }
        if completedCount == totalCount {
            return "将令已成：\(completedCount) 道军令。"
        }
        return "将令部分成行：\(completedCount) / \(totalCount) 道。"
    }

    private func shouldRunAI(for faction: Faction, phase: GamePhase) -> Bool {
        guard phase != .resolution else {
            return false
        }
        if gameState.isAIControlled(faction) {
            return true
        }
        return observerModeEnabled && gameState.isHumanControlled(faction)
    }

    private func runAISequence(
        from state: GameState,
        pipelineMode: WarPipelineMode,
        observerEnabled: Bool
    ) async -> AgentTurnOutcome {
        var currentState = refreshedRuntimeState(state)
        var lastOutcome: AgentTurnOutcome?
        let maxSteps = observerEnabled ? 2 : 1

        for _ in 0..<maxSteps {
            currentState = refreshedRuntimeState(currentState)
            guard shouldRunAIInSnapshot(state: currentState, observerEnabled: observerEnabled) else {
                break
            }

            let manager = turnManager(for: currentState.activeFaction, state: currentState)
            let outcome = await manager.runAITurn(
                state: currentState,
                faction: currentState.activeFaction,
                pipelineMode: pipelineMode
            )
            currentState = refreshedRuntimeState(outcome.state)
            lastOutcome = AgentTurnOutcome(
                state: currentState,
                record: outcome.record,
                directiveRecords: (lastOutcome?.directiveRecords ?? []) + outcome.directiveRecords
            )
        }

        return lastOutcome ?? AgentTurnOutcome(
            state: currentState,
            record: AgentDecisionRecord(
                id: "agent_noop_turn_\(currentState.turn)",
                turn: currentState.turn,
                agentId: "system",
                provider: "System",
                contextSummary: "No AI faction was active.",
                rawJSON: nil,
                parsedIntent: nil,
                commandResults: [],
                errors: []
            )
        )
    }

    private func shouldRunAIInSnapshot(state: GameState, observerEnabled: Bool) -> Bool {
        guard state.phase != .resolution else {
            return false
        }
        if state.isAIControlled(state.activeFaction) {
            return true
        }
        return observerEnabled && state.isHumanControlled(state.activeFaction)
    }

    private func turnManager(for faction: Faction, state: GameState) -> TurnManager {
        if faction == .germany, let turnManager, generalRegistry.allGenerals.isEmpty {
            return turnManager
        }

        let agent: GameAgent
        switch faction {
        case .germany:
            agent = GameAgent.guderian(from: dataLoader, state: state)
        case .allies:
            let assignedIds = state.divisions
                .filter { $0.faction == .allies && !$0.isDestroyed }
                .map(\.id)
            agent = GameAgent.sample(
                id: "allied_mock_commander",
                name: "盟军军机参谋",
                faction: .allies,
                role: .armyCommander,
                assignedDivisionIds: assignedIds
            )
        case .ming, .qing, .dashun, .daxi, .localNeutral:
            let assignedIds = state.divisions
                .filter { $0.faction == faction && !$0.isDestroyed }
                .map(\.id)
            agent = GameAgent.sample(
                id: "\(faction.rawValue)_mock_commander",
                name: "\(faction.displayName)军机参谋",
                faction: faction,
                role: .armyCommander,
                assignedDivisionIds: assignedIds
            )
        }

        return TurnManager(
            agent: agent,
            provider: MockAIClient(),
            providerName: "MockAI",
            commandHandler: commandHandler,
            commanderPool: Self.buildCommanderPool(state: state, registry: generalRegistry),
            marshalAgent: Self.buildMarshalAgent(faction: faction, state: state)
        )
    }

    private static func buildCommanderPool(
        state: GameState,
        registry: GeneralRegistry = .empty
    ) -> TheaterCommanderPool {
        if !registry.allGenerals.isEmpty {
            return GeneralDispatcher(registry: registry).commanderPool(for: state)
        }

        return TheaterCommanderPool.automatic(for: state)
    }

    private static func buildMarshalAgent(faction: Faction, state: GameState) -> MarshalAgent {
        MarshalAgent(config: MarshalAgentConfig.automatic(for: faction, state: state))
    }

    private func handleDivisionTap(_ division: Division) {
        if observerModeEnabled {
            selectDivision(division)
            appendInteractionEvent("查看军情：\(division.name)。")
            return
        }

        if division.faction == playerFaction {
            selectDivision(division)
            appendInteractionEvent("已选本方军伍：\(division.name)。")
            return
        }

        if let attacker = selectedActionDivision {
            submit(.attack(attackerId: attacker.id, targetId: division.id))
        } else {
            selectDivision(division)
            appendInteractionEvent("已选敌情：\(division.name)。")
        }
    }

    private func selectDivision(_ division: Division) {
        selectedUnitId = division.id
        focusedObjectiveId = nil
        selectedHex = mapDisplayAdapter.unitDisplayHex(for: division) ?? division.coord
        selectedRegionId = division.location(in: gameState.map)
        refreshHighlights()
    }

    private func refreshSelectionAfterStateChange() {
        if let selectedUnitId,
           gameState.division(id: selectedUnitId) == nil {
            self.selectedUnitId = nil
        }

        if let selectedDivision {
            selectedHex = mapDisplayAdapter.unitDisplayHex(for: selectedDivision) ?? selectedDivision.coord
            selectedRegionId = selectedDivision.location(in: gameState.map)
        }

        refreshHighlights()
    }

    private func refreshHighlights() {
        guard let division = selectedActionDivision else {
            clearHighlights()
            return
        }

        movementHighlights = MovementRules().movementRange(for: division, in: gameState)
        attackHighlights = Set(
            gameState.divisions
                .filter { $0.faction != division.faction && division.coord.distance(to: $0.coord) <= division.range }
                .map(\.coord)
        )
    }

    private func clearHighlights() {
        movementHighlights = []
        attackHighlights = []
    }

    private func submitMove(division: Division, tappedHex: HexCoord) {
        submit(.move(divisionId: division.id, destination: tappedHex))
    }

    private func commandInteractionText(_ command: Command, in state: GameState) -> String {
        switch command {
        case .move(let divisionId, let destination):
            return "调动 \(divisionName(id: divisionId, in: state)) 至 \(MingMapLabelFormat.coordinate(destination))"
        case .attack(let attackerId, let targetId):
            return "命 \(divisionName(id: attackerId, in: state)) 攻击 \(divisionName(id: targetId, in: state))"
        case .hold(let divisionId):
            return "令 \(divisionName(id: divisionId, in: state)) 就地固守"
        case .allowRetreat(let divisionId):
            return "准 \(divisionName(id: divisionId, in: state)) 必要时退却"
        case .resupply(let divisionId):
            return "令 \(divisionName(id: divisionId, in: state)) 补给整备"
        case .queueProduction(let kind):
            return "筹造 \(kind.displayName)"
        case .enactCourtProject(let kind):
            return "推行朝廷项目：\(kind.displayName)"
        case .endTurn:
            return "结束本阶段"
        }
    }

    private func commandResultMessage(_ result: CommandResult, commandText: String) -> String {
        if result.succeeded {
            return "已执行：\(commandText)。"
        }

        let reasons = result.validation.errors.map(commandValidationText).joined(separator: "、")
        return reasons.isEmpty ? "规则未准。" : "规则未准：\(reasons)。"
    }

    private func commandValidationText(_ error: CommandValidationError) -> String {
        error.mingDisplayText
    }

    private func directiveTypeText(_ type: DirectiveType) -> String {
        switch type {
        case .attack:
            return "进取"
        case .defend:
            return "固守"
        }
    }

    private func divisionName(id: String, in state: GameState) -> String {
        state.division(id: id)?.name ?? "未知军伍 \(id)"
    }

    private func selectionMessage(for coord: HexCoord) -> String {
        guard let selectedRegionId,
              let region = gameState.map.region(id: selectedRegionId) else {
            return "已选 \(MingMapLabelFormat.coordinate(coord))。"
        }
        return "已选州府：\(region.name)（\(MingMapLabelFormat.regionTitle(selectedRegionId))）。"
    }

    private func appendInteractionEvent(_ message: String) {
        interactionLog.append(
            GameLogEntry(
                turn: gameState.turn,
                faction: gameState.activeFaction,
                phase: gameState.phase,
                message: message,
                createdAt: Date()
            )
        )

        if interactionLog.count > 80 {
            interactionLog.removeFirst(interactionLog.count - 80)
        }
    }

    private func saveCurrentGame() {
        savedGameInfo = SavedGameStore.save(gameState)
    }

}
