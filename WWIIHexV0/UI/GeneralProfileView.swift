import SwiftUI

struct GeneralProfileView: View {
    let general: GeneralData
    let assignment: GeneralAssignment?
    let zone: FrontZone?
    let assignedDivisions: [Division]
    let hqUnderAttack: Bool
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MingDesignTokens.sectionSpacing) {
                GeneralProfileHero(
                    general: general,
                    assignment: assignment,
                    zone: zone,
                    assignedDivisions: assignedDivisions,
                    hqUnderAttack: hqUnderAttack
                )

                GeneralProfileSectionCard(title: "履历奏记", systemImage: "scroll", tint: MingDesignTokens.imperialGold) {
                    Text(general.biography)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                GeneralProfileSectionCard(title: "君臣关系", systemImage: "seal", tint: MingDesignTokens.cinnabar) {
                    GeneralProfileMetricBar(
                        title: "忠诚",
                        value: assignment?.loyalty ?? general.baseLoyalty
                    )
                    GeneralProfileMetricBar(
                        title: "军心",
                        value: assignment?.satisfaction ?? general.baseSatisfaction
                    )
                    GeneralProfileInfoRow(title: "手令干预", value: "\(assignment?.interventionCount ?? 0)")
                }

                GeneralProfileSectionCard(title: "将略", systemImage: "star.fill", tint: MingDesignTokens.porcelainBlue) {
                    GeneralProfileSkillsView(skills: general.skills)
                }

                GeneralProfileSectionCard(title: "麾下军伍", systemImage: "person.3", tint: MingDesignTokens.jade) {
                    GeneralProfileUnitsView(divisions: assignedDivisions)
                }
            }
            .padding(MingDesignTokens.panelPadding)
        }
        .background(MingDesignTokens.panelBackground)
        .safeAreaInset(edge: .top) {
            HStack {
                Label("将领名帖", systemImage: "person.text.rectangle")
                    .font(.headline)
                    .foregroundStyle(MingDesignTokens.ink)
                Spacer()
                Button("关闭", systemImage: "xmark", action: onClose)
                    .buttonStyle(.bordered)
                    .frame(minHeight: MingDesignTokens.minimumTapSize)
            }
            .padding(MingDesignTokens.panelPadding)
            .background(MingDesignTokens.panelBackground)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(MingDesignTokens.courtStroke.opacity(0.72))
                    .frame(height: 1)
            }
        }
    }
}

private struct GeneralProfileHero: View {
    let general: GeneralData
    let assignment: GeneralAssignment?
    let zone: FrontZone?
    let assignedDivisions: [Division]
    let hqUnderAttack: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack(alignment: .top, spacing: MingDesignTokens.sectionSpacing) {
                Text(general.profileInitials)
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(MingDesignTokens.cinnabar)
                    .frame(width: 92, height: 112)
                    .background(MingDesignTokens.subtleSeal)
                    .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
                    .overlay {
                        RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius)
                            .stroke(MingDesignTokens.courtStroke, lineWidth: 1)
                    }
                    .accessibilityLabel("\(general.localizedName)印信")

                VStack(alignment: .leading, spacing: 5) {
                    Text(general.localizedName)
                        .font(.title3)
                        .bold()
                        .foregroundStyle(MingDesignTokens.ink)

                    Text("\(general.rank) · \(general.faction.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Label(general.profileCommandStyleDisplayName, systemImage: general.profileCommandStyleImageName)
                        .font(.caption)
                        .bold()
                        .foregroundStyle(general.profileCommandStyleTint)
                        .padding(.horizontal, MingDesignTokens.compactSpacing)
                        .padding(.vertical, 5)
                        .background(general.profileCommandStyleTint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))

                    if let zone {
                        Label(zone.name, systemImage: "map")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 82), spacing: MingDesignTokens.compactSpacing)], alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
                GeneralProfileMetricChip(title: "忠诚", value: "\(assignment?.loyalty ?? general.baseLoyalty)", systemImage: "seal", tint: profilePercentTint(assignment?.loyalty ?? general.baseLoyalty))
                GeneralProfileMetricChip(title: "军心", value: "\(assignment?.satisfaction ?? general.baseSatisfaction)", systemImage: "heart.text.square", tint: profilePercentTint(assignment?.satisfaction ?? general.baseSatisfaction))
                GeneralProfileMetricChip(title: "麾下", value: "\(assignedDivisions.count)", systemImage: "person.3", tint: MingDesignTokens.porcelainBlue)
                GeneralProfileMetricChip(title: "本营", value: hqUnderAttack ? "受压" : "稳", systemImage: hqUnderAttack ? "exclamationmark.triangle" : "checkmark.seal", tint: hqUnderAttack ? MingDesignTokens.cinnabar : MingDesignTokens.jade)
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius)
                .stroke(MingDesignTokens.courtStroke.opacity(0.72), lineWidth: 1)
        }
    }
}

