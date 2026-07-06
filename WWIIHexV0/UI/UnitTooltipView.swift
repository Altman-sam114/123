import SwiftUI

struct UnitTooltipView: View {
    let division: Division?
    let strategicState: UnitInspectorStrategicState?
    let objectiveSummary: BattleObjectiveSummary?
    let map: MapState?

    var body: some View {
        if let division {
            let objectiveContext = UnitTooltipObjectiveContext(
                division: division,
                summary: objectiveSummary,
                map: map
            )

            VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
                UnitTooltipHeader(division: division)
                UnitTooltipStrengthBar(division: division)

                HStack(spacing: 6) {
                    UnitTooltipStatusChip(title: "粮草", value: division.supplyState.tooltipDisplayName, tint: division.supplyState.tooltipTint)
                    UnitTooltipStatusChip(title: "行动", value: division.tooltipActionText, tint: division.canAct ? MingDesignTokens.jade : .secondary)
                    UnitTooltipStatusChip(title: "退守", value: division.tooltipRetreatText, tint: division.tooltipRetreatTint)
                }

                if let strategicState {
                    UnitTooltipStrategicStrip(strategicState: strategicState)
                }

                if let objectiveContext {
                    UnitTooltipObjectiveStrip(context: objectiveContext)
                }

                UnitTooltipStatsRow(stats: division.effectiveStats)
                UnitTooltipComponentStrip(components: division.components)
            }
            .padding(MingDesignTokens.compactSpacing)
            .frame(width: 276, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius)
                    .stroke(division.faction.mingBannerTint.opacity(0.48), lineWidth: 1)
            }
            .padding(10)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                UnitTooltipAccessibilityLabel.make(
                    division: division,
                    strategicState: strategicState,
                    objectiveContext: objectiveContext
                )
            )
        }
    }
}

private struct UnitTooltipObjectiveContext {
    let taskTitle: String
    let taskLine: String
    let targetName: String
    let distance: Int
    let tint: Color

    init?(division: Division, summary: BattleObjectiveSummary?, map: MapState?) {
        guard let summary, summary.isMingScenario, let map else {
            return nil
        }

        guard let task = summary.tasks.sorted(by: Self.taskSort).first,
              let targetObjectiveId = task.targetObjectiveId,
              let target = summary.tracks.flatMap(\.targets).first(where: { $0.objectiveId == targetObjectiveId }),
              let objective = map.objective(id: targetObjectiveId) else {
            return nil
        }

        taskTitle = task.title
        taskLine = "\(task.line.displayName) · \(task.priority.displayName)"
        targetName = target.name
        distance = division.coord.distance(to: objective.coord)
        tint = Self.tint(for: task.priority)
    }

    private static func taskSort(_ lhs: BattleObjectiveSummary.CampaignTask, _ rhs: BattleObjectiveSummary.CampaignTask) -> Bool {
        if lhs.priority.sortRank == rhs.priority.sortRank {
            return lhs.title < rhs.title
        }
        return lhs.priority.sortRank < rhs.priority.sortRank
    }

    private static func tint(for priority: BattleObjectiveSummary.CampaignTask.Priority) -> Color {
        switch priority {
        case .urgent:
            return MingDesignTokens.cinnabar
        case .main:
            return MingDesignTokens.imperialGold
        case .watch:
            return MingDesignTokens.porcelainBlue
        }
    }
}

private struct UnitTooltipObjectiveStrip: View {
    let context: UnitTooltipObjectiveContext

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label("要冲牵引", systemImage: "scope")
                .font(.caption2.bold())
                .foregroundStyle(context.tint)
                .lineLimit(1)

            HStack(spacing: 5) {
                UnitTooltipStrategicChip(
                    title: "本旬",
                    value: context.taskTitle,
                    tint: context.tint
                )
                UnitTooltipStrategicChip(
                    title: "落点",
                    value: context.targetName,
                    tint: MingDesignTokens.cinnabar
                )
                UnitTooltipStrategicChip(
                    title: "相距",
                    value: "\(context.distance) 格",
                    tint: MingDesignTokens.porcelainBlue
                )
            }

            Text(context.taskLine)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .accessibilityElement(children: .combine)
    }
}

private enum UnitTooltipAccessibilityLabel {
    static func make(
        division: Division,
        strategicState: UnitInspectorStrategicState?,
        objectiveContext: UnitTooltipObjectiveContext?
    ) -> String {
        var parts = [division.tooltipAccessibilityLabel]

        if let strategicState {
            parts.append(
                "方面 \(MingMapLabelFormat.theaterTitle(strategicState.dynamicTheaterId))，防区 \(MingMapLabelFormat.frontZoneTitle(strategicState.frontZoneId))，部署 \(strategicState.deploymentRole.tooltipDisplayName)"
            )
        }

        if let objectiveContext {
            parts.append(
                "要冲牵引，\(objectiveContext.taskTitle)，落点 \(objectiveContext.targetName)，相距 \(objectiveContext.distance) 格，\(objectiveContext.taskLine)"
            )
        }

        return parts.joined(separator: "，")
    }
}

