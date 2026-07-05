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
                        directiveRecords: container.lastWarDirectiveRecords
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 10)
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
    case agent = "AI"

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
                    MapLegendBadge(text: "步", title: "军牌", tint: MingDesignTokens.porcelainBlue)
                    FactionBannerLegendBadge()
                    OperationPlanLegendBadge()

                    if showsSupplyRoutes {
                        SupplyRouteLegendBadge()
                    }
                } else {
                    MapLayerLegendBadge(layer: layer)
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

private struct FactionBannerLegendBadge: View {
    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 3) {
                MingFactionFlagBadge(faction: .ming)
                MingFactionFlagBadge(faction: .qing)
                MingFactionFlagBadge(faction: .dashun)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("势力旗")
                    .font(.caption.bold())
                Text("明 / 清 / 顺")
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
