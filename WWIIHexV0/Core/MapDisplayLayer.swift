import Foundation

enum MapDisplayLayer: String, Codable, Equatable, CaseIterable, Identifiable {
    case hex
    case province
    case initialTheater
    case dynamicTheater
    case frontLine
    case deployment

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .hex:
            return "舆图"
        case .province:
            return "州府"
        case .initialTheater:
            return "初划"
        case .dynamicTheater:
            return "战局"
        case .frontLine:
            return "前线"
        case .deployment:
            return "布防"
        }
    }

    var systemImageName: String {
        switch self {
        case .hex:
            return "map"
        case .province:
            return "square.grid.3x3"
        case .initialTheater:
            return "flag"
        case .dynamicTheater:
            return "arrow.triangle.branch"
        case .frontLine:
            return "waveform.path.ecg"
        case .deployment:
            return "shield.lefthalf.filled"
        }
    }

    var legendTitle: String {
        switch self {
        case .hex:
            return "城关粮与军牌"
        case .province:
            return "州府聚合"
        case .initialTheater:
            return "开局方面"
        case .dynamicTheater:
            return "战局方面"
        case .frontLine:
            return "接触前线"
        case .deployment:
            return "军区布防"
        }
    }

    var legendDetail: String {
        switch self {
        case .hex:
            return "显示城池、关隘、粮台、军牌和粮道。"
        case .province:
            return "按州府查看钱粮、治理和控制归属。"
        case .initialTheater:
            return "地图编辑器给出的初始方面基准。"
        case .dynamicTheater:
            return "随具体 hex 推进变化的运行时方面。"
        case .frontLine:
            return "敌我动态方面真实相邻形成的战线。"
        case .deployment:
            return "前线、纵深、驻守三层军区归属。"
        }
    }
}
