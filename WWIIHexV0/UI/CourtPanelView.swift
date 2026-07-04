import SwiftUI

struct CourtPanelView: View {
    let gameState: GameState

    var body: some View {
        let summary = CourtStrategySummary.from(faction: gameState.activeFaction, state: gameState)

        VStack(alignment: .leading, spacing: MingDesignTokens.sectionSpacing) {
            CourtHeaderView(faction: gameState.activeFaction, focus: summary.recommendedFocus)
            CourtRationaleView(summary: summary)
            CourtPressureSection(summary: summary)
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
