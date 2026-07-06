import SwiftUI

struct RegionInspectorView: View {
    let inspectorState: RegionInspectorState?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("州府")
                .font(.headline)

            if let inspectorState {
                regionDetails(inspectorState)
            } else {
                Text("未选择州府。")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(MingDesignTokens.panelPadding)
        .background(MingDesignTokens.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }

    private func regionDetails(_ state: RegionInspectorState) -> some View {
        let occupation = state.region.occupationState ?? .stable

        return VStack(alignment: .leading, spacing: 8) {
            RegionMandateHeader(state: state)
            RegionPrimaryValueSection(state: state, occupation: occupation)
            RegionFourLineSection(state: state, occupation: occupation)
            RegionGovernanceSection(occupation: occupation)
            RegionYieldSection(state: state, occupation: occupation)
            RegionFrontSection(state: state)
            if let selectedHex = state.selectedHex {
                SelectedHexSection(
                    selectedHex: selectedHex,
                    controller: state.selectedHexController,
                    dynamicTheaterId: state.selectedHexDynamicTheaterId,
                    frontZoneId: state.selectedHexFrontZoneId
                )
            }
        }
    }
}

private struct RegionMandateHeader: View {
    let state: RegionInspectorState

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(state.region.mapGlyph)
                .font(.title3.bold())
                .foregroundStyle(MingDesignTokens.cinnabar)
                .frame(width: 44, height: 44)
                .background(MingDesignTokens.subtleSeal)
                .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius)
                        .stroke(MingDesignTokens.cinnabar.opacity(0.45), lineWidth: 1)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(state.region.name)
                    .font(.subheadline.bold())
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    MingFactionFlagBadge(faction: state.region.controller)
                    Text("\(state.region.controller.displayName) / \(state.region.terrain.displayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 5) {
                RegionBadge(title: "城级", value: state.cityLevel.displayName, tint: state.region.statusTint)
                    .frame(width: 88)
                RegionMandateBadge(region: state.region)
                    .frame(width: 88)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct RegionPrimaryValueSection: View {
    let state: RegionInspectorState
    let occupation: OccupationState

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack(alignment: .top, spacing: 8) {
                Label(primary.title, systemImage: primary.systemImageName)
                    .font(.caption.bold())
                    .foregroundStyle(primary.tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 8)

                Text(primary.badge)
                    .font(.caption.bold())
                    .foregroundStyle(primary.tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(primary.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
            }

            Text(primary.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 6)], alignment: .leading, spacing: 6) {
                ForEach(signals) { signal in
                    RegionValueChip(signal: signal)
                }
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }

    private var primary: RegionValueSignal {
        if !state.objectiveNames.isEmpty {
            return RegionValueSignal(
                title: "战局要冲",
                detail: "牵动 \(state.objectiveNames.displaySummary)，当前 \(state.objectiveStatus)。",
                badge: "军事",
                systemImageName: "scope",
                tint: MingDesignTokens.cinnabar
            )
        }

        if state.frontPressure > 0 {
            return RegionValueSignal(
                title: "前线承压",
                detail: "\(state.frontPressureDisplay)，友军 \(state.friendlyDivisions.count) 支，敌情 \(state.visibleEnemyDivisions.count) 支。",
                badge: "军事",
                systemImageName: "exclamationmark.shield",
                tint: state.frontPressureTint
            )
        }

        if state.region.terrain == .fortress {
            return RegionValueSignal(
                title: "城关屏障",
                detail: "\(state.region.name) 是关隘/堡寨地形，适合固守、修城和火器支援。",
                badge: "军事",
                systemImageName: "shield.lefthalf.filled",
                tint: MingDesignTokens.cinnabar
            )
        }

        if state.region.supplyValue >= max(state.region.factories, state.region.infrastructure) && state.region.supplyValue > 0 {
            return RegionValueSignal(
                title: "粮台重地",
                detail: "粮台 \(state.region.supplyValue)，本州府更适合联动筹粮、驿道和前线补给。",
                badge: "经济",
                systemImageName: "shippingbox",
                tint: MingDesignTokens.imperialGold
            )
        }

        if state.region.factories > 0 {
            return RegionValueSignal(
                title: "工坊军械",
                detail: "工坊 \(state.region.factories)，可作为火器、炮队和军械生产的解释支点。",
                badge: "科技",
                systemImageName: "hammer",
                tint: MingDesignTokens.porcelainBlue
            )
        }

        if state.region.infrastructure > 0 {
            return RegionValueSignal(
                title: "驿道节点",
                detail: "驿道 \(state.region.infrastructure)，关系钱粮流通、行军转运和粮道修复。",
                badge: "经济",
                systemImageName: "road.lanes",
                tint: MingDesignTokens.jade
            )
        }

        if occupation.resistance >= 30 || occupation.compliance < 55 {
            return RegionValueSignal(
                title: "治理承压",
                detail: "民变 \(occupation.resistance)%、行政 \(occupation.compliance)%，适合赈济、招抚或整训团练稳定地方。",
                badge: "政策",
                systemImageName: "scroll",
                tint: occupation.governanceTint
            )
        }

        return RegionValueSignal(
            title: state.region.city == nil ? "地方州府" : "城邑根基",
            detail: "钱粮修正 \(occupation.economicYieldPercent)%，可联读民力、银两、粮草和地方治理。",
            badge: "政策",
            systemImageName: "building.columns",
            tint: MingDesignTokens.jade
        )
    }

    private var signals: [RegionValueSignal] {
        [
            RegionValueSignal(
                title: "政",
                detail: "\(occupation.resistanceDisplayName) / \(occupation.complianceDisplayName)",
                badge: "\(occupation.economicYieldPercent)%",
                systemImageName: "scroll",
                tint: occupation.governanceTint
            ),
            RegionValueSignal(
                title: "粮",
                detail: "粮台 \(state.region.supplyValue) / 粮草 \(state.economicOutput.supplies)",
                badge: state.region.supplyValue > 0 ? "粮台" : "平",
                systemImageName: "shippingbox",
                tint: MingDesignTokens.imperialGold
            ),
            RegionValueSignal(
                title: "械",
                detail: "工坊 \(state.region.factories) / 驿道 \(state.region.infrastructure)",
                badge: state.region.factories > 0 ? "工坊" : "驿道",
                systemImageName: "hammer",
                tint: MingDesignTokens.porcelainBlue
            ),
            RegionValueSignal(
                title: "兵",
                detail: state.frontPressure > 0 ? state.frontPressureDisplay : state.objectiveStatus,
                badge: state.objectiveNames.isEmpty ? "州府" : "目标",
                systemImageName: "shield",
                tint: state.frontPressureTint
            )
        ]
    }
}

private struct RegionFourLineSection: View {
    let state: RegionInspectorState
    let occupation: OccupationState

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack(alignment: .top, spacing: 8) {
                Label("州府四线牵引", systemImage: "square.grid.2x2")
                    .font(.caption.bold())
                    .foregroundStyle(MingDesignTokens.cinnabar)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 8)

                Text(summary)
                    .font(.caption.bold())
                    .foregroundStyle(summaryTint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(summaryTint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 126), spacing: 6)], alignment: .leading, spacing: 6) {
                ForEach(signals) { signal in
                    RegionValueChip(signal: signal)
                }
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }

