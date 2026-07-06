import SwiftUI

struct AgentPanelView: View {
    let record: AgentDecisionRecord?
    let rulerRecord: RulerDecisionRecord?
    let directiveRecords: [WarDirectiveRecord]
    let campaignSummary: CampaignAISummary

    init(
        record: AgentDecisionRecord?,
        rulerRecord: RulerDecisionRecord? = nil,
        directiveRecords: [WarDirectiveRecord] = [],
        campaignSummary: CampaignAISummary = .empty
    ) {
        self.record = record
        self.rulerRecord = rulerRecord
        self.directiveRecords = directiveRecords
        self.campaignSummary = campaignSummary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.sectionSpacing) {
            AgentPanelHeader(
                statusTitle: panelStatusTitle,
                statusTint: panelStatusTint,
                executedCount: executedCommandCount,
                rejectedCount: rejectedCommandCount,
                directiveCount: directiveRecords.count
            )

            decisionSection
            AgentCampaignSituationSection(summary: campaignSummary)

            if let rulerRecord {
                AgentRulerCard(record: rulerRecord)
            }

            directiveSection
            commandResultSection
            errorSection
            rawJSONSection
        }
        .padding(MingDesignTokens.panelPadding)
        .background(MingDesignTokens.panelBackground)
        .overlay {
            RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius)
                .stroke(MingDesignTokens.courtStroke.opacity(0.72), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }

