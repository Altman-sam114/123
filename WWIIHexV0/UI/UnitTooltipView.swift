import SwiftUI

struct UnitTooltipView: View {
    let division: Division?

    var body: some View {
        if let division {
            VStack(alignment: .leading, spacing: 6) {
                Text(division.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 4) {
                    GridRow {
                        label("类型")
                        value(division.tooltipTypeCode)
                    }
                    GridRow {
                        label("兵力")
                        value("\(division.strength)/\(division.maxStrength)")
                    }
                    GridRow {
                        label("粮草")
                        value(division.supplyState.tooltipDisplayName)
                    }
                    GridRow {
                        label("退守")
                        value(division.retreatMode.tooltipDisplayName)
                    }
                    GridRow {
                        label("行动")
                        value(division.hasActed ? "是" : "否")
                    }
                }
            }
            .padding(10)
            .frame(width: 220, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.secondary.opacity(0.35), lineWidth: 1)
            }
            .padding(10)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(division.name)，\(division.tooltipTypeCode)，兵力 \(division.strength) / \(division.maxStrength)")
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func value(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }
}

private extension Division {
    var tooltipTypeCode: String {
        if isSiegeCapable {
            return "攻城"
        }
        if isArmor {
            return "旗骑"
        }
        if hasFireSupport {
            return "火器"
        }
        if isMobileUnit {
            return "骑兵"
        }
        return "步军"
    }
}

private extension RetreatMode {
    var tooltipDisplayName: String {
        switch self {
        case .retreatable:
            return "可退守"
        case .hold:
            return "固守"
        }
    }
}

private extension SupplyState {
    var tooltipDisplayName: String {
        switch self {
        case .supplied:
            return "有粮"
        case .lowSupply:
            return "缺粮"
        case .encircled:
            return "被围"
        }
    }
}
