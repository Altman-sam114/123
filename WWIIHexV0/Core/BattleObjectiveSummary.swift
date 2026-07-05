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

    let title: String
    let subtitle: String
    let isMingScenario: Bool
    let tracks: [Track]
    let scoreRows: [ScoreRow]
    let leadingFaction: Faction?

    static func from(state: GameState) -> BattleObjectiveSummary {
        guard state.scenarioId.hasPrefix("chongzhen_1642") else {
            return BattleObjectiveSummary(
                title: "战役目标",
                subtitle: "当前剧本继续沿用 legacy 阿登胜负链。",
                isMingScenario: false,
                tracks: [],
                scoreRows: [],
                leadingFaction: nil
            )
        }

        let rows = scoreRows(in: state)
        return BattleObjectiveSummary(
            title: "崇祯十五年 · 天下目标",
            subtitle: "破关、据中原、控湖广与守京师关口共同构成当前胜负线。",
            isMingScenario: true,
            tracks: [
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
            ],
            scoreRows: rows,
            leadingFaction: leadingFaction(from: rows)
        )
    }

    func track(id: TrackId) -> Track? {
        tracks.first { $0.id == id }
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
}
