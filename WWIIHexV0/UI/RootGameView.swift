import SwiftUI

struct RootGameView: View {
    @ObservedObject var container: AppContainer
    @State private var selectedCompactPanel: CompactInfoPanel = .unit
    @State private var isInfoExpanded = false
    @State private var isGeneralProfilePresented = false

    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height

            ZStack(alignment: .bottomTrailing) {
                boardView
                    .ignoresSafeArea()

                VStack {
                    HUDView(
                        gameState: container.gameState,
                        onEndTurn: container.advanceOrRunAI,
                        onNewGame: container.resetGame
                    )
                    .padding(8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
                    .padding(.top, 8)
                    .padding(.horizontal, 8)

                    mapControls
                        .padding(.horizontal, 8)

                    Spacer()
                }

                if isInfoExpanded {
                    infoOverlay(isLandscape: isLandscape, size: proxy.size)
                        .transition(.opacity)
                }

                Button {
                    isInfoExpanded.toggle()
                } label: {
                    Label("信息", systemImage: isInfoExpanded ? "sidebar.left" : "sidebar.leading")
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                }
                .buttonStyle(.bordered)
                .frame(minHeight: MingDesignTokens.minimumTapSize)
                .accessibilityLabel(isInfoExpanded ? "收起信息面板" : "展开信息面板")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(10)

                UnitTooltipView(division: container.selectedDivision)
                    .allowsHitTesting(false)
            }
        }
        .background(PlatformStyles.systemBackground)
        .sheet(isPresented: $isGeneralProfilePresented) {
            if let general = container.selectedGeneral {
                GeneralProfileView(
                    general: general,
                    assignment: container.selectedGeneralAssignment,
                    zone: container.selectedGeneralCommandZone,
                    assignedDivisions: container.selectedGeneralAssignedDivisions,
                    hqUnderAttack: container.selectedGeneralHQUnderAttack,
                    onClose: { isGeneralProfilePresented = false }
                )
            } else {
                Text("未选中将领。")
                    .font(.headline)
                    .padding()
            }
        }
    }

    private var boardView: some View {
        BoardSceneView(
            renderState: BoardSceneAdapter.renderState(from: container),
            onHexTapped: container.handleBoardTap
        )
        .accessibilityLabel("明末战局六角地图")
    }

    private var mapControls: some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Label("舆图", systemImage: "map")
                    .font(.caption.bold())
                    .foregroundStyle(MingDesignTokens.ink)
                Spacer(minLength: 8)
                Label(container.mapDisplayLayer.legendTitle, systemImage: container.mapDisplayLayer.systemImageName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            MingMapSituationStrip(summary: BattleObjectiveSummary.from(state: container.gameState))

            Picker("图层", selection: Binding(
                get: { container.mapDisplayLayer },
                set: { container.setMapDisplayLayer($0) }
            )) {
                ForEach(MapDisplayLayer.allCases) { layer in
                    Text(layer.displayName).tag(layer)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 8) {
                Toggle(isOn: Binding(
                    get: { container.observerModeEnabled },
                    set: { container.setObserverModeEnabled($0) }
                )) {
                    Label("观战", systemImage: "eye")
                        .lineLimit(1)
                }
                .toggleStyle(.button)
                .frame(maxWidth: .infinity)

                Toggle(isOn: Binding(
                    get: { container.showsSupplyRoutes },
                    set: { container.setShowsSupplyRoutes($0) }
                )) {
                    Label("粮道", systemImage: "shippingbox")
                        .lineLimit(1)
                }
                .toggleStyle(.button)
                .frame(maxWidth: .infinity)
                .disabled(container.mapDisplayLayer != .hex)
            }
            .font(.caption.weight(.semibold))
            .frame(minHeight: MingDesignTokens.minimumTapSize)

            MingMapLegendView(
                layer: container.mapDisplayLayer,
                showsSupplyRoutes: container.mapDisplayLayer == .hex && container.showsSupplyRoutes
            )
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }

    private func infoOverlay(isLandscape: Bool, size: CGSize) -> some View {
        let width = isLandscape ? min(max(size.width * 0.32, 260), 360) : size.width
        let height = isLandscape ? size.height : min(max(size.height * 0.44, 320), 460)

        return VStack(spacing: 0) {
            compactPanelWithTabs
        }
        .frame(width: width, height: height)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius)
                .stroke(.secondary.opacity(0.35), lineWidth: 1)
        }
        .padding(isLandscape ? 10 : 0)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: isLandscape ? .trailing : .bottom
        )
    }

    private var compactPanelWithTabs: some View {
        VStack(spacing: 0) {
            Picker("面板", selection: $selectedCompactPanel) {
                ForEach(CompactInfoPanel.allCases) { panel in
                    Text(panel.rawValue).tag(panel)
                }
            }
            .pickerStyle(.segmented)
            .padding(8)

            compactPanel
        }
    }

    @ViewBuilder
    private var compactPanel: some View {
        ScrollView {
            VStack(spacing: 10) {
                switch selectedCompactPanel {
                case .unit:
                    UnitInspectorView(
                        division: container.selectedDivision,
                        playerFaction: container.playerFaction,
                        strategicState: container.selectedUnitInspectorStrategicState
                    )
                    RegionInspectorView(inspectorState: container.selectedRegionInspectorState)
                    CommandPanelView(
                        selectedDivision: container.selectedDivision,
                        activeFaction: container.gameState.activeFaction,
                        phase: container.gameState.phase,
                        playerFaction: container.playerFaction,
                        observerModeEnabled: container.observerModeEnabled,
                        objectiveSummary: BattleObjectiveSummary.from(state: container.gameState),
                        lastCommandMessage: container.lastCommandMessage,
                        onHold: container.holdSelected,
                        onAllowRetreat: container.allowRetreatSelected,
                        onResupply: container.resupplySelected,
                        onEndTurn: container.advanceOrRunAI
                    )
                    GeneralCommandPanelView(
                        zone: container.selectedGeneralCommandZone,
                        general: container.selectedGeneral,
                        assignment: container.selectedGeneralAssignment,
                        assignedDivisions: container.selectedGeneralAssignedDivisions,
                        targetRegion: container.selectedGeneralTargetRegion,
                        targetZone: container.selectedGeneralTargetZone,
                        hqUnderAttack: container.selectedGeneralHQUnderAttack,
                        plannedOperations: container.selectedGeneralPlannedOperations,
                        canHoldLine: container.canOrderSelectedGeneralHoldLine,
                        canAttackRegion: container.canOrderSelectedGeneralAttackRegion,
                        onShowProfile: { isGeneralProfilePresented = true },
                        onHoldLine: container.orderSelectedGeneralHoldLine,
                        onAttackRegion: container.orderSelectedGeneralAttackRegion
                    )
                case .region:
                    RegionInspectorView(inspectorState: container.selectedRegionInspectorState)
                case .general:
                    GeneralCommandPanelView(
                        zone: container.selectedGeneralCommandZone,
                        general: container.selectedGeneral,
                        assignment: container.selectedGeneralAssignment,
                        assignedDivisions: container.selectedGeneralAssignedDivisions,
                        targetRegion: container.selectedGeneralTargetRegion,
                        targetZone: container.selectedGeneralTargetZone,
                        hqUnderAttack: container.selectedGeneralHQUnderAttack,
                        plannedOperations: container.selectedGeneralPlannedOperations,
                        canHoldLine: container.canOrderSelectedGeneralHoldLine,
                        canAttackRegion: container.canOrderSelectedGeneralAttackRegion,
                        onShowProfile: { isGeneralProfilePresented = true },
                        onHoldLine: container.orderSelectedGeneralHoldLine,
                        onAttackRegion: container.orderSelectedGeneralAttackRegion
                    )
                case .log:
                    EventLogView(entries: container.displayEventLog)
                case .economy:
                    EconomyPanelView(
                        gameState: container.gameState,
                        playerFaction: container.playerFaction,
                        observerModeEnabled: container.observerModeEnabled,
                        onQueueProduction: container.queueProduction
                    )
                case .court:
                    CourtPanelView(
                        gameState: container.gameState,
                        playerFaction: container.playerFaction,
                        observerModeEnabled: container.observerModeEnabled,
                        onEnactProject: container.enactCourtProject
                    )
                case .objective:
                    BattleObjectivePanelView(
                        gameState: container.gameState,
                        onFocusObjective: { objectiveId in
                            container.focusObjective(objectiveId)
                            selectedCompactPanel = .region
                        }
                    )
                case .diplomacy:
                    DiplomacyPanelView(
                        diplomacyState: container.gameState.diplomacyState,
                        activeFaction: container.gameState.activeFaction,
                        courtSummary: CourtStrategySummary.from(
                            faction: container.gameState.activeFaction,
                            state: container.gameState
                        )
                    )
                case .agent:
                    AgentPanelView(
                        record: container.lastAgentDecisionRecord,
                        rulerRecord: container.gameState.diplomacyState.latestRulerRecord,
                        directiveRecords: container.lastWarDirectiveRecords,
                        campaignSummary: CampaignAISummary.from(state: container.gameState)
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 10)
        }
    }
}

private struct MingMapSituationStrip: View {
    let summary: BattleObjectiveSummary

    var body: some View {
        if summary.isMingScenario {
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .center, spacing: 8) {
                    Label("天下急势", systemImage: "globe.asia.australia")
                        .font(.caption.bold())
                        .foregroundStyle(MingDesignTokens.ink)
                        .lineLimit(1)

                    Spacer(minLength: 6)

                    MingMapSituationTaskBadge(title: "急", value: urgentTaskCount, tint: MingDesignTokens.cinnabar)
                    MingMapSituationTaskBadge(title: "主", value: mainTaskCount, tint: MingDesignTokens.jade)
                    MingMapSituationLeaderBadge(faction: summary.leadingFaction)
                }

                MingMapObjectiveScoreStrip(
                    rows: objectiveScoreRows,
                    leadingFaction: summary.leadingFaction
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(lineBriefs) { brief in
                            MingMapSituationLineChip(brief: brief)
                        }
                    }
                    .padding(.vertical, 1)
                }
            }
            .padding(8)
            .background(MingDesignTokens.sectionBackground.opacity(0.84), in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius)
                    .stroke(MingDesignTokens.courtStroke.opacity(0.72), lineWidth: 1)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("天下急势，当前要冲领先方 \(leaderName)，急务 \(urgentTaskCount) 项，主线 \(mainTaskCount) 项")
        }
    }

    private var lineBriefs: [BattleObjectiveSummary.CampaignLineBrief] {
        summary.lineBriefs.sorted { lhs, rhs in
            if lhs.status.sortRank == rhs.status.sortRank {
                return lhs.pressure > rhs.pressure
            }
            return lhs.status.sortRank < rhs.status.sortRank
        }
    }

    private var objectiveScoreRows: [BattleObjectiveSummary.ScoreRow] {
        summary.scoreRows.sorted { lhs, rhs in
            if lhs.points == rhs.points {
                return lhs.objectiveCount > rhs.objectiveCount
            }
            return lhs.points > rhs.points
        }
    }

    private var urgentTaskCount: Int {
        summary.tasks.filter { $0.priority == .urgent }.count
    }

    private var mainTaskCount: Int {
        summary.tasks.filter { $0.priority == .main }.count
    }

    private var leaderName: String {
        summary.leadingFaction?.displayName ?? "未定"
    }
}

