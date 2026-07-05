import Foundation

struct BattleObjectiveSummary: Equatable {
    enum TrackId: String, Equatable {
        case qingPassCapital
        case dashunCentralPlain
        case daxiHuguang
        case mingMandateLine
    }

    enum Timing: Equatable {
        case immediate
        case finalTurn

        var displayName: String {
            switch self {
            case .immediate:
                return "即时判定"
            case .finalTurn:
                return "终局判定"
            }
        }
    }

    struct Target: Equatable, Identifiable {
        let objectiveId: String
        let name: String
        let requiredFaction: Faction
        let controller: Faction?
        let points: Int

        var id: String {
            objectiveId
        }

        var isControlled: Bool {
            controller == requiredFaction
        }

        var controllerName: String {
            controller?.displayName ?? "无人控制"
        }
    }

    struct Track: Equatable, Identifiable {
        let id: TrackId
        let title: String
        let subtitle: String
        let faction: Faction
        let reason: VictoryReason
        let timing: Timing
        let targets: [Target]

        var controlledCount: Int {
            targets.filter(\.isControlled).count
        }

        var requiredCount: Int {
            targets.count
        }

        var isSatisfied: Bool {
            controlledCount == requiredCount && requiredCount > 0
        }

        var progress: Double {
            guard requiredCount > 0 else { return 0 }
            return Double(controlledCount) / Double(requiredCount)
        }

        var statusText: String {
            if isSatisfied {
                return "\(reason.displayName)已成"
            }
            return "尚缺 \(requiredCount - controlledCount) 处"
        }
    }

    struct ScoreRow: Equatable, Identifiable {
        let faction: Faction
        let points: Int
        let objectiveCount: Int

        var id: Faction {
            faction
        }
    }

    struct Cue: Equatable, Identifiable {
        enum Kind: String, Equatable {
            case history
            case policy
            case economy
            case military
            case agent

            var displayName: String {
                switch self {
                case .history:
                    return "史势"
                case .policy:
                    return "政务"
                case .economy:
                    return "钱粮"
                case .military:
                    return "军务"
                case .agent:
                    return "军机"
                }
            }

            var systemImage: String {
                switch self {
                case .history:
                    return "scroll"
                case .policy:
                    return "building.columns"
                case .economy:
                    return "shippingbox"
                case .military:
                    return "shield.lefthalf.filled"
                case .agent:
                    return "brain.head.profile"
                }
            }
        }

        let id: String
        let kind: Kind
        let title: String
        let detail: String

        var eventMessage: String {
            "\(kind.displayName) · \(title)：\(detail)"
        }

        var eventCategory: GameLogCategory {
            switch kind {
            case .economy:
                return .supply
            case .military:
                return .frontChange
            case .agent,
                 .history,
                 .policy:
                return .event
            }
        }
    }

    let title: String
    let subtitle: String
    let isMingScenario: Bool
    let tracks: [Track]
    let scoreRows: [ScoreRow]
    let leadingFaction: Faction?
    let cues: [Cue]

    static func from(state: GameState) -> BattleObjectiveSummary {
        guard state.scenarioId.hasPrefix("chongzhen_1642") else {
            return BattleObjectiveSummary(
                title: "战役目标",
                subtitle: "当前剧本继续沿用 legacy 阿登胜负链。",
                isMingScenario: false,
                tracks: [],
                scoreRows: [],
                leadingFaction: nil,
                cues: []
            )
        }

        let rows = scoreRows(in: state)
        let dataDrivenTracks = tracks(from: state)
        let tracks = dataDrivenTracks.isEmpty ? fallbackTracks(from: state) : dataDrivenTracks
        return BattleObjectiveSummary(
            title: "崇祯十五年 · 天下目标",
            subtitle: "破关、据中原、控湖广与守京师关口共同构成当前胜负线。",
            isMingScenario: true,
            tracks: tracks,
            scoreRows: rows,
            leadingFaction: leadingFaction(from: rows),
            cues: cues(from: state, tracks: tracks)
        )
    }