    @ViewBuilder
    private var decisionSection: some View {
        if let record {
            AgentDecisionSummaryCard(record: record)
        } else {
            AgentSectionCard(title: "塘报空缺", systemImage: "tray", tint: .secondary) {
                Label("暂无军机复盘记录。", systemImage: "hourglass")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: MingDesignTokens.minimumTapSize, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private var directiveSection: some View {
        if !directiveRecords.isEmpty {
            AgentSectionCard(title: "战区指令", systemImage: "map", tint: MingDesignTokens.cinnabar) {
                LazyVStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
                    ForEach(directiveRecords) { directive in
                        AgentDirectiveCard(directive: directive)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var commandResultSection: some View {
        if !allCommandResults.isEmpty {
            AgentSectionCard(title: "命令回执", systemImage: "checklist", tint: MingDesignTokens.jade) {
                LazyVStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
                    ForEach(allCommandResults) { result in
                        AgentCommandResultCard(result: result)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        if let record, !record.errors.isEmpty {
            AgentSectionCard(title: "异常塘报", systemImage: "exclamationmark.triangle", tint: MingDesignTokens.cinnabar) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(record.errors, id: \.self) { error in
                        Label(AgentPanelFormat.errorDisplayText(error), systemImage: "xmark.octagon")
                            .font(.caption)
                            .foregroundStyle(MingDesignTokens.cinnabar)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var rawJSONSection: some View {
        AgentSectionCard(title: "军机底稿", systemImage: "scroll", tint: MingDesignTokens.porcelainBlue) {
            Text(record?.rawJSON ?? rawJSONPlaceholder)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(MingDesignTokens.compactSpacing)
                .background(MingDesignTokens.panelBackground.opacity(0.58), in: RoundedRectangle(cornerRadius: 6))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var allCommandResults: [CommandResultSummary] {
        (record?.commandResults ?? []) + directiveRecords.flatMap(\.commandResults)
    }

    private var executedCommandCount: Int {
        allCommandResults.filter(\.executed).count
    }

    private var rejectedCommandCount: Int {
        allCommandResults.filter { !$0.executed }.count
    }

    private var errorCount: Int {
        record?.errors.count ?? 0
    }

    private var panelStatusTitle: String {
        if errorCount > 0 {
            return "有异常"
        }
        if rejectedCommandCount > 0 {
            return "有驳回"
        }
        if executedCommandCount > 0 {
            return "已成令"
        }
        if record == nil && directiveRecords.isEmpty {
            return "候报"
        }
        return "已记录"
    }

    private var panelStatusTint: Color {
        if errorCount > 0 || rejectedCommandCount > 0 {
            return MingDesignTokens.cinnabar
        }
        if executedCommandCount > 0 {
            return MingDesignTokens.jade
        }
        return .secondary
    }

    private var rawJSONPlaceholder: String {
        """
        暂无可供核验的军机原稿。
        成令后将在此保留原始案卷，便于复查军令来源。
        """
    }
}

private struct AgentCampaignSituationSection: View {
    let summary: CampaignAISummary

    var body: some View {
        if summary.isMingScenario {
            AgentSectionCard(title: "军机五线", systemImage: "globe.asia.australia", tint: MingDesignTokens.cinnabar) {
                VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
                    Text(summary.displaySummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), spacing: 6)], alignment: .leading, spacing: 6) {
                        ForEach(summary.lineBriefs, id: \.line) { brief in
                            AgentCampaignLineChip(brief: brief)
                        }
                    }

                    if !summary.activeTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            Label("当旬军政钱粮火器", systemImage: "list.bullet.clipboard")
                                .font(.caption.bold())
                                .foregroundStyle(MingDesignTokens.imperialGold)

                            ForEach(Array(summary.activeTasks.prefix(3)), id: \.self) { task in
                                Text(task)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(MingDesignTokens.compactSpacing)
                        .background(MingDesignTokens.panelBackground.opacity(0.52), in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
    }
}

private struct AgentCampaignLineChip: View {
    let brief: CampaignLineAISummary

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .center, spacing: 5) {
                Label(brief.line, systemImage: systemImageName)
                    .font(.caption.bold())
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 4)

                Text(brief.status)
                    .font(.caption.bold())
                    .foregroundStyle(tint)
                    .lineLimit(1)
            }

            ProgressView(value: Double(brief.pressure), total: 100)
                .tint(tint)

            HStack(spacing: 5) {
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
        .background(MingDesignTokens.panelBackground.opacity(0.58), in: RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(tint.opacity(brief.status == "告急" ? 0.42 : 0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var tint: Color {
        switch brief.line {
        case "天下":
            return MingDesignTokens.cinnabar
        case "政策":
            return MingDesignTokens.porcelainBlue
        case "经济":
            return MingDesignTokens.jade
        case "科技":
            return MingDesignTokens.imperialGold
        case "军事":
            return MingDesignTokens.ink
        default:
            return .secondary
        }
    }

    private var systemImageName: String {
        switch brief.line {
        case "天下":
            return "globe.asia.australia"
        case "政策":
            return "scroll"
        case "经济":
            return "shippingbox"
        case "科技":
            return "sparkles"
        case "军事":
            return "shield.lefthalf.filled"
        default:
            return "circle"
        }
    }
}

private struct AgentPanelHeader: View {
    let statusTitle: String
    let statusTint: Color
    let executedCount: Int
    let rejectedCount: Int
    let directiveCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack(alignment: .center, spacing: 10) {
                Text("机")
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
                    Text("军机复盘")
                        .font(.headline)
                        .lineLimit(1)
                    Text("最高意志、督师指令、命令回执与军机底稿")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Text(statusTitle)
                    .font(.caption.bold())
                    .foregroundStyle(statusTint)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: 6))
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 78), spacing: 6)], alignment: .leading, spacing: 6) {
                AgentMetricChip(title: "成令", value: "\(executedCount)", systemImage: "checkmark.seal", tint: MingDesignTokens.jade)
                AgentMetricChip(title: "驳回", value: "\(rejectedCount)", systemImage: "xmark.seal", tint: rejectedCount > 0 ? MingDesignTokens.cinnabar : .secondary)
                AgentMetricChip(title: "战区", value: "\(directiveCount)", systemImage: "map", tint: MingDesignTokens.porcelainBlue)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct AgentDecisionSummaryCard: View {
    let record: AgentDecisionRecord

    var body: some View {
        AgentSectionCard(title: "决策摘要", systemImage: "scroll", tint: MingDesignTokens.imperialGold) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 6)], alignment: .leading, spacing: 6) {
                AgentInfoChip(title: "主事", value: AgentPanelFormat.agentTitle(record.agentId), systemImage: "person.crop.square", tint: MingDesignTokens.cinnabar)
                AgentInfoChip(title: "来源", value: AgentPanelFormat.providerTitle(record.provider), systemImage: "antenna.radiowaves.left.and.right", tint: MingDesignTokens.porcelainBlue)
                AgentInfoChip(title: "意图", value: record.parsedIntent ?? "尚无定策", systemImage: "scope", tint: MingDesignTokens.imperialGold)
            }

            VStack(alignment: .leading, spacing: 5) {
                Label("局势摘要", systemImage: "doc.text")
                    .font(.caption.bold())
                    .foregroundStyle(MingDesignTokens.jade)
                Text(AgentPanelFormat.contextSummaryText(record.contextSummary))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(MingDesignTokens.compactSpacing)
            .background(MingDesignTokens.panelBackground.opacity(0.52), in: RoundedRectangle(cornerRadius: 6))
        }
    }
}

private struct AgentRulerCard: View {
    let record: RulerDecisionRecord

    var body: some View {
        AgentSectionCard(title: "最高意志", systemImage: "crown", tint: MingDesignTokens.cinnabar) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 6)], alignment: .leading, spacing: 6) {
                AgentInfoChip(title: "主上", value: AgentPanelFormat.agentTitle(record.rulerAgentId), systemImage: "person.text.rectangle", tint: MingDesignTokens.cinnabar)
                AgentInfoChip(title: "姿态", value: record.posture.displayName, systemImage: "flag", tint: MingDesignTokens.imperialGold)
                AgentInfoChip(title: "重心", value: AgentPanelFormat.frontZoneTitle(record.preferredFrontZoneId, empty: "未指定"), systemImage: "scope", tint: MingDesignTokens.porcelainBlue)
                AgentInfoChip(title: "目标", value: targetText, systemImage: "mappin.and.ellipse", tint: MingDesignTokens.jade)
                AgentInfoChip(title: "攻势阈", value: attackThresholdText, systemImage: "gauge.with.dots.needle.bottom.50percent", tint: MingDesignTokens.imperialGold)
                AgentInfoChip(title: "留营", value: reserveBiasText, systemImage: "shield.lefthalf.filled", tint: MingDesignTokens.porcelainBlue)
            }

            if !record.diplomacySummary.isEmpty {
                AgentTextNote(title: "天下判断", systemImage: "globe.asia.australia", text: record.diplomacySummary, tint: MingDesignTokens.porcelainBlue)
            }

            if !record.rationale.isEmpty {
                AgentTextNote(title: "朱批理由", systemImage: "seal", text: record.rationale, tint: MingDesignTokens.cinnabar)
            }
        }
    }

    private var targetText: String {
        AgentPanelFormat.regionListTitle(record.targetRegionIds, empty: "未指定")
    }

    private var attackThresholdText: String {
        if record.attackThresholdAdjustment == 0 {
            return "不变"
        }
        return String(format: "%+.2f", record.attackThresholdAdjustment)
    }

    private var reserveBiasText: String {
        if record.reserveBias == 0 {
            return "不变"
        }
        return record.reserveBias > 0 ? "+\(record.reserveBias)" : "\(record.reserveBias)"
    }
}

private struct AgentDirectiveCard: View {
    let directive: WarDirectiveRecord

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            HStack(alignment: .center, spacing: 8) {
                Text(AgentPanelFormat.frontZoneTitle(directive.zoneId, empty: "全局"))
                    .font(.caption.bold())
                    .foregroundStyle(MingDesignTokens.cinnabar)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(MingDesignTokens.subtleSeal, in: RoundedRectangle(cornerRadius: 6))

                Text(directive.directiveType.map(AgentPanelFormat.directiveTypeText) ?? "诊断")
                    .font(.caption.bold())
                    .foregroundStyle(directive.directiveType == .attack ? MingDesignTokens.cinnabar : MingDesignTokens.jade)

                Spacer(minLength: 8)

                Text("\(executedCount) 成 / \(rejectedCount) 驳")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(rejectedCount > 0 ? MingDesignTokens.cinnabar : .secondary)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 6)], alignment: .leading, spacing: 6) {
                AgentInfoChip(title: "势力", value: directive.faction.displayName, systemImage: "flag.2.crossed", tint: MingDesignTokens.imperialGold)
                AgentInfoChip(title: "军机", value: AgentPanelFormat.agentTitle(directive.issuerId), systemImage: "person.crop.square", tint: MingDesignTokens.porcelainBlue)
                AgentInfoChip(title: "督师", value: directive.commanderAgentId.map(AgentPanelFormat.agentTitle) ?? "未署", systemImage: "person.line.dotted.person", tint: MingDesignTokens.jade)
                AgentInfoChip(title: "战术", value: tacticText, systemImage: "scope", tint: MingDesignTokens.cinnabar)
                AgentInfoChip(title: "目标", value: targetText, systemImage: "mappin.and.ellipse", tint: MingDesignTokens.porcelainBlue)
                AgentInfoChip(title: "指向", value: commandTargetText, systemImage: "arrow.up.right.circle", tint: MingDesignTokens.imperialGold)
            }

            AgentTextNote(
                title: "势力军略",
                systemImage: "seal",
                text: doctrineText,
                tint: doctrine.commandStyle.agentPanelTint
            )

            if !directive.diagnostics.isEmpty {
                AgentTextNote(
                    title: "塘报诊断",
                    systemImage: "waveform.path.ecg",
                    text: directive.diagnostics.joined(separator: " / "),
                    tint: MingDesignTokens.imperialGold
                )
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.panelBackground.opacity(0.52), in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }

    private var executedCount: Int {
        directive.commandResults.filter(\.executed).count
    }

    private var rejectedCount: Int {
        directive.commandResults.count - executedCount
    }

    private var tacticText: String {
        directive.tactic?.displayName ?? directive.category.map(AgentPanelFormat.commandCategoryText) ?? "未定"
    }

    private var targetText: String {
        AgentPanelFormat.regionListTitle(directive.targetRegionIds, empty: "无目标")
    }

    private var commandTargetText: String {
        guard let target = directive.commandTarget else {
            return "未指定"
        }

        return AgentPanelFormat.directiveTargetTitle(target)
    }

    private var doctrine: ZoneCommanderDoctrine {
        ZoneCommanderDoctrine.profile(for: directive.faction)
    }

    private var doctrineText: String {
        let skillText = doctrine.skills
            .map(AgentPanelFormat.doctrineSkillText)
            .joined(separator: " / ")
        let biasText = AgentPanelFormat.doctrineTacticBiasText(for: directive.faction)
        return "\(doctrine.title) · \(doctrine.commandStyle.agentPanelDisplayName)；偏重 \(skillText)；战术偏向 \(biasText)"
    }
}

private struct AgentCommandResultCard: View {
    let result: CommandResultSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .center, spacing: 8) {
                Label(result.agentPanelStatusText, systemImage: result.agentPanelStatusImage)
                    .font(.caption.bold())
                    .foregroundStyle(result.agentPanelStatusTint)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(AgentPanelFormat.commandDisplayText(result))
                    .font(.caption.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Text(result.agentPanelDetailText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 78), spacing: 6)], alignment: .leading, spacing: 6) {
                AgentInfoChip(title: "部队", value: result.divisionId ?? "全局", systemImage: "shield", tint: MingDesignTokens.porcelainBlue)
                AgentInfoChip(title: "令序", value: result.orderIndex.map { "第 \($0 + 1) 道" } ?? "无", systemImage: "number", tint: MingDesignTokens.imperialGold)
                AgentInfoChip(title: "校验", value: result.agentPanelValidationText, systemImage: "checkmark.shield", tint: result.agentPanelStatusTint)
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.panelBackground.opacity(0.52), in: RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
    }
}

private struct AgentSectionCard<Content: View>: View {
    let title: String
    let systemImage: String
    let tint: Color
    let content: Content

    init(
        title: String,
        systemImage: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.bold())
                .foregroundStyle(tint)
                .lineLimit(1)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }
}

private struct AgentMetricChip: View {
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
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(tint)
                    .lineLimit(1)
            }
        } icon: {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MingDesignTokens.sectionBackground, in: RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .combine)
    }
}