private struct GeneralProfileSectionCard<Content: View>: View {
    let title: String
    let systemImage: String
    let tint: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(tint)

            content
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }
}

private struct GeneralProfileMetricBar: View {
    let title: String
    let value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(value)")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(profilePercentTint(value))
            }

            ProgressView(value: Double(value), total: 100)
                .tint(profilePercentTint(value))
        }
    }
}

private struct GeneralProfileMetricChip: View {
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

private struct GeneralProfileInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        LabeledContent(title) {
            Text(value)
                .bold()
                .foregroundStyle(MingDesignTokens.ink)
        }
        .font(.caption)
    }
}

private struct GeneralProfileSkillsView: View {
    let skills: [String]

    private let columns = [
        GridItem(.adaptive(minimum: 118), spacing: MingDesignTokens.compactSpacing)
    ]

    var body: some View {
        if skills.isEmpty {
            Label("暂无明确将略。", systemImage: "star")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            LazyVGrid(columns: columns, alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
                ForEach(skills, id: \.self) { skill in
                    Label(skill.replacingOccurrences(of: "_", with: " "), systemImage: "star.fill")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(MingDesignTokens.porcelainBlue)
                        .lineLimit(2)
                        .padding(MingDesignTokens.compactSpacing)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(MingDesignTokens.panelBackground.opacity(0.55), in: RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }
}

private struct GeneralProfileUnitsView: View {
    let divisions: [Division]

    var body: some View {
        if divisions.isEmpty {
            Label("暂无可用营伍。", systemImage: "person.3")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            ForEach(divisions, id: \.id) { division in
                HStack(spacing: MingDesignTokens.compactSpacing) {
                    Label(division.name, systemImage: division.profileIcon)
                        .font(.caption)
                        .lineLimit(1)
                    Spacer(minLength: MingDesignTokens.compactSpacing)
                    Text("\(division.strength)/\(division.maxStrength)")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(profilePercentTint(division.profileStrengthPercent))
                }
                .padding(.horizontal, MingDesignTokens.compactSpacing)
                .padding(.vertical, 6)
                .background(MingDesignTokens.panelBackground.opacity(0.55), in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}

private func profilePercentTint(_ value: Int) -> Color {
    if value >= 65 {
        return MingDesignTokens.jade
    }
    if value >= 40 {
        return MingDesignTokens.imperialGold
    }
    return MingDesignTokens.cinnabar
}

private extension GeneralData {
    var profileInitials: String {
        let words = localizedName.split(separator: " ")
        let letters = words.prefix(2).compactMap(\.first)
        return letters.isEmpty ? String(name.prefix(2)).uppercased() : String(letters).uppercased()
    }

    var profileCommandStyleDisplayName: String {
        switch commandStyle {
        case .aggressive:
            return "锐进统兵"
        case .balanced:
            return "持重统兵"
        case .cautious:
            return "谨守统兵"
        }
    }

    var profileCommandStyleImageName: String {
        switch commandStyle {
        case .aggressive:
            return "flame"
        case .balanced:
            return "scale.3d"
        case .cautious:
            return "shield"
        }
    }

    var profileCommandStyleTint: Color {
        switch commandStyle {
        case .aggressive:
            return MingDesignTokens.cinnabar
        case .balanced:
            return MingDesignTokens.imperialGold
        case .cautious:
            return MingDesignTokens.jade
        }
    }
}

private extension Division {
    var profileIcon: String {
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

    var profileStrengthPercent: Int {
        guard maxStrength > 0 else {
            return 0
        }
        return Int((Double(strength) / Double(maxStrength) * 100).rounded())
    }
}
