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

    enum CampaignLine: String, Equatable {
        case world
        case policy
        case economy
        case technology
        case military

        var displayName: String {
            switch self {
            case .world:
                return "天下"
            case .policy:
                return "政策"
            case .economy:
                return "经济"
            case .technology:
                return "科技"
            case .military:
                return "军事"
            }
        }

        var systemImage: String {
            switch self {
            case .world:
                return "globe.asia.australia"
            case .policy:
                return "building.columns"
            case .economy:
                return "shippingbox"
            case .technology:
                return "hammer"
            case .military:
                return "shield.lefthalf.filled"
            }
        }
    }

    enum CampaignStageStatus: String, Equatable {
        case watch
        case focus
        case warning
        case achieved

        var displayName: String {
            switch self {
            case .watch:
                return "观察"
            case .focus:
                return "主线"
            case .warning:
                return "告急"
            case .achieved:
                return "已成"
            }
        }
    }

    struct CampaignStage: Equatable, Identifiable {
        let id: String
        let line: CampaignLine
        let title: String
        let turnWindow: String
        let summary: String
        let detail: String
        let status: CampaignStageStatus
        let progress: Double
    }

    struct CampaignTask: Equatable, Identifiable {
        enum Priority: String, Equatable {
            case urgent
            case main
            case watch

            var displayName: String {
                switch self {
                case .urgent:
                    return "急务"
                case .main:
                    return "主线"
                case .watch:
                    return "留意"
                }
            }

            var systemImage: String {
                switch self {
                case .urgent:
                    return "exclamationmark.triangle.fill"
                case .main:
                    return "scope"
                case .watch:
                    return "eye"
                }
            }
        }

        let id: String
        let line: CampaignLine
        let priority: Priority
        let title: String
        let detail: String
        let targetObjectiveId: String?
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
    let stages: [CampaignStage]
    let tasks: [CampaignTask]
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
                stages: [],
                tasks: [],
                cues: []
            )
        }

        let rows = scoreRows(in: state)
        let dataDrivenTracks = tracks(from: state)
        let tracks = dataDrivenTracks.isEmpty ? fallbackTracks(from: state) : dataDrivenTracks
        let leader = leadingFaction(from: rows)
        return BattleObjectiveSummary(
            title: "崇祯十五年 · 天下目标",
            subtitle: "破关、据中原、控湖广与守京师关口共同构成当前胜负线。",
            isMingScenario: true,
            tracks: tracks,
            scoreRows: rows,
            leadingFaction: leader,
            stages: campaignStages(from: state, tracks: tracks, leadingFaction: leader),
            tasks: campaignTasks(from: state, tracks: tracks, leadingFaction: leader),
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

    private static func campaignStages(
        from state: GameState,
        tracks: [Track],
        leadingFaction: Faction?
    ) -> [CampaignStage] {
        let qingTrack = tracks.first { $0.id == .qingPassCapital }
        let dashunTrack = tracks.first { $0.id == .dashunCentralPlain }
        let daxiTrack = tracks.first { $0.id == .daxiHuguang }
        let mingTrack = tracks.first { $0.id == .mingMandateLine }
        let mingFireSupportCount = state.divisions.filter {
            $0.faction == .ming && $0.components.contains { $0.type.isFireSupportComponent }
        }.count
        let finalPressure = max(0, min(1, Double(state.turn) / Double(max(1, state.maxTurns))))

        return [
            CampaignStage(
                id: "pass_capital_screen",
                line: .military,
                title: "山海关屏障",
                turnWindow: "1-5 回合",
                summary: "清军破关入京线",
                detail: stageDetail(
                    track: qingTrack,
                    empty: "山海关和北京仍是明廷北线命门；清方一旦先取关口，畿辅压力会立刻上升。",
                    active: "清方已摸到破关入京链，明廷需调兵固关或用朝廷项目补城防粮道。",
                    complete: "清方破关入京条件已成，当前战局已进入京畿崩解风险。"
                ),
                status: pressureStatus(for: qingTrack),
                progress: qingTrack?.progress ?? 0
            ),
            CampaignStage(
                id: "central_plain_grain_chain",
                line: .economy,
                title: "河南秦陕粮链",
                turnWindow: "3-10 回合",
                summary: "大顺扩粮与中原立足",
                detail: stageDetail(
                    track: dashunTrack,
                    empty: "开封、洛阳、西安尚未连成大顺粮链；河南秦陕仍是明廷可争取的缓冲区。",
                    active: "大顺已取得部分中原秦陕要冲，粮草和民变压力会逼迫明廷在剿抚之间取舍。",
                    complete: "大顺已连起中原秦陕粮链，后续目标应转向救援、招抚或南线保全。"
                ),
                status: pressureStatus(for: dashunTrack),
                progress: dashunTrack?.progress ?? 0
            ),
            CampaignStage(
                id: "huguang_grain_base",
                line: .economy,
                title: "湖广粮道",
                turnWindow: "6-14 回合",
                summary: "荆州武昌与南线粮根",
                detail: stageDetail(
                    track: daxiTrack,
                    empty: "湖广粮区暂未被大西打通；武昌和荆州仍是南线军粮与终局分值核心。",
                    active: "大西已切入湖广粮区，府库、粮台和南线军令需要提前联动。",
                    complete: "大西已据湖广粮区，明廷终局名分和南线粮草同时承压。"
                ),
                status: pressureStatus(for: daxiTrack),
                progress: daxiTrack?.progress ?? 0
            ),
            CampaignStage(
                id: "court_four_line_balance",
                line: .policy,
                title: "朝廷四线取舍",
                turnWindow: "全局",
                summary: "政策、经济、科技、军事联动",
                detail: courtStageDetail(leadingFaction: leadingFaction, turn: state.turn),
                status: state.turn <= 2 ? .focus : .watch,
                progress: min(1, Double(state.turn) / Double(max(1, state.maxTurns)))
            ),
            CampaignStage(
                id: "firearms_fortification",
                line: .technology,
                title: "火器修城",
                turnWindow: "4-12 回合",
                summary: "红衣炮、城防与围城准备",
                detail: mingFireSupportCount > 0
                    ? "明廷现有 \(mingFireSupportCount) 支火器/炮队可支撑守城或反围；后续要看银两、粮草和部署位置。"
                    : "明廷当前缺少火器/炮队支点；遇到围城或关隘压力时，应考虑火器整备或修城固守。",
                status: mingFireSupportCount > 0 ? .focus : .warning,
                progress: min(1, Double(mingFireSupportCount) / 2)
            ),
            CampaignStage(
                id: "final_mandate_line",
                line: .world,
                title: "终局名分线",
                turnWindow: "\(max(1, state.maxTurns - 3))-\(state.maxTurns) 回合",
                summary: "北京、山海关、武昌终局判定",
                detail: stageDetail(
                    track: mingTrack,
                    empty: "明廷终局线尚未稳住；北京、山海关和武昌必须同时保住，才有名分续命空间。",
                    active: "明廷已守住部分终局要冲，但仍需同时兼顾北门和湖广。",
                    complete: "明廷终局要冲暂时完整；临近终局时仍需防止清、大顺、大西改写局势。"
                ),
                status: finalPressure > 0.82 && !(mingTrack?.isSatisfied ?? false) ? .warning : pressureStatus(for: mingTrack),
                progress: mingTrack?.progress ?? 0
            )
        ]
    }

    private static func pressureStatus(for track: Track?) -> CampaignStageStatus {
        guard let track else {
            return .watch
        }
        if track.isSatisfied {
            return .achieved
        }
        if track.progress >= 0.5 {
            return .warning
        }
        if track.controlledCount > 0 {
            return .focus
        }
        return .watch
    }

    private static func stageDetail(
        track: Track?,
        empty: String,
        active: String,
        complete: String
    ) -> String {
        guard let track else {
            return empty
        }
        if track.isSatisfied {
            return complete
        }
        if track.controlledCount > 0 {
            return active
        }
        return empty
    }

    private static func courtStageDetail(leadingFaction: Faction?, turn: Int) -> String {
        let leaderText = leadingFaction.map { "当前要冲分暂由 \($0.displayName) 领先" } ?? "当前要冲分尚未拉开"
        if turn <= 2 {
            return "\(leaderText)；开局应先看天下、朝廷、府库和粮道，再决定征饷、赈济、修城或整训。"
        }
        return "\(leaderText)；后续朝议要把民变、银两、粮草、火器和方面军令连成同一条决策链。"
    }

    private static func campaignTasks(
        from state: GameState,
        tracks: [Track],
        leadingFaction: Faction?
    ) -> [CampaignTask] {
        let qingTrack = tracks.first { $0.id == .qingPassCapital }
        let dashunTrack = tracks.first { $0.id == .dashunCentralPlain }
        let daxiTrack = tracks.first { $0.id == .daxiHuguang }
        let mingTrack = tracks.first { $0.id == .mingMandateLine }
        let mingFireSupportCount = state.divisions.filter {
            $0.faction == .ming && $0.components.contains { $0.type.isFireSupportComponent }
        }.count

        var tasks: [CampaignTask] = [
            militaryTask(qingTrack: qingTrack),
            policyTask(state: state, leadingFaction: leadingFaction),
            economyTask(dashunTrack: dashunTrack, daxiTrack: daxiTrack),
            technologyTask(
                qingTrack: qingTrack,
                mingTrack: mingTrack,
                mingFireSupportCount: mingFireSupportCount
            )
        ]

        if state.turn >= max(1, state.maxTurns - 3) {
            tasks.insert(finalMandateTask(mingTrack: mingTrack), at: 0)
        }

        return Array(tasks.prefix(5))
    }

    private static func militaryTask(qingTrack: Track?) -> CampaignTask {
        let target = missingTarget(in: qingTrack)?.objectiveId ?? "obj_shanhaiguan"
        let priority: CampaignTask.Priority = (qingTrack?.controlledCount ?? 0) > 0 ? .urgent : .main
        let title = priority == .urgent ? "堵住破关入京" : "守山海关与京师"
        let detail = priority == .urgent
            ? "清军已推进破关入京线；先定位缺口城关，调军粮、守军和火器挡住京畿崩盘。"
            : "开局先看山海关、北京和周边粮道，北门稳住后才有余力处置河南、湖广。"
        return CampaignTask(
            id: "hold_pass_capital",
            line: .military,
            priority: priority,
            title: title,
            detail: detail,
            targetObjectiveId: target
        )
    }

    private static func policyTask(state: GameState, leadingFaction: Faction?) -> CampaignTask {
        let priority: CampaignTask.Priority = state.activeFaction == .ming && state.turn <= 2 ? .main : .watch
        let leaderText = leadingFaction.map { "当前要冲分由 \($0.displayName) 领先" } ?? "当前要冲分未定"
        return CampaignTask(
            id: "settle_revenue_and_relief",
            line: .policy,
            priority: priority,
            title: "定征饷安民尺度",
            detail: "\(leaderText)；朝廷先比较征饷、赈济、修城和团练，短期军费不能压垮州府民变。",
            targetObjectiveId: nil
        )
    }

    private static func economyTask(dashunTrack: Track?, daxiTrack: Track?) -> CampaignTask {
        if let dashunTrack, dashunTrack.controlledCount > 0 {
            return CampaignTask(
                id: "block_central_plain_grain_chain",
                line: .economy,
                priority: dashunTrack.progress >= 0.5 ? .urgent : .main,
                title: "截断河南秦陕粮链",
                detail: "大顺已取 \(dashunTrack.controlledCount) / \(dashunTrack.requiredCount) 处中原秦陕要冲；先看余下城池和府库粮道，避免其连成粮根。",
                targetObjectiveId: missingTarget(in: dashunTrack)?.objectiveId
            )
        }

        if let daxiTrack, daxiTrack.controlledCount > 0 {
            return CampaignTask(
                id: "protect_huguang_grain_base",
                line: .economy,
                priority: daxiTrack.progress >= 0.5 ? .urgent : .main,
                title: "保湖广粮道",
                detail: "大西已切入湖广粮区；荆州、武昌关系南线军粮和终局要冲分，需先看粮台和守军。",
                targetObjectiveId: missingTarget(in: daxiTrack)?.objectiveId
            )
        }

        return CampaignTask(
            id: "guard_grain_chain",
            line: .economy,
            priority: .watch,
            title: "巡河南湖广粮根",
            detail: "河南秦陕和湖广是流民军扩张的粮源；提前盯住开封、洛阳、武昌，别等塘报告急再调兵。",
            targetObjectiveId: missingTarget(in: dashunTrack)?.objectiveId ?? missingTarget(in: daxiTrack)?.objectiveId
        )
    }

    private static func technologyTask(
        qingTrack: Track?,
        mingTrack: Track?,
        mingFireSupportCount: Int
    ) -> CampaignTask {
        let target = missingTarget(in: qingTrack)?.objectiveId
            ?? missingTarget(in: mingTrack)?.objectiveId
            ?? "obj_beijing"
        if mingFireSupportCount > 0 {
            return CampaignTask(
                id: "ready_firearms_forts",
                line: .technology,
                priority: .main,
                title: "调火器守城",
                detail: "明廷现有 \(mingFireSupportCount) 支火器/炮队支点；把火力、城防和粮台放到同一条守城链上。",
                targetObjectiveId: target
            )
        }

        return CampaignTask(
            id: "ready_firearms_forts",
            line: .technology,
            priority: .watch,
            title: "补火器与城防",
            detail: "当前缺少火器/炮队支点；若山海关、北京或武昌承压，优先考虑火器整备和修城固守。",
            targetObjectiveId: target
        )
    }

    private static func finalMandateTask(mingTrack: Track?) -> CampaignTask {
        CampaignTask(
            id: "hold_final_mandate_line",
            line: .world,
            priority: .urgent,
            title: "守终局名分线",
            detail: "终局前必须同时看北京、山海关和武昌；任何一处易手都会改写明廷名分与天下要冲分。",
            targetObjectiveId: missingTarget(in: mingTrack)?.objectiveId ?? "obj_beijing"
        )
    }

    private static func missingTarget(in track: Track?) -> Target? {
        guard let track else {
            return nil
        }
        return track.targets.first { !$0.isControlled } ?? track.targets.first
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
