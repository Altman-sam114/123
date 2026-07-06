import SwiftUI

struct CourtPanelView: View {
    let gameState: GameState
    let playerFaction: Faction
    let observerModeEnabled: Bool
    let onEnactProject: (CourtProjectKind) -> Void

    var body: some View {
        let summary = CourtStrategySummary.from(faction: gameState.activeFaction, state: gameState)
        let objectiveSummary = BattleObjectiveSummary.from(state: gameState)

        VStack(alignment: .leading, spacing: MingDesignTokens.sectionSpacing) {
            CourtHeaderView(faction: gameState.activeFaction, focus: summary.recommendedFocus)
            CourtCouncilBriefSection(
                summary: summary,
                recommendedProject: CourtProjectKind(focus: summary.recommendedFocus)
            )
            CourtPolicyTicketSection(
                summary: summary,
                recommendedProject: CourtProjectKind(focus: summary.recommendedFocus),
                lineBriefs: objectiveSummary.isMingScenario ? objectiveSummary.lineBriefs : []
            )
            CourtRationaleView(summary: summary)
            CourtCampaignLineSection(
                briefs: objectiveSummary.isMingScenario ? objectiveSummary.lineBriefs : []
            )
            CourtPressureSection(summary: summary)
            CourtDebateSection(summary: summary)
            CourtProjectSection(
                summary: summary,
                recommendedProject: CourtProjectKind(focus: summary.recommendedFocus),
                canEnact: canEnact,
                onEnactProject: onEnactProject
            )
            CourtSecondaryFocusSection(focuses: summary.secondaryFocuses)
            CourtMetricsGrid(summary: summary)
        }
        .padding(MingDesignTokens.panelPadding)
        .background(MingDesignTokens.panelBackground)
        .overlay {
            RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius)
                .stroke(MingDesignTokens.courtStroke, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }

    private func canEnact(_ kind: CourtProjectKind) -> Bool {
        !observerModeEnabled &&
            gameState.activeFaction == playerFaction &&
            gameState.phase.allowsHumanCommands &&
            gameState.economyState.ledger(for: gameState.activeFaction).stockpile.canAfford(kind.cost)
    }
}

private struct CourtHeaderView: View {
    let faction: Faction
    let focus: CourtPolicyFocus

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text("朝")
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
                Text("\(faction.displayName) 朝议")
                    .font(.headline)
                Label(focus.displayName, systemImage: focus.systemImageName)
                    .font(.subheadline)
                    .foregroundStyle(MingDesignTokens.cinnabar)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct CourtRationaleView: View {
    let summary: CourtStrategySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("主议")
                .font(.subheadline.bold())
            Text(summary.rationale)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MingDesignTokens.panelPadding)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }
}

private struct CourtCouncilBriefSection: View {
    let summary: CourtStrategySummary
    let recommendedProject: CourtProjectKind

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("朝议总纲")
                        .font(.subheadline.bold())
                        .foregroundStyle(MingDesignTokens.ink)

                    Text("主议 \(summary.recommendedFocus.displayName) · \(recommendedProject.domainDisplayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                Spacer(minLength: 8)

                CourtCouncilSeal(title: leadingDomain.displayName, value: leadingPressure, tint: leadingDomain.tint)
            }

            Text(summary.displaySummary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 94), spacing: 6)], alignment: .leading, spacing: 6) {
                ForEach(signals) { signal in
                    CourtCouncilPressureChip(signal: signal)
                }
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius)
                .stroke(leadingDomain.tint.opacity(0.26), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var signals: [CourtCouncilPressureSignal] {
        CourtProjectDomain.allCases.map { domain in
            CourtCouncilPressureSignal(
                domain: domain,
                value: pressure(for: domain),
                isPrimary: recommendedProject.domains.contains(domain)
            )
        }
    }

    private var leadingDomain: CourtProjectDomain {
        signals.max {
            if $0.value == $1.value {
                return $0.domain.rawValue > $1.domain.rawValue
            }
            return $0.value < $1.value
        }?.domain ?? recommendedProject.primaryDomain
    }

    private var leadingPressure: Int {
        pressure(for: leadingDomain)
    }

    private func pressure(for domain: CourtProjectDomain) -> Int {
        switch domain {
        case .policy:
            return summary.policyPressure
        case .economy:
            return summary.economyPressure
        case .technology:
            return summary.technologyPressure
        case .military:
            return summary.militaryPressure
        }
    }
}

