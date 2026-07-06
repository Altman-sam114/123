import SwiftUI

struct BattleObjectivePanelView: View {
    let gameState: GameState
    let onFocusObjective: (String) -> Void

    init(gameState: GameState, onFocusObjective: @escaping (String) -> Void = { _ in }) {
        self.gameState = gameState
        self.onFocusObjective = onFocusObjective
    }

    var body: some View {
        let summary = BattleObjectiveSummary.from(state: gameState)
        let courtSummary = CourtStrategySummary.from(faction: gameState.activeFaction, state: gameState)
        let ledger = gameState.economyState.ledger(for: gameState.activeFaction)

        VStack(alignment: .leading, spacing: MingDesignTokens.sectionSpacing) {
            BattleObjectiveHeader(summary: summary, turn: gameState.turn, maxTurns: gameState.maxTurns)

            if summary.isMingScenario {
                BattleObjectiveFourPolicyBoard(
                    summary: summary,
                    courtSummary: courtSummary,
                    ledger: ledger
                )
                BattleObjectiveStrategicEye(summary: summary, onFocusObjective: onFocusObjective)
                BattleObjectiveGapBoard(tracks: summary.tracks, onFocusObjective: onFocusObjective)
                BattleObjectiveScoreboard(summary: summary)
                BattleObjectiveLineBriefBoard(briefs: summary.lineBriefs)
                BattleObjectiveCueBoard(cues: summary.cues)
                BattleObjectiveTaskBoard(tasks: summary.tasks, onFocusObjective: onFocusObjective)
                BattleObjectiveStageBoard(stages: summary.stages)

                VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
                    Text("胜负线")
                        .font(.subheadline.bold())
                        .foregroundStyle(MingDesignTokens.ink)

                    ForEach(summary.tracks) { track in
                        BattleObjectiveTrackCard(
                            track: track,
                            isFinalTurn: gameState.turn >= gameState.maxTurns,
                            onFocusObjective: onFocusObjective
                        )
                    }
                }
            } else {
                BattleObjectiveLegacyNotice(subtitle: summary.subtitle)
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

private struct BattleObjectiveFourPolicyBoard: View {
    let summary: BattleObjectiveSummary
    let courtSummary: CourtStrategySummary
    let ledger: FactionEconomyLedger

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Label("国势四策", systemImage: "scroll")
                    .font(.subheadline.bold())
                    .foregroundStyle(MingDesignTokens.ink)

                Spacer(minLength: 8)

                Text("主议 \(courtSummary.recommendedFocus.displayName)")
                    .font(.caption.bold())
                    .foregroundStyle(MingDesignTokens.cinnabar)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }

            Text(boardSummary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 142), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(cards) { card in
                    BattleObjectiveFourPolicyCard(card: card)
                }
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .contain)
    }

    private var boardSummary: String {
        let backup = courtSummary.secondaryFocuses.map(\.displayName).joined(separator: "、")
        let backupClause = backup.isEmpty ? "暂无备议" : "备议 \(backup)"
        let leader = summary.leadingFaction?.displayName ?? "未分胜势"
        return "\(leader)暂领要冲分；\(backupClause)。此处只把胜负线、朝议和府库余势合并判读，不自动批票或下令。"
    }

    private var urgentBrief: BattleObjectiveSummary.CampaignLineBrief? {
        summary.lineBriefs.sorted {
            if $0.status != $1.status {
                return $0.status.objectivePanelRank < $1.status.objectivePanelRank
            }
            return $0.pressure > $1.pressure
        }.first
    }

    private var militaryTask: BattleObjectiveSummary.CampaignTask? {
        summary.tasks.first { $0.line == .military && $0.priority == .urgent }
            ?? summary.tasks.first { $0.line == .military }
            ?? summary.tasks.first { $0.priority == .urgent }
    }