    private var summary: String {
        if !state.objectiveNames.isEmpty {
            return "要冲在案"
        }
        if state.frontPressure > 0 {
            return "前线牵动"
        }
        if occupation.resistance >= 30 || occupation.compliance < 55 {
            return "先稳地方"
        }
        return "政粮械兵"
    }

    private var summaryTint: Color {
        if !state.objectiveNames.isEmpty || state.frontPressure >= 3 {
            return MingDesignTokens.cinnabar
        }
        if state.frontPressure > 0 || occupation.resistance >= 30 || occupation.compliance < 55 {
            return MingDesignTokens.imperialGold
        }
        return MingDesignTokens.jade
    }

    private var signals: [RegionValueSignal] {
        [
            RegionValueSignal(
                title: "政策",
                detail: policyDetail,
                badge: "民变 \(occupation.resistance) / 行政 \(occupation.compliance)",
                systemImageName: "scroll",
                tint: occupation.governanceTint
            ),
            RegionValueSignal(
                title: "经济",
                detail: "银两 \(state.economicOutput.industry)，粮台 \(state.region.supplyValue)，修正 \(occupation.economicYieldPercent)%。",
                badge: "民力 \(state.economicOutput.manpower) / 粮 \(state.economicOutput.supplies)",
                systemImageName: "shippingbox",
                tint: MingDesignTokens.imperialGold
            ),
            RegionValueSignal(
                title: "科技",
                detail: technologyDetail,
                badge: "工 \(state.region.factories) / 驿 \(state.region.infrastructure)",
                systemImageName: "hammer",
                tint: MingDesignTokens.porcelainBlue
            ),
            RegionValueSignal(
                title: "军事",
                detail: militaryDetail,
                badge: "压 \(pressureBadge) / 友 \(state.friendlyDivisions.count)",
                systemImageName: "shield.lefthalf.filled",
                tint: state.frontPressureTint
            )
        ]
    }