private struct CourtCouncilPressureSignal: Identifiable {
    let domain: CourtProjectDomain
    let value: Int
    let isPrimary: Bool

    var id: CourtProjectDomain {
        domain
    }
}

private struct CourtCouncilSeal: View {
    let title: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text("\(value)")
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(tint)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(minWidth: 54)
        .background(MingDesignTokens.panelBackground.opacity(0.66), in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct CourtCouncilPressureChip: View {
    let signal: CourtCouncilPressureSignal

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Label(signal.domain.displayName, systemImage: signal.domain.systemImageName)
                    .font(.caption2.bold())
                    .foregroundStyle(signal.domain.tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 4)

                if signal.isPrimary {
                    Text("主")
                        .font(.caption2.bold())
                        .foregroundStyle(MingDesignTokens.cinnabar)
                        .lineLimit(1)
                }
            }

            ProgressView(value: Double(signal.value), total: 100)
                .tint(signal.domain.tint)

            Text("势 \(signal.value)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .background(MingDesignTokens.panelBackground.opacity(signal.isPrimary ? 0.78 : 0.52), in: RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(signal.domain.tint.opacity(signal.isPrimary ? 0.42 : 0.18), lineWidth: 1)
        }
    }
}

private struct CourtPolicyTicketSection: View {
    let summary: CourtStrategySummary
    let recommendedProject: CourtProjectKind
    let lineBriefs: [BattleObjectiveSummary.CampaignLineBrief]

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Label("朝议批票", systemImage: "checkmark.seal")
                    .font(.subheadline.bold())
                    .foregroundStyle(primaryDomain.tint)

                Spacer(minLength: 8)

