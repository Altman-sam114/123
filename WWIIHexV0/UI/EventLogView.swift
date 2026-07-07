import SwiftUI

struct EventLogView: View {
    let entries: [GameLogEntry]
    let objectiveSummary: BattleObjectiveSummary?

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.sectionSpacing) {
            EventLogHeader(summary: summary)
            EventLogSummaryGrid(summary: summary)
            EventLogCampaignLineDigest(summary: objectiveSummary)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
                    if recentEntries.isEmpty {
                        EventLogEmptyState()
                    } else {
                        ForEach(recentEntries) { item in
                            EventLogReportRow(item: item)
                        }
                    }
                }
            }
            .frame(minHeight: 140)
        }
        .padding(MingDesignTokens.panelPadding)
        .background(MingDesignTokens.panelBackground)
        .overlay {
            RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius)
                .stroke(MingDesignTokens.courtStroke.opacity(0.72), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }

    private var recentEntries: [LogDisplayEntry] {
        entries
            .suffix(60)
            .reversed()
            .map { LogDisplayEntry(entry: $0, category: LogDisplayCategory(entry: $0)) }
    }

    private var summary: EventLogSummary {
        EventLogSummary(entries: recentEntries)
    }
}

private struct EventLogCampaignLineDigest: View {
    let summary: BattleObjectiveSummary?

    var body: some View {
        if let summary, summary.isMingScenario, !lineBriefs.isEmpty {
            VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: MingDesignTokens.compactSpacing) {
                    Label("五线急报", systemImage: "waveform.path.ecg")
                        .font(.subheadline.bold())
                        .foregroundStyle(MingDesignTokens.ink)

                    Spacer(minLength: MingDesignTokens.compactSpacing)

                    Text(headline)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: MingDesignTokens.compactSpacing) {
                        ForEach(lineBriefs) { brief in
                            EventLogCampaignLineChip(brief: brief)
                        }
                    }
                    .padding(.vertical, 1)
                }
            }
            .padding(MingDesignTokens.compactSpacing)
            .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("五线急报，\(headline)")
        }
    }

    private var lineBriefs: [BattleObjectiveSummary.CampaignLineBrief] {
        guard let summary, summary.isMingScenario else {
            return []
        }
        return summary.lineBriefs.sorted { lhs, rhs in
            if lhs.status.sortRank == rhs.status.sortRank {
                if lhs.pressure == rhs.pressure {
                    return lhs.line.rawValue < rhs.line.rawValue
                }
                return lhs.pressure > rhs.pressure
            }
            return lhs.status.sortRank < rhs.status.sortRank
        }
    }

    private var headline: String {
        guard let leading = lineBriefs.first else {
            return "五线候报"
        }
        if leading.urgentTaskCount > 0 {
            return "\(leading.line.displayName)\(leading.status.displayName) · 急务 \(leading.urgentTaskCount)"
        }
        if leading.activeTaskCount > 0 {
            return "\(leading.line.displayName)\(leading.status.displayName) · 主线 \(leading.activeTaskCount)"
        }
        return "\(leading.line.displayName)\(leading.status.displayName) · 势 \(leading.pressure)"
    }
}

