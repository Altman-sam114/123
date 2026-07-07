import SwiftUI

struct EconomyPanelView: View {
    let gameState: GameState
    let playerFaction: Faction
    let observerModeEnabled: Bool
    let onQueueProduction: (ProductionKind) -> Void

    var body: some View {
        let faction = gameState.activeFaction
        let ledger = gameState.economyState.ledger(for: faction)
        let governance = GovernanceAISummary.from(faction: faction, map: gameState.map)
        let courtSummary = CourtStrategySummary.from(faction: faction, state: gameState)
        let objectiveSummary = BattleObjectiveSummary.from(state: gameState)
        let divisions = gameState.divisions.filter { $0.faction == faction && !$0.isDestroyed }

        VStack(alignment: .leading, spacing: 10) {
            TreasuryHeader(
                faction: faction,
                canAct: canActForCurrentFaction,
                observerModeEnabled: observerModeEnabled
            )
            TreasuryStockpileSection(ledger: ledger)
            TreasuryFlowSection(ledger: ledger)
            TreasuryFourLineSection(ledger: ledger, summary: courtSummary)
            TreasuryWorldPolicySection(
                ledger: ledger,
                courtSummary: courtSummary,
                objectiveSummary: objectiveSummary
            )
            TreasuryFamineRiskSection(
                ledger: ledger,
                governance: governance,
                divisions: divisions
            )
            TreasuryMilitaryPaySection(
                ledger: ledger,
                governance: governance,
                divisions: divisions
            )
            TreasuryGovernanceSection(governance: governance)
            ProductionActionSection(
                ledger: ledger,
                canAct: canActForCurrentFaction,
                observerModeEnabled: observerModeEnabled,
                canQueue: canQueue,
                onQueueProduction: onQueueProduction
            )
            ProductionQueueSection(queue: ledger.productionQueue)
        }
        .padding(MingDesignTokens.panelPadding)
        .background(MingDesignTokens.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }

    private var canActForCurrentFaction: Bool {
        !observerModeEnabled &&
            gameState.activeFaction == playerFaction &&
            gameState.phase.allowsHumanCommands
    }

    private func canQueue(_ kind: ProductionKind) -> Bool {
        canActForCurrentFaction &&
            gameState.economyState.ledger(for: gameState.activeFaction).stockpile.canAfford(kind.cost)
    }
}

private struct TreasuryHeader: View {
    let faction: Faction
    let canAct: Bool
    let observerModeEnabled: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text("库")
                .font(.title3.bold())
                .foregroundStyle(MingDesignTokens.imperialGold)
                .frame(width: 44, height: 44)
                .background(MingDesignTokens.subtleSeal)
                .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius)
                        .stroke(MingDesignTokens.imperialGold.opacity(0.46), lineWidth: 1)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("\(faction.displayName) 府库")
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text("民力、银两、粮草与募兵筹粮")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 8)

            TreasuryStatusBadge(
                title: statusTitle,
                tint: canAct ? MingDesignTokens.jade : .secondary
            )
        }
        .accessibilityElement(children: .combine)
    }

    private var statusTitle: String {
        if observerModeEnabled {
            return "观战"
        }
        return canAct ? "可下令" : "待本方"
    }
}

private struct TreasuryStatusBadge: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.caption.bold())
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct TreasuryStockpileSection: View {
    let ledger: FactionEconomyLedger

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("府库总账", systemImage: "banknote")
                .font(.caption.bold())
                .foregroundStyle(MingDesignTokens.imperialGold)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 78), spacing: 6)], alignment: .leading, spacing: 6) {
                TreasuryResourceBadge(title: "民力", value: ledger.stockpile.manpower, detail: "可征调", tint: MingDesignTokens.jade)
                TreasuryResourceBadge(title: "银两", value: ledger.stockpile.industry, detail: "军费", tint: MingDesignTokens.imperialGold)
                TreasuryResourceBadge(title: "粮草", value: ledger.stockpile.supplies, detail: "军粮", tint: MingDesignTokens.porcelainBlue)
            }

            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 5) {
                TreasuryInfoRow(label: "本回合入账", value: ledger.lastIncome.compactDisplaySummary)
                TreasuryInfoRow(label: "军粮维护", value: "粮 \(ledger.lastUpkeep.supplies)")
                TreasuryInfoRow(label: "补员消耗", value: ledger.lastReinforcementSpend.compactDisplaySummary)
                TreasuryInfoRow(label: "更新时间", value: "第 \(ledger.lastUpdatedTurn) 回合")
            }
            .padding(.top, 4)
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }
}

