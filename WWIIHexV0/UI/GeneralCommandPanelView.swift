import SwiftUI

struct GeneralCommandPanelView: View {
    let zone: FrontZone?
    let general: GeneralData?
    let assignment: GeneralAssignment?
    let assignedDivisions: [Division]
    let targetRegion: RegionNode?
    let targetZone: FrontZone?
    let hqUnderAttack: Bool
    let plannedOperations: [PlayerPlannedOperation]
    let canHoldLine: Bool
    let canAttackRegion: Bool
    let onShowProfile: () -> Void
    let onHoldLine: () -> Void
    let onAttackRegion: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.sectionSpacing) {
            GeneralCommandHeader(
                zone: zone,
                general: general,
                assignment: assignment,
                assignedDivisions: assignedDivisions,
                hqUnderAttack: hqUnderAttack
            )

            if let zone {
                if let general {
                    GeneralCommandIdentityCard(
                        general: general,
                        assignment: assignment,
                        assignedDivisions: assignedDivisions,
                        hqUnderAttack: hqUnderAttack,
                        onShowProfile: onShowProfile
                    )
                } else {
                    GeneralCommandEmptyState(text: "该防区尚未授印。", systemImage: "person.badge.questionmark")
                }

                GeneralCommandTargetSection(
                    zone: zone,
                    targetRegion: targetRegion,
                    targetZone: targetZone
                )

                GeneralCommandUnitsSection(divisions: assignedDivisions)

                GeneralCommandActionSection(
                    canHoldLine: canHoldLine,
                    canAttackRegion: canAttackRegion,
                    onHoldLine: onHoldLine,
                    onAttackRegion: onAttackRegion
                )

                if !plannedOperations.isEmpty {
                    GeneralCommandPlannedOperationsSection(operations: plannedOperations)
                }
            } else {
                GeneralCommandEmptyState(text: "请在舆图上选中己方防区。", systemImage: "map")
            }
        }
        .padding(MingDesignTokens.panelPadding)
        .background(MingDesignTokens.panelBackground)
        .overlay {
            RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius)
                .stroke(MingDesignTokens.courtStroke.opacity(0.72), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }
}

private struct GeneralCommandHeader: View {
    let zone: FrontZone?
    let general: GeneralData?
    let assignment: GeneralAssignment?
    let assignedDivisions: [Division]
    let hqUnderAttack: Bool

    var body: some View {
        HStack(alignment: .top, spacing: MingDesignTokens.compactSpacing) {
            Text("将")
                .font(.headline)
                .bold()
                .foregroundStyle(MingDesignTokens.cinnabar)
                .frame(width: 34, height: 34)
                .background(MingDesignTokens.subtleSeal)
                .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius)
                        .stroke(MingDesignTokens.courtStroke, lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text("将印军令")
                    .font(.headline)
                    .foregroundStyle(MingDesignTokens.ink)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: MingDesignTokens.compactSpacing)

            Label(statusText, systemImage: statusImageName)
                .font(.caption)
                .bold()
                .foregroundStyle(statusTint)
                .padding(.horizontal, MingDesignTokens.compactSpacing)
                .padding(.vertical, 5)
                .background(statusTint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
        }
    }

    private var subtitle: String {
        guard let zone else {
            return "候选方面防区"
        }
        if let general {
            return "\(zone.name) · \(general.localizedName)领 \(assignedDivisions.count) 营"
        }
        return "\(zone.name) · 待授主将"
    }

    private var statusText: String {
        if hqUnderAttack {
            return "本营受压"
        }
        guard zone != nil else {
            return "候选"
        }
        guard general != nil else {
            return "待授印"
        }
        if let assignment, assignment.satisfaction < 40 {
            return "军心摇动"
        }
        return "可议令"
    }

    private var statusImageName: String {
        if hqUnderAttack {
            return "exclamationmark.triangle"
        }
        if zone == nil {
            return "map"
        }
        if general == nil {
            return "person.badge.questionmark"
        }
        return "seal"
    }

    private var statusTint: Color {
        if hqUnderAttack {
            return MingDesignTokens.cinnabar
        }
        if let assignment, assignment.satisfaction < 40 {
            return MingDesignTokens.imperialGold
        }
        if general == nil {
            return .secondary
        }
        return MingDesignTokens.jade
    }
}