private struct AgentInfoChip: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(value)
                    .font(.caption.bold())
                    .foregroundStyle(tint)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } icon: {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(tint)
                .frame(width: 16)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
        .background(MingDesignTokens.panelBackground.opacity(0.58), in: RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .combine)
    }
}

private struct AgentTextNote: View {
    let title: String
    let systemImage: String
    let text: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: systemImage)
                .font(.caption.bold())
                .foregroundStyle(tint)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.panelBackground.opacity(0.52), in: RoundedRectangle(cornerRadius: 6))
    }
}

private enum AgentPanelFormat {
    static func agentTitle(_ id: String) -> String {
        MingMapLabelFormat.agentTitle(id)
    }

    static func providerTitle(_ provider: String) -> String {
        switch provider {
        case "MockAI":
            return "军机推演"
        case "System":
            return "系统成令"
        case "Static":
            return "定稿案卷"
        case "FailingProvider":
            return "异常案卷"
        default:
            if provider.contains("+") {
                return provider
                    .split(separator: "+")
                    .map { providerTitle(String($0)) }
                    .joined(separator: " + ")
            }
            if provider.localizedCaseInsensitiveContains("llm") {
                return "外部军机案卷"
            }
            return readableFallback(provider, prefix: "案卷来源")
        }
    }