private struct TreasuryResourceBadge: View {
    let title: String
    let value: Int
    let detail: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text("\(value)")
                .font(.title3.bold())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MingDesignTokens.panelBackground.opacity(0.52), in: RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .combine)
    }
}

private struct TreasuryInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        GridRow {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
    }
}

private struct TreasuryFlowSection: View {
    let ledger: FactionEconomyLedger

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack(alignment: .firstTextBaseline) {
                Label("收支急报", systemImage: pressureSystemImageName)
                    .font(.caption.bold())
                    .foregroundStyle(pressureTint)
                Spacer(minLength: 8)
                Text(pressureStatus.title)
                    .font(.caption.bold())
                    .foregroundStyle(pressureTint)
                    .lineLimit(1)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 78), spacing: 6)], alignment: .leading, spacing: 6) {
                TreasuryNetBadge(title: "净民力", value: netManpower, tint: MingDesignTokens.jade)
                TreasuryNetBadge(title: "净银两", value: netIndustry, tint: MingDesignTokens.imperialGold)
                TreasuryNetBadge(title: "净粮草", value: netSupplies, tint: supplyTint)
                TreasuryNetBadge(title: "营造", value: ledger.productionQueue.count, suffix: "项", tint: queueTint)
            }

            Text(flowDetail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }

    private var netManpower: Int {
        ledger.lastIncome.manpower - ledger.lastReinforcementSpend.manpower
    }

    private var netIndustry: Int {
        ledger.lastIncome.industry - ledger.lastReinforcementSpend.industry
    }

    private var netSupplies: Int {
        ledger.lastIncome.supplies - ledger.lastUpkeep.supplies - ledger.lastReinforcementSpend.supplies
    }

    private var readyOrders: Int {
        ledger.productionQueue.filter(\.isReady).count
    }

    private var pressureStatus: TreasuryPressureStatus {
        if netSupplies < 0 {
            return .grain
        }
        if netIndustry < 0 || netManpower < 0 {
            return .reinforcement
        }
        if readyOrders > 0 {
            return .deployment
        }
        return .stable
    }

    private var pressureSystemImageName: String {
        pressureStatus.systemImageName
    }

    private var pressureTint: Color {
        pressureStatus.tint
    }

    private var supplyTint: Color {
        netSupplies < 0 ? MingDesignTokens.cinnabar : MingDesignTokens.porcelainBlue
    }

    private var queueTint: Color {
        readyOrders > 0 ? MingDesignTokens.porcelainBlue : .secondary
    }

    private var flowDetail: String {
        let readyText = readyOrders > 0 ? "，\(readyOrders) 项待部署" : ""
        return "入账 \(ledger.lastIncome.compactDisplaySummary)；军粮维护粮 \(ledger.lastUpkeep.supplies)，补员耗 \(ledger.lastReinforcementSpend.compactDisplaySummary)\(readyText)。"
    }
}