                Text(ticketStatus)
                    .font(.caption.bold())
                    .foregroundStyle(primaryDomain.tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Text(ticketSummary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: 7)], alignment: .leading, spacing: 7) {
                CourtPolicyTicketChip(
                    title: "票拟",
                    value: recommendedProject.displayName,
                    detail: recommendedProject.domainDisplayName,
                    systemImage: recommendedProject.systemImageName,
                    tint: primaryDomain.tint
                )
                CourtPolicyTicketChip(
                    title: leadingDomain.displayName,
                    value: "\(leadingPressure)",
                    detail: "四线最高",
                    systemImage: leadingDomain.systemImageName,
                    tint: leadingDomain.tint
                )
                CourtPolicyTicketChip(
                    title: "战役",
                    value: leadingLineTitle,
                    detail: leadingLineDetail,
                    systemImage: leadingLineSystemImage,
                    tint: leadingLineTint
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("耗 \(recommendedProject.cost.compactDisplaySummary)\(gainText)")
                    .font(.caption.bold())
                    .foregroundStyle(primaryDomain.tint)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(recommendedProject.benefitSummary) 风险：\(recommendedProject.riskSummary)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius)
                .stroke(primaryDomain.tint.opacity(0.28), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var primaryDomain: CourtProjectDomain {
        recommendedProject.primaryDomain
    }

    private var leadingDomain: CourtProjectDomain {
        CourtProjectDomain.allCases.max {
            let lhs = pressure(for: $0)
            let rhs = pressure(for: $1)
            if lhs == rhs {
                return $0.rawValue > $1.rawValue
            }
            return lhs < rhs
        } ?? primaryDomain
    }

    private var leadingPressure: Int {
        pressure(for: leadingDomain)
    }

    private var urgentLine: BattleObjectiveSummary.CampaignLineBrief? {
        lineBriefs.max {
            if $0.urgentTaskCount == $1.urgentTaskCount {
                if $0.pressure == $1.pressure {
                    return $0.line.rawValue > $1.line.rawValue
                }
                return $0.pressure < $1.pressure
            }
            return $0.urgentTaskCount < $1.urgentTaskCount
        }
    }

    private var leadingLineTitle: String {
        urgentLine?.line.displayName ?? "待察"
    }

    private var leadingLineDetail: String {
        guard let urgentLine else {
            return "无明末战役线"
        }
        if urgentLine.urgentTaskCount > 0 {
            return "急务 \(urgentLine.urgentTaskCount)"
        }
        if urgentLine.activeTaskCount > 0 {
            return "主线 \(urgentLine.activeTaskCount)"
        }
        return "势 \(urgentLine.pressure)"
    }

    private var leadingLineSystemImage: String {
        urgentLine?.line.systemImage ?? "eye"
    }

    private var leadingLineTint: Color {
        guard let urgentLine else {
            return .secondary
        }
        switch urgentLine.line {
        case .world:
            return MingDesignTokens.cinnabar
        case .policy:
            return MingDesignTokens.jade
        case .economy:
            return MingDesignTokens.imperialGold
        case .technology:
            return MingDesignTokens.porcelainBlue
        case .military:
            return MingDesignTokens.ink
        }
    }

    private var gainText: String {
        recommendedProject.resourceGain.isEmpty ? "" : " / 得 \(recommendedProject.resourceGain.compactDisplaySummary)"
    }

    private var ticketStatus: String {
        if leadingPressure >= 75 || (urgentLine?.urgentTaskCount ?? 0) > 0 {
            return "急批"
        }
        if recommendedProject.domains.count > 1 {
            return "兼线"
        }
        return "可行"
    }

    private var ticketSummary: String {
        let lineClause: String
        if let urgentLine {
            lineClause = "\(urgentLine.line.displayName)线\(urgentLine.status.displayName)，\(urgentLine.detail)"
        } else {
            lineClause = "暂无明末战役线急报"
        }
        return "据四线压力，\(leadingDomain.displayName)最急；据天下态势，\(lineClause)。本旬票拟 \(recommendedProject.displayName)，只作朝廷扫读，不自动执行。"
    }

    private func pressure(for domain: CourtProjectDomain) -> Int {
        switch domain {
        case .policy:
            return summary.policyPressure
        case .economy:
            return summary.economyPressure
        case .technology:
            return summary.technologyPressure
        case .military:
            return summary.militaryPressure
        }
    }
}

private struct CourtPolicyTicketChip: View {
    let title: String
    let value: String
    let detail: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: systemImage)
                .font(.caption2.bold())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Text(value)
                .font(.caption.bold())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.74)

            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .background(MingDesignTokens.panelBackground.opacity(0.58), in: RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(tint.opacity(0.2), lineWidth: 1)
        }
    }
}

private struct CourtCampaignLineSection: View {
    let briefs: [BattleObjectiveSummary.CampaignLineBrief]

    var body: some View {
        if !briefs.isEmpty {
            VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
                HStack(alignment: .firstTextBaseline) {
                    Text("天下五线态势")
                        .font(.subheadline.bold())
                        .foregroundStyle(MingDesignTokens.ink)
                    Spacer(minLength: 8)
                    Text("战役来源")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 128), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(briefs) { brief in
                        CourtCampaignLineCard(brief: brief)
                    }
                }
            }
            .padding(MingDesignTokens.compactSpacing)
            .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        }
    }
}