    func track(id: TrackId) -> Track? {
        tracks.first { $0.id == id }
    }

    private static func tracks(from state: GameState) -> [Track] {
        state.victoryConditions.compactMap { condition in
            guard let metadata = trackMetadata(for: condition),
                  let faction = Faction(rawValue: condition.faction) else {
                return nil
            }

            let objectiveIds = condition.objectiveIds ?? condition.objectiveId.map { [$0] } ?? []
            guard !objectiveIds.isEmpty else {
                return nil
            }

            return makeTrack(
                id: metadata.id,
                title: metadata.title,
                subtitle: condition.description,
                faction: faction,
                reason: metadata.reason,
                timing: metadata.timing,
                objectiveIds: objectiveIds,
                state: state
            )
        }
    }

    private static func fallbackTracks(from state: GameState) -> [Track] {
        [
            makeTrack(
                id: .qingPassCapital,
                title: "破关入京",
                subtitle: "后金/清须控制山海关与北京，打开畿辅门户。",
                faction: .qing,
                reason: .qingBreaksPassAndCapital,
                timing: .immediate,
                objectiveIds: ["obj_shanhaiguan", "obj_beijing"],
                state: state
            ),
            makeTrack(
                id: .dashunCentralPlain,
                title: "据中原秦陕",
                subtitle: "大顺须连控开封、洛阳与西安，稳住中原和秦陕。",
                faction: .dashun,
                reason: .dashunControlsCentralPlain,
                timing: .immediate,
                objectiveIds: ["obj_kaifeng", "obj_luoyang", "obj_xian"],
                state: state
            ),
            makeTrack(
                id: .daxiHuguang,
                title: "据湖广粮区",
                subtitle: "大西须控制荆州与武昌，取得湖广粮道根基。",
                faction: .daxi,
                reason: .daxiControlsHuguangBase,
                timing: .immediate,
                objectiveIds: ["obj_jingzhou", "obj_wuchang"],
                state: state
            ),
            makeTrack(
                id: .mingMandateLine,
                title: "守京师关口",
                subtitle: "明廷须在终局守住北京、山海关与武昌，保住京畿、关门和湖广。",
                faction: .ming,
                reason: .mingHoldsMandateAtFinalTurn,
                timing: .finalTurn,
                objectiveIds: ["obj_beijing", "obj_shanhaiguan", "obj_wuchang"],
                state: state
            )
        ]
    }

    private static func trackMetadata(
        for condition: VictoryConditionDefinition
    ) -> (id: TrackId, title: String, reason: VictoryReason, timing: Timing)? {
        let timing: Timing = condition.type == "holdObjectives" ? .finalTurn : .immediate
        switch condition.id {
        case "qing_break_pass":
            return (.qingPassCapital, "破关入京", .qingBreaksPassAndCapital, timing)
        case "dashun_grain_chain":
            return (.dashunCentralPlain, "据中原秦陕", .dashunControlsCentralPlain, timing)
        case "daxi_huguang_base":
            return (.daxiHuguang, "据湖广粮区", .daxiControlsHuguangBase, timing)
        case "ming_hold_north":
            return (.mingMandateLine, "守京师关口", .mingHoldsMandateAtFinalTurn, .finalTurn)
        default:
            return nil
        }
    }

    private static func makeTrack(
        id: TrackId,
        title: String,
        subtitle: String,
        faction: Faction,
        reason: VictoryReason,
        timing: Timing,
        objectiveIds: [String],
        state: GameState
    ) -> Track {
        Track(
            id: id,
            title: title,
            subtitle: subtitle,
            faction: faction,
            reason: reason,
            timing: timing,
            targets: objectiveIds.map { target(objectiveId: $0, requiredFaction: faction, state: state) }
        )
    }

