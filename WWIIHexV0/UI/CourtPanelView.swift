import SwiftUI

struct CourtPanelView: View {
    let gameState: GameState
    let playerFaction: Faction
    let observerModeEnabled: Bool
    let onEnactProject: (CourtProjectKind) -> Void

    var body: some View {
        let summary = CourtStrategySummary.from(faction: gameState.activeFaction, state: gameState)

        VStack(alignment: .leading, spacing: MingDesignTokens.sectionSpacing) {
            CourtHeaderView(faction: gameState.activeFaction, focus: summary.recommendedFocus)
            CourtRationaleView(summary: summary)
            CourtPressureSection(summary: summary)
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
        orderedProjects.filter { $0.primaryDomain == domain }
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
        return "\(tag)\(project.domainDisplayName) / 耗 \(project.cost.compactDisplaySummary)\(gain)。\(project.benefitSummary) 风险：\(project.riskSummary)"
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
        case .fortify:
            self = .fortify
        case .trainMilitia:
            self = .trainMilitia
        case .firearmReform:
            self = .firearmReform
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