    private var cards: [BattleObjectiveFourPolicyCardModel] {
        [
            BattleObjectiveFourPolicyCardModel(
                id: "policy",
                title: "政策",
                value: "压 \(courtSummary.policyPressure)",
                detail: "\(courtSummary.recommendedFocus.domainDisplayName)主议；不稳州府 \(courtSummary.unstableRegions) 处，先判征饷、安民、招抚的名分代价。",
                systemImage: BattleObjectiveSummary.CampaignLine.policy.systemImage,
                tint: BattleObjectiveSummary.CampaignLine.policy.objectivePanelTint
            ),
            BattleObjectiveFourPolicyCardModel(
                id: "economy",
                title: "经济",
                value: "银 \(ledger.stockpile.industry) / 粮 \(ledger.stockpile.supplies)",
                detail: economyDetail,
                systemImage: BattleObjectiveSummary.CampaignLine.economy.systemImage,
                tint: BattleObjectiveSummary.CampaignLine.economy.objectivePanelTint
            ),
            BattleObjectiveFourPolicyCardModel(
                id: "technology",
                title: "科技",
                value: "压 \(courtSummary.technologyPressure)",
                detail: "火器攻城军 \(courtSummary.fireSupportUnits) 支；看红衣炮、火器整备、修城和粮台驿道能否支撑要冲线。",
                systemImage: BattleObjectiveSummary.CampaignLine.technology.systemImage,
                tint: BattleObjectiveSummary.CampaignLine.technology.objectivePanelTint
            ),
            BattleObjectiveFourPolicyCardModel(
                id: "military",
                title: "军事",
                value: "压 \(courtSummary.militaryPressure)",
                detail: militaryDetail,
                systemImage: BattleObjectiveSummary.CampaignLine.military.systemImage,
                tint: BattleObjectiveSummary.CampaignLine.military.objectivePanelTint
            )
        ]
    }

    private var economyDetail: String {
        if let urgentBrief, urgentBrief.line == .economy || urgentBrief.line == .world {
            return "\(urgentBrief.title)势 \(urgentBrief.pressure)；府库需同时顾粮道、银饷和本旬要冲落点。"
        }
        return "民力 \(ledger.stockpile.manpower)，入账 \(ledger.lastIncome.compactDisplaySummary)；先看军粮维护与补员消耗。"
    }

    private var militaryDetail: String {
        if let militaryTask {
            return "\(militaryTask.priority.displayName)：\(militaryTask.title)。前线 \(courtSummary.activeFronts) 处，先保能调之兵。"
        }
        return "前线 \(courtSummary.activeFronts) 处；先判山海关、北京、开封、湖广等要冲军势。"
    }
}

private struct BattleObjectiveFourPolicyCardModel: Identifiable {
    let id: String
    let title: String
    let value: String
    let detail: String
    let systemImage: String
    let tint: Color
}

