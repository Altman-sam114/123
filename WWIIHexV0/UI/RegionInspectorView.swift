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
                RegionInfoRow(label: "方面", value: state.theaterId?.rawValue ?? "无")
                RegionInfoRow(label: "防区", value: state.frontZoneId?.rawValue ?? "无")
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
                RegionInfoRow(label: "坐标", value: "\(selectedHex.q),\(selectedHex.r)")
                GridRow {
                    Text("控制")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HexControllerValue(controller: controller)
                }
                RegionInfoRow(label: "方面", value: dynamicTheaterId?.rawValue ?? "无")
                RegionInfoRow(label: "防区", value: frontZoneId?.rawValue ?? "无")
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