private struct TreasuryFourLineSection: View {
    let ledger: FactionEconomyLedger
    let summary: CourtStrategySummary

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack(alignment: .firstTextBaseline) {
                Label("府库四线牵引", systemImage: summary.recommendedFocus.systemImageName)
                    .font(.caption.bold())
                    .foregroundStyle(leadingTint)
                Spacer(minLength: 8)
                Text(summary.recommendedFocus.displayName)
                    .font(.caption.bold())
                    .foregroundStyle(leadingTint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 6)], alignment: .leading, spacing: 6) {
                TreasuryFourLineBadge(
                    title: "政策",
                    value: summary.policyPressure,
                    detail: "不稳 \(summary.unstableRegions)",
                    systemImageName: "scroll",
                    tint: MingDesignTokens.jade
                )
                TreasuryFourLineBadge(
                    title: "经济",
                    value: summary.economyPressure,
                    detail: "银 \(ledger.stockpile.industry)",
                    systemImageName: "banknote",
                    tint: MingDesignTokens.imperialGold
                )
                TreasuryFourLineBadge(
                    title: "科技",
                    value: summary.technologyPressure,
                    detail: "火炮 \(summary.fireSupportUnits)",
                    systemImageName: "scope",
                    tint: MingDesignTokens.porcelainBlue
                )
                TreasuryFourLineBadge(
                    title: "军事",
                    value: summary.militaryPressure,
                    detail: "接战 \(summary.activeFronts)",
                    systemImageName: "shield",
                    tint: MingDesignTokens.cinnabar
                )
            }

            Text(treasuryMinute)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }

    private var leadingTint: Color {
        let pressure = [
            (summary.policyPressure, MingDesignTokens.jade),
            (summary.economyPressure, MingDesignTokens.imperialGold),
            (summary.technologyPressure, MingDesignTokens.porcelainBlue),
            (summary.militaryPressure, MingDesignTokens.cinnabar)
        ]
        return pressure.max { lhs, rhs in
            lhs.0 < rhs.0
        }?.1 ?? MingDesignTokens.imperialGold
    }

    private var treasuryMinute: String {
        let secondary = summary.secondaryFocuses
            .map(\.displayName)
            .joined(separator: "、")
        let secondaryClause = secondary.isEmpty ? "" : "，备议 \(secondary)"
        return "户部会看：民力 \(ledger.stockpile.manpower)，银 \(ledger.stockpile.industry)，粮 \(ledger.stockpile.supplies)，营造 \(ledger.productionQueue.count) 项；主议 \(summary.recommendedFocus.displayName)\(secondaryClause)。"
    }
}

