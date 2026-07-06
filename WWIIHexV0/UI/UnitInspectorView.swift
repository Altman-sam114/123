import SwiftUI

struct UnitInspectorView: View {
    let division: Division?
    let playerFaction: Faction
    let strategicState: UnitInspectorStrategicState?
    let objectiveSummary: BattleObjectiveSummary?
    let map: MapState?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("军队详情")
                .font(.headline)

            if let division {
                unitDetails(division)
            } else {
                Text("未选中部队。")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(MingDesignTokens.panelPadding)
        .background(MingDesignTokens.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }

    private func unitDetails(_ division: Division) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            UnitCommandHeader(division: division, playerFaction: playerFaction)
            UnitReadinessSection(division: division)
            UnitWarReadinessSection(division: division)
            UnitFirepowerSection(division: division)
            if let objectiveContext = UnitInspectorObjectiveContext(
                division: division,
                summary: objectiveSummary,
                map: map
            ) {
                UnitObjectiveSection(context: objectiveContext)
            }
            UnitStatsGrid(stats: division.effectiveStats)
            UnitComponentSection(components: division.components)
            if let strategicState {
                UnitPositionSection(strategicState: strategicState)
            }
        }
    }
}

private struct UnitCommandHeader: View {
    let division: Division
    let playerFaction: Faction

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(division.commandGlyph)
                .font(.title3.bold())
                .foregroundStyle(MingDesignTokens.cinnabar)
                .frame(width: 44, height: 44)
                .background(MingDesignTokens.subtleSeal)
                .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius)
                        .stroke(MingDesignTokens.cinnabar.opacity(0.45), lineWidth: 1)
                }
                .overlay(alignment: .topTrailing) {
                    MingFactionFlagBadge(faction: division.faction)
                        .offset(x: 5, y: -5)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(division.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(division.faction.displayName)旗下 · \(division.commandRoleName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
            }

            Spacer(minLength: 8)

            UnitStatusChip(
                title: "控制",
                value: division.faction == playerFaction ? "本方可调" : "他方军情",
                tint: division.faction == playerFaction ? MingDesignTokens.jade : .secondary
            )
        }
        .accessibilityElement(children: .combine)
    }
}

private struct UnitReadinessSection: View {
    let division: Division

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack {
                Label("军情", systemImage: division.commandSystemImageName)
                    .font(.caption.bold())
                    .foregroundStyle(division.readinessTint)
                Spacer(minLength: 8)
                Text(division.inspectorStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("兵力")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(division.inspectorStrengthText)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: division.strengthRatio, total: 1)
                    .tint(division.readinessTint)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 6)], alignment: .leading, spacing: 6) {
                UnitStatusChip(title: "粮草", value: division.supplyState.displayName, tint: division.supplyState.tint)
                UnitStatusChip(title: "退守", value: division.retreatMode.displayName, tint: division.retreatMode.tint)
                UnitStatusChip(title: "行动", value: division.hasActed ? "已行" : "待令", tint: division.hasActed ? .secondary : MingDesignTokens.jade)
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }
}

private struct UnitStatusChip: View {
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
                .minimumScaleFactor(0.78)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MingDesignTokens.panelBackground.opacity(0.52), in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct UnitWarReadinessSection: View {
    let division: Division

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack(spacing: 6) {
                Label("军令战备", systemImage: "list.bullet.rectangle")
                    .font(.caption.bold())
                    .foregroundStyle(division.readinessTint)
                Spacer(minLength: 8)
                Text(division.warReadinessStateText)
                    .font(.caption)
                    .foregroundStyle(division.readinessTint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Text(division.warReadinessBrief)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 82), spacing: 6)], alignment: .leading, spacing: 6) {
                ForEach(division.warReadinessSignals, id: \.title) { signal in
                    UnitWarSignalTile(signal: signal)
                }
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }
}

private struct UnitWarSignalTile: View {
    let signal: UnitWarReadinessSignal

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: signal.systemImage)
                .font(.caption2)
                .foregroundStyle(signal.tint)
                .frame(width: 13)

            VStack(alignment: .leading, spacing: 1) {
                Text(signal.title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(signal.value)
                    .font(.caption.bold())
                    .foregroundStyle(signal.tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
        }
        .padding(7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MingDesignTokens.panelBackground.opacity(0.52), in: RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .combine)
    }
}

