import SwiftUI

struct HUDView: View {
    let gameState: GameState
    let onEndTurn: () -> Void
    let onNewGame: (() -> Void)?

    init(gameState: GameState, onEndTurn: @escaping () -> Void, onNewGame: (() -> Void)? = nil) {
        self.gameState = gameState
        self.onEndTurn = onEndTurn
        self.onNewGame = onNewGame
    }

    var body: some View {
        let faction = gameState.activeFaction
        let ledger = activeLedger
        let courtSummary = CourtStrategySummary.from(faction: faction, state: gameState)
        let objectiveContext = HUDObjectiveContext(summary: BattleObjectiveSummary.from(state: gameState))

        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack(alignment: .center, spacing: 10) {
                Text("朝")
                    .font(.title3.bold())
                    .foregroundStyle(MingDesignTokens.cinnabar)
                    .frame(width: 44, height: 44)
                    .background(MingDesignTokens.subtleSeal)
                    .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
                    .overlay {
                        RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius)
                            .stroke(MingDesignTokens.courtStroke, lineWidth: 1)
                    }
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text("崇祯十五年 · 天下裂变")
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)

                    Text("\(faction.displayName) · \(gameState.phase.displayName) · 主议 \(courtSummary.recommendedFocus.displayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Spacer(minLength: 8)

                HUDStatusBadge(title: victoryText, systemImage: victoryIconName, tint: victoryTint)

                if let onNewGame {
                    NewGameButton(action: onNewGame)
                }

                Button(action: onEndTurn) {
                    Label("结束回合", systemImage: "forward.end")
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
                .buttonStyle(.borderedProminent)
                .frame(minHeight: MingDesignTokens.minimumTapSize)
            }

            LazyVGrid(columns: metricColumns, alignment: .leading, spacing: 7) {
                HUDMetricBadge(title: "回合", value: "\(gameState.turn) / \(gameState.maxTurns)", systemImage: "calendar")
                HUDMetricBadge(title: "民力", value: "\(ledger.stockpile.manpower)", systemImage: "person.2")
                HUDMetricBadge(title: "银两", value: "\(ledger.stockpile.industry)", systemImage: "banknote")
                HUDMetricBadge(title: "粮草", value: "\(ledger.stockpile.supplies)", systemImage: "shippingbox")
                HUDMetricBadge(title: "营造", value: "\(ledger.productionQueue.count) 项", systemImage: "hourglass")
                HUDMetricBadge(title: "入账", value: ledger.lastIncome.compactDisplaySummary, systemImage: "tray.and.arrow.down")
            }

            if let objectiveContext {
                HUDObjectiveStrip(context: objectiveContext)
            }

            HUDCourtPressureStrip(summary: courtSummary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MingDesignTokens.panelPadding)
        .background(MingDesignTokens.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }

    private var metricColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 92), spacing: 7, alignment: .leading)]
    }

    private var victoryText: String {
        guard let winner = gameState.victoryState.winner else {
            return "未决"
        }
        guard let reason = gameState.victoryState.reason else {
            return "\(winner.displayName) 胜"
        }
        return "\(winner.displayName)胜 · \(reason.displayName)"
    }

    private var victoryIconName: String {
        gameState.victoryState.winner == nil ? "flag" : "crown"
    }

    private var victoryTint: Color {
        gameState.victoryState.winner == nil ? MingDesignTokens.porcelainBlue : MingDesignTokens.imperialGold
    }

    private var activeLedger: FactionEconomyLedger {
        gameState.economyState.ledger(for: gameState.activeFaction)
    }
}

private struct HUDObjectiveContext {
    let leaderText: String
    let leaderDetail: String
    let urgentLineText: String
    let urgentLineDetail: String
    let taskText: String
    let taskDetail: String
    let urgentLineTint: Color