    private var policyDetail: String {
        if occupation.resistance >= 30 || occupation.compliance < 55 {
            return "宜赈济、招抚或团练，先压民变再承征饷。"
        }
        return "行政尚稳，可承接征饷、守备和地方营造。"
    }

    private var technologyDetail: String {
        if state.region.factories > 0 {
            return "工坊可作火器、炮队和军械支点。"
        }
        if state.region.infrastructure > 0 {
            return "驿道利转运、修城和粮道整备。"
        }
        return "军械根基薄，仍需朝廷营造。"
    }

    private var militaryDetail: String {
        if !state.objectiveNames.isEmpty {
            return "\(state.objectiveNames.displaySummary)：\(state.objectiveStatus)。敌情 \(state.visibleEnemyDivisions.count) 支。"
        }
        if state.frontPressure > 0 {
            return "\(state.frontPressureDisplay)，敌情 \(state.visibleEnemyDivisions.count) 支。"
        }
        return "暂无要冲压力，适合整补、筹粮或稳住地方。"
    }

    private var pressureBadge: String {
        state.frontPressure <= 0 ? "0" : state.frontPressure.formatted(.number.precision(.fractionLength(1)))
    }
}

private struct RegionValueSignal: Identifiable {
    let title: String
    let detail: String
    let badge: String
    let systemImageName: String
    let tint: Color

    var id: String {
        "\(title)-\(badge)-\(detail)"
    }
}

private struct RegionValueChip: View {
    let signal: RegionValueSignal

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Label(signal.title, systemImage: signal.systemImageName)
                    .font(.caption.bold())
                    .foregroundStyle(signal.tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 4)

                Text(signal.badge)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Text(signal.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .background(MingDesignTokens.panelBackground.opacity(0.52), in: RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .combine)
    }
}

private struct RegionMandateBadge: View {
    let region: RegionNode

    var body: some View {
        Text(mandateText)
            .font(.caption2.bold())
            .foregroundStyle(region.controller.mingBannerTint)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(region.controller.mingBannerTint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
            .accessibilityLabel("州府归属\(mandateText)")
    }

    private var mandateText: String {
        region.owner == region.controller ? "原属稳固" : "原属 \(region.owner.bannerGlyph)"
    }
}

private struct RegionGovernanceSection: View {
    let occupation: OccupationState

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack {
                Label("地方治理", systemImage: "scroll")
                    .font(.caption.bold())
                    .foregroundStyle(occupation.governanceTint)
                Spacer(minLength: 8)
                Text("\(occupation.economicYieldPercent)% 钱粮")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            RegionProgressRow(
                title: "民变",
                value: occupation.resistance,
                detail: occupation.resistanceDisplayName,
                tint: MingDesignTokens.cinnabar
            )
            RegionProgressRow(
                title: "行政",
                value: occupation.compliance,
                detail: occupation.complianceDisplayName,
                tint: MingDesignTokens.jade
            )
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }
}

private struct RegionProgressRow: View {
    let title: String
    let value: Int
    let detail: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(value)% / \(detail)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            ProgressView(value: Double(value), total: 100)
                .tint(tint)
        }
    }
}