private struct CourtCampaignLineCard: View {
    let brief: BattleObjectiveSummary.CampaignLineBrief

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 6) {
                Label(brief.line.displayName, systemImage: brief.line.systemImage)
                    .font(.caption.bold())
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 4)

                Label(brief.status.displayName, systemImage: statusSystemImage)
                    .font(.caption.bold())
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            ProgressView(value: Double(brief.pressure), total: 100)
                .tint(tint)

            HStack(spacing: 6) {
                Text("势 \(brief.pressure)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                if brief.urgentTaskCount > 0 {
                    Text("急 \(brief.urgentTaskCount)")
                        .font(.caption.bold())
                        .foregroundStyle(MingDesignTokens.cinnabar)
                } else if brief.activeTaskCount > 0 {
                    Text("事 \(brief.activeTaskCount)")
                        .font(.caption.bold())
                        .foregroundStyle(tint)
                }
            }

            Text(brief.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MingDesignTokens.panelBackground.opacity(0.52), in: RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(tint.opacity(brief.status == .warning ? 0.45 : 0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var statusSystemImage: String {
        switch brief.status {
        case .warning:
            return "exclamationmark.triangle"
        case .focus:
            return "scope"
        case .achieved:
            return "checkmark.seal"
        case .watch:
            return "eye"
        }
    }

    private var tint: Color {
        switch brief.line {
        case .world:
            return MingDesignTokens.cinnabar
        case .policy:
            return MingDesignTokens.jade
        case .economy:
            return MingDesignTokens.imperialGold
        case .technology:
            return MingDesignTokens.porcelainBlue
        case .military:
            return MingDesignTokens.ink
        }
    }
}

private struct CourtPressureSection: View {
    let summary: CourtStrategySummary

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            Text("四线压力")
                .font(.subheadline.bold())

            CourtPressureRow(
                title: "政策",
                value: summary.policyPressure,
                detail: "民变 / 行政",
                systemImage: "scroll",
                tint: MingDesignTokens.jade
            )
            CourtPressureRow(
                title: "经济",
                value: summary.economyPressure,
                detail: "银两 / 民力 / 粮草",
                systemImage: "banknote",
                tint: MingDesignTokens.imperialGold
            )
            CourtPressureRow(
                title: "科技",
                value: summary.technologyPressure,
                detail: "火器 / 炮队",
                systemImage: "scope",
                tint: MingDesignTokens.porcelainBlue
            )
            CourtPressureRow(
                title: "军事",
                value: summary.militaryPressure,
                detail: "前线 / 缺粮 / 被围",
                systemImage: "shield",
                tint: MingDesignTokens.cinnabar
            )
        }
    }
}

private struct CourtPressureRow: View {
    let title: String
    let value: Int
    let detail: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.caption.bold())
                Spacer()
                Text("\(value)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: Double(value), total: 100)
                .tint(tint)

            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct CourtSecondaryFocusSection: View {
    let focuses: [CourtPolicyFocus]

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            Text("备议")
                .font(.subheadline.bold())

            if focuses.isEmpty {
                Text("暂无备议。")
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(focuses) { focus in
                    CourtFocusRow(focus: focus)
                }
            }
        }
    }
}

private struct CourtDebateSection: View {
    let summary: CourtStrategySummary

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack(alignment: .firstTextBaseline) {
                Text("朝议争点")
                    .font(.subheadline.bold())
                Spacer(minLength: 8)
                Text(summary.recommendedFocus.displayName)
                    .font(.caption.bold())
                    .foregroundStyle(MingDesignTokens.cinnabar)
            }

