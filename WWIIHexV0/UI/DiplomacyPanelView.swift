import SwiftUI

struct DiplomacyPanelView: View {
    let diplomacyState: DiplomacyState
    let activeFaction: Faction
    let courtSummary: CourtStrategySummary?
    let objectiveSummary: BattleObjectiveSummary?

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
            worldOrderSection

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

    private var worldOrderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("天下牵引")
                .font(.subheadline.weight(.semibold))

            WorldOrderReadingRow(
                title: "战和格局",
                value: warRelationSummary,
                detail: hostilePowerText,
                systemImageName: "bolt.horizontal",
                tint: MingDesignTokens.cinnabar
            )

            if let objectiveContext = WorldObjectiveContext(summary: objectiveSummary) {
                WorldObjectiveSection(context: objectiveContext)
            }

            if let courtSummary {
                WorldOrderReadingRow(
                    title: "朝议牵引",
                    value: courtSummary.recommendedFocus.displayName,
                    detail: courtSummary.rationale,
                    systemImageName: courtSummary.recommendedFocus.systemImageName,
                    tint: policyFocusTint(courtSummary.recommendedFocus)
                )

                WorldOrderPressureStrip(summary: courtSummary)
            } else {
                WorldOrderReadingRow(
                    title: "朝议牵引",
                    value: "暂无朝议",
                    detail: "尚未形成政策、经济、科技、军事四线摘要。",
                    systemImageName: "scroll",
                    tint: MingDesignTokens.imperialGold
                )
            }

            if let diplomacySummary = latestDiplomacySummary {
                WorldOrderReadingRow(
                    title: "御前奏报",
                    value: "最新判断",
                    detail: diplomacySummary,
                    systemImageName: "seal",
                    tint: MingDesignTokens.porcelainBlue
                )
            }
        }
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
                BlocMandateRow(
                    bloc: bloc,
                    memberNames: bloc.memberCountryIds.map { countryName(for: $0) },
                    isActive: bloc.faction == activeFaction
                )
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
                    DiplomaticRelationRow(
                        relation: relation,
                        firstCountry: country(for: relation.firstCountryId),
                        secondCountry: country(for: relation.secondCountryId),
                        isActive: relation.containsActiveCountry(activeCountryIds),
                        statusTint: statusColor(for: relation.status)
                    )
                }
            }
        }
    }

    private func rulerSection(_ record: RulerDecisionRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("朝议/军议")
                .font(.subheadline.weight(.semibold))
            LabeledContent("主事") {
                Text(MingMapLabelFormat.agentTitle(record.rulerAgentId))
            }
            LabeledContent("态势") {
                Text(record.posture.displayName)
            }
            if let zoneId = record.preferredFrontZoneId {
                LabeledContent("重心") {
                    Text(MingMapLabelFormat.frontZoneTitle(zoneId))
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

    private var warRelationSummary: String {
        let hostileCount = diplomacyState.relations.filter(\.status.isHostile).count
        let truceCount = diplomacyState.relations.filter { $0.status == .truce }.count
        let passageCount = diplomacyState.relations.filter { $0.status == .passage }.count

        var parts: [String] = []
        parts.append("敌对 \(hostileCount)")
        if truceCount > 0 {
            parts.append("停战 \(truceCount)")
        }
        if passageCount > 0 {
            parts.append("借道 \(passageCount)")
        }
        return parts.joined(separator: " / ")
    }

    private var latestDiplomacySummary: String? {
        guard let summary = diplomacyState.latestRulerRecord?.diplomacySummary,
              !summary.isEmpty else {
            return nil
        }
        return summary
    }

    private func policyFocusTint(_ focus: CourtPolicyFocus) -> Color {
        switch focus {
        case .relief,
             .appeaseGentry,
             .trainMilitia:
            return MingDesignTokens.jade
        case .raiseTax,
             .agrarianReform,
             .grainTransport:
            return MingDesignTokens.imperialGold
        case .firearmReform,
             .redCannonMaintenance:
            return MingDesignTokens.porcelainBlue
        case .fortify:
            return MingDesignTokens.cinnabar
        }
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
        diplomacyState.countries.first { $0.id == countryId }?.name ?? MingMapLabelFormat.countryTitle(countryId)
    }

    private func country(for countryId: CountryId) -> CountryProfile? {
        diplomacyState.countries.first { $0.id == countryId }
    }

    private func blocName(for blocId: DiplomaticBlocId) -> String {
        diplomacyState.blocs.first { $0.id == blocId }?.name ?? MingMapLabelFormat.blocTitle(blocId)
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

private struct WorldOrderReadingRow: View {
    let title: String
    let value: String
    let detail: String
    let systemImageName: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImageName)
                .font(.caption.bold())
                .foregroundStyle(tint)
                .frame(width: 20, height: 20)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 5))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(title)
                        .font(.caption.bold())
                    Text(value)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, MingDesignTokens.compactSpacing)
        .padding(.vertical, 7)
        .background(MingDesignTokens.sectionBackground.opacity(0.56), in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }
}

