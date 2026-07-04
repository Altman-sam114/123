import SwiftUI

struct EconomyPanelView: View {
    let gameState: GameState
    let playerFaction: Faction
    let observerModeEnabled: Bool
    let onQueueProduction: (ProductionKind) -> Void

    var body: some View {
        let faction = gameState.activeFaction
        let ledger = gameState.economyState.ledger(for: faction)

        VStack(alignment: .leading, spacing: 10) {
            TreasuryHeader(
                faction: faction,
                canAct: canActForCurrentFaction,
                observerModeEnabled: observerModeEnabled
            )
            TreasuryStockpileSection(ledger: ledger)
            ProductionActionSection(
                ledger: ledger,
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

private struct ProductionActionSection: View {
    let ledger: FactionEconomyLedger
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
                        onQueueProduction: onQueueProduction
                    )
                }
            }
        }
        .padding(MingDesignTokens.compactSpacing)
        .background(MingDesignTokens.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }
}

private struct ProductionActionRow: View {
    let kind: ProductionKind
    let canQueue: Bool
    let canAfford: Bool
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
                Text(kind.intentSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
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