            ForEach(debates) { debate in
                CourtDebateRow(debate: debate)
            }
        }
    }

    private var debates: [CourtDebateItem] {
        [
            CourtDebateItem(
                id: "policy-economy",
                title: "安民与征饷",
                systemImage: "scale.3d",
                tint: summary.policyPressure >= summary.economyPressure ? MingDesignTokens.jade : MingDesignTokens.imperialGold,
                leadingTitle: "民变",
                leadingValue: summary.policyPressure,
                leadingDetail: "不稳州府 \(summary.unstableRegions)",
                trailingTitle: "军费",
                trailingValue: summary.economyPressure,
                trailingDetail: "可控州府 \(summary.controlledRegions)",
                verdict: summary.policyPressure >= summary.economyPressure ? "先稳地方" : "先补军费"
            ),
            CourtDebateItem(
                id: "technology-military",
                title: "火器与团练",
                systemImage: "scope",
                tint: summary.technologyPressure >= summary.militaryPressure ? MingDesignTokens.porcelainBlue : MingDesignTokens.cinnabar,
                leadingTitle: "军械",
                leadingValue: summary.technologyPressure,
                leadingDetail: "火器/炮队 \(summary.fireSupportUnits)",
                trailingTitle: "前线",
                trailingValue: summary.militaryPressure,
                trailingDetail: "接战 \(summary.activeFronts)",
                verdict: summary.technologyPressure >= summary.militaryPressure ? "先整火器" : "先固军伍"
            ),
            CourtDebateItem(
                id: "grain-fortress",
                title: "粮道与城防",
                systemImage: "shippingbox",
                tint: summary.economyPressure >= summary.militaryPressure ? MingDesignTokens.imperialGold : MingDesignTokens.cinnabar,
                leadingTitle: "粮饷",
                leadingValue: summary.economyPressure,
                leadingDetail: "银粮压力 \(summary.economyPressure)",
                trailingTitle: "城关",
                trailingValue: summary.militaryPressure,
                trailingDetail: "军事压力 \(summary.militaryPressure)",
                verdict: summary.economyPressure >= summary.militaryPressure ? "先保粮台" : "先守要冲"
            )
        ]
    }
}

private struct CourtDebateItem: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let tint: Color
    let leadingTitle: String
    let leadingValue: Int
    let leadingDetail: String
    let trailingTitle: String
    let trailingValue: Int
    let trailingDetail: String
    let verdict: String
}

private struct CourtDebateRow: View {
    let debate: CourtDebateItem

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .center, spacing: 8) {
                Label(debate.title, systemImage: debate.systemImage)
                    .font(.caption.bold())
                    .foregroundStyle(debate.tint)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(debate.verdict)
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            HStack(alignment: .top, spacing: MingDesignTokens.compactSpacing) {
                CourtDebateMetric(
                    title: debate.leadingTitle,
                    value: debate.leadingValue,
                    detail: debate.leadingDetail,
                    tint: debate.tint
                )
                CourtDebateMetric(
                    title: debate.trailingTitle,
                    value: debate.trailingValue,
                    detail: debate.trailingDetail,
                    tint: debate.tint
                )
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }
}

private struct CourtDebateMetric: View {
    let title: String
    let value: Int
    let detail: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 4)
                Text("\(value)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: Double(value), total: 100)
                .tint(tint)

            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CourtProjectSection: View {
    let summary: CourtStrategySummary
    let recommendedProject: CourtProjectKind
    let canEnact: (CourtProjectKind) -> Bool
    let onEnactProject: (CourtProjectKind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            Text("四线项目")
                .font(.subheadline.bold())

            ForEach(CourtProjectDomain.allCases) { domain in
                CourtProjectDomainGroup(
                    domain: domain,
                    pressure: pressure(for: domain),
                    projects: projects(for: domain),
                    recommendedProject: recommendedProject,
                    canEnact: canEnact,
                    onEnactProject: onEnactProject
                )
            }
        }
    }

    private var orderedProjects: [CourtProjectKind] {
        [recommendedProject] + CourtProjectKind.allCases.filter { $0 != recommendedProject }
    }

    private func projects(for domain: CourtProjectDomain) -> [CourtProjectKind] {
        orderedProjects.filter { $0.domains.contains(domain) }
    }

    private func pressure(for domain: CourtProjectDomain) -> Int {
        switch domain {
        case .policy:
            return summary.policyPressure
        case .economy:
            return summary.economyPressure
        case .technology:
            return summary.technologyPressure
        case .military:
            return summary.militaryPressure
        }
    }
}