private struct UnitTooltipStrategicStrip: View {
    let strategicState: UnitInspectorStrategicState

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("军位")
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(spacing: 5) {
                UnitTooltipStrategicChip(
                    title: "方面",
                    value: MingMapLabelFormat.theaterTitle(strategicState.dynamicTheaterId),
                    tint: MingDesignTokens.porcelainBlue
                )
                UnitTooltipStrategicChip(
                    title: "防区",
                    value: MingMapLabelFormat.frontZoneTitle(strategicState.frontZoneId),
                    tint: MingDesignTokens.jade
                )
                UnitTooltipStrategicChip(
                    title: "部署",
                    value: strategicState.deploymentRole.tooltipDisplayName,
                    tint: strategicState.deploymentRole.tooltipTint
                )
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct UnitTooltipStrategicChip: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(value)
                .font(.caption2.bold())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct UnitTooltipHeader: View {
    let division: Division

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Text(division.tooltipGlyph)
                    .font(.title3.bold())
                    .foregroundStyle(division.faction.mingBannerTint)
                    .frame(width: 38, height: 38)
                    .background(MingDesignTokens.subtleSeal, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
                    .overlay {
                        RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius)
                            .stroke(division.faction.mingBannerTint.opacity(0.34), lineWidth: 1)
                    }

                MingFactionFlagBadge(faction: division.faction)
                    .offset(x: 5, y: -5)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(division.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(division.faction.displayName) · \(division.tooltipPostureText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct UnitTooltipStrengthBar: View {
    let division: Division

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("兵力")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 8)

                Text("\(division.strength)/\(division.maxStrength)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: division.tooltipStrengthRatio, total: 1)
                .tint(division.tooltipStrengthTint)
        }
    }
}

private struct UnitTooltipStatusChip: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(value)
                .font(.caption.bold())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
        .background(MingDesignTokens.panelBackground.opacity(0.58), in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct UnitTooltipStatsRow: View {
    let stats: EffectiveStats

    private let columns = [
        GridItem(.flexible(minimum: 38), spacing: 5),
        GridItem(.flexible(minimum: 38), spacing: 5),
        GridItem(.flexible(minimum: 38), spacing: 5),
        GridItem(.flexible(minimum: 38), spacing: 5),
        GridItem(.flexible(minimum: 38), spacing: 5)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 5) {
            UnitTooltipStatChip(title: "攻", value: stats.attack, tint: MingDesignTokens.cinnabar)
            UnitTooltipStatChip(title: "守", value: stats.defense, tint: MingDesignTokens.jade)
            UnitTooltipStatChip(title: "行", value: stats.movement, tint: MingDesignTokens.imperialGold)
            UnitTooltipStatChip(title: "程", value: stats.range, tint: MingDesignTokens.porcelainBlue)
            UnitTooltipStatChip(title: "察", value: stats.vision, tint: .secondary)
        }
    }
}

private struct UnitTooltipStatChip: View {
    let title: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(spacing: 1) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text("\(value)")
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(tint)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 34)
        .background(MingDesignTokens.sectionBackground.opacity(0.72), in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct UnitTooltipComponentStrip: View {
    let components: [DivisionComponent]

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("兵种")
                .font(.caption2)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 5)], alignment: .leading, spacing: 5) {
                ForEach(Array(components.enumerated()), id: \.offset) { _, component in
                    UnitTooltipComponentChip(component: component)
                }
            }
        }
    }
}

private struct UnitTooltipComponentChip: View {
    let component: DivisionComponent

    var body: some View {
        HStack(spacing: 4) {
            Text(component.type.tooltipGlyph)
                .font(.caption.bold())
                .foregroundStyle(component.type.tooltipTint)
                .lineLimit(1)

            Text(component.type.tooltipDisplayName)
                .font(.caption2)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Spacer(minLength: 2)

            Text(component.tooltipWeightText)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(component.type.tooltipTint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(component.type.tooltipTint.opacity(0.22), lineWidth: 1)
        }
    }
}

private extension Division {
    var tooltipStrengthRatio: Double {
        guard maxStrength > 0 else {
            return 0
        }
        return min(max(Double(strength) / Double(maxStrength), 0), 1)
    }