private struct RegionYieldSection: View {
    let state: RegionInspectorState
    let occupation: OccupationState

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            Text("钱粮城防")
                .font(.caption.bold())

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 74), spacing: 6)], alignment: .leading, spacing: 6) {
                RegionBadge(title: "民力", value: "\(state.economicOutput.manpower)", tint: MingDesignTokens.jade)
                RegionBadge(title: "银两", value: "\(state.economicOutput.industry)", tint: MingDesignTokens.imperialGold)
                RegionBadge(title: "粮草", value: "\(state.economicOutput.supplies)", tint: MingDesignTokens.porcelainBlue)
                RegionBadge(title: "粮台", value: "\(state.region.supplyValue)", tint: MingDesignTokens.imperialGold)
                RegionBadge(title: "工坊", value: "\(state.region.factories)", tint: MingDesignTokens.porcelainBlue)
                RegionBadge(title: "驿道", value: "\(state.region.infrastructure)", tint: .secondary)
            }

            Text("城池 \(state.region.city?.name ?? "无") / \(state.region.terrain == .fortress ? "有关隘" : "无关隘") / 修正 \(occupation.economicYieldPercent)%")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }
}

private struct RegionBadge: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MingDesignTokens.panelBackground.opacity(0.52), in: RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .combine)
    }
}

private struct RegionFrontSection: View {
    let state: RegionInspectorState

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack {
                Label("战局归属", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                    .font(.caption.bold())
                    .foregroundStyle(state.frontPressureTint)
                Spacer(minLength: 8)
                Text(state.frontPressureDisplay)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 5) {
                RegionInfoRow(label: "方面", value: MingMapLabelFormat.theaterTitle(state.theaterId))
                RegionInfoRow(label: "防区", value: MingMapLabelFormat.frontZoneTitle(state.frontZoneId))
                RegionInfoRow(label: "目标", value: state.objectiveNames.displaySummary)
                RegionInfoRow(label: "目标状态", value: state.objectiveStatus)
                RegionInfoRow(label: "友军", value: state.friendlyDivisions.unitDisplaySummary)
                RegionInfoRow(label: "敌情", value: state.visibleEnemyDivisions.unitDisplaySummary)
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }
}

private struct SelectedHexSection: View {
    let selectedHex: HexCoord
    let controller: Faction?
    let dynamicTheaterId: TheaterId?
    let frontZoneId: FrontZoneId?

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            Text("当前格")
                .font(.caption.bold())

            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 5) {
                RegionInfoRow(label: "格位", value: MingMapLabelFormat.coordinate(selectedHex))
                GridRow {
                    Text("控制")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HexControllerValue(controller: controller)
                }
                RegionInfoRow(label: "方面", value: MingMapLabelFormat.theaterTitle(dynamicTheaterId))
                RegionInfoRow(label: "防区", value: MingMapLabelFormat.frontZoneTitle(frontZoneId))
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }
}

private struct HexControllerValue: View {
    let controller: Faction?

    var body: some View {
        HStack(spacing: 5) {
            if let controller {
                MingFactionFlagBadge(faction: controller)
                Text(controller.displayName)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            } else {
                Text("无")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct RegionInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        GridRow {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.bold())
                .lineLimit(2)
                .minimumScaleFactor(0.72)
        }
    }
}

private extension RegionNode {
    var mapGlyph: String {
        if terrain == .fortress {
            return "关"
        }
        if supplyValue > 0 {
            return "粮"
        }
        if city != nil {
            return "城"
        }
        return "府"
    }

    var statusTint: Color {
        if terrain == .fortress {
            return MingDesignTokens.cinnabar
        }
        if supplyValue > 0 {
            return MingDesignTokens.imperialGold
        }
        if city != nil {
            return MingDesignTokens.porcelainBlue
        }
        return MingDesignTokens.jade
    }
}

private extension OccupationState {
    var governanceTint: Color {
        if resistance >= 55 {
            return MingDesignTokens.cinnabar
        }
        if resistance >= 30 || compliance < 55 {
            return MingDesignTokens.imperialGold
        }
        return MingDesignTokens.jade
    }
}

private extension RegionInspectorState {
    var frontPressureDisplay: String {
        frontPressure <= 0 ? "无前线压力" : "压力 \(frontPressure.formatted(.number.precision(.fractionLength(2))))"
    }

    var frontPressureTint: Color {
        if frontPressure >= 3 {
            return MingDesignTokens.cinnabar
        }
        if frontPressure > 0 {
            return MingDesignTokens.imperialGold
        }
        return MingDesignTokens.jade
    }
}

private extension Array where Element == String {
    var displaySummary: String {
        isEmpty ? "无" : joined(separator: ", ")
    }
}

private extension Array where Element == Division {
    var unitDisplaySummary: String {
        isEmpty ? "无" : map(\.name).joined(separator: ", ")
    }
}