private struct UnitFirepowerSection: View {
    let division: Division

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack(spacing: 6) {
                Label("军械火力", systemImage: division.firepowerSystemImageName)
                    .font(.caption.bold())
                    .foregroundStyle(division.firepowerTint)
                Spacer(minLength: 8)
                Text(division.firepowerPostureText)
                    .font(.caption)
                    .foregroundStyle(division.firepowerTint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Text(division.firepowerBrief)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("军械占比")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(division.firepowerSharePercent)%")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(division.firepowerTint)
                }

                ProgressView(value: Double(division.firepowerSharePercent), total: 100)
                    .tint(division.firepowerTint)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 82), spacing: 6)], alignment: .leading, spacing: 6) {
                ForEach(division.firepowerSignals, id: \.title) { signal in
                    UnitWarSignalTile(signal: signal)
                }
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }
}

private struct UnitInspectorObjectiveContext {
    let taskTitle: String
    let taskDetail: String
    let targetName: String
    let targetController: String
    let distance: Int
    let postureTitle: String
    let postureDetail: String
    let tint: Color
    let postureTint: Color

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
        taskDetail = "\(task.line.displayName) · \(task.priority.displayName)"
        targetName = target.name
        targetController = target.controllerName
        distance = division.coord.distance(to: objective.coord)
        postureTitle = Self.postureTitle(for: division)
        postureDetail = Self.postureDetail(for: division, task: task, target: target)
        tint = Self.tint(for: task.priority)
        postureTint = division.objectivePostureTint
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

    private static func postureTitle(for division: Division) -> String {
        if division.isDestroyed {
            return "溃散"
        }
        if division.supplyState == .encircled {
            return "断粮"
        }
        if division.isRetreating {
            return "退守"
        }
        if division.hasActed {
            return "已行"
        }
        if division.isSiegeCapable {
            return "攻城"
        }
        if division.hasFireSupport {
            return "火器"
        }
        if division.isArmor || division.isMobileUnit {
            return "机动"
        }
        return "守线"
    }

    private static func postureDetail(
        for division: Division,
        task: BattleObjectiveSummary.CampaignTask,
        target: BattleObjectiveSummary.Target
    ) -> String {
        if division.isDestroyed {
            return "本军已溃，只能作为战损复盘，不宜牵动 \(target.name)。"
        }
        if division.supplyState == .encircled {
            return "粮道断绝，先解围补粮，再承接 \(task.line.displayName) 急务。"
        }
        if division.isRetreating {
            return "退守未定，适合稳住后路，暂不宜强接 \(target.name)。"
        }
        if division.hasActed {
            return "本旬已行，可作为 \(target.name) 下旬调度和战线复盘依据。"
        }
        if division.isSiegeCapable {
            return "炮车攻具可压城关堡寨，适合争夺 \(target.name) 等要冲。"
        }
        if division.hasFireSupport {
            return "火器营可守关截援，适合支撑 \(task.line.displayName) 线。"
        }
        if division.isArmor || division.isMobileUnit {
            return "机动军伍可抢驿道、截援或补位，牵动 \(target.name) 周边。"
        }
        return "步军营伍适合守线、驻防或接应主力，稳住 \(task.line.displayName) 线。"
    }
}

private struct UnitObjectiveSection: View {
    let context: UnitInspectorObjectiveContext

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack(spacing: 6) {
                Label("要冲牵引", systemImage: "scope")
                    .font(.caption.bold())
                    .foregroundStyle(context.tint)
                Spacer(minLength: 8)
                Text(context.taskDetail)
                    .font(.caption)
                    .foregroundStyle(context.tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Text(context.postureDetail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 82), spacing: 6)], alignment: .leading, spacing: 6) {
                UnitWarSignalTile(
                    signal: UnitWarReadinessSignal(
                        title: "本旬",
                        value: context.taskTitle,
                        systemImage: "scroll",
                        tint: context.tint
                    )
                )
                UnitWarSignalTile(
                    signal: UnitWarReadinessSignal(
                        title: "落点",
                        value: context.targetName,
                        systemImage: "mappin.and.ellipse",
                        tint: MingDesignTokens.cinnabar
                    )
                )
                UnitWarSignalTile(
                    signal: UnitWarReadinessSignal(
                        title: "相距",
                        value: "\(context.distance) 格",
                        systemImage: "ruler",
                        tint: MingDesignTokens.porcelainBlue
                    )
                )
                UnitWarSignalTile(
                    signal: UnitWarReadinessSignal(
                        title: "兵势",
                        value: context.postureTitle,
                        systemImage: "flag.2.crossed",
                        tint: context.postureTint
                    )
                )
            }

            Text("现控：\(context.targetController)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }
}