    private static func target(objectiveId: String, requiredFaction: Faction, state: GameState) -> Target {
        let objective = state.map.objective(id: objectiveId)
        let controller = objective.flatMap { state.map.tile(at: $0.coord)?.controller }
        return Target(
            objectiveId: objectiveId,
            name: objective?.name ?? objectiveId,
            requiredFaction: requiredFaction,
            controller: controller,
            points: objective.map { max(1, $0.points) } ?? 0
        )
    }

    private static func scoreRows(in state: GameState) -> [ScoreRow] {
        let eligibleFactions: [Faction] = [.ming, .qing, .dashun, .daxi]
        var points = Dictionary(uniqueKeysWithValues: eligibleFactions.map { ($0, 0) })
        var counts = Dictionary(uniqueKeysWithValues: eligibleFactions.map { ($0, 0) })

        for objective in state.map.objectives {
            guard let controller = state.map.tile(at: objective.coord)?.controller,
                  eligibleFactions.contains(controller) else {
                continue
            }
            points[controller, default: 0] += max(1, objective.points)
            counts[controller, default: 0] += 1
        }

        return eligibleFactions.map {
            ScoreRow(
                faction: $0,
                points: points[$0, default: 0],
                objectiveCount: counts[$0, default: 0]
            )
        }
    }

    private static func leadingFaction(from rows: [ScoreRow]) -> Faction? {
        guard rows.map(\.points).max() ?? 0 > 0 else {
            return nil
        }

        return rows.max { lhs, rhs in
            if lhs.points == rhs.points {
                return priority(of: lhs.faction) > priority(of: rhs.faction)
            }
            return lhs.points < rhs.points
        }?.faction
    }

    private static func priority(of faction: Faction) -> Int {
        let factions: [Faction] = [.ming, .qing, .dashun, .daxi]
        return factions.firstIndex(of: faction) ?? factions.endIndex
    }

    private static func cues(from state: GameState, tracks: [Track]) -> [Cue] {
        var cues: [Cue] = []

        if state.turn == 1 {
            cues.append(
                Cue(
                    id: "songjin_aftershock",
                    kind: .history,
                    title: "松锦余波",
                    detail: "辽东主力受挫后，山海关、北京与湖广粮道成为明廷能否续命的关节。"
                )
            )
        }

        if state.activeFaction == .ming && state.turn <= 2 {
            cues.append(
                Cue(
                    id: "chongzhen_revenue_pressure",
                    kind: .policy,
                    title: "催饷与安民",
                    detail: "朝廷可短期征饷补军费，也可赈济压民变；两者会牵动政策、经济与军事压力。"
                )
            )
        }

        let strainedUnits = state.divisions.filter {
            $0.faction == state.activeFaction && $0.supplyState != .supplied
        }
        if let unit = strainedUnits.first {
            cues.append(
                Cue(
                    id: "supply_warning_\(unit.id)",
                    kind: .economy,
                    title: "粮道告急",
                    detail: "\(unit.name) 已非满粮状态；先看粮道虚线和府库粮草，再决定补给或撤守。"
                )
            )
        }

        if !state.warDirectiveRecords.isEmpty {
            cues.append(
                Cue(
                    id: "agent_after_action",
                    kind: .agent,
                    title: "军机复盘",
                    detail: "AI 回合已有督师指令和命令回执，可在军机面板查看诸方 Agent 的取舍。"
                )
            )
        }

        if let pressureTrack = tracks.first(where: { $0.timing == .immediate && $0.controlledCount > 0 && !$0.isSatisfied }) {
            cues.append(
                Cue(
                    id: "objective_pressure_\(pressureTrack.id.rawValue)",
                    kind: .military,
                    title: "\(pressureTrack.title)逼近",
                    detail: "\(pressureTrack.faction.displayName)已取 \(pressureTrack.controlledCount) / \(pressureTrack.requiredCount) 处要冲，需尽快调兵或改变方面目标。"
                )
            )
        }

        return Array(cues.prefix(4))
    }
}