private struct MingMapObjectiveScoreStrip: View {
    let rows: [BattleObjectiveSummary.ScoreRow]
    let leadingFaction: Faction?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label("要冲分布", systemImage: "mappin.and.ellipse")
                .font(.caption.bold())
                .foregroundStyle(MingDesignTokens.ink)
                .lineLimit(1)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(rows) { row in
                        MingMapObjectiveScoreChip(
                            row: row,
                            isLeading: row.faction == leadingFaction
                        )
                    }
                }
                .padding(.vertical, 1)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("要冲分布，\(scoreSummary)")
    }

    private var scoreSummary: String {
        rows.map { row in
            "\(row.faction.displayName)\(row.points)分\(row.objectiveCount)处"
        }
        .joined(separator: "，")
    }
}

private struct MingMapObjectiveScoreChip: View {
    let row: BattleObjectiveSummary.ScoreRow
    let isLeading: Bool

    var body: some View {
        HStack(spacing: 5) {
            MingFactionFlagBadge(faction: row.faction)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(row.faction.displayName)
                        .font(.caption.bold())
                        .foregroundStyle(row.faction.mingBannerTint)
                        .lineLimit(1)

                    if isLeading {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundStyle(MingDesignTokens.imperialGold)
                            .accessibilityHidden(true)
                    }
                }

                Text("\(row.points) 分 / \(row.objectiveCount) 处")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .frame(minWidth: 92, alignment: .leading)
        .background(MingDesignTokens.panelBackground.opacity(isLeading ? 0.78 : 0.58), in: RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(row.faction.mingBannerTint.opacity(isLeading ? 0.5 : 0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.faction.displayName)，要冲分 \(row.points)，控制 \(row.objectiveCount) 处")
    }
}

private struct MingMapSituationLeaderBadge: View {
    let faction: Faction?

    var body: some View {
        HStack(spacing: 5) {
            if let faction {
                MingFactionFlagBadge(faction: faction)
                Text(faction.displayName)
                    .foregroundStyle(faction.mingBannerTint)
            } else {
                Text("未定")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(MingDesignTokens.panelBackground.opacity(0.68), in: RoundedRectangle(cornerRadius: 5))
            }
        }
        .font(.caption.bold())
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("要冲领先方 \(faction?.displayName ?? "未定")")
    }
}

private struct MingMapSituationTaskBadge: View {
    let title: String
    let value: Int
    let tint: Color

    var body: some View {
        HStack(spacing: 3) {
            Text(title)
                .font(.caption2.bold())
            Text("\(value)")
                .font(.caption2.monospacedDigit().bold())
        }
        .foregroundStyle(value > 0 ? tint : .secondary)
        .lineLimit(1)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(tint.opacity(value > 0 ? 0.13 : 0.06), in: RoundedRectangle(cornerRadius: 5))
        .accessibilityElement(children: .combine)
    }
}

private struct MingMapSituationLineChip: View {
    let brief: BattleObjectiveSummary.CampaignLineBrief

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: brief.line.systemImage)
                    .foregroundStyle(tint)
                    .frame(width: 14)
                    .accessibilityHidden(true)

                Text(brief.line.displayName)
                    .font(.caption.bold())
                    .foregroundStyle(MingDesignTokens.ink)

                Spacer(minLength: 4)

                Text(brief.status.displayName)
                    .font(.caption2.bold())
                    .foregroundStyle(tint)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.78)