private struct TreasuryFourLineBadge: View {
    let title: String
    let value: Int
    let detail: String
    let systemImageName: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(title, systemImage: systemImageName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text("\(value)")
                .font(.caption.bold())
                .foregroundStyle(value >= 65 ? MingDesignTokens.cinnabar : tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
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

private struct TreasuryWorldPolicySection: View {
    let ledger: FactionEconomyLedger
    let courtSummary: CourtStrategySummary
    let objectiveSummary: BattleObjectiveSummary

    var body: some View {
        if objectiveSummary.isMingScenario {
            VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
                HStack(alignment: .firstTextBaseline) {
                    Label("经世策眼", systemImage: leadingBrief?.line.systemImage ?? "globe.asia.australia")
                        .font(.caption.bold())
                        .foregroundStyle(leadingTint)
                    Spacer(minLength: 8)
                    Text(courtSummary.recommendedFocus.displayName)
                        .font(.caption.bold())
                        .foregroundStyle(leadingTint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 6)], alignment: .leading, spacing: 6) {
                    TreasuryWorldPolicyBadge(
                        title: "天下",
                        value: objectiveSummary.leadingFaction?.displayName ?? "未定",
                        detail: leadingScoreDetail,
                        systemImageName: "crown",
                        tint: objectiveSummary.leadingFaction?.mingBannerTint ?? MingDesignTokens.imperialGold
                    )
                    TreasuryWorldPolicyBadge(
                        title: "最急五线",
                        value: urgentLineTitle,
                        detail: urgentLineDetail,
                        systemImageName: leadingBrief?.line.systemImage ?? "scope",
                        tint: leadingTint
                    )
                    TreasuryWorldPolicyBadge(
                        title: "府库余势",
                        value: treasuryReserveTitle,
                        detail: "粮 \(ledger.stockpile.supplies)",
                        systemImageName: "shippingbox",
                        tint: treasuryReserveTint
                    )
                    TreasuryWorldPolicyBadge(
                        title: "本旬取舍",
                        value: courtSummary.recommendedFocus.displayName,
                        detail: secondaryFocusDetail,
                        systemImageName: courtSummary.recommendedFocus.systemImageName,
                        tint: leadingTint
                    )
                }

                Text(worldMinute)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(MingDesignTokens.compactSpacing)
            .background(MingDesignTokens.sectionBackground)
            .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
            .accessibilityElement(children: .combine)
        }
    }

    private var leadingBrief: BattleObjectiveSummary.CampaignLineBrief? {
        objectiveSummary.lineBriefs
            .sorted {
                if $0.status != $1.status {
                    return statusRank($0.status) < statusRank($1.status)
                }
                return $0.pressure > $1.pressure
            }
            .first
    }

    private var leadingScoreDetail: String {
        guard let faction = objectiveSummary.leadingFaction,
              let row = objectiveSummary.scoreRows.first(where: { $0.faction == faction }) else {
            return "要冲未分"
        }
        return "\(row.points) 分 / \(row.objectiveCount) 处"
    }

    private var urgentLineTitle: String {
        guard let leadingBrief else {
            return "暂无"
        }
        return leadingBrief.line.displayName
    }

    private var urgentLineDetail: String {
        guard let leadingBrief else {
            return "五线未启"
        }
        return "\(leadingBrief.status.displayName) · 势 \(leadingBrief.pressure)"
    }

    private var treasuryReserveTitle: String {
        if ledger.stockpile.supplies < max(1, ledger.lastUpkeep.supplies) {
            return "粮紧"
        }
        if ledger.stockpile.industry < 20 {
            return "银紧"
        }
        return "可支"
    }

    private var treasuryReserveTint: Color {
        switch treasuryReserveTitle {
        case "粮紧", "银紧":
            return MingDesignTokens.cinnabar
        default:
            return MingDesignTokens.jade
        }
    }

    private var leadingTint: Color {
        guard let leadingBrief else {
            return MingDesignTokens.imperialGold
        }
        switch leadingBrief.line {
        case .world:
            return MingDesignTokens.cinnabar
        case .policy:
            return MingDesignTokens.porcelainBlue
        case .economy:
            return MingDesignTokens.jade
        case .technology:
            return MingDesignTokens.imperialGold
        case .military:
            return MingDesignTokens.ink
        }
    }

    private var secondaryFocusDetail: String {
        let secondary = courtSummary.secondaryFocuses
            .prefix(2)
            .map(\.displayName)
            .joined(separator: "、")
        return secondary.isEmpty ? "无备议" : "备 \(secondary)"
    }

    private var worldMinute: String {
        let urgentClause: String
        if let leadingBrief {
            urgentClause = "\(leadingBrief.line.displayName) \(leadingBrief.status.displayName)"
        } else {
            urgentClause = "五线未启"
        }
        return "经世会看：要冲分、粮道、地方治理与府库余势同判；当前 \(urgentClause)，主议 \(courtSummary.recommendedFocus.displayName)，只作票拟提醒，不自动下令。"
    }

    private func statusRank(_ status: BattleObjectiveSummary.CampaignStageStatus) -> Int {
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
}

private struct TreasuryWorldPolicyBadge: View {
    let title: String
    let value: String
    let detail: String
    let systemImageName: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(title, systemImage: systemImageName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
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

private struct TreasuryFamineRiskSection: View {
    let ledger: FactionEconomyLedger
    let governance: GovernanceAISummary
    let divisions: [Division]

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack(alignment: .firstTextBaseline) {
                Label("民食灾荒", systemImage: status.systemImageName)
                    .font(.caption.bold())
                    .foregroundStyle(status.tint)
                Spacer(minLength: 8)
                Text(status.title)
                    .font(.caption.bold())
                    .foregroundStyle(status.tint)
                    .lineLimit(1)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 78), spacing: 6)], alignment: .leading, spacing: 6) {
                TreasuryGovernanceBadge(title: "民食", value: publicFoodIndex, detail: "余势", tint: foodTint)
                TreasuryGovernanceBadge(title: "粮差", value: grainGap, detail: "本旬", tint: grainGapTint)
                TreasuryGovernanceBadge(title: "不稳", value: governance.unstableRegions, detail: "州府", tint: unrestTint)
                TreasuryGovernanceBadge(title: "断粮", value: encircledCount, detail: "军伍", tint: encircledTint)
            }

            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }

    private var lowSupplyCount: Int {
        divisions.filter { $0.supplyState == .lowSupply }.count
    }

    private var encircledCount: Int {
        divisions.filter { $0.supplyState == .encircled }.count
    }

    private var grainGap: Int {
        max(0, ledger.lastUpkeep.supplies + ledger.lastReinforcementSpend.supplies - ledger.lastIncome.supplies)
    }

    private var publicFoodIndex: Int {
        clamp(ledger.stockpile.supplies + governance.averageCompliance - governance.averageResistance - grainGap / 2)
    }

    private var status: TreasuryFamineRiskStatus {
        if governance.controlledRegions == 0 && divisions.isEmpty {
            return .empty
        }
        if publicFoodIndex < 35 || encircledCount > 0 {
            return .crisis
        }
        if grainGap > ledger.stockpile.supplies / 2 || governance.unstableRegions > 0 || lowSupplyCount > 0 {
            return .watch
        }
        return .steady
    }

    private var foodTint: Color {
        publicFoodIndex < 35 ? MingDesignTokens.cinnabar : MingDesignTokens.jade
    }

    private var grainGapTint: Color {
        grainGap > ledger.stockpile.supplies / 2 ? MingDesignTokens.cinnabar : MingDesignTokens.imperialGold
    }

    private var unrestTint: Color {
        governance.unstableRegions > 0 ? MingDesignTokens.cinnabar : .secondary
    }

    private var encircledTint: Color {
        encircledCount > 0 ? MingDesignTokens.cinnabar : .secondary
    }

    private var detail: String {
        "民食会看：库存粮 \(ledger.stockpile.supplies)，本旬粮差 \(grainGap)，缺粮军伍 \(lowSupplyCount)，断粮被围 \(encircledCount)，民变 \(governance.averageResistance)，行政 \(governance.averageCompliance)。此处只作灾荒风险提示，不执行事件效果。"
    }

    private func clamp(_ value: Int) -> Int {
        max(0, min(100, value))
    }
}

private enum TreasuryFamineRiskStatus {
    case empty
    case crisis
    case watch
    case steady

