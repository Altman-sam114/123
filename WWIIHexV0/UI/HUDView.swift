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
