import SwiftUI

struct UnitInspectorView: View {
    let division: Division?
    let playerFaction: Faction
    let strategicState: UnitInspectorStrategicState?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("军队详情")
                .font(.headline)

            if let division {
                unitDetails(division)
            } else {
                Text("未选中部队。")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(MingDesignTokens.panelPadding)
        .background(MingDesignTokens.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: MingDesignTokens.cornerRadius))
    }

    private func unitDetails(_ division: Division) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(division.name)
                .font(.subheadline.weight(.semibold))

            LabeledContent("势力") {
                Text(division.faction.displayName)
            }

            LabeledContent("控制") {
                Text(division.faction == playerFaction ? "玩家" : "只读")
            }

            if let strategicState {
                LabeledContent("坐标") {
                    Text("\(strategicState.coord.q),\(strategicState.coord.r)")
                }

                LabeledContent("州府") {
                    Text(strategicState.regionId?.rawValue ?? "无")
                }

                LabeledContent("动态方面") {
                    Text(strategicState.dynamicTheaterId?.rawValue ?? "无")
                }

                LabeledContent("前线防区") {
                    Text(strategicState.frontZoneId?.rawValue ?? "无")
                }

                LabeledContent("部署") {
                    Text(strategicState.deploymentRole.displayName)
                }

                LabeledContent("前线") {
                    Text(frontLineSummary(strategicState.frontLineIds))
                        .multilineTextAlignment(.trailing)
                }
            }

            LabeledContent("兵力") {
                Text(division.inspectorStrengthText)
            }

            LabeledContent("退守") {
                Text(division.retreatMode.displayName)
            }

            LabeledContent("粮草") {
                Text(division.supplyState.displayName)
            }

            LabeledContent("已行动") {
                Text(division.hasActed ? "是" : "否")
            }

            LabeledContent("状态") {
                Text(division.inspectorStatusText)
            }

            LabeledContent("兵种") {
                Text(componentSummary(for: division))
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private func componentSummary(for division: Division) -> String {
        division.components
            .map { "\($0.type.displayCode) \(Int(($0.weight * 100).rounded()))%" }
            .joined(separator: " / ")
    }

    private func frontLineSummary(_ ids: [FrontLineId]) -> String {
        ids.isEmpty ? "无" : ids.map(\.rawValue).joined(separator: ", ")
    }
}

private extension Division {
    var inspectorStrengthText: String {
        "\(strength) / \(maxStrength)"
    }

    var inspectorStatusText: String {
        var statuses: [String] = []

        if isRetreating {
            statuses.append("退守中")
        }

        if isDestroyed {
            statuses.append("溃散")
        }

        return statuses.isEmpty ? "待命" : statuses.joined(separator: ", ")
    }
}

private extension RetreatMode {
    var displayName: String {
        switch self {
        case .retreatable:
            return "可退守"
        case .hold:
            return "固守"
        }
    }
}

private extension ComponentType {
    var displayCode: String {
        switch self {
        case .tank:
            return "装甲"
        case .motorizedInfantry:
            return "摩托"
        case .infantry:
            return "步军"
        case .artillery:
            return "炮队"
        case .cavalry:
            return "骑兵"
        case .firearm:
            return "火器"
        case .bannerCavalry:
            return "旗骑"
        case .militia:
            return "团练"
        case .siegeEngine:
            return "攻城"
        }
    }
}

private extension SupplyState {
    var displayName: String {
        switch self {
        case .supplied:
            return "有粮"
        case .lowSupply:
            return "缺粮"
        case .encircled:
            return "断粮/被围"
        }
    }
}

private extension UnitDeploymentRole {
    var displayName: String {
        switch self {
        case .frontUnit:
            return "前线"
        case .depthUnit:
            return "纵深"
        case .garrisonUnit:
            return "驻防"
        }
    }
}

private extension Set where Element == HexDirection {
    var displaySummary: String {
        HexDirection.ordered
            .filter { contains($0) }
            .map(\.displayCode)
            .joined(separator: ", ")
    }
}

private extension HexDirection {
    var displayCode: String {
        switch self {
        case .east:
            return "东"
        case .northEast:
            return "东北"
        case .northWest:
            return "西北"
        case .west:
            return "西"
        case .southWest:
            return "西南"
        case .southEast:
            return "东南"
        }
    }
}