    var title: String {
        switch self {
        case .empty:
            return "暂无民食"
        case .crisis:
            return "灾荒急"
        case .watch:
            return "民食紧"
        case .steady:
            return "民食可支"
        }
    }

    var systemImageName: String {
        switch self {
        case .empty:
            return "tray"
        case .crisis,
             .watch:
            return "exclamationmark.triangle"
        case .steady:
            return "leaf"
        }
    }

    var tint: Color {
        switch self {
        case .empty:
            return .secondary
        case .crisis:
            return MingDesignTokens.cinnabar
        case .watch:
            return MingDesignTokens.imperialGold
        case .steady:
            return MingDesignTokens.jade
        }
    }
}

private struct TreasuryGovernanceSection: View {
    let governance: GovernanceAISummary

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack(alignment: .firstTextBaseline) {
                Label("内政钱粮", systemImage: "building.columns")
                    .font(.caption.bold())
                    .foregroundStyle(governanceTint)
                Spacer(minLength: 8)
                Text(governanceStatus)
                    .font(.caption.bold())
                    .foregroundStyle(governanceTint)
                    .lineLimit(1)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 78), spacing: 6)], alignment: .leading, spacing: 6) {
                TreasuryGovernanceBadge(title: "州府", value: governance.controlledRegions, detail: "掌控", tint: MingDesignTokens.jade)
                TreasuryGovernanceBadge(title: "不稳", value: governance.unstableRegions, detail: "需安抚", tint: unstableTint)
                TreasuryGovernanceBadge(title: "民变", value: governance.averageResistance, detail: "均值", tint: resistanceTint)
                TreasuryGovernanceBadge(title: "行政", value: governance.averageCompliance, detail: "均值", tint: complianceTint)
            }

            Text(governanceDetail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }

    private var governanceStatus: String {
        if governance.controlledRegions == 0 {
            return "暂无州府"
        }
        return governance.unstableRegions > 0 ? "地方不稳" : "地方平稳"
    }

    private var governanceTint: Color {
        governance.unstableRegions > 0 ? MingDesignTokens.cinnabar : MingDesignTokens.jade
    }

    private var unstableTint: Color {
        governance.unstableRegions > 0 ? MingDesignTokens.cinnabar : .secondary
    }

    private var resistanceTint: Color {
        governance.averageResistance >= 25 ? MingDesignTokens.cinnabar : MingDesignTokens.imperialGold
    }

    private var complianceTint: Color {
        governance.averageCompliance < 55 ? MingDesignTokens.cinnabar : MingDesignTokens.porcelainBlue
    }

    private var governanceDetail: String {
        let lowest = MingMapLabelFormat.regionTitle(governance.lowestComplianceRegionId)
        return "地方治理会修正州府钱粮产出；最低行政 \(lowest)，不稳州府 \(governance.unstableRegions) 处。"
    }
}