private struct WorldOrderPressureStrip: View {
    let summary: CourtStrategySummary

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 58), spacing: 6)], spacing: 6) {
            CourtPressureBadge(label: "政策", value: summary.policyPressure, tint: MingDesignTokens.jade)
            CourtPressureBadge(label: "经济", value: summary.economyPressure, tint: MingDesignTokens.imperialGold)
            CourtPressureBadge(label: "科技", value: summary.technologyPressure, tint: MingDesignTokens.porcelainBlue)
            CourtPressureBadge(label: "军事", value: summary.militaryPressure, tint: MingDesignTokens.cinnabar)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct WorldObjectiveContext {
    let leaderTitle: String
    let leaderDetail: String
    let lineTitle: String
    let lineDetail: String
    let taskTitle: String
    let taskDetail: String
    let scoreRows: [BattleObjectiveSummary.ScoreRow]
    let lineTint: Color

    init?(summary: BattleObjectiveSummary?) {
        guard let summary, summary.isMingScenario else {
            return nil
        }

        let leadingRow = summary.leadingFaction.flatMap { faction in
            summary.scoreRows.first { $0.faction == faction }
        }
        let leaderName = summary.leadingFaction?.displayName ?? "未分胜势"
        leaderTitle = leadingRow.map { "\(leaderName) \($0.points)" } ?? leaderName
        leaderDetail = leadingRow.map { "控制要冲 \($0.objectiveCount) 处，当前只作天下态势读数。" } ?? "要冲分尚未拉开。"

        let line = Self.urgentLine(in: summary)
        lineTitle = line?.title ?? "五线待察"
        lineDetail = line.map { "\($0.line.displayName) · \($0.status.displayName) · 压力 \($0.pressure)" } ?? "暂无告急五线。"
        lineTint = Self.tint(for: line?.status)

        let task = summary.tasks.sorted(by: Self.taskSort).first
        let target = task?.targetObjectiveId.flatMap { objectiveId in
            summary.tracks.flatMap(\.targets).first { $0.objectiveId == objectiveId }
        }
        taskTitle = task?.title ?? "本旬候报"
        if let task, let target {
            taskDetail = "\(task.line.displayName) · \(task.priority.displayName) · \(target.name) · \(target.controllerName)"
        } else if let task {
            taskDetail = "\(task.line.displayName) · \(task.priority.displayName)"
        } else {
            taskDetail = "暂无急务或主线任务。"
        }

        scoreRows = Array(summary.scoreRows.prefix(5))
    }

    private static func urgentLine(in summary: BattleObjectiveSummary) -> BattleObjectiveSummary.CampaignLineBrief? {
        summary.lineBriefs.sorted {
            if $0.status != $1.status {
                return statusRank($0.status) < statusRank($1.status)
            }
            return $0.pressure > $1.pressure
        }.first
    }

    private static func taskSort(_ lhs: BattleObjectiveSummary.CampaignTask, _ rhs: BattleObjectiveSummary.CampaignTask) -> Bool {
        if lhs.priority.sortRank == rhs.priority.sortRank {
            return lhs.title < rhs.title
        }
        return lhs.priority.sortRank < rhs.priority.sortRank
    }

    private static func statusRank(_ status: BattleObjectiveSummary.CampaignStageStatus) -> Int {
        switch status {
        case .warning:
            return 0
        case .focus:
            return 1
        case .watch:
            return 2
        case .achieved:
            return 3
        }
    }

    private static func tint(for status: BattleObjectiveSummary.CampaignStageStatus?) -> Color {
        switch status {
        case .warning:
            return MingDesignTokens.cinnabar
        case .focus:
            return MingDesignTokens.imperialGold
        case .watch:
            return MingDesignTokens.porcelainBlue
        case .achieved:
            return MingDesignTokens.jade
        case nil:
            return .secondary
        }
    }
}

private struct WorldObjectiveSection: View {
    let context: WorldObjectiveContext

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            WorldOrderReadingRow(
                title: "天下棋势",
                value: context.leaderTitle,
                detail: context.leaderDetail,
                systemImageName: "globe.asia.australia",
                tint: MingDesignTokens.imperialGold
            )

            WorldOrderReadingRow(
                title: "最急五线",
                value: context.lineTitle,
                detail: context.lineDetail,
                systemImageName: "exclamationmark.triangle",
                tint: context.lineTint
            )

            WorldOrderReadingRow(
                title: "本旬落点",
                value: context.taskTitle,
                detail: context.taskDetail,
                systemImageName: "scope",
                tint: MingDesignTokens.porcelainBlue
            )

            if !context.scoreRows.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 6)], spacing: 6) {
                    ForEach(context.scoreRows) { row in
                        WorldObjectiveScoreChip(row: row)
                    }
                }
                .accessibilityElement(children: .contain)
            }
        }
    }
}

