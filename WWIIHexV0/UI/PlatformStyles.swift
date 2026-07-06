import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum PlatformStyles {
    static var systemBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .systemBackground)
        #endif
    }

    static var secondarySystemBackground: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(uiColor: .secondarySystemBackground)
        #endif
    }

    static var tertiarySystemBackground: Color {
        #if os(macOS)
        Color(nsColor: .underPageBackgroundColor)
        #else
        Color(uiColor: .tertiarySystemBackground)
        #endif
    }

    static var panelStroke: Color {
        .secondary.opacity(0.28)
    }

    static var selectionTint: Color {
        .yellow.opacity(0.18)
    }
}

enum MingDesignTokens {
    static let cornerRadius: CGFloat = 8
    static let panelPadding: CGFloat = 12
    static let sectionSpacing: CGFloat = 12
    static let compactSpacing: CGFloat = 8
    static let minimumTapSize: CGFloat = 44

    static var cinnabar: Color {
        Color(red: 0.62, green: 0.13, blue: 0.12)
    }

    static var imperialGold: Color {
        Color(red: 0.82, green: 0.58, blue: 0.18)
    }

    static var ink: Color {
        Color(red: 0.12, green: 0.13, blue: 0.13)
    }

    static var jade: Color {
        Color(red: 0.14, green: 0.44, blue: 0.32)
    }

    static var porcelainBlue: Color {
        Color(red: 0.18, green: 0.34, blue: 0.56)
    }

    static var panelBackground: Color {
        PlatformStyles.systemBackground
    }

    static var sectionBackground: Color {
        PlatformStyles.tertiarySystemBackground
    }

    static var subtleSeal: Color {
        cinnabar.opacity(0.14)
    }

    static var courtStroke: Color {
        imperialGold.opacity(0.46)
    }
}

enum MingMapLabelFormat {
    static func agentTitle(_ id: String) -> String {
        switch id {
        case "ruler_chongzhen":
            return "崇祯御前"
        case "ruler_huangtaiji":
            return "清主御前"
        case "ruler_li_zicheng":
            return "大顺中军"
        case "ruler_zhang_xianzhong":
            return "大西行营"
        case "ruler_local_neutral":
            return "地方乡绅"
        case "ruler_germany":
            return "德军统帅部"
        case "ruler_allies":
            return "盟军统帅部"
        case "marshal_ming":
            return "明廷枢辅"
        case "marshal_qing":
            return "清军议政"
        case "marshal_dashun":
            return "大顺军师"
        case "marshal_daxi":
            return "大西军师"
        case "marshal_localNeutral":
            return "地方团练"
        default:
            if id.hasPrefix("ruler_") {
                return readableIdentifier(id, removing: "ruler_")
            }
            if id.hasPrefix("marshal_") {
                return readableIdentifier(id, removing: "marshal_")
            }
            if id.hasPrefix("commander_") {
                return readableIdentifier(id, removing: "commander_")
            }
            return id
        }
    }

    static func coordinate(_ coord: HexCoord) -> String {
        "舆图格 \(coord.q)-\(coord.r)"
    }

    static func countryTitle(_ id: CountryId) -> String {
        switch id.rawValue {
        case "ming":
            return "明廷"
        case "qing":
            return "后金/清"
        case "dashun":
            return "大顺"
        case "daxi":
            return "大西"
        case "local_neutral":
            return "地方中立"
        default:
            return readableIdentifier(id.rawValue, removing: nil)
        }
    }

    static func blocTitle(_ id: DiplomaticBlocId) -> String {
        switch id.rawValue {
        case "ming_court":
            return "明廷朝局"
        case "qing_banners":
            return "八旗军议"
        case "dashun_camp":
            return "大顺行营"
        case "daxi_camp":
            return "大西行营"
        case "local_neutral":
            return "地方观望"
        default:
            return readableIdentifier(id.rawValue, removing: nil)
        }
    }

    static func regionTitle(_ id: RegionId?, empty: String = "无") -> String {
        guard let id else {
            return empty
        }
        return regionTitle(id)
    }

    static func theaterTitle(_ id: TheaterId?, empty: String = "无") -> String {
        guard let id else {
            return empty
        }
        return theaterTitle(id)
    }

    static func frontZoneTitle(_ id: FrontZoneId?, empty: String = "无") -> String {
        guard let id else {
            return empty
        }
        return frontZoneTitle(id)
    }

