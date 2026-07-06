import SwiftUI

struct CommandPanelView: View {
    let selectedDivision: Division?
    let activeFaction: Faction
    let phase: GamePhase
    let playerFaction: Faction
    let observerModeEnabled: Bool
    let objectiveSummary: BattleObjectiveSummary?
    let lastCommandMessage: String?
    let onHold: () -> Void
    let onAllowRetreat: () -> Void
    let onResupply: () -> Void
    let onEndTurn: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            commandHeader
            selectedUnitSection
            commandActionSection
            endTurnSection
            commandReceiptSection
        }
        .padding(MingDesignTokens.panelPadding)
        .background(MingDesignTokens.panelBackground)
        .overlay {
            RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius)
                .stroke(MingDesignTokens.courtStroke.opacity(0.72), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }

    private var commandHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            Text("令")
                .font(.title3.bold())
                .foregroundStyle(MingDesignTokens.cinnabar)
                .frame(width: 44, height: 44)
                .background(MingDesignTokens.subtleSeal)
                .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius)
                        .stroke(MingDesignTokens.courtStroke, lineWidth: 1)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("军令牌")
                    .font(.headline)
                    .lineLimit(1)
                Text("\(activeFaction.displayName) · \(phase.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 8)

            CommandReadinessBadge(title: readinessTitle, tint: readinessTint)
        }
        .accessibilityElement(children: .combine)
    }

    private var selectedUnitSection: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            Label("选中军情", systemImage: "scope")
                .font(.caption.bold())
                .foregroundStyle(MingDesignTokens.cinnabar)

            if let selectedDivision {
                HStack(alignment: .center, spacing: 10) {
                    Text(selectedDivision.commandPanelGlyph)
                        .font(.title3.bold())
                        .foregroundStyle(selectedDivision.commandPanelReadinessTint)
                        .frame(width: 38, height: 38)
                        .background(MingDesignTokens.panelBackground.opacity(0.58), in: RoundedRectangle(cornerRadius: 6))
                        .overlay(alignment: .topTrailing) {
                            MingFactionFlagBadge(faction: selectedDivision.faction)
                                .offset(x: 5, y: -5)
                        }
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(selectedDivision.name)
                            .font(.subheadline.bold())
                            .lineLimit(1)
                            .minimumScaleFactor(0.74)
                        Text("\(selectedDivision.faction.displayName) · \(selectedDivision.commandPanelRoleName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }

                    Spacer(minLength: 8)

                    VStack(alignment: .trailing, spacing: 3) {
                        Text("\(selectedDivision.strength) / \(selectedDivision.maxStrength)")
                            .font(.caption.bold())
                        Text("兵力")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                ProgressView(value: selectedDivision.commandPanelStrengthRatio)
                    .tint(selectedDivision.commandPanelReadinessTint)

                LazyVGrid(columns: commandInfoColumns, alignment: .leading, spacing: 6) {
                    CommandStatusChip(title: "粮草", value: selectedDivision.supplyState.commandPanelDisplayName, tint: selectedDivision.supplyState.commandPanelTint)
                    CommandStatusChip(title: "退守", value: selectedDivision.retreatMode.commandPanelDisplayName, tint: selectedDivision.retreatMode.commandPanelTint)
                    CommandStatusChip(title: "行动", value: selectedDivision.hasActed ? "已行" : "待令", tint: selectedDivision.hasActed ? .secondary : MingDesignTokens.jade)
                    CommandStatusChip(title: "坐标", value: selectedDivision.coord.commandPanelDisplayName, tint: MingDesignTokens.porcelainBlue)
                }
            } else {
                Label("未点选己方军队，可先在舆图上选军牌。", systemImage: "hand.tap")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: MingDesignTokens.minimumTapSize, alignment: .leading)
                    .padding(.horizontal, 8)
                    .background(MingDesignTokens.panelBackground.opacity(0.48), in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }

    private var commandActionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("战术处置", systemImage: "scroll")
                .font(.caption.bold())
                .foregroundStyle(MingDesignTokens.imperialGold)

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            CommandMapOrderHint(text: mapOrderHintText)
            CommandObjectiveOrderSection(
                summary: objectiveSummary,
                selectedDivision: selectedDivision
            )

            LazyVGrid(columns: commandActionColumns, alignment: .leading, spacing: 6) {
                CommandActionButton(
                    title: "固守",
                    subtitle: "据城关守线",
                    systemImage: "shield.fill",
                    tint: MingDesignTokens.cinnabar,
                    isEnabled: canSetHold,
                    action: onHold
                )

                CommandActionButton(
                    title: "准许退守",
                    subtitle: "保存兵力撤整",
                    systemImage: "arrow.uturn.backward.circle",
                    tint: MingDesignTokens.imperialGold,
                    isEnabled: canSetRetreatable,
                    action: onAllowRetreat
                )

                CommandActionButton(
                    title: "就地补给",
                    subtitle: "整粮草补军",
                    systemImage: "shippingbox.fill",
                    tint: MingDesignTokens.porcelainBlue,
                    isEnabled: canCommandSelectedUnit,
                    action: onResupply
                )
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }

    private var endTurnSection: some View {
        Button(action: onEndTurn) {
            Label("结束回合", systemImage: "forward.end.fill")
                .font(.caption.bold())
                .frame(maxWidth: .infinity, minHeight: MingDesignTokens.minimumTapSize)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityHint("结束当前势力回合，进入下一方行动或结算。")
    }

    @ViewBuilder
    private var commandReceiptSection: some View {
        if let lastCommandMessage {
            VStack(alignment: .leading, spacing: 5) {
                Label("军令回执", systemImage: "checkmark.seal")
                    .font(.caption.bold())
                    .foregroundStyle(MingDesignTokens.jade)

                Text(lastCommandMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(MingDesignTokens.compactSpacing)
            .background(MingDesignTokens.subtleSeal.opacity(0.72), in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        }
    }

    private var canCommandSelectedUnit: Bool {
        guard !observerModeEnabled else {
            return false
        }

        guard let selectedDivision else {
            return false
        }

        return selectedDivision.faction == playerFaction &&
            activeFaction == playerFaction &&
            phase.allowsHumanCommands &&
            !selectedDivision.hasActed
    }

    private var canSetHold: Bool {
        canCommandSelectedUnit && selectedDivision?.retreatMode != .hold
    }

    private var canSetRetreatable: Bool {
        canCommandSelectedUnit && selectedDivision?.retreatMode != .retreatable
    }

    private var statusText: String {
        if observerModeEnabled {
            return "观察模式：军令不可用。"
        }

        guard let selectedDivision else {
            return "未选择可行动军队。"
        }

        guard selectedDivision.faction == playerFaction else {
            return "已选中敌军，军令不可用。"
        }

        guard activeFaction == playerFaction, phase.allowsHumanCommands else {
            return "\(phase.displayName)阶段不可下达军令。"
        }

        guard !selectedDivision.hasActed else {
            return "该军队本回合已行动。"
        }

        return "可移动或攻击。"
    }

    private var mapOrderHintText: String {
        if observerModeEnabled {
            return "观察模式只可阅军情，不能在舆图落子。"
        }

        guard let selectedDivision else {
            return "先点选己方军牌；调动或攻击在舆图上点目标格。"
        }

        guard selectedDivision.faction == playerFaction else {
            return "敌军只供观测；请改点本方军牌再下令。"
        }

        guard activeFaction == playerFaction, phase.allowsHumanCommands else {
            return "待本方行令阶段，再在舆图点目标格调动或攻击。"
        }

        guard !selectedDivision.hasActed else {
            return "该军本旬已行；可阅军情，不能再落子。"
        }

        switch selectedDivision.supplyState {
        case .encircled:
            return "被围断粮：宜先固守或补给；调动与攻击仍在舆图点目标格。"
        case .lowSupply:
            return "粮草偏紧：可先补给，或在舆图点近处格位稳线。"
        case .supplied:
            return "调动、攻击请在舆图点目标格；固守、准退、补给在此牌批令。"
        }
    }

    private var readinessTitle: String {
        if observerModeEnabled {
            return "观战"
        }

        guard let selectedDivision else {
            return "候令"
        }

        guard selectedDivision.faction == playerFaction else {
            return "敌情"
        }

        guard activeFaction == playerFaction, phase.allowsHumanCommands else {
            return "待本方"
        }

        guard !selectedDivision.hasActed else {
            return "已行动"
        }

        return "可下令"
    }

    private var readinessTint: Color {
        canCommandSelectedUnit ? MingDesignTokens.jade : .secondary
    }

    private var commandInfoColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 72), spacing: 6, alignment: .leading)]
    }

    private var commandActionColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 96), spacing: 6, alignment: .leading)]
    }
}