private struct UnitStatsGrid: View {
    let stats: EffectiveStats

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 58), spacing: 6)], alignment: .leading, spacing: 6) {
            UnitStatTile(label: "攻", value: stats.attack, systemImage: "flame", tint: MingDesignTokens.cinnabar)
            UnitStatTile(label: "守", value: stats.defense, systemImage: "shield", tint: MingDesignTokens.jade)
            UnitStatTile(label: "行", value: stats.movement, systemImage: "arrow.triangle.swap", tint: MingDesignTokens.imperialGold)
            UnitStatTile(label: "程", value: stats.range, systemImage: "scope", tint: MingDesignTokens.porcelainBlue)
            UnitStatTile(label: "察", value: stats.vision, systemImage: "eye", tint: .secondary)
        }
    }
}

private struct UnitStatTile: View {
    let label: String
    let value: Int
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption2)
                .foregroundStyle(tint)
                .frame(width: 13)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(value)")
                    .font(.caption.monospacedDigit().bold())
            }
        }
        .padding(7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }
}

private struct UnitComponentSection: View {
    let components: [DivisionComponent]

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            Text("兵种编成")
                .font(.caption.bold())

            if components.isEmpty {
                Text("暂无编成资料。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(components.enumerated()), id: \.offset) { _, component in
                    UnitComponentRow(component: component)
                }
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }
}

private struct UnitComponentRow: View {
    let component: DivisionComponent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(component.type.displayCode)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text("\(Int((component.weight * 100).rounded()))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.16))
                    Capsule()
                        .fill(component.type.tint.opacity(0.86))
                        .frame(width: max(4, proxy.size.width * component.weight))
                }
            }
            .frame(height: 5)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct UnitPositionSection: View {
    let strategicState: UnitInspectorStrategicState

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            Text("驻防归属")
                .font(.caption.bold())

            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 5) {
                UnitPositionRow(label: "格位", value: MingMapLabelFormat.coordinate(strategicState.coord))
                UnitPositionRow(label: "州府", value: MingMapLabelFormat.regionTitle(strategicState.regionId))
                UnitPositionRow(label: "方面", value: MingMapLabelFormat.theaterTitle(strategicState.dynamicTheaterId))
                UnitPositionRow(label: "防区", value: MingMapLabelFormat.frontZoneTitle(strategicState.frontZoneId))
                UnitPositionRow(label: "部署", value: strategicState.deploymentRole.displayName)
                UnitPositionRow(label: "前线", value: MingMapLabelFormat.frontLineSummary(strategicState.frontLineIds))
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }
}

private struct UnitPositionRow: View {
    let label: String
    let value: String

    var body: some View {
        GridRow {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
    }
}

private struct UnitWarReadinessSignal {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color
}

private extension Division {
    var inspectorStrengthText: String {
        "\(strength) / \(maxStrength)"
    }

    var strengthRatio: Double {
        guard maxStrength > 0 else {
            return 0
        }
        return Double(strength) / Double(maxStrength)
    }

    var inspectorStatusText: String {
        var statuses: [String] = []

        if isRetreating {
            statuses.append("退守中")
        }

        if isDestroyed {
            statuses.append("溃散")
        }

        return statuses.isEmpty ? "待命" : statuses.joined(separator: ", ")
    }