    static func frontLineSummary(_ ids: [FrontLineId], empty: String = "无") -> String {
        guard !ids.isEmpty else {
            return empty
        }
        if ids.count == 1, let first = ids.first {
            return "接敌线 \(readableIdentifier(first.rawValue, removing: "frontline_"))"
        }
        return "接敌线 \(ids.count) 处"
    }

    static func regionTitle(_ id: RegionId) -> String {
        switch id.rawValue {
        case "region_liaodong_rear":
            return "辽东后路"
        case "region_jinzhou":
            return "锦州"
        case "region_ningyuan":
            return "宁远"
        case "region_shanhaiguan":
            return "山海关"
        case "region_xuanfu":
            return "宣府"
        case "region_datong":
            return "大同"
        case "region_yongping":
            return "永平"
        case "region_jizhou":
            return "蓟州"
        case "region_beijing":
            return "北京"
        case "region_baoding":
            return "保定"
        case "region_zhending":
            return "真定"
        case "region_taiyuan":
            return "太原"
        case "region_dengzhou":
            return "登莱"
        case "region_jinan":
            return "济南"
        case "region_kaifeng":
            return "开封"
        case "region_luoyang":
            return "洛阳"
        case "region_tongguan":
            return "潼关"
        case "region_xian":
            return "西安"
        case "region_xuzhou":
            return "徐州"
        case "region_guide":
            return "归德"
        case "region_nanyang":
            return "南阳"
        case "region_xiangyang":
            return "襄阳"
        case "region_hanzhong":
            return "汉中"
        case "region_shaanxi_hinterland":
            return "秦陕后路"
        case "region_huaian":
            return "淮安"
        case "region_fengyang":
            return "凤阳"
        case "region_wuchang":
            return "武昌"
        case "region_jingzhou":
            return "荆州"
        case "region_yunyang":
            return "郧阳"
        case "region_sichuan_gate":
            return "川东门户"
        default:
            return readableIdentifier(id.rawValue, removing: "region_")
        }
    }

    static func theaterTitle(_ id: TheaterId) -> String {
        switch id.rawValue {
        case "theater_qing_liaodong":
            return "辽东清军"
        case "theater_ming_guanning":
            return "关宁防线"
        case "theater_ming_jifu":
            return "畿辅防区"
        case "theater_ming_northwest":
            return "西北边镇"
        case "theater_ming_shandong":
            return "山东登莱"
        case "theater_ming_huaihu":
            return "淮湖防线"
        case "theater_dashun_henan":
            return "大顺河南"
        case "theater_dashun_shaanxi":
            return "大顺秦陕"
        case "theater_daxi_huguang":
            return "大西湖广"
        default:
            return readableIdentifier(id.rawValue, removing: "theater_")
        }
    }

    static func frontZoneTitle(_ id: FrontZoneId) -> String {
        switch id.rawValue {
        case "ming_zone":
            return "畿辅防区"
        case "qing_zone":
            return "关外旗营"
        case "dashun_zone":
            return "河南老营"
        case "daxi_zone":
            return "湖广机动营"
        case "local_zone":
            return "乡绅团练"
        default:
            if id.rawValue.hasPrefix("theater_") {
                return theaterTitle(TheaterId(id.rawValue))
            }
            return readableIdentifier(id.rawValue, removing: nil)
        }
    }

    static func readableIdentifier(_ value: String, removing prefix: String?) -> String {
        let trimmed: String
        if let prefix, value.hasPrefix(prefix) {
            trimmed = String(value.dropFirst(prefix.count))
        } else {
            trimmed = value
        }
        return trimmed.replacingOccurrences(of: "_", with: " ")
    }
}

extension Faction {
    var mingBannerTint: Color {
        switch self {
        case .germany:
            return .gray
        case .allies:
            return .blue
        case .ming:
            return MingDesignTokens.cinnabar
        case .qing:
            return MingDesignTokens.jade
        case .dashun:
            return MingDesignTokens.imperialGold
        case .daxi:
            return .purple
        case .localNeutral:
            return .secondary
        }
    }
}

struct MingFactionFlagBadge: View {
    let faction: Faction

    var body: some View {
        Text(faction.bannerGlyph)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .lineLimit(1)
            .frame(minWidth: 20, minHeight: 18)
            .padding(.horizontal, 4)
            .background(faction.mingBannerTint, in: RoundedRectangle(cornerRadius: 4))
            .accessibilityLabel(Text("\(faction.displayName)旗号"))
    }
}