private struct CommandMapOrderHint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: "mappin.and.ellipse")
                .font(.caption.bold())
                .foregroundStyle(MingDesignTokens.porcelainBlue)
                .frame(width: 18, height: 18)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("舆图军令")
                    .font(.caption.bold())
                    .foregroundStyle(MingDesignTokens.porcelainBlue)
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(MingDesignTokens.panelBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .combine)
    }
}

private struct CommandObjectiveOrderSection: View {
    let summary: BattleObjectiveSummary?
    let selectedDivision: Division?

    var body: some View {
        if let summary, summary.isMingScenario {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Label("要冲军令", systemImage: urgentLine?.line.systemImage ?? "flag.2.crossed")
                        .font(.caption.bold())
                        .foregroundStyle(sectionTint)
                    Spacer(minLength: 8)
                    Text(primaryTask?.priority.displayName ?? "候报")
                        .font(.caption.bold())
                        .foregroundStyle(sectionTint)
                        .lineLimit(1)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 6)], alignment: .leading, spacing: 6) {
                    CommandObjectiveChip(
                        title: "本旬",
                        value: primaryTask?.title ?? "候塘报",
                        detail: primaryTaskDetail,
                        systemImageName: primaryTask?.priority.systemImage ?? "scroll",
                        tint: sectionTint
                    )
                    CommandObjectiveChip(
                        title: "落点",
                        value: targetTitle,
                        detail: targetDetail,
                        systemImageName: "mappin.and.ellipse",
                        tint: MingDesignTokens.cinnabar
                    )
                    CommandObjectiveChip(
                        title: "兵势",
                        value: divisionFitTitle,
                        detail: divisionFitDetail,
                        systemImageName: divisionFitImage,
                        tint: divisionFitTint
                    )
                }

                Text(orderMinute)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(MingDesignTokens.panelBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
            .accessibilityElement(children: .combine)
        }
    }

    private var primaryTask: BattleObjectiveSummary.CampaignTask? {
        summary?.tasks.first { $0.priority == .urgent }
            ?? summary?.tasks.first { $0.priority == .main }
            ?? summary?.tasks.first
    }

    private var urgentLine: BattleObjectiveSummary.CampaignLineBrief? {
        summary?.lineBriefs
            .sorted {
                if $0.status != $1.status {
                    return statusRank($0.status) < statusRank($1.status)
                }
                return $0.pressure > $1.pressure
            }
            .first
    }

    private var primaryTaskDetail: String {
        guard let primaryTask else {
            return "无急务"
        }
        return "\(primaryTask.line.displayName) · \(primaryTask.priority.displayName)"
    }

    private var targetTitle: String {
        guard let objectiveId = primaryTask?.targetObjectiveId else {
            return "看目标"
        }
        return targetName(for: objectiveId) ?? "要冲"
    }

    private var targetDetail: String {
        guard primaryTask?.targetObjectiveId != nil else {
            return "无定位"
        }
        return "依舆图落子"
    }

    private var divisionFitTitle: String {
        guard let selectedDivision else {
            return "未选军"
        }
        switch selectedDivision.supplyState {
        case .encircled:
            return "先救粮"
        case .lowSupply:
            return "近线稳"
        case .supplied:
            if selectedDivision.isSiegeCapable {
                return "攻城破口"
            }
            if selectedDivision.hasFireSupport {
                return "火器压城"
            }
            if selectedDivision.effectiveStats.movement >= 3 {
                return "机动截援"
            }
            if selectedDivision.retreatMode == .hold {
                return "守线稳军"
            }
            return "步军守要"
        }
    }

    private var divisionFitDetail: String {
        guard let selectedDivision else {
            return "点己方军牌"
        }
        switch selectedDivision.supplyState {
        case .encircled:
            return "断粮被围"
        case .lowSupply:
            return "粮草偏紧"
        case .supplied:
            if selectedDivision.isSiegeCapable {
                return "城关优先"
            }
            if selectedDivision.hasFireSupport {
                return "配合守城"
            }
            if selectedDivision.effectiveStats.movement >= 3 {
                return "截援追击"
            }
            if selectedDivision.retreatMode == .hold {
                return "据点固守"
            }
            return selectedDivision.commandPanelRoleName
        }
    }

    private var divisionFitImage: String {
        guard let selectedDivision else {
            return "hand.tap"
        }
        if selectedDivision.supplyState != .supplied {
            return "shippingbox"
        }
        if selectedDivision.isSiegeCapable {
            return "building.columns"
        }
        if selectedDivision.hasFireSupport {
            return "scope"
        }
        if selectedDivision.effectiveStats.movement >= 3 {
            return "arrow.triangle.swap"
        }
        return "shield"
    }

    private var divisionFitTint: Color {
        guard let selectedDivision else {
            return .secondary
        }
        switch selectedDivision.supplyState {
        case .encircled:
            return MingDesignTokens.cinnabar
        case .lowSupply:
            return MingDesignTokens.imperialGold
        case .supplied:
            return selectedDivision.commandPanelReadinessTint
        }
    }

    private var sectionTint: Color {
        guard let line = urgentLine?.line else {
            return MingDesignTokens.imperialGold
        }
        switch line {
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

    private var orderMinute: String {
        let taskText = primaryTask.map { "\($0.line.displayName) \($0.priority.displayName)" } ?? "暂无急务"
        return "军令会看：\(taskText)、目标落点与本军兵势同判；调动和攻击仍在舆图点格，不在此处自动下令。"
    }

    private func targetName(for objectiveId: String) -> String? {
        summary?.tracks
            .flatMap(\.targets)
            .first { $0.objectiveId == objectiveId }?
            .name
    }

    private func statusRank(_ status: BattleObjectiveSummary.CampaignStageStatus) -> Int {
        switch status {
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

private struct CommandObjectiveChip: View {
    let title: String
    let value: String
    let detail: String
    let systemImageName: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(title, systemImage: systemImageName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MingDesignTokens.sectionBackground.opacity(0.72), in: RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .combine)
    }
}

private struct CommandReadinessBadge: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.caption.bold())
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct CommandStatusChip: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(MingDesignTokens.panelBackground.opacity(0.52), in: RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .combine)
    }
}