private struct TreasuryGovernanceBadge: View {
    let title: String
    let value: Int
    let detail: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text("\(value)")
                .font(.caption.bold())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MingDesignTokens.panelBackground.opacity(0.52), in: RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .combine)
    }
}

private enum TreasuryPressureStatus {
    case grain
    case reinforcement
    case deployment
    case stable

    var title: String {
        switch self {
        case .grain:
            return "粮草吃紧"
        case .reinforcement:
            return "补员吃紧"
        case .deployment:
            return "待部署"
        case .stable:
            return "府库平稳"
        }
    }

    var systemImageName: String {
        switch self {
        case .grain, .reinforcement:
            return "exclamationmark.triangle"
        case .deployment:
            return "flag.checkered"
        case .stable:
            return "chart.line.uptrend.xyaxis"
        }
    }

    var tint: Color {
        switch self {
        case .grain, .reinforcement:
            return MingDesignTokens.cinnabar
        case .deployment:
            return MingDesignTokens.porcelainBlue
        case .stable:
            return MingDesignTokens.jade
        }
    }
}

private struct TreasuryNetBadge: View {
    let title: String
    let value: Int
    var suffix: String = ""
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(displayValue)
                .font(.caption.bold())
                .foregroundStyle(value < 0 ? MingDesignTokens.cinnabar : tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MingDesignTokens.panelBackground.opacity(0.52), in: RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .combine)
    }

    private var displayValue: String {
        if suffix.isEmpty {
            return value > 0 ? "+\(value)" : "\(value)"
        }
        return "\(value)\(suffix)"
    }
}

private struct TreasuryMilitaryPaySection: View {
    let ledger: FactionEconomyLedger
    let governance: GovernanceAISummary
    let divisions: [Division]

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack(alignment: .firstTextBaseline) {
                Label("军饷民心", systemImage: status.systemImageName)
                    .font(.caption.bold())
                    .foregroundStyle(status.tint)
                Spacer(minLength: 8)
                Text(status.title)
                    .font(.caption.bold())
                    .foregroundStyle(status.tint)
                    .lineLimit(1)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 78), spacing: 6)], alignment: .leading, spacing: 6) {
                TreasuryGovernanceBadge(title: "军伍", value: divisions.count, detail: "在册", tint: MingDesignTokens.porcelainBlue)
                TreasuryGovernanceBadge(title: "缺粮", value: supplyWarningCount, detail: "需救", tint: supplyWarningTint)
                TreasuryGovernanceBadge(title: "军饷", value: payReserve, detail: "余势", tint: payTint)
                TreasuryGovernanceBadge(title: "民心", value: publicSentiment, detail: "综合", tint: sentimentTint)
            }

            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }

    private var lowSupplyCount: Int {
        divisions.filter { $0.supplyState == .lowSupply }.count
    }

    private var encircledCount: Int {
        divisions.filter { $0.supplyState == .encircled }.count
    }

    private var supplyWarningCount: Int {
        lowSupplyCount + encircledCount
    }

    private var payReserve: Int {
        ledger.stockpile.industry - max(0, ledger.lastReinforcementSpend.industry + divisions.count * 2)
    }

    private var publicSentiment: Int {
        clamp(governance.averageCompliance - governance.averageResistance / 2)
    }

    private var status: TreasuryMilitaryPayStatus {
        if divisions.isEmpty && governance.controlledRegions == 0 {
            return .empty
        }
        if encircledCount > 0 || ledger.lastUpkeep.supplies > ledger.stockpile.supplies + ledger.lastIncome.supplies {
            return .grain
        }
        if payReserve < 0 {
            return .pay
        }
        if governance.unstableRegions > 0 || publicSentiment < 45 {
            return .sentiment
        }
        return .steady
    }

    private var supplyWarningTint: Color {
        supplyWarningCount > 0 ? MingDesignTokens.cinnabar : MingDesignTokens.jade
    }

    private var payTint: Color {
        payReserve < 0 ? MingDesignTokens.cinnabar : MingDesignTokens.imperialGold
    }

    private var sentimentTint: Color {
        publicSentiment < 45 ? MingDesignTokens.cinnabar : MingDesignTokens.jade
    }

    private var detail: String {
        "账房奏报：库存银 \(ledger.stockpile.industry)，补员耗银 \(ledger.lastReinforcementSpend.industry)，军粮维护 \(ledger.lastUpkeep.supplies)；缺粮 \(lowSupplyCount)，被围 \(encircledCount)，民变 \(governance.averageResistance)，行政 \(governance.averageCompliance)。"
    }

    private func clamp(_ value: Int) -> Int {
        max(0, min(100, value))
    }
}