    var commandGlyph: String {
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

    var commandRoleName: String {
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

    var commandSystemImageName: String {
        if isSiegeCapable {
            return "building.2"
        }
        if isArmor || isMobileUnit {
            return "arrow.forward.circle"
        }
        if hasFireSupport {
            return "scope"
        }
        return "shield"
    }

    var readinessTint: Color {
        if isDestroyed || supplyState == .encircled {
            return MingDesignTokens.cinnabar
        }
        if isRetreating || supplyState == .lowSupply {
            return MingDesignTokens.imperialGold
        }
        if strengthRatio < 0.45 {
            return MingDesignTokens.cinnabar
        }
        if strengthRatio < 0.7 {
            return MingDesignTokens.imperialGold
        }
        return MingDesignTokens.jade
    }

    var warReadinessStateText: String {
        if isDestroyed {
            return "溃散"
        }
        if isRetreating {
            return "退守"
        }
        if supplyState == .encircled {
            return "断粮"
        }
        if supplyState == .lowSupply {
            return "缺粮"
        }
        if hasActed {
            return "已行"
        }
        return "可调"
    }

    var warReadinessBrief: String {
        if isDestroyed {
            return "军伍已溃，当前只能作为战损塘报和复盘依据。"
        }
        if isRetreating {
            let target = retreatTarget.map(MingMapLabelFormat.coordinate) ?? "后方格位"
            return "部队正在向 \(target) 退守，剩余 \(retreatTurnsRemaining) 旬；应先稳住粮道与兵力。"
        }
        if supplyState == .encircled {
            return "粮道断绝，攻守行程已受压；宜先解围或补给再发重令。"
        }
        if supplyState == .lowSupply {
            return "粮草偏紧，机动和攻势会受牵制；适合短促处置或就近补粮。"
        }
        if strengthRatio < 0.45 {
            return "兵力折损过半，宜守要冲、等补员或并入稳固防区。"
        }
        if hasActed {
            return "本旬军令已行，仍可作为战线态势和下旬筹划参考。"
        }
        return "军令尚可调度，可结合粮道、兵力和兵种定位决定进取或固守。"
    }

    var warReadinessSignals: [UnitWarReadinessSignal] {
        [
            UnitWarReadinessSignal(
                title: "军令",
                value: canAct ? "可调" : warReadinessStateText,
                systemImage: canAct ? "checkmark.seal" : "clock",
                tint: canAct ? MingDesignTokens.jade : readinessTint
            ),
            UnitWarReadinessSignal(
                title: "粮道",
                value: supplyState.displayName,
                systemImage: supplyState.systemImageName,
                tint: supplyState.tint
            ),
            UnitWarReadinessSignal(
                title: "战力",
                value: warStrengthBandText,
                systemImage: "gauge.with.dots.needle.67percent",
                tint: warStrengthTint
            ),
            UnitWarReadinessSignal(
                title: "用兵",
                value: warRoleShortText,
                systemImage: commandSystemImageName,
                tint: roleTint
            )
        ]
    }

    var warStrengthBandText: String {
        if strengthRatio >= 0.75 {
            return "充足"
        }
        if strengthRatio >= 0.45 {
            return "半损"
        }
        return "危急"
    }

    var warStrengthTint: Color {
        if strengthRatio >= 0.75 {
            return MingDesignTokens.jade
        }
        if strengthRatio >= 0.45 {
            return MingDesignTokens.imperialGold
        }
        return MingDesignTokens.cinnabar
    }

    var warRoleShortText: String {
        if isSiegeCapable {
            return "攻城"
        }
        if hasFireSupport {
            return "火器"
        }
        if isArmor || isMobileUnit {
            return "机动"
        }
        return "守线"
    }

    var roleTint: Color {
        if isSiegeCapable || hasFireSupport {
            return MingDesignTokens.porcelainBlue
        }
        if isArmor || isMobileUnit {
            return MingDesignTokens.imperialGold
        }
        return MingDesignTokens.jade
    }

    var objectivePostureTint: Color {
        if isDestroyed || supplyState == .encircled {
            return MingDesignTokens.cinnabar
        }
        if isRetreating || hasActed || supplyState == .lowSupply {
            return MingDesignTokens.imperialGold
        }
        if isSiegeCapable || hasFireSupport {
            return MingDesignTokens.porcelainBlue
        }
        if isArmor || isMobileUnit {
            return MingDesignTokens.imperialGold
        }
        return MingDesignTokens.jade
    }

    var firepowerSharePercent: Int {
        componentSharePercent(for: [.artillery, .firearm, .siegeEngine])
    }

    var firearmSharePercent: Int {
        componentSharePercent(for: [.firearm])
    }

    var artillerySharePercent: Int {
        componentSharePercent(for: [.artillery])
    }

    var siegeSharePercent: Int {
        componentSharePercent(for: [.siegeEngine])
    }

    var firepowerPostureText: String {
        if isDestroyed {
            return "军械散失"
        }
        if supplyState == .encircled {
            return "断粮难用"
        }
        if supplyState == .lowSupply {
            return "缺粮限火"
        }
        if isSiegeCapable && hasFireSupport {
            return "攻城重器"
        }
        if isSiegeCapable {
            return "攻城主力"
        }
        if hasFireSupport {
            return "火器支援"
        }
        if firepowerSharePercent > 0 {
            return "辅火"
        }
        return "冷兵守线"
    }

    var firepowerBrief: String {
        if isDestroyed {
            return "军伍已溃，火器炮车只作战损记录，不能再支撑城防或攻坚。"
        }
        if supplyState == .encircled {
            return "军械需粮药驮运，断粮被围时射程和攻势价值难以发挥。"
        }
        if supplyState == .lowSupply {
            return "火器炮队仍可压阵，但粮草偏紧会限制连续攻坚和守城久战。"
        }
        if isSiegeCapable {
            return "炮队与攻城器械可压城关、破堡寨，适合配合主力争夺要冲。"
        }
        if hasFireSupport {
            return "火器营可支援邻近战线，适合守关、截援或短程压制敌军。"
        }
        if firepowerSharePercent > 0 {
            return "军械只作辅兵，主要仍靠步骑接战；攻城和远程压制能力有限。"
        }
        return "本部未成火器炮队，适合守线、驻防或依托主力承接军令。"
    }

    var firepowerSignals: [UnitWarReadinessSignal] {
        [
            UnitWarReadinessSignal(
                title: "火器",
                value: "\(firearmSharePercent)%",
                systemImage: "scope",
                tint: firearmSharePercent > 0 ? MingDesignTokens.porcelainBlue : .secondary
            ),
            UnitWarReadinessSignal(
                title: "炮队",
                value: "\(artillerySharePercent)%",
                systemImage: "target",
                tint: artillerySharePercent > 0 ? MingDesignTokens.cinnabar : .secondary
            ),
            UnitWarReadinessSignal(
                title: "攻城",
                value: "\(siegeSharePercent)%",
                systemImage: "building.2",
                tint: siegeSharePercent > 0 ? MingDesignTokens.imperialGold : .secondary
            ),
            UnitWarReadinessSignal(
                title: "射程",
                value: "\(effectiveStats.range) 格",
                systemImage: "ruler",
                tint: effectiveStats.range > 1 ? MingDesignTokens.porcelainBlue : .secondary
            )
        ]
    }

    var firepowerSystemImageName: String {
        if isSiegeCapable {
            return "building.2"
        }
        if hasFireSupport || firepowerSharePercent > 0 {
            return "scope"
        }
        return "shield"
    }

    var firepowerTint: Color {
        if isDestroyed || supplyState == .encircled {
            return MingDesignTokens.cinnabar
        }
        if supplyState == .lowSupply {
            return MingDesignTokens.imperialGold
        }
        if isSiegeCapable {
            return MingDesignTokens.cinnabar
        }
        if hasFireSupport || firepowerSharePercent > 0 {
            return MingDesignTokens.porcelainBlue
        }
        return MingDesignTokens.jade
    }

    private func componentSharePercent(for types: Set<ComponentType>) -> Int {
        let share = components
            .filter { types.contains($0.type) }
            .reduce(0.0) { $0 + $1.weight }
        return max(0, min(100, Int((share * 100).rounded())))
    }
}

private extension RetreatMode {
    var displayName: String {
        switch self {
        case .retreatable:
            return "可退守"
        case .hold:
            return "固守"
        }
    }

    var tint: Color {
        switch self {
        case .retreatable:
            return MingDesignTokens.imperialGold
        case .hold:
            return MingDesignTokens.cinnabar
        }
    }
}

private extension ComponentType {
    var displayCode: String {
        switch self {
        case .tank:
            return "装甲"
        case .motorizedInfantry:
            return "摩托"
        case .infantry:
            return "步军"
        case .artillery:
            return "炮队"
        case .cavalry:
            return "骑兵"
        case .firearm:
            return "火器"
        case .bannerCavalry:
            return "旗骑"
        case .militia:
            return "团练"
        case .siegeEngine:
            return "攻城"
        }
    }

    var tint: Color {
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

private extension SupplyState {
    var displayName: String {
        switch self {
        case .supplied:
            return "有粮"
        case .lowSupply:
            return "缺粮"
        case .encircled:
            return "断粮/被围"
        }
    }

    var tint: Color {
        switch self {
        case .supplied:
            return MingDesignTokens.jade
        case .lowSupply:
            return MingDesignTokens.imperialGold
        case .encircled:
            return MingDesignTokens.cinnabar
        }
    }

    var systemImageName: String {
        switch self {
        case .supplied:
            return "leaf"
        case .lowSupply:
            return "exclamationmark.triangle"
        case .encircled:
            return "xmark.octagon"
        }
    }
}

private extension UnitDeploymentRole {
    var displayName: String {
        switch self {
        case .frontUnit:
            return "前线"
        case .depthUnit:
            return "纵深"
        case .garrisonUnit:
            return "驻防"
        }
    }
}

private extension Array where Element == FrontLineId {
    var displaySummary: String {
        MingMapLabelFormat.frontLineSummary(self)
    }
}

private extension Set where Element == HexDirection {
    var displaySummary: String {
        HexDirection.ordered
            .filter { contains($0) }
            .map(\.displayCode)
            .joined(separator: ", ")
    }
}

private extension HexDirection {
    var displayCode: String {
        switch self {
        case .east:
            return "东"
        case .northEast:
            return "东北"
        case .northWest:
            return "西北"
        case .west:
            return "西"
        case .southWest:
            return "西南"
        case .southEast:
            return "东南"
        }
    }
}
