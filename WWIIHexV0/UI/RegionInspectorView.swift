import SwiftUI

struct RegionInspectorView: View {
    let inspectorState: RegionInspectorState?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("州府")
                .font(.headline)

            if let inspectorState {
                regionDetails(inspectorState)
            } else {
                Text("未选择州府。")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(PlatformStyles.systemBackground)
        .clipShape(.rect(cornerRadius: 8))
    }

    private func regionDetails(_ state: RegionInspectorState) -> some View {
        let occupation = state.region.occupationState ?? .stable

        return VStack(alignment: .leading, spacing: 8) {
            Text(state.region.name)
                .font(.subheadline.weight(.semibold))

            if let selectedHex = state.selectedHex {
                LabeledContent("地块") {
                    Text("\(selectedHex.q),\(selectedHex.r)")
                }

                LabeledContent("地块控制") {
                    Text(state.selectedHexController?.displayName ?? "无")
                }

                LabeledContent("动态方面") {
                    Text(state.selectedHexDynamicTheaterId?.rawValue ?? "无")
                }

                LabeledContent("前线防区") {
                    Text(state.selectedHexFrontZoneId?.rawValue ?? "无")
                }
            }

            LabeledContent("控制") {
                Text(state.region.controller.displayName)
            }

            LabeledContent("地形") {
                Text(state.region.terrain.displayName)
            }

            LabeledContent("城池") {
                Text(state.region.city?.name ?? "无")
            }

            LabeledContent("城级") {
                Text(state.cityLevel.displayName)
            }

            LabeledContent("关隘/要塞") {
                Text(state.region.terrain == .fortress ? "是" : "否")
            }

            LabeledContent("粮草") {
                Text("\(state.region.supplyValue)")
            }

            LabeledContent("工坊") {
                Text("\(state.region.factories)")
            }

            LabeledContent("产出") {
                Text(state.economicOutput.compactDisplaySummary)
                    .multilineTextAlignment(.trailing)
            }

            LabeledContent("治理") {
                Text(occupation.displaySummary)
                    .multilineTextAlignment(.trailing)
            }

            LabeledContent("钱粮修正") {
                Text("\(occupation.economicYieldPercent)%")
            }

            LabeledContent("方面") {
                Text(state.theaterId?.rawValue ?? "无")
            }

            LabeledContent("前线防区") {
                Text(state.frontZoneId?.rawValue ?? "无")
            }

            LabeledContent("前线压力") {
                Text(state.frontPressure, format: .number.precision(.fractionLength(2)))
            }

            LabeledContent("驿道/治理") {
                Text("\(state.region.infrastructure)")
            }

            LabeledContent("目标") {
                Text(state.objectiveNames.isEmpty ? "无" : state.objectiveNames.joined(separator: ", "))
                    .multilineTextAlignment(.trailing)
            }

            LabeledContent("目标状态") {
                Text(state.objectiveStatus)
            }

            LabeledContent("友军") {
                Text(unitNames(state.friendlyDivisions))
                    .multilineTextAlignment(.trailing)
            }

            LabeledContent("可见敌军") {
                Text(unitNames(state.visibleEnemyDivisions))
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private func unitNames(_ divisions: [Division]) -> String {
        guard !divisions.isEmpty else {
            return "无"
        }
        return divisions.map(\.name).joined(separator: ", ")
    }
}