private enum TreasuryMilitaryPayStatus {
    case empty
    case grain
    case pay
    case sentiment
    case steady

    var title: String {
        switch self {
        case .empty:
            return "暂无账报"
        case .grain:
            return "军粮压顶"
        case .pay:
            return "军饷吃紧"
        case .sentiment:
            return "民心承压"
        case .steady:
            return "军饷可支"
        }
    }

    var systemImageName: String {
        switch self {
        case .empty:
            return "tray"
        case .grain,
             .pay,
             .sentiment:
            return "exclamationmark.triangle"
        case .steady:
            return "checkmark.seal"
        }
    }

    var tint: Color {
        switch self {
        case .empty:
            return .secondary
        case .grain,
             .pay,
             .sentiment:
            return MingDesignTokens.cinnabar
        case .steady:
            return MingDesignTokens.jade
        }
    }
}

private struct ProductionActionSection: View {
    let ledger: FactionEconomyLedger
    let canAct: Bool
    let observerModeEnabled: Bool
    let canQueue: (ProductionKind) -> Bool
    let onQueueProduction: (ProductionKind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            Label("募兵与筹粮", systemImage: "person.3.sequence")
                .font(.caption.bold())

            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(ProductionKind.allCases) { kind in
                    ProductionActionRow(
                        kind: kind,
                        canQueue: canQueue(kind),
                        canAfford: ledger.stockpile.canAfford(kind.cost),
                        availability: availability(for: kind),
                        onQueueProduction: onQueueProduction
                    )
                }
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }

    private func availability(for kind: ProductionKind) -> ProductionActionAvailability {
        if observerModeEnabled {
            return .observer
        }
        if !canAct {
            return .waitingTurn
        }
        let shortage = ledger.stockpile.shortageSummary(comparedTo: kind.cost)
        if !shortage.isEmpty {
            return .missing(shortage)
        }
        return .ready
    }
}