            ProgressView(value: Double(brief.pressure), total: 100)
                .tint(tint)

            HStack(spacing: 5) {
                Text("势 \(brief.pressure)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)

                if brief.urgentTaskCount > 0 {
                    Text("急 \(brief.urgentTaskCount)")
                        .font(.caption2.bold())
                        .foregroundStyle(MingDesignTokens.cinnabar)
                } else if brief.activeTaskCount > 0 {
                    Text("事 \(brief.activeTaskCount)")
                        .font(.caption2.bold())
                        .foregroundStyle(tint)
                }
            }
            .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(width: 116, alignment: .leading)
        .background(MingDesignTokens.panelBackground.opacity(0.66), in: RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(tint.opacity(brief.status == .warning ? 0.44 : 0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(brief.line.displayName)线，\(brief.status.displayName)，压力 \(brief.pressure)")
    }

    private var tint: Color {
        switch brief.line {
        case .world:
            return MingDesignTokens.cinnabar
        case .policy:
            return MingDesignTokens.porcelainBlue
        case .economy:
            return MingDesignTokens.jade
        case .technology:
            return MingDesignTokens.imperialGold
        case .military:
            return MingDesignTokens.ink
        }
    }
}

private extension BattleObjectiveSummary.CampaignStageStatus {
    var sortRank: Int {
        switch self {
        case .warning:
            return 0
        case .focus:
            return 1
        case .watch:
            return 2
        case .achieved:
            return 3
        }
    }
}

private enum CompactInfoPanel: String, CaseIterable, Identifiable {
    case unit = "军队"
    case region = "州府"
    case general = "将领"
    case log = "塘报"
    case economy = "钱粮"
    case court = "朝廷"
    case objective = "目标"
    case diplomacy = "天下"
    case agent = "军机"

    var id: String {
        rawValue
    }
}

private struct MingMapLegendView: View {
    let layer: MapDisplayLayer
    let showsSupplyRoutes: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                if layer == .hex {
                    MapLegendBadge(text: "城", title: "城池", tint: MingDesignTokens.imperialGold)
                    MapLegendBadge(text: "关", title: "关隘", tint: MingDesignTokens.cinnabar)
                    MapLegendBadge(text: "粮", title: "粮台", tint: MingDesignTokens.jade)
                    UnitTypeLegendBadge()
                    UnitStateLegendBadge()
                    FactionBannerLegendBadge()
                    OperationPlanLegendBadge()
                    ObjectiveFocusLegendBadge()

                    if showsSupplyRoutes {
                        SupplyRouteLegendBadge()
                    }
                } else {
                    MapLayerLegendBadge(layer: layer)

                    ForEach(layer.readingNotes) { note in
                        MapLayerReadingBadge(note: note)
                    }
                }
            }
            .padding(.vertical, 1)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct MapLayerLegendBadge: View {
    let layer: MapDisplayLayer

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: layer.systemImageName)
                .foregroundStyle(MingDesignTokens.cinnabar)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(layer.legendTitle)
                    .font(.caption.bold())
                Text(layer.legendDetail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(MingDesignTokens.sectionBackground.opacity(0.82), in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }
}

private struct MapLayerReadingBadge: View {
    let note: MapLayerReadingNote

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: note.systemImageName)
                .foregroundStyle(note.tint)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(note.title)
                    .font(.caption.bold())
                Text(note.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(MingDesignTokens.sectionBackground.opacity(0.82), in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }
}

private struct MapLayerReadingNote: Identifiable {
    let title: String
    let detail: String
    let systemImageName: String
    let tint: Color

    var id: String {
        title
    }
}

private struct MapLegendBadge: View {
    let text: String
    let title: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 22, height: 18)
                .background(tint, in: RoundedRectangle(cornerRadius: 4))

            Text(title)
                .font(.caption)
                .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .background(MingDesignTokens.sectionBackground.opacity(0.82), in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }
}

private struct UnitTypeLegendBadge: View {
    private let unitTypes: [UnitTypeLegendSymbol] = [
        UnitTypeLegendSymbol(text: "步", tint: MingDesignTokens.porcelainBlue),
        UnitTypeLegendSymbol(text: "骑", tint: MingDesignTokens.jade),
        UnitTypeLegendSymbol(text: "火", tint: MingDesignTokens.cinnabar),
        UnitTypeLegendSymbol(text: "城", tint: MingDesignTokens.imperialGold),
        UnitTypeLegendSymbol(text: "旗", tint: .purple)
    ]

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 3) {
                ForEach(unitTypes, id: \.text) { item in
                    Text(item.text)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 19, height: 17)
                        .background(item.tint, in: RoundedRectangle(cornerRadius: 4))
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("兵种军牌")
                    .font(.caption.bold())
                Text("步 / 骑 / 火 / 城 / 旗")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(MingDesignTokens.sectionBackground.opacity(0.82), in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }
}

private struct UnitTypeLegendSymbol {
    let text: String
    let tint: Color
}

private struct UnitStateLegendBadge: View {
    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                SupplyDot(color: .green)
                SupplyDot(color: .orange)
                SupplyDot(color: MingDesignTokens.cinnabar)
                Text("2")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 16, height: 16)
                    .background(.black.opacity(0.88), in: Circle())
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("粮草与堆叠")
                    .font(.caption.bold())
                Text("满 / 低 / 断 / 数")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(MingDesignTokens.sectionBackground.opacity(0.82), in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }
}

private struct SupplyDot: View {
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.75), lineWidth: 1)
            }
            .accessibilityHidden(true)
    }
}