private struct EventLogCampaignLineChip: View {
    let brief: BattleObjectiveSummary.CampaignLineBrief

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(brief.line.displayName, systemImage: brief.line.systemImage)
                .font(.caption.bold())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            HStack(spacing: 6) {
                Text(brief.status.displayName)
                    .font(.caption.bold())
                    .foregroundStyle(tint)

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
        .frame(width: 154, alignment: .leading)
        .padding(8)
        .background(MingDesignTokens.panelBackground.opacity(0.58), in: RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(tint.opacity(0.22), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var tint: Color {
        switch brief.status {
        case .warning:
            return MingDesignTokens.cinnabar
        case .focus:
            return MingDesignTokens.imperialGold
        case .watch:
            return MingDesignTokens.porcelainBlue
        case .achieved:
            return MingDesignTokens.jade
        }
    }
}

private struct EventLogHeader: View {
    let summary: EventLogSummary

    var body: some View {
        HStack(alignment: .top, spacing: MingDesignTokens.compactSpacing) {
            Text("报")
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
                Text("塘报战记")
                    .font(.headline)
                    .foregroundStyle(MingDesignTokens.ink)

                Text(summary.headline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: MingDesignTokens.compactSpacing)

            Label(summary.statusText, systemImage: summary.statusImageName)
                .font(.caption)
                .bold()
                .foregroundStyle(summary.statusTint)
                .padding(.horizontal, MingDesignTokens.compactSpacing)
                .padding(.vertical, 5)
                .background(summary.statusTint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
        }
    }
}

private struct EventLogSummaryGrid: View {
    let summary: EventLogSummary

    private let columns = [
        GridItem(.adaptive(minimum: 72), spacing: MingDesignTokens.compactSpacing)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            EventLogMetricChip(title: "急务", value: summary.campaignTaskCount, systemImage: "exclamationmark.triangle", tint: MingDesignTokens.cinnabar)
            EventLogMetricChip(title: "战役", value: summary.campaignCueCount, systemImage: "scroll", tint: MingDesignTokens.imperialGold)
            EventLogMetricChip(title: "战事", value: summary.battleCount, systemImage: "flame", tint: MingDesignTokens.cinnabar)
            EventLogMetricChip(title: "粮草", value: summary.supplyCount, systemImage: "shippingbox", tint: MingDesignTokens.jade)
            EventLogMetricChip(title: "州府", value: summary.territoryCount, systemImage: "building.columns", tint: MingDesignTokens.imperialGold)
            EventLogMetricChip(title: "天下", value: summary.diplomacyCount, systemImage: "globe.asia.australia", tint: MingDesignTokens.porcelainBlue)
        }
    }
}

private struct EventLogMetricChip: View {
    let title: String
    let value: Int
    let systemImage: String
    let tint: Color

    var body: some View {
        Label {
            Text("\(title) \(value)")
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        } icon: {
            Image(systemName: systemImage)
        }
        .font(.caption)
        .foregroundStyle(tint)
        .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
        .padding(.horizontal, MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct EventLogEmptyState: View {
    var body: some View {
        Label("尚无塘报入册", systemImage: "scroll")
            .font(.body)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: MingDesignTokens.minimumTapSize, alignment: .leading)
            .padding(MingDesignTokens.compactSpacing)
            .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct EventLogReportRow: View {
    let item: LogDisplayEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Label(item.category.displayName, systemImage: item.category.systemImageName)
                    .font(.caption)
                    .bold()
                    .foregroundStyle(item.category.foregroundStyle)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(item.category.backgroundStyle, in: RoundedRectangle(cornerRadius: 6))

                Text(item.metadataText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)
            }

            Text(item.entry.message)
                .font(.body)
                .foregroundStyle(MingDesignTokens.ink)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            if let receiptText = item.receiptText {
                Label(receiptText, systemImage: "checkmark.seal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground.opacity(0.86), in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(item.category.foregroundStyle.opacity(0.72))
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 2))
        }
        .accessibilityElement(children: .combine)
    }
}

private struct LogDisplayEntry: Identifiable {
    let entry: GameLogEntry
    let category: LogDisplayCategory

    var id: UUID {
        entry.id
    }

    var metadataText: String {
        let faction = entry.faction?.displayName ?? "系统"
        let phase = entry.phase?.displayName ?? "整备"
        return "第 \(entry.turn) 回合 · \(faction) · \(phase)"
    }

    var receiptText: String? {
        guard let relatedRecordId = entry.relatedRecordId else {
            return nil
        }
        if relatedRecordId.hasPrefix("battle-task-") {
            return "本旬急务"
        }
        if relatedRecordId.hasPrefix("battle-cue-") {
            return "战役提示"
        }
        if relatedRecordId.hasPrefix("objective-control-") {
            return "目标换手"
        }
        if relatedRecordId.hasPrefix("war_directive_") {
            return "战区军令"
        }
        if relatedRecordId.hasPrefix("directive_") {
            return "战区回执"
        }
        if relatedRecordId.hasPrefix("agent_") {
            return "军机回执"
        }
        if relatedRecordId.hasPrefix("ruler_") {
            return "朱批回执"
        }
        return "系统回执"
    }
}

private struct EventLogSummary {
    let totalCount: Int
    let campaignTaskCount: Int
    let campaignCueCount: Int
    let battleCount: Int
    let supplyCount: Int
    let territoryCount: Int
    let diplomacyCount: Int
    let latestCategory: LogDisplayCategory?

    init(entries: [LogDisplayEntry]) {
        self.totalCount = entries.count
        self.campaignTaskCount = entries.filter { $0.category == .campaignTask }.count
        self.campaignCueCount = entries.filter { $0.category == .campaignCue }.count
        self.battleCount = entries.filter { $0.category.isBattleReport }.count
        self.supplyCount = entries.filter { $0.category == .supply }.count
        self.territoryCount = entries.filter { $0.category.isTerritoryReport }.count
        self.diplomacyCount = entries.filter { $0.category == .diplomacy }.count
        self.latestCategory = entries.first?.category
    }

    var headline: String {
        guard totalCount > 0 else {
            return "军中尚无新报"
        }
        if let latestCategory {
            return "近 \(totalCount) 条近报 · 最新 \(latestCategory.displayName)"
        }
        return "近 \(totalCount) 条近报"
    }

    var statusText: String {
        if totalCount == 0 {
            return "候报"
        }
        if campaignTaskCount > 0 {
            return "有急务"
        }
        if campaignCueCount > 0 {
            return "战役"
        }
        if battleCount > 0 {
            return "有军情"
        }
        if supplyCount > 0 {
            return "粮情"
        }
        if territoryCount > 0 {
            return "战局"
        }
        if diplomacyCount > 0 {
            return "天下"
        }
        return "入册"
    }

    var statusImageName: String {
        if campaignTaskCount > 0 {
            return "exclamationmark.triangle"
        }
        if campaignCueCount > 0 {
            return "scroll"
        }
        if battleCount > 0 {
            return "exclamationmark.triangle"
        }
        if supplyCount > 0 {
            return "shippingbox"
        }
        if territoryCount > 0 {
            return "map"
        }
        if diplomacyCount > 0 {
            return "globe.asia.australia"
        }
        return totalCount == 0 ? "hourglass" : "scroll"
    }

    var statusTint: Color {
        if campaignTaskCount > 0 {
            return MingDesignTokens.cinnabar
        }
        if campaignCueCount > 0 {
            return MingDesignTokens.imperialGold
        }
        if battleCount > 0 {
            return MingDesignTokens.cinnabar
        }
        if supplyCount > 0 {
            return MingDesignTokens.jade
        }
        if territoryCount > 0 {
            return MingDesignTokens.imperialGold
        }
        if diplomacyCount > 0 {
            return MingDesignTokens.porcelainBlue
        }
        return .secondary
    }
}

private extension BattleObjectiveSummary.CampaignStageStatus {
    var sortRank: Int {
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

private enum LogDisplayCategory {
    case campaignTask
    case campaignCue
    case combat
    case retreat
    case reinforcement
    case encirclement
    case supply
    case frontChange
    case theaterChange
    case regionOwnerChange
    case diplomacy
    case event

    init(entry: GameLogEntry) {
        if let relatedRecordId = entry.relatedRecordId {
            if relatedRecordId.hasPrefix("battle-task-") {
                self = .campaignTask
                return
            }
            if relatedRecordId.hasPrefix("battle-cue-") {
                self = .campaignCue
                return
            }
        }

        switch entry.category {
        case .combat:
            self = .combat
            return
        case .retreat:
            self = .retreat
            return
        case .reinforce:
            self = .reinforcement
            return
        case .encircle:
            self = .encirclement
            return
        case .supply:
            self = .supply
            return
        case .frontChange:
            self = .frontChange
            return
        case .theaterChange:
            self = .theaterChange
            return
        case .regionOwnerChange:
            self = .regionOwnerChange
            return
        case .diplomacy:
            self = .diplomacy
            return
        case .event:
            break
        }

        let message = entry.message
        let text = message.lowercased()

        if text.contains("retreat") || text.contains("routed") || text.contains("routing") {
            self = .retreat
        } else if text.contains("reinforce") || text.contains("replacement") || text.contains("replenish") {
            self = .reinforcement
        } else if text.contains("encircle") || text.contains("encircled") {
            self = .encirclement
        } else if text.contains("attack") || text.contains("damage") || text.contains("combat") || text.contains("hit") {
            self = .combat
        } else if text.contains("supply") || text.contains("supplied") {
            self = .supply
        } else {
            self = .event
        }
    }

    var displayName: String {
        switch self {
        case .campaignTask:
            return "急务"
        case .campaignCue:
            return "战役"
        case .combat:
            return "战斗"
        case .retreat:
            return "退守"
        case .reinforcement:
            return "补员"
        case .encirclement:
            return "合围"
        case .supply:
            return "粮草"
        case .frontChange:
            return "前线"
        case .theaterChange:
            return "方面"
        case .regionOwnerChange:
            return "州府"
        case .diplomacy:
            return "外交"
        case .event:
            return "事件"
        }
    }

    var foregroundStyle: Color {
        switch self {
        case .campaignTask:
            return MingDesignTokens.cinnabar
        case .campaignCue:
            return MingDesignTokens.imperialGold
        case .combat:
            return MingDesignTokens.cinnabar
        case .retreat:
            return MingDesignTokens.imperialGold
        case .reinforcement:
            return MingDesignTokens.jade
        case .encirclement:
            return MingDesignTokens.cinnabar
        case .supply:
            return MingDesignTokens.jade
        case .frontChange:
            return MingDesignTokens.porcelainBlue
        case .theaterChange:
            return MingDesignTokens.porcelainBlue
        case .regionOwnerChange:
            return MingDesignTokens.imperialGold
        case .diplomacy:
            return MingDesignTokens.porcelainBlue
        case .event:
            return .secondary
        }
    }

    var backgroundStyle: Color {
        foregroundStyle.opacity(0.12)
    }

    var systemImageName: String {
        switch self {
        case .campaignTask:
            return "exclamationmark.triangle"
        case .campaignCue:
            return "scroll"
        case .combat:
            return "flame"
        case .retreat:
            return "arrow.uturn.backward.circle"
        case .reinforcement:
            return "cross.case"
        case .encirclement:
            return "target"
        case .supply:
            return "shippingbox"
        case .frontChange:
            return "point.3.connected.trianglepath.dotted"
        case .theaterChange:
            return "map"
        case .regionOwnerChange:
            return "building.columns"
        case .diplomacy:
            return "globe.asia.australia"
        case .event:
            return "scroll"
        }
    }

    var isBattleReport: Bool {
        switch self {
        case .combat, .retreat, .reinforcement, .encirclement:
            return true
        case .campaignTask, .campaignCue, .supply, .frontChange, .theaterChange, .regionOwnerChange, .diplomacy, .event:
            return false
        }
    }

    var isTerritoryReport: Bool {
        switch self {
        case .frontChange, .theaterChange, .regionOwnerChange:
            return true
        case .campaignTask, .campaignCue, .combat, .retreat, .reinforcement, .encirclement, .supply, .diplomacy, .event:
            return false
        }
    }
}