    static func contextSummaryText(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "暂无战场摘要。"
        }
        if trimmed == "No AI faction was active." {
            return "当前无军机势力行动。"
        }
        return text
    }

    static func frontZoneTitle(_ id: FrontZoneId?, empty: String) -> String {
        guard let id else {
            return empty
        }
        return MingMapLabelFormat.frontZoneTitle(id)
    }

    static func regionListTitle(_ ids: [RegionId], empty: String) -> String {
        let text = ids.map(MingMapLabelFormat.regionTitle).joined(separator: "、")
        return text.isEmpty ? empty : text
    }

    static func directiveTargetTitle(_ target: DirectiveTarget) -> String {
        switch target {
        case .theater(let theaterId):
            return "方面 \(MingMapLabelFormat.theaterTitle(theaterId))"
        case .region(let regionId):
            return "州府 \(MingMapLabelFormat.regionTitle(regionId))"
        }
    }

    static func directiveTypeText(_ type: DirectiveType) -> String {
        switch type {
        case .attack:
            return "进攻"
        case .defend:
            return "防御"
        }
    }

    static func commandCategoryText(_ category: CommandCategory) -> String {
        switch category {
        case .offense:
            return "攻势"
        case .defense:
            return "守势"
        }
    }

    static func commandDisplayText(_ result: CommandResultSummary) -> String {
        if let commandDisplayName = result.commandDisplayName,
           let text = localizedCommandText(commandDisplayName) {
            return text
        }

        return result.orderType?.displayName ?? "军令"
    }

    private static func localizedCommandText(_ commandDisplayName: String) -> String? {
        if commandDisplayName.hasPrefix("Move(") {
            return "调动"
        }
        if commandDisplayName.hasPrefix("Attack(") {
            return "攻击"
        }
        if commandDisplayName.hasPrefix("Hold(") {
            return "固守"
        }
        if commandDisplayName.hasPrefix("AllowRetreat(") {
            return "准退"
        }
        if commandDisplayName.hasPrefix("Resupply(") {
            return "补给整备"
        }
        if commandDisplayName.hasPrefix("QueueProduction(") {
            return "营造筹备"
        }
        if commandDisplayName.hasPrefix("朝廷项目(") {
            return commandDisplayName
        }
        if commandDisplayName == "End Turn" {
            return "结束阶段"
        }
        return nil
    }

    static func doctrineSkillText(_ skill: String) -> String {
        switch skill {
        case "capital_defense":
            return "守京畿"
        case "grain_conservation":
            return "保粮"
        case "fortress_coordination":
            return "城关协防"
        case "banner_cavalry":
            return "旗骑"
        case "encirclement":
            return "合围"
        case "relief_route_cutting":
            return "截援"
        case "grain_expansion":
            return "扩粮"
        case "weak_city_breakthrough":
            return "破弱城"
        case "rapid_consolidation":
            return "巩固中原"
        case "mobile_raiding":
            return "流动作战"
        case "supply_capture":
            return "夺粮"
        case "rear_disruption":
            return "扰后"
        case "town_security":
            return "守城镇"
        case "militia_defense":
            return "团练自保"
        case "armored_thrust":
            return "装甲突击"
        case "operational_breakthrough":
            return "纵深突破"
        case "coalition_coordination":
            return "联军协同"
        case "reserve_control":
            return "预备队管制"
        default:
            return readableFallback(skill, prefix: "军略")
        }
    }

    static func doctrineTacticBiasText(for faction: Faction) -> String {
        switch faction {
        case .ming:
            return "火器压制 / 层层设防"
        case .qing:
            return "突骑破阵 / 合围"
        case .dashun:
            return "破围 / 正攻"
        case .daxi:
            return "流动作战 / 佯攻"
        case .localNeutral:
            return "固守 / 团练自保"
        case .germany:
            return "疾袭 / 突破"
        case .allies:
            return "联军协同 / 预备队"
        }
    }

    static func errorDisplayText(_ text: String) -> String {
        if let validationError = CommandValidationError(rawValue: text) {
            return validationError.mingDisplayText
        }

        switch text {
        case "Mapping failed.":
            return "军令映射未成"
        case "No AI faction was active.":
            return "当前无军机势力行动"
        default:
            if text.localizedCaseInsensitiveContains("mapping failed") {
                return "军令映射未成"
            }
            if text.localizedCaseInsensitiveContains("not found") {
                return "案卷目标未找到"
            }
            if text.localizedCaseInsensitiveContains("invalid") {
                return "案卷格式不合"
            }
            if text.localizedCaseInsensitiveContains("empty") {
                return "案卷为空"
            }
            return readableFallback(text, prefix: "异常案卷")
        }
    }

    static func commandMessageText(_ message: String) -> String {
        switch message {
        case "Mapping failed.":
            return "军令映射未成。"
        default:
            return message
        }
    }

    static func validationErrorListText(_ errors: [String], empty: String) -> String {
        let text = errors
            .map(errorDisplayText)
            .filter { !$0.isEmpty }
            .joined(separator: "、")
        return text.isEmpty ? empty : text
    }

    private static func readableFallback(_ value: String, prefix: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "\(prefix)：未载"
        }

        let readable = trimmed
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
        return "\(prefix)：\(readable)"
    }

}