private struct BattleObjectiveFourPolicyCard: View {
    let card: BattleObjectiveFourPolicyCardModel

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                Image(systemName: card.systemImage)
                    .font(.caption.bold())
                    .foregroundStyle(card.tint)
                    .frame(width: 22, height: 22)
                    .background(card.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 1) {
                    Text(card.title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(card.value)
                        .font(.caption.bold())
                        .foregroundStyle(card.tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }

            Text(card.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
        .background(MingDesignTokens.panelBackground.opacity(0.58), in: RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(card.tint.opacity(0.2), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct BattleObjectiveStrategicEye: View {
    let summary: BattleObjectiveSummary
    let onFocusObjective: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            Label("天下棋眼", systemImage: "scope")
                .font(.subheadline.bold())
                .foregroundStyle(MingDesignTokens.ink)

            BattleObjectiveEyeRow(
                title: "要冲分",
                value: leadingText,
                detail: leadingDetail,
                systemImage: "crown",
                tint: summary.leadingFaction?.mingBannerTint ?? MingDesignTokens.imperialGold
            )

            if let urgentBrief {
                BattleObjectiveEyeRow(
                    title: "最急五线",
                    value: "\(urgentBrief.line.displayName) · \(urgentBrief.status.displayName)",
                    detail: urgentBrief.detail,
                    systemImage: urgentBrief.line.systemImage,
                    tint: urgentBrief.line.objectivePanelTint
                )
            }

            if let task = firstActionTask {
                BattleObjectiveEyeRow(
                    title: "本旬先手",
                    value: "\(task.priority.displayName) · \(task.title)",
                    detail: task.detail,
                    systemImage: task.priority.systemImage,
                    tint: task.line.objectivePanelTint,
                    targetObjectiveId: task.targetObjectiveId,
                    targetName: task.targetObjectiveId.flatMap(targetName)
                ) { objectiveId in
                    onFocusObjective(objectiveId)
                }
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }

    private var urgentBrief: BattleObjectiveSummary.CampaignLineBrief? {
        summary.lineBriefs
            .sorted {
                if $0.status != $1.status {
                    return $0.status.objectivePanelRank < $1.status.objectivePanelRank
                }
                return $0.pressure > $1.pressure
            }
            .first
    }

    private var firstActionTask: BattleObjectiveSummary.CampaignTask? {
        summary.tasks.first { $0.priority == .urgent }
            ?? summary.tasks.first { $0.priority == .main }
            ?? summary.tasks.first
    }

    private var leadingText: String {
        summary.leadingFaction?.displayName ?? "未定"
    }

    private var leadingDetail: String {
        if let leadingFaction = summary.leadingFaction {
            let leadingRow = summary.scoreRows.first { $0.faction == leadingFaction }
            return "当前由\(leadingFaction.displayName)暂领 \(leadingRow?.points ?? 0) 分；仍需同时盯住城关、粮道、朝议和军机五线。"
        }
        return "当前要冲分尚未拉开；先看山海关、北京、开封、湖广和终局名分线。"
    }

    private func targetName(for objectiveId: String) -> String? {
        summary.tracks
            .flatMap(\.targets)
            .first { $0.objectiveId == objectiveId }?
            .name
    }
}

private struct BattleObjectiveEyeRow: View {
    let title: String
    let value: String
    let detail: String
    let systemImage: String
    let tint: Color
    var targetObjectiveId: String?
    var targetName: String?
    var onFocusObjective: ((String) -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.bold())
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(title)
                        .font(.caption.bold())
                    Text(value)
                        .font(.caption.bold())
                        .foregroundStyle(tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                }

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let targetObjectiveId, let onFocusObjective {
                Spacer(minLength: 4)

                Button {
                    onFocusObjective(targetObjectiveId)
                } label: {
                    Label(targetName ?? "定位", systemImage: "mappin.and.ellipse")
                        .font(.caption.bold())
                        .foregroundStyle(tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                        .padding(.horizontal, 8)
                        .frame(minHeight: MingDesignTokens.minimumTapSize)
                        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .accessibilityHint("定位到本旬先手相关城关")
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 7)
        .background(MingDesignTokens.panelBackground.opacity(0.58), in: RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

private extension BattleObjectiveSummary.CampaignLine {
    var objectivePanelTint: Color {
        switch self {
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
}

private extension BattleObjectiveSummary.CampaignStageStatus {
    var objectivePanelRank: Int {
        switch self {
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

private struct BattleObjectiveGapBoard: View {
    let tracks: [BattleObjectiveSummary.Track]
    let onFocusObjective: (String) -> Void

    var body: some View {
        if !tracks.isEmpty {
            VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Label("要冲缺口", systemImage: "flag.2.crossed")
                        .font(.subheadline.bold())
                        .foregroundStyle(MingDesignTokens.ink)

                    Spacer(minLength: 8)

                    Text(overallStatus)
                        .font(.caption.bold())
                        .foregroundStyle(MingDesignTokens.cinnabar)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                Text("各路胜负线按未控城关扫读，先看最高分缺口，再回舆图定位落点。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 156), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(tracks) { track in
                        BattleObjectiveGapCard(track: track, onFocusObjective: onFocusObjective)
                    }
                }
            }
            .padding(MingDesignTokens.compactSpacing)
            .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        }
    }

    private var overallStatus: String {
        let missingCount = tracks.reduce(0) { total, track in
            total + track.targets.filter { !$0.isControlled }.count
        }
        if missingCount == 0 {
            return "诸线已满"
        }
        return "尚缺 \(missingCount) 处"
    }
}

private struct BattleObjectiveGapCard: View {
    let track: BattleObjectiveSummary.Track
    let onFocusObjective: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .top, spacing: 7) {
                MingFactionFlagBadge(faction: track.faction)

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.caption.bold())
                        .foregroundStyle(MingDesignTokens.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text(gapStatus)
                        .font(.caption)
                        .foregroundStyle(track.faction.mingBannerTint)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)
            }

            Text(gapDetail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            if let focusTarget {
                Button {
                    onFocusObjective(focusTarget.objectiveId)
                } label: {
                    Label(focusTarget.name, systemImage: "mappin.and.ellipse")
                        .font(.caption.bold())
                        .foregroundStyle(track.faction.mingBannerTint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                        .frame(maxWidth: .infinity, minHeight: MingDesignTokens.minimumTapSize, alignment: .leading)
                        .padding(.horizontal, 8)
                        .background(track.faction.mingBannerTint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .accessibilityHint("定位到\(focusTarget.name)")
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(track.isSatisfied ? MingDesignTokens.subtleSeal : MingDesignTokens.panelBackground.opacity(0.58), in: RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(track.faction.mingBannerTint.opacity(track.isSatisfied ? 0.48 : 0.22), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var missingTargets: [BattleObjectiveSummary.Target] {
        track.targets.filter { !$0.isControlled }
    }

    private var focusTarget: BattleObjectiveSummary.Target? {
        let candidates = missingTargets.isEmpty ? track.targets : missingTargets
        return candidates.sorted {
            if $0.points == $1.points {
                return $0.name < $1.name
            }
            return $0.points > $1.points
        }.first
    }

    private var gapStatus: String {
        if track.isSatisfied {
            return "已据 \(track.requiredCount) / \(track.requiredCount) 处"
        }
        return "尚缺 \(missingTargets.count) / \(track.requiredCount) 处"
    }

    private var gapDetail: String {
        if track.isSatisfied {
            return "\(track.faction.displayName)所需要冲已齐，仍需守住现有城关，防止终局前换手。"
        }
        guard let focusTarget else {
            return "此线暂无可定位要冲。"
        }

        let missingNames = missingTargets.prefix(2).map(\.name).joined(separator: "、")
        let prefix = missingNames.isEmpty ? "缺口未明" : "缺 \(missingNames)"
        return "\(prefix)；最高缺口 \(focusTarget.name)，现 \(focusTarget.controllerName)，值 \(focusTarget.points) 分。"
    }
}

private struct BattleObjectiveHeader: View {
    let summary: BattleObjectiveSummary
    let turn: Int
    let maxTurns: Int

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack(alignment: .top, spacing: 10) {
                Text("标")
                    .font(.headline.bold())
                    .foregroundStyle(MingDesignTokens.cinnabar)
                    .frame(width: 38, height: 38)
                    .background(MingDesignTokens.subtleSeal)
                    .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
                    .overlay {
                        RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius)
                            .stroke(MingDesignTokens.courtStroke, lineWidth: 1)
                    }
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(summary.title)
                        .font(.headline)
                        .foregroundStyle(MingDesignTokens.ink)
                        .lineLimit(2)
                    Text(summary.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 6)], alignment: .leading, spacing: 6) {
                BattleObjectiveMetricChip(
                    title: "回合",
                    value: "\(turn) / \(maxTurns)",
                    systemImage: "calendar",
                    tint: MingDesignTokens.porcelainBlue
                )
                BattleObjectiveMetricChip(
                    title: "领先",
                    value: summary.leadingFaction?.displayName ?? "未定",
                    systemImage: "crown",
                    tint: summary.leadingFaction?.mingBannerTint ?? .secondary
                )
                BattleObjectiveMetricChip(
                    title: "目标线",
                    value: summary.isMingScenario ? "\(summary.tracks.count) 条" : "旧制",
                    systemImage: "scope",
                    tint: MingDesignTokens.imperialGold
                )
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }
}

private struct BattleObjectiveLineBriefBoard: View {
    let briefs: [BattleObjectiveSummary.CampaignLineBrief]

    var body: some View {
        if !briefs.isEmpty {
            VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
                Text("天下五线态势")
                    .font(.subheadline.bold())
                    .foregroundStyle(MingDesignTokens.ink)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 136), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(briefs) { brief in
                        BattleObjectiveLineBriefCard(brief: brief)
                    }
                }
            }
            .padding(MingDesignTokens.compactSpacing)
            .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        }
    }
}

private struct BattleObjectiveLineBriefCard: View {
    let brief: BattleObjectiveSummary.CampaignLineBrief

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .center, spacing: 6) {
                Label(brief.title, systemImage: brief.line.systemImage)
                    .font(.caption.bold())
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 6)

                Text(brief.status.displayName)
                    .font(.caption.bold())
                    .foregroundStyle(tint)
                    .lineLimit(1)
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
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MingDesignTokens.panelBackground.opacity(0.58), in: RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(tint.opacity(brief.status == .warning ? 0.42 : 0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var tint: Color {
        switch brief.line {
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
}

private struct BattleObjectiveTaskBoard: View {
    let tasks: [BattleObjectiveSummary.CampaignTask]
    let onFocusObjective: (String) -> Void

    var body: some View {
        if !tasks.isEmpty {
            VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
                Text("本旬任务链")
                    .font(.subheadline.bold())
                    .foregroundStyle(MingDesignTokens.ink)

                ForEach(tasks) { task in
                    BattleObjectiveTaskRow(task: task, onFocusObjective: onFocusObjective)
                }
            }
            .padding(MingDesignTokens.compactSpacing)
            .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        }
    }
}

private struct BattleObjectiveTaskRow: View {
    let task: BattleObjectiveSummary.CampaignTask
    let onFocusObjective: (String) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Label(task.line.displayName, systemImage: task.line.systemImage)
                .font(.caption.bold())
                .foregroundStyle(tint)
                .labelStyle(.iconOnly)
                .frame(width: 24, height: 24)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                .accessibilityLabel(task.line.displayName)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Label(task.priority.displayName, systemImage: task.priority.systemImage)
                        .font(.caption.bold())
                        .foregroundStyle(tint)
                        .lineLimit(1)
                    Text(task.title)
                        .font(.caption.bold())
                        .foregroundStyle(MingDesignTokens.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                Text(task.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let objectiveId = task.targetObjectiveId {
                Spacer(minLength: 4)

                Button {
                    onFocusObjective(objectiveId)
                } label: {
                    Label("定位", systemImage: "mappin.and.ellipse")
                        .font(.caption.bold())
                        .foregroundStyle(tint)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .frame(minHeight: MingDesignTokens.minimumTapSize)
                        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .accessibilityHint("定位到任务相关城关")
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 7)
        .background(MingDesignTokens.panelBackground.opacity(0.58), in: RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(tint.opacity(task.priority == .urgent ? 0.42 : 0.18), lineWidth: 1)
        }
    }

    private var tint: Color {
        switch task.line {
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
}

private struct BattleObjectiveStageBoard: View {
    let stages: [BattleObjectiveSummary.CampaignStage]

    var body: some View {
        if !stages.isEmpty {
            VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
                Text("阶段战局链")
                    .font(.subheadline.bold())
                    .foregroundStyle(MingDesignTokens.ink)

                ForEach(stages) { stage in
                    BattleObjectiveStageRow(stage: stage)
                }
            }
            .padding(MingDesignTokens.compactSpacing)
            .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        }
    }
}

private struct BattleObjectiveStageRow: View {
    let stage: BattleObjectiveSummary.CampaignStage

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Label(stage.line.displayName, systemImage: stage.line.systemImage)
                    .font(.caption.bold())
                    .foregroundStyle(tint)
                    .labelStyle(.iconOnly)
                    .frame(width: 24, height: 24)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                    .accessibilityLabel(stage.line.displayName)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(stage.title)
                            .font(.caption.bold())
                            .foregroundStyle(MingDesignTokens.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                        Text(stage.turnWindow)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Text(stage.summary)
                        .font(.caption)
                        .foregroundStyle(tint)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Text(stage.status.displayName)
                    .font(.caption.bold())
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
            }

            Text(stage.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ProgressView(value: stage.progress, total: 1)
                .tint(tint)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 7)
        .background(MingDesignTokens.panelBackground.opacity(0.58), in: RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(tint.opacity(stage.status == .warning ? 0.42 : 0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var tint: Color {
        switch stage.line {
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
}

private struct BattleObjectiveCueBoard: View {
    let cues: [BattleObjectiveSummary.Cue]

    var body: some View {
        if !cues.isEmpty {
            VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
                Text("战役提示")
                    .font(.subheadline.bold())
                    .foregroundStyle(MingDesignTokens.ink)

                ForEach(cues) { cue in
                    BattleObjectiveCueRow(cue: cue)
                }
            }
            .padding(MingDesignTokens.compactSpacing)
            .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        }
    }
}

private struct BattleObjectiveCueRow: View {
    let cue: BattleObjectiveSummary.Cue

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Label(cue.kind.displayName, systemImage: cue.kind.systemImage)
                .font(.caption.bold())
                .foregroundStyle(tint)
                .labelStyle(.iconOnly)
                .frame(width: 24, height: 24)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                .accessibilityLabel(cue.kind.displayName)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(cue.kind.displayName)
                        .font(.caption.bold())
                        .foregroundStyle(tint)
                    Text(cue.title)
                        .font(.caption.bold())
                        .foregroundStyle(MingDesignTokens.ink)
                        .lineLimit(1)
                }

                Text(cue.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 7)
        .background(MingDesignTokens.panelBackground.opacity(0.58), in: RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .combine)
    }

    private var tint: Color {
        switch cue.kind {
        case .history:
            return MingDesignTokens.cinnabar
        case .policy:
            return MingDesignTokens.porcelainBlue
        case .economy:
            return MingDesignTokens.jade
        case .technology:
            return MingDesignTokens.porcelainBlue
        case .military:
            return MingDesignTokens.imperialGold
        case .agent:
            return MingDesignTokens.ink
        }
    }
}

private struct BattleObjectiveScoreboard: View {
    let summary: BattleObjectiveSummary

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            Text("终局要冲分")
                .font(.subheadline.bold())
                .foregroundStyle(MingDesignTokens.ink)

            ForEach(summary.scoreRows) { row in
                BattleObjectiveScoreRowView(
                    row: row,
                    maxPoints: max(summary.scoreRows.map(\.points).max() ?? 1, 1),
                    isLeading: row.faction == summary.leadingFaction
                )
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }
}

private struct BattleObjectiveScoreRowView: View {
    let row: BattleObjectiveSummary.ScoreRow
    let maxPoints: Int
    let isLeading: Bool

    var body: some View {
        HStack(spacing: 8) {
            MingFactionFlagBadge(faction: row.faction)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(row.faction.displayName)
                        .font(.caption.bold())
                        .lineLimit(1)
                    if isLeading {
                        Label("领先", systemImage: "crown.fill")
                            .font(.caption)
                            .foregroundStyle(MingDesignTokens.imperialGold)
                            .lineLimit(1)
                    }
                }

                ProgressView(value: Double(row.points), total: Double(maxPoints))
                    .tint(row.faction.mingBannerTint)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(row.points) 分")
                    .font(.caption.monospacedDigit().bold())
                Text("\(row.objectiveCount) 处")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, MingDesignTokens.compactSpacing)
        .padding(.vertical, 7)
        .background(isLeading ? MingDesignTokens.subtleSeal : MingDesignTokens.panelBackground.opacity(0.52), in: RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .combine)
    }
}

private struct BattleObjectiveTrackCard: View {
    let track: BattleObjectiveSummary.Track
    let isFinalTurn: Bool
    let onFocusObjective: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack(alignment: .top, spacing: 8) {
                MingFactionFlagBadge(faction: track.faction)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(track.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(MingDesignTokens.ink)
                            .lineLimit(1)
                        Text(track.timing.displayName)
                            .font(.caption)
                            .foregroundStyle(track.timing == .finalTurn && !isFinalTurn ? .secondary : track.faction.mingBannerTint)
                            .lineLimit(1)
                    }

                    Text(track.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Label(track.statusText, systemImage: track.isSatisfied ? "checkmark.seal.fill" : "circle.dashed")
                    .font(.caption.bold())
                    .foregroundStyle(track.isSatisfied ? track.faction.mingBannerTint : .secondary)
                    .lineLimit(1)
            }

            ProgressView(value: track.progress, total: 1)
                .tint(track.faction.mingBannerTint)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 6)], alignment: .leading, spacing: 6) {
                ForEach(track.targets) { target in
                    Button {
                        onFocusObjective(target.objectiveId)
                    } label: {
                        BattleObjectiveTargetChip(target: target, tint: track.faction.mingBannerTint)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("定位到\(target.name)")
                }
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(track.isSatisfied ? MingDesignTokens.subtleSeal : MingDesignTokens.sectionBackground.opacity(0.78), in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius)
                .stroke(track.faction.mingBannerTint.opacity(track.isSatisfied ? 0.72 : 0.26), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct BattleObjectiveTargetChip: View {
    let target: BattleObjectiveSummary.Target
    let tint: Color

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Image(systemName: target.isControlled ? "checkmark.circle.fill" : "flag")
                .foregroundStyle(target.isControlled ? tint : .secondary)
                .frame(width: 16)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(target.name)
                    .font(.caption.bold())
                    .lineLimit(1)
                Text("现 \(target.controllerName) / \(target.points) 分")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 4)

            controllerBadge
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .background(MingDesignTokens.panelBackground.opacity(0.58), in: RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var controllerBadge: some View {
        if let controller = target.controller {
            MingFactionFlagBadge(faction: controller)
        } else {
            Text("无")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(minWidth: 20, minHeight: 18)
                .padding(.horizontal, 4)
                .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: 4))
                .accessibilityLabel("无人控制")
        }
    }
}

private struct BattleObjectiveMetricChip: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .frame(width: 16)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
        .background(MingDesignTokens.panelBackground.opacity(0.56), in: RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .combine)
    }
}

private struct BattleObjectiveLegacyNotice: View {
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            Label("旧剧本胜负链", systemImage: "flag.checkered")
                .font(.subheadline.bold())
                .foregroundStyle(MingDesignTokens.porcelainBlue)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }
}
