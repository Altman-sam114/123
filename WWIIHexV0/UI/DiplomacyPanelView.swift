import SwiftUI

struct DiplomacyPanelView: View {
    let diplomacyState: DiplomacyState
    let activeFaction: Faction

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("天下局势", systemImage: "map")
                .font(.headline)

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
        .padding(12)
        .background(PlatformStyles.systemBackground)
        .clipShape(.rect(cornerRadius: 8))
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
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(country.name)
                            .font(.caption.weight(.semibold))
                        Text("\(country.faction.displayName) / \(country.blocId.rawValue)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("战意 \(country.warSupport)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(country.faction == activeFaction ? .primary : .secondary)
                }
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