private extension ZoneCommanderAgentConfig.CommandStyle {
    var agentPanelDisplayName: String {
        switch self {
        case .aggressive:
            return "锐进"
        case .balanced:
            return "持重"
        case .cautious:
            return "谨守"
        }
    }

    var agentPanelTint: Color {
        switch self {
        case .aggressive:
            return MingDesignTokens.cinnabar
        case .balanced:
            return MingDesignTokens.porcelainBlue
        case .cautious:
            return MingDesignTokens.jade
        }
    }
}

private extension CommandResultSummary {
    var agentPanelStatusText: String {
        if !mappingSucceeded {
            return "映射失败"
        }
        return executed ? "已执行" : "被驳回"
    }

    var agentPanelStatusImage: String {
        if !mappingSucceeded {
            return "exclamationmark.triangle"
        }
        return executed ? "checkmark.seal" : "xmark.seal"
    }

    var agentPanelStatusTint: Color {
        if executed {
            return MingDesignTokens.jade
        }
        if !mappingSucceeded || !(validationSucceeded ?? true) {
            return MingDesignTokens.cinnabar
        }
        return MingDesignTokens.imperialGold
    }

    var agentPanelDetailText: String {
        if !mappingSucceeded {
            let text = AgentPanelFormat.validationErrorListText(errors, empty: "")
            return text.isEmpty ? "军令未能映射到底层命令。" : "军令映射未成：\(text)"
        }
        if executed {
            return AgentPanelFormat.commandMessageText(message)
        }
        if !errors.isEmpty {
            return "被规则驳回：\(AgentPanelFormat.validationErrorListText(errors, empty: "未列明原因"))"
        }
        return AgentPanelFormat.commandMessageText(message)
    }

    var agentPanelValidationText: String {
        if !mappingSucceeded {
            return "未成令"
        }
        guard let validationSucceeded else {
            return "未校验"
        }
        return validationSucceeded ? "合规" : "未准"
    }
}

private extension AgentOrderType {
    var displayName: String {
        switch self {
        case .move:
            return "行军"
        case .attack:
            return "进攻"
        case .hold:
            return "固守"
        case .resupply:
            return "补给"
        }
    }
}