private struct GeneralCommandIdentityCard: View {
    let general: GeneralData
    let assignment: GeneralAssignment?
    let assignedDivisions: [Division]
    let hqUnderAttack: Bool
    let onShowProfile: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack(alignment: .top, spacing: MingDesignTokens.compactSpacing) {
                Button(action: onShowProfile) {
                    Text(general.mingInitials)
                        .font(.title3)
                        .bold()
                        .frame(width: 46, height: 46)
                        .foregroundStyle(MingDesignTokens.cinnabar)
                        .background(MingDesignTokens.subtleSeal)
                        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
                        .overlay {
                            RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius)
                                .stroke(MingDesignTokens.courtStroke, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("查看\(general.localizedName)名帖")

                VStack(alignment: .leading, spacing: 3) {
                    Text(general.localizedName)
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(MingDesignTokens.ink)

                    Text("\(general.rank) · \(general.faction.displayName) · \(general.commandStyleDisplayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Text(general.biography)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }

            if !general.skills.isEmpty {
                Text(general.skillsText)
                    .font(.caption)
                    .foregroundStyle(MingDesignTokens.porcelainBlue)
                    .lineLimit(2)
            }

            GeneralCommandMetricGrid(
                assignment: assignment,
                general: general,
                assignedCount: assignedDivisions.count,
                hqUnderAttack: hqUnderAttack
            )

            Button("将领名帖", systemImage: "person.text.rectangle", action: onShowProfile)
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity, minHeight: MingDesignTokens.minimumTapSize, alignment: .leading)
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }
}

private struct GeneralCommandMetricGrid: View {
    let assignment: GeneralAssignment?
    let general: GeneralData
    let assignedCount: Int
    let hqUnderAttack: Bool

    private let columns = [
        GridItem(.adaptive(minimum: 76), spacing: MingDesignTokens.compactSpacing)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            GeneralCommandMetricChip(title: "忠诚", value: "\(assignment?.loyalty ?? general.baseLoyalty)", systemImage: "seal", tint: loyaltyTint)
            GeneralCommandMetricChip(title: "军心", value: "\(assignment?.satisfaction ?? general.baseSatisfaction)", systemImage: "heart.text.square", tint: satisfactionTint)
            GeneralCommandMetricChip(title: "干预", value: "\(assignment?.interventionCount ?? 0)", systemImage: "hand.raised", tint: MingDesignTokens.imperialGold)
            GeneralCommandMetricChip(title: "麾下", value: "\(assignedCount)", systemImage: "person.3", tint: MingDesignTokens.porcelainBlue)
        }

        if hqUnderAttack {
            Label("本营受压，军令宜先稳防。", systemImage: "exclamationmark.triangle")
                .font(.caption)
                .bold()
                .foregroundStyle(MingDesignTokens.cinnabar)
        }
    }

    private var loyaltyTint: Color {
        let value = assignment?.loyalty ?? general.baseLoyalty
        return value >= 65 ? MingDesignTokens.jade : value >= 40 ? MingDesignTokens.imperialGold : MingDesignTokens.cinnabar
    }

    private var satisfactionTint: Color {
        let value = assignment?.satisfaction ?? general.baseSatisfaction
        return value >= 65 ? MingDesignTokens.jade : value >= 40 ? MingDesignTokens.imperialGold : MingDesignTokens.cinnabar
    }
}

private struct GeneralCommandMetricChip: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(tint)
                    .lineLimit(1)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, minHeight: 38, alignment: .leading)
        .padding(.horizontal, MingDesignTokens.compactSpacing)
        .padding(.vertical, 5)
        .background(MingDesignTokens.panelBackground.opacity(0.55), in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct GeneralCommandTargetSection: View {
    let zone: FrontZone
    let targetRegion: RegionNode?
    let targetZone: FrontZone?

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            Label("方面态势", systemImage: "scope")
                .font(.caption)
                .bold()
                .foregroundStyle(MingDesignTokens.cinnabar)

            HStack(spacing: MingDesignTokens.compactSpacing) {
                GeneralCommandInfoChip(title: "防区", value: zone.name, tint: MingDesignTokens.porcelainBlue)
                GeneralCommandInfoChip(title: "压力", value: "\(zone.pressure)", tint: zone.pressure > 60 ? MingDesignTokens.cinnabar : MingDesignTokens.imperialGold)
                GeneralCommandInfoChip(title: "战态", value: zone.state.displayName, tint: zone.state.tint)
            }

            if let targetRegion {
                Label(targetText(for: targetRegion), systemImage: targetZone?.faction == zone.faction ? "shield" : "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            } else {
                Text("未指定进取州府，当前以防区态势议令。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }

    private func targetText(for region: RegionNode) -> String {
        if let targetZone, targetZone.faction == zone.faction {
            return "目标 \(region.name) · 友方防区"
        }
        if let targetZone {
            return "目标 \(region.name) · \(targetZone.faction.displayName)"
        }
        return "目标 \(region.name)"
    }
}

private struct GeneralCommandInfoChip: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .bold()
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.panelBackground.opacity(0.55), in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct GeneralCommandUnitsSection: View {
    let divisions: [Division]

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            Label("麾下军伍", systemImage: "person.3")
                .font(.caption)
                .bold()
                .foregroundStyle(MingDesignTokens.cinnabar)

            if divisions.isEmpty {
                Text("暂无可调营伍。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(divisions.prefix(5)), id: \.id) { division in
                    HStack(spacing: MingDesignTokens.compactSpacing) {
                        Label(division.name, systemImage: division.generalCommandIcon)
                            .font(.caption)
                            .lineLimit(1)

                        Spacer(minLength: MingDesignTokens.compactSpacing)

                        Text(division.generalCommandStrengthText)
                            .font(.caption)
                            .bold()
                            .foregroundStyle(division.generalCommandTint)
                    }
                    .padding(.horizontal, MingDesignTokens.compactSpacing)
                    .padding(.vertical, 5)
                    .background(MingDesignTokens.panelBackground.opacity(0.48), in: RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }
}

private struct GeneralCommandActionSection: View {
    let canHoldLine: Bool
    let canAttackRegion: Bool
    let onHoldLine: () -> Void
    let onAttackRegion: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            Label("将令处置", systemImage: "checklist")
                .font(.caption)
                .bold()
                .foregroundStyle(MingDesignTokens.cinnabar)

            HStack(spacing: MingDesignTokens.compactSpacing) {
                Button("固守防线", systemImage: "shield.fill", action: onHoldLine)
                    .disabled(!canHoldLine)
                    .frame(maxWidth: .infinity, minHeight: MingDesignTokens.minimumTapSize)

                Button("进取州府", systemImage: "arrow.up.right.circle", action: onAttackRegion)
                    .disabled(!canAttackRegion)
                    .frame(maxWidth: .infinity, minHeight: MingDesignTokens.minimumTapSize)
            }
            .buttonStyle(.bordered)

            Text("固守用于稳住防线，进取用于逼向当前目标州府。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }
}

private struct GeneralCommandPlannedOperationsSection: View {
    let operations: [PlayerPlannedOperation]

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            Label("军令计划", systemImage: "list.bullet.clipboard")
                .font(.caption)
                .bold()
                .foregroundStyle(MingDesignTokens.cinnabar)

            ForEach(operations) { operation in
                Label(operation.summaryText, systemImage: operation.systemImageName)
                    .font(.caption)
                    .foregroundStyle(operation.tint)
                    .lineLimit(2)
                    .padding(.horizontal, MingDesignTokens.compactSpacing)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(MingDesignTokens.panelBackground.opacity(0.48), in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }
}

private struct GeneralCommandEmptyState: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.body)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: MingDesignTokens.minimumTapSize, alignment: .leading)
            .padding(MingDesignTokens.compactSpacing)
            .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }
}

private extension GeneralData {
    var mingInitials: String {
        let words = localizedName.split(separator: " ")
        let letters = words.prefix(2).compactMap(\.first)
        return letters.isEmpty ? String(name.prefix(2)).uppercased() : String(letters).uppercased()
    }

    var commandStyleDisplayName: String {
        switch commandStyle {
        case .aggressive:
            return "锐进"
        case .balanced:
            return "持重"
        case .cautious:
            return "谨守"
        }
    }

    var skillsText: String {
        "将略：" + skills.map { $0.replacingOccurrences(of: "_", with: " ") }.joined(separator: " · ")
    }
}

private extension WarState {
    var displayName: String {
        switch self {
        case .peace:
            return "整备"
        case .lowIntensity:
            return "接战"
        case .highIntensity:
            return "激战"
        case .totalWar:
            return "决战"
        }
    }

    var tint: Color {
        switch self {
        case .peace:
            return MingDesignTokens.jade
        case .lowIntensity:
            return MingDesignTokens.imperialGold
        case .highIntensity, .totalWar:
            return MingDesignTokens.cinnabar
        }
    }
}

private extension Division {
    var generalCommandIcon: String {
        if isSiegeCapable {
            return "target"
        }
        if hasFireSupport {
            return "scope"
        }
        if isMobileUnit {
            return "arrow.triangle.swap"
        }
        return "person.3.fill"
    }

    var generalCommandStrengthText: String {
        "\(strength)/\(maxStrength)"
    }

    var generalCommandTint: Color {
        let ratio = maxStrength > 0 ? Double(strength) / Double(maxStrength) : 0
        if ratio >= 0.66 {
            return MingDesignTokens.jade
        }
        if ratio >= 0.35 {
            return MingDesignTokens.imperialGold
        }
        return MingDesignTokens.cinnabar
    }
}

private extension PlayerPlannedOperation {
    var systemImageName: String {
        directiveType == .attack ? "arrow.up.right.circle" : "shield.fill"
    }

    var tint: Color {
        directiveType == .attack ? MingDesignTokens.cinnabar : MingDesignTokens.jade
    }

    var summaryText: String {
        let target = targetRegionId?.rawValue ?? sourceRegionId?.rawValue ?? zoneId.rawValue
        let directive = directiveType == .attack ? "进取" : "固守"
        return "第 \(turn) 回合 · \(directive) · \(target)"
    }
}