private struct CourtProjectDomainGroup: View {
    let domain: CourtProjectDomain
    let pressure: Int
    let projects: [CourtProjectKind]
    let recommendedProject: CourtProjectKind
    let canEnact: (CourtProjectKind) -> Bool
    let onEnactProject: (CourtProjectKind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Label(domain.displayName, systemImage: domain.systemImageName)
                    .font(.caption.bold())
                    .foregroundStyle(domain.tint)
                Spacer()
                Text("压力 \(pressure)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Text(domain.agendaDetail)
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(projects) { project in
                CourtProjectRow(
                    project: project,
                    isRecommended: project == recommendedProject,
                    isEnabled: canEnact(project),
                    onEnactProject: onEnactProject
                )
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }
}

private struct CourtProjectRow: View {
    let project: CourtProjectKind
    let isRecommended: Bool
    let isEnabled: Bool
    let onEnactProject: (CourtProjectKind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Button(action: enactProject) {
                Label(project.displayName, systemImage: project.systemImageName)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .frame(minHeight: MingDesignTokens.minimumTapSize)
            .disabled(!isEnabled)
            .accessibilityHint(isRecommended ? "当前主议项目" : project.domainDisplayName)

            Text(detailText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, MingDesignTokens.compactSpacing)
        .background(isRecommended ? MingDesignTokens.subtleSeal : MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }

    private func enactProject() {
        onEnactProject(project)
    }

    private var detailText: String {
        let gain = project.resourceGain.isEmpty ? "" : " / 得 \(project.resourceGain.compactDisplaySummary)"
        let tag = isRecommended ? "主议 / " : ""
        let domainTag = project.domains.count > 1 ? "兼线 \(project.domainDisplayName)" : project.domainDisplayName
        return "\(tag)\(domainTag) / 耗 \(project.cost.compactDisplaySummary)\(gain)。\(project.benefitSummary) 风险：\(project.riskSummary)"
    }
}

private struct CourtFocusRow: View {
    let focus: CourtPolicyFocus

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(focus.displayName, systemImage: focus.systemImageName)
                .font(.caption.bold())
                .foregroundStyle(.primary)
            Text("\(focus.domainDisplayName)：\(focus.benefitSummary) 风险：\(focus.riskSummary)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}

private struct CourtMetricsGrid: View {
    let summary: CourtStrategySummary

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), spacing: 8)], alignment: .leading, spacing: 8) {
            CourtMetricView(label: "州府", value: summary.controlledRegions, systemImage: "building.columns")
            CourtMetricView(label: "不稳", value: summary.unstableRegions, systemImage: "flame")
            CourtMetricView(label: "火器/炮队", value: summary.fireSupportUnits, systemImage: "scope")
            CourtMetricView(label: "前线", value: summary.activeFronts, systemImage: "point.topleft.down.curvedto.point.bottomright.up")
        }
    }
}

private struct CourtMetricView: View {
    let label: String
    let value: Int
    let systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(value)")
                    .font(.subheadline.bold())
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(MingDesignTokens.cinnabar)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }
}

private extension CourtProjectKind {
    init(focus: CourtPolicyFocus) {
        switch focus {
        case .raiseTax:
            self = .raiseTax
        case .relief:
            self = .relief
        case .appeaseGentry:
            self = .appeaseGentry
        case .agrarianReform:
            self = .agrarianReform
        case .fortify:
            self = .fortify
        case .trainMilitia:
            self = .trainMilitia
        case .firearmReform:
            self = .firearmReform
        case .redCannonMaintenance:
            self = .redCannonMaintenance
        case .grainTransport:
            self = .grainTransport
        }
    }
}

private extension CourtProjectDomain {
    var tint: Color {
        switch self {
        case .policy:
            return MingDesignTokens.jade
        case .economy:
            return MingDesignTokens.imperialGold
        case .technology:
            return MingDesignTokens.porcelainBlue
        case .military:
            return MingDesignTokens.cinnabar
        }
    }
}
