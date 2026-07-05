import SwiftUI

struct CommandPanelView: View {
    let selectedDivision: Division?
    let activeFaction: Faction
    let phase: GamePhase
    let playerFaction: Faction
    let observerModeEnabled: Bool
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
        "\(q), \(r)"
    }
}