private struct FactionBannerLegendBadge: View {
    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 3) {
                MingFactionFlagBadge(faction: .ming)
                MingFactionFlagBadge(faction: .qing)
                MingFactionFlagBadge(faction: .dashun)
                MingFactionFlagBadge(faction: .daxi)
                MingFactionFlagBadge(faction: .localNeutral)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("势力旗")
                    .font(.caption.bold())
                Text("明 / 清 / 顺 / 西 / 乡")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(MingDesignTokens.sectionBackground.opacity(0.82), in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }
}

private struct SupplyRouteLegendBadge: View {
    var body: some View {
        HStack(spacing: 8) {
            SupplyRouteSwatch()
            VStack(alignment: .leading, spacing: 1) {
                Text("粮道")
                    .font(.caption.bold())
                Text("可达粮台")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(MingDesignTokens.sectionBackground.opacity(0.82), in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }
}

private struct OperationPlanLegendBadge: View {
    var body: some View {
        HStack(spacing: 8) {
            OperationPlanSwatch()
            VStack(alignment: .leading, spacing: 1) {
                Text("军令计划")
                    .font(.caption.bold())
                Text("进取 / 固守")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(MingDesignTokens.sectionBackground.opacity(0.82), in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }
}

private struct ObjectiveFocusLegendBadge: View {
    var body: some View {
        HStack(spacing: 8) {
            Text("标")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 19, height: 17)
                .background(MingDesignTokens.cinnabar, in: RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 1) {
                Text("目标定位")
                    .font(.caption.bold())
                Text("胜负线城关")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(MingDesignTokens.sectionBackground.opacity(0.82), in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }
}

private extension MapDisplayLayer {
    var readingNotes: [MapLayerReadingNote] {
        switch self {
        case .hex:
            return []
        case .province:
            return [
                MapLayerReadingNote(title: "政令", detail: "看州府归属与治理", systemImageName: "scroll", tint: MingDesignTokens.jade),
                MapLayerReadingNote(title: "钱粮", detail: "扫粮台、工坊、驿道", systemImageName: "shippingbox", tint: MingDesignTokens.imperialGold),
                MapLayerReadingNote(title: "民变", detail: "找行政承压州府", systemImageName: "exclamationmark.triangle", tint: MingDesignTokens.cinnabar)
            ]
        case .initialTheater:
            return [
                MapLayerReadingNote(title: "开局", detail: "方面基准不随推进", systemImageName: "flag", tint: MingDesignTokens.porcelainBlue),
                MapLayerReadingNote(title: "督抚", detail: "读辽东、畿辅、秦陕", systemImageName: "person.text.rectangle", tint: MingDesignTokens.jade),
                MapLayerReadingNote(title: "分防", detail: "用于筹划守关守城", systemImageName: "shield", tint: MingDesignTokens.imperialGold)
            ]
        case .dynamicTheater:
            return [
                MapLayerReadingNote(title: "推进", detail: "只随具体舆图格变化", systemImageName: "arrow.up.forward", tint: MingDesignTokens.cinnabar),
                MapLayerReadingNote(title: "军机", detail: "看各方当前方面", systemImageName: "brain.head.profile", tint: MingDesignTokens.porcelainBlue),
                MapLayerReadingNote(title: "伸缩", detail: "辨认战局突破口", systemImageName: "arrow.triangle.2.circlepath", tint: MingDesignTokens.jade)
            ]
        case .frontLine:
            return [
                MapLayerReadingNote(title: "接敌", detail: "真实相邻才成前线", systemImageName: "waveform.path.ecg", tint: MingDesignTokens.cinnabar),
                MapLayerReadingNote(title: "守关", detail: "看京畿、山海、开封", systemImageName: "building.columns", tint: MingDesignTokens.imperialGold),
                MapLayerReadingNote(title: "截援", detail: "找围点打援缺口", systemImageName: "point.topleft.down.curvedto.point.bottomright.up", tint: MingDesignTokens.jade)
            ]
        case .deployment:
            return [
                MapLayerReadingNote(title: "前军", detail: "前线可调军伍", systemImageName: "figure.walk", tint: MingDesignTokens.cinnabar),
                MapLayerReadingNote(title: "纵深", detail: "预备队与粮道后路", systemImageName: "arrow.down.left.and.arrow.up.right", tint: MingDesignTokens.porcelainBlue),
                MapLayerReadingNote(title: "驻守", detail: "城关州府守备", systemImageName: "shield.lefthalf.filled", tint: MingDesignTokens.jade)
            ]
        }
    }
}

private struct OperationPlanSwatch: View {
    var body: some View {
        HStack(spacing: 3) {
            Text("进")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 19, height: 17)
                .background(MingDesignTokens.cinnabar, in: RoundedRectangle(cornerRadius: 4))

            Text("守")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 19, height: 17)
                .background(MingDesignTokens.jade, in: RoundedRectangle(cornerRadius: 4))
        }
        .accessibilityHidden(true)
    }
}

private struct SupplyRouteSwatch: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: 2, y: size.height / 2))
            path.addLine(to: CGPoint(x: size.width - 2, y: size.height / 2))
            context.stroke(
                path,
                with: .color(MingDesignTokens.imperialGold),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [8, 5])
            )
        }
        .frame(width: 44, height: 14)
        .accessibilityHidden(true)
    }
}
