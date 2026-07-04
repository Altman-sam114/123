import SwiftUI

struct AgentPanelView: View {
    let record: AgentDecisionRecord?
    let rulerRecord: RulerDecisionRecord?
    let directiveRecords: [WarDirectiveRecord]

    init(
        record: AgentDecisionRecord?,
        rulerRecord: RulerDecisionRecord? = nil,
        directiveRecords: [WarDirectiveRecord] = []
    ) {
        self.record = record
        self.rulerRecord = rulerRecord
        self.directiveRecords = directiveRecords
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AI 决策")
                .font(.headline)

            LabeledContent("主事") {
                Text(record?.agentId ?? "暂无主事")
            }

            LabeledContent("来源") {
                Text(record?.provider ?? "模拟 AI")
            }

            LabeledContent("意图") {
                Text(record?.parsedIntent ?? "尚无决策。")
                    .multilineTextAlignment(.trailing)
            }

            if let contextSummary = record?.contextSummary {
                LabeledContent("摘要") {
                    Text(contextSummary)
                        .multilineTextAlignment(.trailing)
                }
            }

            if let rulerRecord {
                Divider()
                LabeledContent("最高意志") {
                    Text(rulerRecord.rulerAgentId)
                }
                LabeledContent("姿态") {
                    Text(rulerRecord.posture.displayName)
                }
                if let zoneId = rulerRecord.preferredFrontZoneId {
                    LabeledContent("重心") {
                        Text(zoneId.rawValue)
                    }
                }
            }

            if let record, !record.commandResults.isEmpty {
                Text("命令结果")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(record.commandResults) { result in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.commandDisplayName ?? result.orderType?.rawValue ?? "军令")
                                .font(.caption)
                                .bold()
                            Text(resultLine(result))
                                .font(.caption)
                                .foregroundStyle(result.executed ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            if !directiveRecords.isEmpty {
                Text("战区指令")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(directiveRecords) { directive in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(directive.zoneId?.rawValue ?? "全局")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(MingDesignTokens.subtleSeal)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))

                                Text(directiveSummary(directive))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }

                            if !directive.diagnostics.isEmpty {
                                Text(directive.diagnostics.joined(separator: " / "))
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(6)
                        .background(MingDesignTokens.sectionBackground)
                        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
                    }
                }
            }

            if let record, !record.errors.isEmpty {
                Text("错误")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(record.errors, id: \.self) { error in
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }

            Text("原始 JSON")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(record?.rawJSON ?? rawJSONPlaceholder)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(MingDesignTokens.sectionBackground)
                .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
        }
        .padding(MingDesignTokens.panelPadding)
        .background(MingDesignTokens.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }

    private func directiveSummary(_ directive: WarDirectiveRecord) -> String {
        let type = directive.directiveType.map(directiveTypeText) ?? "诊断"
        let tactic = directive.tactic?.displayName ?? directive.category?.rawValue ?? "无战术"
        let executed = directive.commandResults.filter(\.executed).count
        let rejected = directive.commandResults.count - executed
        let targets = directive.targetRegionIds.map(\.rawValue).joined(separator: ", ")
        let targetText = targets.isEmpty ? "无目标" : targets
        return "\(type) / \(tactic) / 成功 \(executed)，拒绝 \(rejected) / \(targetText)"
    }

    private func resultLine(_ result: CommandResultSummary) -> String {
        if !result.mappingSucceeded {
            return "映射失败：\(result.errors.joined(separator: ", "))"
        }

        if result.executed {
            return result.message
        }

        if !result.errors.isEmpty {
            return "被拒绝：\(result.errors.joined(separator: ", "))"
        }

        return result.message
    }

    private func directiveTypeText(_ type: DirectiveType) -> String {
        switch type {
        case .attack:
            return "进攻"
        case .defend:
            return "防御"
        }
    }

    private var rawJSONPlaceholder: String {
        """
        {
          "agentId": "明末枢辅",
          "status": "暂无决策",
          "orders": []
        }
        """
    }
}