    var tooltipStrengthTint: Color {
        if tooltipStrengthRatio >= 0.75 {
            return MingDesignTokens.jade
        }
        if tooltipStrengthRatio >= 0.45 {
            return MingDesignTokens.imperialGold
        }
        return MingDesignTokens.cinnabar
    }

    var tooltipGlyph: String {
        if isSiegeCapable {
            return "城"
        }
        if isArmor {
            return "骑"
        }
        if hasFireSupport {
            return "火"
        }
        if isMobileUnit {
            return "驰"
        }
        return "军"
    }

    var tooltipPostureText: String {
        "\(tooltipRoleName) · \(tooltipCoordText)"
    }

    var tooltipRoleName: String {
        if isSiegeCapable {
            return "攻城营"
        }
        if isArmor {
            return "旗骑突击"
        }
        if hasFireSupport {
            return "火器压阵"
        }
        if isMobileUnit {
            return "游骑机动"
        }
        return "步军守线"
    }

    var tooltipCoordText: String {
        MingMapLabelFormat.coordinate(coord)
    }

    var tooltipActionText: String {
        if isDestroyed {
            return "已溃"
        }
        if isRetreating {
            return "退守中"
        }
        return canAct ? "待令" : "已行"
    }

    var tooltipRetreatText: String {
        if isRetreating {
            return "余 \(retreatTurnsRemaining) 旬"
        }
        return retreatMode.tooltipDisplayName
    }

    var tooltipRetreatTint: Color {
        if isRetreating {
            return MingDesignTokens.cinnabar
        }
        return retreatMode.tooltipTint
    }

    var tooltipAccessibilityLabel: String {
        "\(name)，\(faction.displayName)，\(tooltipRoleName)，兵力 \(strength) / \(maxStrength)，\(supplyState.tooltipDisplayName)，\(tooltipActionText)，\(tooltipRetreatText)"
    }
}

private extension RetreatMode {
    var tooltipDisplayName: String {
        switch self {
        case .retreatable:
            return "可退守"
        case .hold:
            return "固守"
        }
    }

    var tooltipTint: Color {
        switch self {
        case .retreatable:
            return MingDesignTokens.imperialGold
        case .hold:
            return MingDesignTokens.cinnabar
        }
    }
}

private extension UnitDeploymentRole {
    var tooltipDisplayName: String {
        switch self {
        case .frontUnit:
            return "前线"
        case .depthUnit:
            return "纵深"
        case .garrisonUnit:
            return "驻防"
        }
    }

    var tooltipTint: Color {
        switch self {
        case .frontUnit:
            return MingDesignTokens.cinnabar
        case .depthUnit:
            return MingDesignTokens.imperialGold
        case .garrisonUnit:
            return MingDesignTokens.jade
        }
    }
}

private extension SupplyState {
    var tooltipDisplayName: String {
        switch self {
        case .supplied:
            return "有粮"
        case .lowSupply:
            return "缺粮"
        case .encircled:
            return "被围"
        }
    }

    var tooltipTint: Color {
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

private extension ComponentType {
    var tooltipGlyph: String {
        switch self {
        case .tank:
            return "甲"
        case .motorizedInfantry:
            return "车"
        case .infantry:
            return "步"
        case .artillery:
            return "炮"
        case .cavalry:
            return "骑"
        case .firearm:
            return "火"
        case .bannerCavalry:
            return "旗"
        case .militia:
            return "练"
        case .siegeEngine:
            return "城"
        }
    }

    var tooltipDisplayName: String {
        switch self {
        case .tank:
            return "甲"
        case .motorizedInfantry:
            return "车"
        case .infantry:
            return "步"
        case .artillery:
            return "炮"
        case .cavalry:
            return "骑"
        case .firearm:
            return "火"
        case .bannerCavalry:
            return "旗骑"
        case .militia:
            return "团"
        case .siegeEngine:
            return "城"
        }
    }

    var tooltipTint: Color {
        switch self {
        case .tank:
            return .gray
        case .motorizedInfantry:
            return MingDesignTokens.imperialGold
        case .infantry:
            return MingDesignTokens.jade
        case .artillery:
            return MingDesignTokens.porcelainBlue
        case .cavalry:
            return MingDesignTokens.imperialGold
        case .firearm:
            return MingDesignTokens.porcelainBlue
        case .bannerCavalry:
            return MingDesignTokens.cinnabar
        case .militia:
            return .secondary
        case .siegeEngine:
            return MingDesignTokens.cinnabar
        }
    }
}

private extension DivisionComponent {
    var tooltipWeightText: String {
        "\(Int((weight * 100).rounded()))%"
    }
}
