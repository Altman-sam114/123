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
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    identityBlock
                    VStack(alignment: .leading, spacing: 12) {
                        biographyBlock
                        statusBlock
                    }
                }

                skillsBlock
                assignedUnitsBlock
            }
            .padding(18)
        }
        .background(.ultraThinMaterial)
        .safeAreaInset(edge: .top) {
            HStack {
                Text("将领档案")
                    .font(.headline)
                Spacer()
                Button("关闭", systemImage: "xmark", action: onClose)
                    .buttonStyle(.bordered)
                    .frame(minHeight: MingDesignTokens.minimumTapSize)
            }
            .padding(MingDesignTokens.panelPadding)
            .background(MingDesignTokens.panelBackground)
        }
    }

    private var identityBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(initials)
                .font(.title.weight(.bold))
                .frame(width: 112, height: 144)
                .foregroundStyle(MingDesignTokens.cinnabar)
                .background(MingDesignTokens.subtleSeal)
                .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
                .accessibilityLabel("\(general.localizedName)印信")

            Text(general.localizedName)
                .font(.title3.weight(.semibold))
            Text(general.rank)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(general.faction.displayName)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(MingDesignTokens.sectionBackground)
                .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        }
        .frame(minWidth: 132, alignment: .leading)
    }

    private var biographyBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("履历")
                .font(.headline)
            Text(general.biography)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            LabeledContent("统兵风格") {
                Text(styleLabel(general.commandStyle))
            }
            if let zone {
                LabeledContent("所属战区") {
                    Text(zone.name)
                        .multilineTextAlignment(.trailing)
                }
            }
            if hqUnderAttack {
                Label("本营受压", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }
        }
    }

    private var statusBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("君臣关系")
                .font(.headline)
            metricBar(title: "忠诚", value: assignment?.loyalty ?? general.baseLoyalty)
            metricBar(title: "军心", value: assignment?.satisfaction ?? general.baseSatisfaction)
            LabeledContent("玩家干预") {
                Text("\(assignment?.interventionCount ?? 0)")
            }
        }
    }

    private var skillsBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("技能")
                .font(.headline)
            if general.skills.isEmpty {
                Text("暂无明确技能。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(general.skills, id: \.self) { skill in
                        Label(skill.replacingOccurrences(of: "_", with: " "), systemImage: "star.fill")
                            .font(.caption.weight(.semibold))
                            .lineLimit(2)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(MingDesignTokens.sectionBackground)
                            .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
                    }
                }
            }
        }
    }

    private var assignedUnitsBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("麾下部队")
                .font(.headline)
            if assignedDivisions.isEmpty {
                Text("暂无可用部队。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(assignedDivisions, id: \.id) { division in
                    LabeledContent(division.name) {
                        Text("\(division.strength)/\(division.maxStrength)")
                    }
                    .font(.caption)
                }
            }
        }
    }

    private func metricBar(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value)")
            }
            .font(.caption)
            ProgressView(value: Double(value), total: 100)
                .tint(value >= 65 ? .green : value >= 40 ? .orange : .red)
        }
    }

    private var initials: String {
        let words = general.localizedName.split(separator: " ")
        let letters = words.prefix(2).compactMap(\.first)
        return letters.isEmpty ? String(general.name.prefix(2)).uppercased() : String(letters).uppercased()
    }

    private func styleLabel(_ style: ZoneCommanderAgentConfig.CommandStyle) -> String {
        switch style {
        case .aggressive:
            return "锐进"
        case .balanced:
            return "持重"
        case .cautious:
            return "谨守"
        }
    }
}
