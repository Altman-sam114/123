import SwiftUI

struct DiplomacyPanelView: View {
    let diplomacyState: DiplomacyState
    let activeFaction: Faction
    let courtSummary: CourtStrategySummary?

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.sectionSpacing) {
            Label("天下局势", systemImage: "map")
                .font(.headline)
                .foregroundStyle(MingDesignTokens.ink)

            WorldMandateBannerView(
                faction: activeFaction,
                situationText: worldPressureText,
                hostilePowerText: hostilePowerText,
                warSupport: activeWarSupport,
                courtSummary: courtSummary
            )

            situationSection

            if let rulerRecord = diplomacyState.latestRulerRecord {
                Divider()
                rulerSection(rulerRecord)
            }

            Divider()
            countrySection
            Divider()
            relationSection
            Divider()
            blocSection
        }
        .padding(MingDesignTokens.panelPadding)
        .background(MingDesignTokens.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }

    private var situationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("天下概览")
                .font(.subheadline.weight(.semibold))

            LabeledContent("当前势力") {
                Text(activeFaction.displayName)
            }

            LabeledContent("名义主体") {
                Text(activeCountryNames)
                    .multilineTextAlignment(.trailing)
            }

            LabeledContent("战事态势") {
                Text(worldPressureText)
                    .multilineTextAlignment(.trailing)
            }

            LabeledContent("主要对手") {
                Text(hostilePowerText)
                    .multilineTextAlignment(.trailing)
            }
        }
        .font(.caption)
    }

    private var countrySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("诸方势力")
                .font(.subheadline.weight(.semibold))

            ForEach(diplomacyState.countries) { country in
                CountryPowerRow(
                    country: country,
                    blocName: blocName(for: country.blocId),
                    isActive: country.faction == activeFaction
                )
            }
        }
    }

    private var blocSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("阵营名义")
                .font(.subheadline.weight(.semibold))

            ForEach(diplomacyState.blocs) { bloc in
                LabeledContent(bloc.name) {
                    Text("\(bloc.memberCountryIds.count) 方")
                        .foregroundStyle(bloc.faction == activeFaction ? .primary : .secondary)
                }
                .font(.caption)
            }
        }
    }

    private var relationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("战和关系")
                .font(.subheadline.weight(.semibold))

            if diplomacyState.relations.isEmpty {
                Text("暂无可见天下关系。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(diplomacyState.relations) { relation in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(countryName(for: relation.firstCountryId)) - \(countryName(for: relation.secondCountryId))")
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            Text("张力 \(relation.tension) / 第 \(relation.sinceTurn) 回合起")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(relation.status.displayName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(statusColor(for: relation.status))
                    }
                }
            }
        }
    }

    private func rulerSection(_ record: RulerDecisionRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("朝议/军议")
                .font(.subheadline.weight(.semibold))
            LabeledContent("主事") {
                Text(record.rulerAgentId)
            }
            LabeledContent("态势") {
                Text(record.posture.displayName)
            }
            if let zoneId = record.preferredFrontZoneId {
                LabeledContent("重心") {
                    Text(zoneId.rawValue)
                }
            }
            Text(record.rationale)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .font(.caption)
    }

    private var activeCountries: [CountryProfile] {
        diplomacyState.countries(for: activeFaction)
    }

    private var activeCountryIds: Set<CountryId> {
        Set(activeCountries.map(\.id))
    }

    private var activeRelations: [DiplomaticRelation] {
        diplomacyState.relations.filter { relation in
            activeCountryIds.contains(relation.firstCountryId) ||
                activeCountryIds.contains(relation.secondCountryId)
        }
    }

    private var hostileRelations: [DiplomaticRelation] {
        activeRelations.filter(\.status.isHostile)
    }

    private var activeCountryNames: String {
        let names = activeCountries.map(\.name)
        return names.isEmpty ? "未登记" : names.joined(separator: "、")
    }

    private var activeWarSupport: Int? {
        guard !activeCountries.isEmpty else {
            return nil
        }
        return activeCountries.reduce(0) { $0 + $1.warSupport } / activeCountries.count
    }

    private var hostilePowerText: String {
        var names: [String] = []
        for relation in hostileRelations {
            for countryId in [relation.firstCountryId, relation.secondCountryId]
                where !activeCountryIds.contains(countryId) {
                let name = countryName(for: countryId)
                if !names.contains(name) {
                    names.append(name)
                }
            }
        }
        return names.isEmpty ? "暂无公开敌对" : names.joined(separator: "、")
    }

    private var worldPressureText: String {
        switch hostileRelations.count {
        case 0:
            return activeFaction == .localNeutral ? "地方观望，受战事牵动" : "暂无公开战事"
        case 1:
            return "一线交锋"
        case 2:
            return "两面受压"
        default:
            return "多方交兵"
        }
    }

    private func countryName(for countryId: CountryId) -> String {
        diplomacyState.countries.first { $0.id == countryId }?.name ?? countryId.rawValue
    }

    private func blocName(for blocId: DiplomaticBlocId) -> String {
        diplomacyState.blocs.first { $0.id == blocId }?.name ?? blocId.rawValue
    }

    private func statusColor(for status: DiplomaticStatus) -> Color {
        switch status {
        case .atWar, .hostile:
            return .red
        case .allied, .coBelligerent, .vassal, .passage:
            return .green
        case .neutral, .truce:
            return .secondary
        }
    }
}