private struct CommandActionButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Label(title, systemImage: systemImage)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: MingDesignTokens.minimumTapSize, alignment: .leading)
        }
        .buttonStyle(.bordered)
        .tint(isEnabled ? tint : .secondary)
        .disabled(!isEnabled)
        .accessibilityElement(children: .combine)
    }
}

private extension Division {
    var commandPanelStrengthRatio: Double {
        guard maxStrength > 0 else {
            return 0
        }
        return Double(strength) / Double(maxStrength)
    }

    var commandPanelGlyph: String {
        if isSiegeCapable {
            return "城"
        }
        if isArmor {
            return "旗"
        }
        if hasFireSupport {
            return "火"
        }
        if isMobileUnit {
            return "骑"
        }
        return "步"
    }

    var commandPanelRoleName: String {
        if isSiegeCapable {
            return "攻城炮队"
        }
        if isArmor {
            return "旗骑精锐"
        }
        if hasFireSupport {
            return "火器支援"
        }
        if isMobileUnit {
            return "机动骑兵"
        }
        return "步军营伍"
    }

    var commandPanelReadinessTint: Color {
        if isDestroyed || supplyState == .encircled {
            return MingDesignTokens.cinnabar
        }
        if isRetreating || supplyState == .lowSupply {
            return MingDesignTokens.imperialGold
        }
        if commandPanelStrengthRatio < 0.45 {
            return MingDesignTokens.cinnabar
        }
        if commandPanelStrengthRatio < 0.7 {
            return MingDesignTokens.imperialGold
        }
        return MingDesignTokens.jade
    }
}

private extension RetreatMode {
    var commandPanelDisplayName: String {
        switch self {
        case .retreatable:
            return "可退守"
        case .hold:
            return "固守"
        }
    }

    var commandPanelTint: Color {
        switch self {
        case .retreatable:
            return MingDesignTokens.imperialGold
        case .hold:
            return MingDesignTokens.cinnabar
        }
    }
}

private extension SupplyState {
    var commandPanelDisplayName: String {
        switch self {
        case .supplied:
            return "有粮"
        case .lowSupply:
            return "缺粮"
        case .encircled:
            return "断粮"
        }
    }

    var commandPanelTint: Color {
        switch self {
        case .supplied:
            return MingDesignTokens.jade
        case .lowSupply:
            return MingDesignTokens.imperialGold
        case .encircled:
            return MingDesignTokens.cinnabar
        }
    }
}

private extension HexCoord {
    var commandPanelDisplayName: String {
        MingMapLabelFormat.coordinate(self)
    }
}
