import SwiftUI

struct UnitInspectorView: View {
    let division: Division?
    let playerFaction: Faction
    let strategicState: UnitInspectorStrategicState?

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

                Text("\(division.faction.displayName) / \(division.commandRoleName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Spacer(minLength: 8)

            UnitStatusChip(
                title: "控制",
                value: division.faction == playerFaction ? "玩家" : "只读",
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
                UnitPositionRow(label: "坐标", value: "\(strategicState.coord.q),\(strategicState.coord.r)")
                UnitPositionRow(label: "州府", value: strategicState.regionId?.rawValue ?? "无")
                UnitPositionRow(label: "方面", value: strategicState.dynamicTheaterId?.rawValue ?? "无")
                UnitPositionRow(label: "防区", value: strategicState.frontZoneId?.rawValue ?? "无")
                UnitPositionRow(label: "部署", value: strategicState.deploymentRole.displayName)
                UnitPositionRow(label: "前线", value: strategicState.frontLineIds.displaySummary)
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
        isEmpty ? "无" : map(\.rawValue).joined(separator: ", ")
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