private struct CountryPowerRow: View {
    let country: CountryProfile
    let blocName: String
    let isActive: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(country.faction.mingBannerTint)
                .frame(width: 4, height: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(country.name)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text("\(country.faction.displayName) / \(blocName)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                ProgressView(value: Double(country.warSupport), total: 100)
                    .tint(country.faction.mingBannerTint)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text("战意")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(country.warSupport)")
                    .font(.caption.monospacedDigit().bold())
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, MingDesignTokens.compactSpacing)
        .background(isActive ? MingDesignTokens.subtleSeal : MingDesignTokens.sectionBackground.opacity(0.56), in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }
}

private struct WorldMandateBannerView: View {
    let faction: Faction
    let situationText: String
    let hostilePowerText: String
    let warSupport: Int?
    let courtSummary: CourtStrategySummary?

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack(alignment: .center, spacing: 10) {
                Text("势")
                    .font(.headline.bold())
                    .foregroundStyle(MingDesignTokens.cinnabar)
                    .frame(width: 36, height: 36)
                    .background(MingDesignTokens.subtleSeal)
                    .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(faction.displayName) 急势")
                        .font(.subheadline.bold())
                    Text("战局 \(situationText) / 对手 \(hostilePowerText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                if let warSupport {
                    MandateMetricView(label: "战意", value: "\(warSupport)")
                }
            }

            if let courtSummary {
                Label(courtSummary.recommendedFocus.displayName, systemImage: courtSummary.recommendedFocus.systemImageName)
                    .font(.caption.bold())
                    .foregroundStyle(MingDesignTokens.cinnabar)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 58), spacing: 6)], spacing: 6) {
                    CourtPressureBadge(label: "政策", value: courtSummary.policyPressure, tint: MingDesignTokens.jade)
                    CourtPressureBadge(label: "经济", value: courtSummary.economyPressure, tint: MingDesignTokens.imperialGold)
                    CourtPressureBadge(label: "科技", value: courtSummary.technologyPressure, tint: MingDesignTokens.porcelainBlue)
                    CourtPressureBadge(label: "军事", value: courtSummary.militaryPressure, tint: MingDesignTokens.cinnabar)
                }
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground.opacity(0.88), in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius)
                .stroke(MingDesignTokens.courtStroke.opacity(0.7), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct MandateMetricView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.monospacedDigit().bold())
        }
    }
}

private struct CourtPressureBadge: View {
    let label: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.16))
                    Capsule()
                        .fill(tint.opacity(0.85))
                        .frame(width: proxy.size.width * CGFloat(value) / 100)
                }
            }
            .frame(height: 4)
            Text("\(value)")
                .font(.caption2.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(MingDesignTokens.panelBackground.opacity(0.45), in: RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .combine)
    }
}