    init?(summary: BattleObjectiveSummary) {
        guard summary.isMingScenario else {
            return nil
        }

        let leadingRow = summary.leadingFaction.flatMap { faction in
            summary.scoreRows.first { $0.faction == faction }
        }
        let leadingName = summary.leadingFaction?.displayName ?? "未分胜势"
        leaderText = leadingRow.map { "\(leadingName) \($0.points)" } ?? leadingName
        leaderDetail = leadingRow.map { "要冲 \($0.objectiveCount) 处" } ?? "要冲分未拉开"

        let line = Self.urgentLine(in: summary)
        urgentLineText = line?.title ?? "五线待察"
        urgentLineDetail = line.map { "\($0.line.displayName) · \($0.status.displayName) · 压力 \($0.pressure)" } ?? "暂无告急线"
        urgentLineTint = Self.tint(for: line?.status)

        let task = summary.tasks.sorted(by: Self.taskSort).first
        let target = task?.targetObjectiveId.flatMap { objectiveId in
            summary.tracks.flatMap(\.targets).first { $0.objectiveId == objectiveId }
        }
        taskText = task?.title ?? "本旬候报"
        if let task, let target {
            taskDetail = "\(task.line.displayName) · \(task.priority.displayName) · \(target.name) · \(target.controllerName)"
        } else if let task {
            taskDetail = "\(task.line.displayName) · \(task.priority.displayName)"
        } else {
            taskDetail = "暂无急务"
        }
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

private struct HUDObjectiveStrip: View {
    let context: HUDObjectiveContext

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("朝报要冲", systemImage: "scope")
                .font(.caption.bold())
                .foregroundStyle(MingDesignTokens.imperialGold)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 6)], alignment: .leading, spacing: 6) {
                HUDObjectiveBadge(
                    title: "棋势",
                    value: context.leaderText,
                    detail: context.leaderDetail,
                    systemImage: "crown",
                    tint: MingDesignTokens.imperialGold
                )
                HUDObjectiveBadge(
                    title: "急线",
                    value: context.urgentLineText,
                    detail: context.urgentLineDetail,
                    systemImage: "exclamationmark.triangle",
                    tint: context.urgentLineTint
                )
                HUDObjectiveBadge(
                    title: "本旬",
                    value: context.taskText,
                    detail: context.taskDetail,
                    systemImage: "target",
                    tint: MingDesignTokens.porcelainBlue
                )
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground.opacity(0.74), in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .contain)
    }
}

private struct HUDObjectiveBadge: View {
    let title: String
    let value: String
    let detail: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(tint)
                .frame(width: 16)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(value)
                    .font(.caption.bold())
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)

                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .background(MingDesignTokens.panelBackground.opacity(0.58), in: RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .combine)
    }
}

private struct HUDStatusBadge: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.bold())
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: 6))
            .accessibilityElement(children: .combine)
    }
}

private struct HUDMetricBadge: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(MingDesignTokens.imperialGold)
                .frame(width: 16)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(value)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
        .background(MingDesignTokens.sectionBackground.opacity(0.86), in: RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .combine)
    }
}

private struct HUDCourtPressureStrip: View {
    let summary: CourtStrategySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Label("朝议四线", systemImage: summary.recommendedFocus.systemImageName)
                    .font(.caption.bold())
                    .foregroundStyle(MingDesignTokens.cinnabar)
                Spacer(minLength: 8)
                Text(summary.recommendedFocus.domainDisplayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 74), spacing: 6)], alignment: .leading, spacing: 6) {
                HUDPressureBadge(title: "政策", value: summary.policyPressure, tint: MingDesignTokens.jade)
                HUDPressureBadge(title: "经济", value: summary.economyPressure, tint: MingDesignTokens.imperialGold)
                HUDPressureBadge(title: "科技", value: summary.technologyPressure, tint: MingDesignTokens.porcelainBlue)
                HUDPressureBadge(title: "军事", value: summary.militaryPressure, tint: MingDesignTokens.cinnabar)
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.subtleSeal.opacity(0.72), in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }
}

private struct HUDPressureBadge: View {
    let title: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(tint)
                    .frame(width: 7, height: 7)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer(minLength: 4)

                Text("\(value)")
                    .font(.caption.bold())
                    .foregroundStyle(tint)
                    .lineLimit(1)
            }

            ProgressView(value: Double(value), total: 100)
                .tint(tint)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .background(MingDesignTokens.panelBackground.opacity(0.58), in: RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .combine)
    }
}