private struct ProductionActionRow: View {
    let kind: ProductionKind
    let canQueue: Bool
    let canAfford: Bool
    let availability: ProductionActionAvailability
    let onQueueProduction: (ProductionKind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                onQueueProduction(kind)
            } label: {
                HStack(alignment: .center, spacing: 8) {
                    Label(kind.displayName, systemImage: kind.systemImageName)
                        .font(.caption.bold())
                        .foregroundStyle(kind.tint)
                    Spacer(minLength: 8)
                    Text("\(kind.buildTurns) 回合")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, minHeight: MingDesignTokens.minimumTapSize, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .disabled(!canQueue)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(kind.intentSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Label(availability.title, systemImage: availability.systemImageName)
                        .font(.caption)
                        .foregroundStyle(availability.tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                Spacer(minLength: 8)
                Text("耗费 \(kind.cost.compactDisplaySummary)")
                    .font(.caption)
                    .foregroundStyle(canAfford ? .secondary : MingDesignTokens.cinnabar)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .padding(7)
        .background(MingDesignTokens.panelBackground.opacity(0.45), in: RoundedRectangle(cornerRadius: 6))
    }
}

private enum ProductionActionAvailability {
    case ready
    case missing(String)
    case waitingTurn
    case observer

    var title: String {
        switch self {
        case .ready:
            return "可开工"
        case let .missing(shortage):
            return "尚缺 \(shortage)"
        case .waitingTurn:
            return "待本方"
        case .observer:
            return "观战"
        }
    }

    var systemImageName: String {
        switch self {
        case .ready:
            return "checkmark.seal"
        case .missing:
            return "exclamationmark.triangle"
        case .waitingTurn:
            return "hourglass"
        case .observer:
            return "eye"
        }
    }

    var tint: Color {
        switch self {
        case .ready:
            return MingDesignTokens.jade
        case .missing:
            return MingDesignTokens.cinnabar
        case .waitingTurn,
             .observer:
            return .secondary
        }
    }
}

private struct ProductionQueueSection: View {
    let queue: [ProductionOrder]

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack {
                Label("营造队列", systemImage: "hourglass")
                    .font(.caption.bold())
                Spacer(minLength: 8)
                Text("\(queue.count) 项")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if queue.isEmpty {
                Text("暂无募兵或筹粮。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(queue) { order in
                        ProductionQueueRow(order: order)
                    }
                }
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }
}

private struct ProductionQueueRow: View {
    let order: ProductionOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Label(order.kind.displayName, systemImage: order.kind.systemImageName)
                    .font(.caption.bold())
                    .foregroundStyle(order.kind.tint)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(order.isReady ? "待部署" : "\(order.remainingTurns) 回合")
                    .font(.caption)
                    .foregroundStyle(order.isReady ? MingDesignTokens.jade : .secondary)
                    .lineLimit(1)
            }

            ProgressView(value: order.progress, total: 1)
                .tint(order.kind.tint)

            Text("第 \(order.createdTurn) 回合开工")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(7)
        .background(MingDesignTokens.panelBackground.opacity(0.45), in: RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .combine)
    }
}

private extension ProductionOrder {
    var progress: Double {
        guard totalTurns > 0 else {
            return 1
        }
        return Double(totalTurns - remainingTurns) / Double(totalTurns)
    }
}

private extension EconomyResources {
    func shortageSummary(comparedTo cost: EconomyResources) -> String {
        let deficits: [(label: String, value: Int)] = [
            ("民力", max(0, cost.manpower - manpower)),
            ("银两", max(0, cost.industry - industry)),
            ("粮草", max(0, cost.supplies - supplies))
        ].filter { $0.value > 0 }

        return deficits
            .map { "\($0.label) \($0.value)" }
            .joined(separator: " / ")
    }
}

private extension ProductionKind {
    var systemImageName: String {
        switch self {
        case .infantryDivision:
            return "figure.walk"
        case .panzerDivision:
            return "shield.lefthalf.filled"
        case .motorizedDivision:
            return "hare"
        case .artilleryDivision:
            return "scope"
        case .supplyStockpile:
            return "shippingbox"
        }
    }

    var tint: Color {
        switch self {
        case .infantryDivision:
            return MingDesignTokens.jade
        case .panzerDivision:
            return MingDesignTokens.cinnabar
        case .motorizedDivision:
            return MingDesignTokens.porcelainBlue
        case .artilleryDivision:
            return MingDesignTokens.imperialGold
        case .supplyStockpile:
            return MingDesignTokens.imperialGold
        }
    }

    var intentSummary: String {
        switch self {
        case .infantryDivision:
            return "补充守城与正兵。"
        case .panzerDivision:
            return "整备精骑，强化突击。"
        case .motorizedDivision:
            return "募集哨骑，利于机动。"
        case .artilleryDivision:
            return "造炮修器，支援攻城。"
        case .supplyStockpile:
            return "筹粮入仓，缓解军粮。"
        }
    }
}
