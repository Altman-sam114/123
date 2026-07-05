import SwiftUI

struct BattleObjectivePanelView: View {
    let gameState: GameState

    var body: some View {
        let summary = BattleObjectiveSummary.from(state: gameState)

        VStack(alignment: .leading, spacing: MingDesignTokens.sectionSpacing) {
            BattleObjectiveHeader(summary: summary, turn: gameState.turn, maxTurns: gameState.maxTurns)

            if summary.isMingScenario {
                BattleObjectiveScoreboard(summary: summary)

                VStack(alignment: .leading, spacing: MingDesignTokens.compactSpacing) {
                    Text("胜负线")
                        .font(.subheadline.bold())
                        .foregroundStyle(MingDesignTokens.ink)

                    ForEach(summary.tracks) { track in
                        BattleObjectiveTrackCard(
                            track: track,
                            isFinalTurn: gameState.turn >= gameState.maxTurns
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
                    BattleObjectiveTargetChip(target: target, tint: track.faction.mingBannerTint)
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
                Text("\(target.controllerName) / \(target.points) 分")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .background(MingDesignTokens.panelBackground.opacity(0.58), in: RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .combine)
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