private struct WorldObjectiveScoreChip: View {
    let row: BattleObjectiveSummary.ScoreRow

    var body: some View {
        HStack(spacing: 6) {
            MingFactionFlagBadge(faction: row.faction)

            VStack(alignment: .leading, spacing: 1) {
                Text(row.faction.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text("\(row.points) / \(row.objectiveCount)")
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(row.faction.mingBannerTint)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MingDesignTokens.sectionBackground.opacity(0.56), in: RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .combine)
    }
}

private struct CountryPowerRow: View {
    let country: CountryProfile
    let blocName: String
    let isActive: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            MingFactionFlagBadge(faction: country.faction)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(country.name)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)

                    if country.isPrimaryBelligerent {
                        Label("主战", systemImage: "flag.fill")
                            .font(.caption2.bold())
                            .foregroundStyle(country.faction.mingBannerTint)
                            .lineLimit(1)
                    }
                }

                Text("\(country.faction.displayName) / \(blocName)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                ProgressView(value: Double(country.warSupport), total: 100)
                    .tint(country.faction.mingBannerTint)

                if country.surrenderProgress > 0 {
                    Text("离散 \(country.surrenderProgress)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(MingDesignTokens.cinnabar)
                }
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

private struct DiplomaticRelationRow: View {
    let relation: DiplomaticRelation
    let firstCountry: CountryProfile?
    let secondCountry: CountryProfile?
    let isActive: Bool
    let statusTint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                relationSide(country: firstCountry, fallback: MingMapLabelFormat.countryTitle(relation.firstCountryId))

                Image(systemName: relation.status.isHostile ? "bolt.horizontal.fill" : "arrow.left.arrow.right")
                    .font(.caption.bold())
                    .foregroundStyle(statusTint)
                    .frame(width: 20)
                    .accessibilityHidden(true)

                relationSide(country: secondCountry, fallback: MingMapLabelFormat.countryTitle(relation.secondCountryId))

                Spacer(minLength: 8)

                Text(relation.status.displayName)
                    .font(.caption.bold())
                    .foregroundStyle(statusTint)
                    .lineLimit(1)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(statusTint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
            }

            HStack(spacing: 8) {
                Text("张力 \(relation.tension)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 54, alignment: .leading)

                ProgressView(value: Double(relation.tension), total: 100)
                    .tint(statusTint)

                Text("第 \(relation.sinceTurn) 回合")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, MingDesignTokens.compactSpacing)
        .padding(.vertical, 7)
        .background(isActive ? MingDesignTokens.subtleSeal : MingDesignTokens.sectionBackground.opacity(0.56), in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius)
                .stroke(statusTint.opacity(relation.status.isHostile ? 0.38 : 0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private func relationSide(country: CountryProfile?, fallback: String) -> some View {
        HStack(spacing: 5) {
            if let country {
                MingFactionFlagBadge(faction: country.faction)
                Text(country.name)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            } else {
                Text(fallback)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BlocMandateRow: View {
    let bloc: DiplomaticBloc
    let memberNames: [String]
    let isActive: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            MingFactionFlagBadge(faction: bloc.faction)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(bloc.name)
                        .font(.caption.bold())
                        .lineLimit(1)

                    if isActive {
                        Text("当前")
                            .font(.caption2.bold())
                            .foregroundStyle(bloc.faction.mingBannerTint)
                            .lineLimit(1)
                    }
                }

                Text(memberSummary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Text("\(bloc.memberCountryIds.count) 方")
                .font(.caption.monospacedDigit().bold())
                .foregroundStyle(isActive ? bloc.faction.mingBannerTint : .secondary)
        }
        .padding(.horizontal, MingDesignTokens.compactSpacing)
        .padding(.vertical, 7)
        .background(isActive ? MingDesignTokens.subtleSeal : MingDesignTokens.sectionBackground.opacity(0.56), in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }

    private var memberSummary: String {
        memberNames.isEmpty ? "未登记成员" : memberNames.joined(separator: "、")
    }
}

private extension DiplomaticRelation {
    func containsActiveCountry(_ activeCountryIds: Set<CountryId>) -> Bool {
        activeCountryIds.contains(firstCountryId) || activeCountryIds.contains(secondCountryId)
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
