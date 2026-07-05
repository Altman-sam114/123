# WWIIHexV0 核心流程文档（明末迁移 v4.7 剧本胜利条件数据驱动、明末胜负链、战役目标面板、本旬任务链/任务塘报、目标定位、目标换手塘报与阶段战局链首片，v4.6 UI、朝廷项目、朝议争点、朝报令条、军令牌、将印军令/将领名帖、军机复盘牌、塘报战记、军情牌、州府牌、天下急势、地图标识、粮道线路/开关、军令计划线、势力旗号、舆图图例与四线项目分组首片）

> 本文是项目当前核心逻辑的接手文档。目标不是复述历史设计，而是按当前代码真实链路说明：数据如何进入游戏，hex / region / theater / front / deploy 如何派生，主游戏和地图编辑器如何共同维护同一套地图语义，AI / 玩家命令如何落到规则系统。

资料依据：`AGENTS.md`、`README.md`、`update_log.md`、`md/test/test.md`、`md/prompt/v4.0-明末迁移/codex-v4.0-明末aiagent迁移总提示词.md`、v0.355/v0.36/v0.37 阶段文档，以及当前源码中的 `Core/`、`Rules/`、`Commands/`、`Agents/`、`Turn/`、`App/`、`SpriteKit/`、`UI/`、`MapEditor/` 与关键测试。

---

## 0. 一句话总览

当前主链路是：

```text
MapEditor / JSON 数据
  -> DataLoader
  -> GameState
  -> turnOrder / humanControlledFactions / aiControlledFactions
  -> DiplomacyState 关系判断
  -> DiplomacyPanelView 天下急势只读摘要
  -> Hex controller / Division coord
  -> Region 聚合
  -> EconomyState 收入 / 生产 / 补员
  -> CourtStrategySummary 政策 / 经济 / 科技 / 军事摘要
  -> CourtPanelView 朝议争点只读展示
  -> CourtProjectDomain / CourtProjectKind / Command.enactCourtProject 朝廷四线项目
  -> Initial Theater snapshot + runtime hexToTheater
  -> FrontLine 动态 hex 接触
  -> WarDeployment hexToFrontZone + FRONT/DEPTH/GARRISON
  -> MarshalAgent / TheaterDirective JSON
  -> TheaterDirectiveDecoder
  -> TheaterDirectiveCompiler
  -> ZoneCommanderAgent fallback / 手写 ZoneDirective
  -> WarCommandExecutor
  -> RuleEngine
  -> CommandExecutor
  -> BattleObjectiveSummary 从 GameState.victoryConditions 编译明末胜负线 / objective points / 战役提示 / 本旬任务链 / 阶段战局链只读摘要
  -> VictoryRules 明末胜负链 / legacy 阿登胜负链
  -> CommandExecutor.appendBattleCueEvents 战役提示入塘报
  -> CommandExecutor.appendBattleTaskEvents 本旬任务入塘报
  -> CommandExecutor.appendObjectiveControlEventIfNeeded 目标换手入塘报
  -> BattleObjectivePanelView 目标 chip 只读定位 selectedHex / selectedRegionId
  -> StrategicStateSynchronizer
  -> SupplyRules.supplyPath 粮道线路只读派生
  -> BoardRenderState.showsSupplyRoutes / PlayerCommandState 军令计划线 / MapDisplayLayer 舆图图例 / UI overlay / 塘报战记 / WarDirectiveRecord
```

最关键的铁律：

- `HexTile.controller` 和 `Division.coord` 是战术层权威。
- `RegionNode.controller` 是从 region 内 hex controller 加权聚合出来的战略快照。
- `regionToTheater` 是初始/基础战区归属，不是运行时推进层。
- `hexToTheater` 是运行时动态战区权威。
- `hexToFrontZone` 是部署层动态归属权威。
- v4.1 兼容层中，`Faction` 已扩展为 legacy Germany / Allies 加明廷、后金/清、大顺、大西、地方中立；新敌我判断应走 `DiplomacyState`，不再新增 `Faction.opponent` 调用。
- v4.2 默认数据首片中，`DataLoader.loadInitialGameState()` 优先尝试 `chongzhen_1642_scenario` + `chongzhen_1642_regions`，失败才回退阿登 legacy 数据。
- v4.3 军队首步中，`ComponentType` 已补明末骑兵、火器、旗骑、团练、攻城器械等兼容 case；默认明末初始单位已切到明末 template，legacy 阿登 template 继续保留。
- v4.4 钱粮首片中，`EconomyResources.manpower/industry/supplies` 暂保留为兼容字段名，但 UI、日志和 AI 摘要显示为民力、银两、粮草；生产项显示为募营兵、募精骑、募哨骑、造炮队和筹粮。
- v4.4 治理首片中，`OccupationState.resistance/compliance` 已按民变/行政掌控解释，并对州府钱粮产出做轻量修正；该摘要进入州府面板和 AI 钱粮摘要。
- v4.4 天下局势首片中，玩家信息面板的外交入口改为“天下”，`DiplomacyPanelView` 显示当前势力、名义主体、战事态势、主要对手、诸方势力、战和关系和朝议/军议。
- v4.5 朝廷首片中，`CourtStrategySummary` 从钱粮、治理、补给、前线和火器/炮队状态派生政策、经济、科技、军事四线压力；Root 信息面板新增“朝廷”tab，AI 与元帅摘要可读取同一朝议建议。
- v4.6 UI 首片中，`MingDesignTokens` 提供明末面板色彩/圆角/间距常量；`CourtPanelView` 已从 `RootGameView` 拆出并改为奏疏/印玺风格；主 UI、军令、将领名帖、单位、塘报战记、AI 面板继续中文化；`UnitNode` 地图军牌从 NATO 图形改为中文徽记和守/退状态。
- v4.6 朝报令条首片中，`HUDView` 从普通指标 grid 升级为顶部朝报令条，展示当前势力、回合、胜负、民力、银两、粮草、入账、营造队列和政策/经济/科技/军事四线压力；该片只读 `GameState`、`FactionEconomyLedger` 和 `CourtStrategySummary`，结束回合/新局仍走原回调。
- v4.6 部队军情牌首片中，`UnitInspectorView` 从字段列表升级为只读军情牌，展示军牌字、兵力条、粮草/退守/行动、攻守行程察指标、兵种编成条和驻防归属；该片只读 `Division` 与 `UnitInspectorStrategicState`，不改变战斗、补给、部署或命令规则。
- v4.6 军令牌首片中，`CommandPanelView` 从简单标题和按钮列升级为军令牌，展示当前势力/阶段、选中军情、兵力、粮草、退守、行动、固守/退守/补给处置和军令回执；固守、准许退守、就地补给和结束回合仍只调用 `RootGameView` 注入的原有回调，不直接修改 `GameState`。
- v4.6 将领面板首片中，`GeneralCommandPanelView` 从简单将领列表升级为将印军令，展示防区、压力、战态、主将履历、忠诚、军心、干预、麾下军伍、目标和军令计划；`GeneralProfileView` 升级为将领名帖，展示印信、统兵风格、履历奏记、君臣关系、将略和麾下军伍。该片只读 `GeneralData`、`GeneralAssignment`、`FrontZone`、`Division` 与 `PlayerPlannedOperation`，固守/进取仍走原回调，不直接改规则状态。
- v4.6 军机复盘牌首片中，`AgentPanelView` 从 LabeledContent 调试列表升级为只读军机复盘牌，展示决策摘要、最高意志、战区指令、命令回执、异常塘报和原始 JSON；该片只读 `AgentDecisionRecord`、`RulerDecisionRecord` 与 `WarDirectiveRecord`，不改变 `MarshalAgent`、`RulerAgent`、`WarCommandExecutor`、`Command` 或 `RuleEngine`。
- v4.6 塘报战记首片中，`EventLogView` 从简单战报列表升级为只读塘报战记，展示最近塘报数量、战事/粮草/州府/天下分类计数、最新分类、回合/势力/阶段和相关回执；该片只读 `GameLogEntry`，不改变日志 schema、命令执行或规则权威。
- v4.6 州府牌首片中，`RegionInspectorView` 从字段列表升级为只读州府牌，展示城关粮坊、地方治理、钱粮城防、方面/防区/目标、友敌军和当前格；该片只读 `RegionInspectorState`、`RegionNode` 和 `OccupationState`，不改变 hex 控制、region 聚合、经济结算、前线/部署或命令规则。
- v4.6 府库牌首片中，`EconomyPanelView` 从表格/按钮列表升级为只读府库牌加生产入口，展示民力、银两、粮草库存、本回合入账、军粮维护、补员消耗、募兵筹粮和营造队列；生产按钮仍只走 `Command.queueProduction -> CommandValidator -> EconomyRules`，不直接改经济账本。
- v4.6 天下急势首片中，`DiplomacyPanelView` 从 `DiplomacyState` 和只读 `CourtStrategySummary` 派生顶部“天下急势”、势力战意条、主要对手和政策/经济/科技/军事四线压力；该片只影响 SwiftUI 展示，不改变外交关系、朝廷项目或规则执行。
- v4.6 朝廷项目首片中，`CourtProjectKind` 将征饷、赈济安民、修城固守、整训团练、火器整备、粮台转运收口为一次性项目；玩家从朝廷面板触发 `Command.enactCourtProject(kind:)`，再经 `CommandValidator` 与 `EconomyRules` 执行。
- v4.6 四线项目分组首片中，`CourtProjectDomain` 将朝廷项目归入政策、经济、科技、军事四线；`CourtPanelView` 按四线展示压力值、关注点、项目成本收益和风险，不新增持久政策/科技状态。
- v4.6 朝议争点首片中，`CourtPanelView` 继续只读 `CourtStrategySummary`，把安民与征饷、火器与团练、粮道与城防三组冲突做成紧凑摘要，让玩家看到政策、经济、科技、军事之间的取舍；该片不新增朝廷状态、不改变项目执行链。
- v4.6 地图标识首片中，`BaseTerrain.displayName` 已切为明末中文地形名；`HexNode` 用“城 / 关 / 粮”badge 标识城池、关隘/堡寨和粮台，并把旧主地图 `FORT`、`SUP A/G` 标记改为“关隘”“粮台”。该变化只影响 SpriteKit 展示，不改补给、占领、战区或经济规则。
- v4.6 粮道线路首片中，`SupplyRules.supplyPath` 在既有补给通行/成本规则上返回只读 hex 路线；`BoardScene` 仅在默认 hex 图层为玩家势力有有效补给线的军队绘制粮道虚线，路线位于战争迷雾下方，不新增粮道状态、不改变补给判定。
- v4.6 粮道开关首片中，`AppContainer.showsSupplyRoutes` 只作为 UI/渲染状态进入 `BoardRenderState`；`RootGameView` 顶部显示“粮道”按钮和图例，关闭后 `BoardScene.drawSupplyRoutes` 直接跳过绘制，不影响 `SupplyRules` 判定。
- v4.6 舆图图例首片中，`MapDisplayLayer.displayName` 已改为舆图、州府、初划、战局、前线、布防；同一 enum 提供图标、图例标题和说明，`RootGameView` 顶部图例条用“城 / 关 / 粮 / 步”、势力旗和粮道虚线解释当前地图符号。该片只影响 SwiftUI 展示，不改变 layer rawValue、overlay 计算或规则权威。
- v4.6 军令计划线首片中，`BoardScene.drawPlannedOperations` 只读 `PlayerCommandState.plannedOperations`，把当前回合玩家计划画成朱砂“进”令牌箭头和青绿“守”令牌；`RootGameView` 顶部图例增加“军令计划 / 进取 / 固守”。该片只影响 SpriteKit/SwiftUI 展示，不改变计划记录、`ZoneDirective`、`WarCommandExecutor`、`Command` 或 `RuleEngine`。
- v4.6 势力旗号首片中，`Faction.bannerGlyph` 为明廷、后金/清、大顺、大西和地方中立提供短旗号；`UnitNode` 在地图军牌顶端显示“明/清/顺/西/乡”等旗号，`UnitInspectorView` 与 `CommandPanelView` 的军牌印面同步显示旗号，`RootGameView` 顶部图例增加“势力旗”。该片只影响 UI/SpriteKit 展示，不改变 `Faction` 控制语义、外交关系、单位状态、命令执行或规则权威。
- v4.7 明末胜负链首片中，`Objective` 保留 scenario JSON 的 `points`，`DataLoader` 会把 `ScenarioDefinition.victoryConditions` 写入 `GameState.victoryConditions`，`MapState` 可按 objective id 查询控制方；`BattleObjectiveSummary` 优先从 `GameState.victoryConditions` 编译清破关入京、大顺据中原秦陕、大西据湖广粮区、明廷守京师关口四条胜负线和 objective points 领先方，缺失时才回退内置目标；同一摘要还只读派生松锦余波、催饷安民、粮道告急、军机复盘和目标线压力等战役提示，按当前压力派生军事守关、政策征饷安民、经济粮链、科技火器修城和终局名分等本旬任务链，以及山海关屏障、河南秦陕粮链、湖广粮道、朝廷四线取舍、火器修城、终局名分线等阶段战局链，服务 v4.7 教程/历史代入感首片，不新增事件执行器或持久状态；`CommandExecutor` 结束回合时会将当前摘要 cue 用 `battle-cue-<turn>-<faction>-<cue id>` 去重写入 `eventLog`，让提示进入塘报战记，并将急务/主线任务最多 3 条用 `battle-task-<turn>-<faction>-<task id>` 去重写入任务塘报，帮助复盘当旬军政钱粮火器重点；明末 objective hex 经合法移动占领换手时，`CommandExecutor.appendObjectiveControlEventIfNeeded` 根据占领前后 `HexTile.controller` 追加目标换手塘报，记录原控制方、新控制方和要冲分，只追加日志不执行事件效果；`VictoryRules` 对 `chongzhen_1642` 剧本读取同一摘要执行明末条件，legacy 阿登胜负条件保持原路径。`HUDView` 的胜负 badge 只读显示胜负理由短语，`RootGameView` 信息面板新增“目标”tab，用 `BattleObjectivePanelView` 展示当前各城关控制方、进度、战役提示、本旬任务链、阶段战局链和终局要冲分；目标 chip 与任务定位按钮可通过 `AppContainer.focusObjective(_:)` 定位目标 hex 和州府牌，它只更新 UI 选择、高亮和交互日志，不提交命令、不改变 `GameState` 权威状态。
- `GamePhase.allowsHumanCommands` 是玩家可操作阶段的当前 UI/App 判定入口，兼容 `.humanAction` 与 legacy `.alliedPlayer`。
- `turnOrder`、`humanControlledFactions`、`aiControlledFactions` 是通用回合和控制方配置；旧阿登仍 fallback 为 Germany AI / Allies player。
- `EconomyState` 是 faction 级经济总账；收入来自受控 region、城市、工厂、基础设施和补给值，但战术占领仍以 hex 为准。
- 玩家、AI、后续聊天命令最终都必须经过 `Command` / `ZoneDirective -> WarCommandExecutor -> RuleEngine`，不能直接改 `GameState`。
- v0.5 默认战争 AI 上游是 `MarshalAgent -> TheaterDirective JSON -> TheaterDirectiveDecoder -> TheaterDirectiveCompiler`，下游执行收口到 `ZoneDirective -> WarCommandExecutor -> RuleEngine`。
- `CourtStrategySummary` 与 `BattleObjectiveSummary` 都是只读派生摘要，不直接改 `GameState`；`BattleObjectiveSummary.Cue` 用于目标面板的历史/教程提示和回合末塘报入册，不执行事件效果；`BattleObjectiveSummary.CampaignTask` 只把当前胜负线压力、回合和明廷火器支点翻译成目标面板的本旬任务链，并可由 `appendBattleTaskEvents` 将急务/主线任务写入塘报，不保存持久任务进度，不执行政策/经济/科技/军事效果；目标换手塘报只记录已经发生的 objective hex 控制变化，不替代 `VictoryRules` 或 `BattleObjectiveSummary`；`CourtPanelView` 的朝议争点和 `CourtProjectDomain` 只服务四线展示、争点表达和项目分组，可执行朝廷项目必须走 `Command.enactCourtProject -> CommandValidator -> CommandExecutor -> EconomyRules`。`HUDView` 的朝报令条、`BattleObjectivePanelView` 的目标面板与目标定位、`CommandPanelView` 的军令牌、`GeneralCommandPanelView` 的将印军令、`GeneralProfileView` 的将领名帖、`AgentPanelView` 的军机复盘牌、`EventLogView` 的塘报战记、`UnitInspectorView` 的军情牌、`RegionInspectorView` 的州府牌、`EconomyPanelView` 的府库牌、`DiplomacyPanelView` 的天下急势、`BoardScene.drawPlannedOperations` 的军令计划线、`UnitNode` / `MingFactionFlagBadge` 的势力旗号、`AppContainer.showsSupplyRoutes` 和 `MapDisplayLayer` 图例元数据只控制 UI 展示。`RulerAgent` 仍不是默认主链路。

---

## 1. 核心状态对象

### 1.1 GameState

源码：`WWIIHexV0/Core/GameState.swift`

`GameState` 是运行时总状态，主要字段：

```text
scenarioId
turn / maxTurns
activeFaction
phase
map: MapState
theaterState: TheaterState
frontLineState: FrontLineState
warDeploymentState: WarDeploymentState
economyState: EconomyState
diplomacyState: DiplomacyState
victoryConditions: [VictoryConditionDefinition]
turnOrder: [Faction]
humanControlledFactions: [Faction]
aiControlledFactions: [Faction]
divisions: [Division]
victoryState
eventLog
warDirectiveRecords
playerCommandState
```

状态含义：

- `map` 保存地图、hex、region、补给源和目标点。
- `divisions` 保存所有单位。单位当前位置在 `Division.coord`，不是 region 或 theater。
- `theaterState` 保存初始战区快照与运行时动态战区。
- `frontLineState` 从动态战区相邻 hex 派生。
- `warDeploymentState` 从动态战区/前线/单位位置派生，供 AI 调度单位。
- `economyState` 保存民力、银两、粮草三项兼容资源、生产队列、上回合收入/维护费/补员消耗，不直接改变战术占领权；源码字段名仍是 `manpower/industry/supplies`。
- `CourtStrategySummary` 不保存进 `GameState`，而是从钱粮、治理、前线、补给和单位组件即时派生，供朝廷面板、AgentContext 和 MarshalBattlefieldSummary 读取；`CourtProjectDomain` / `CourtProjectKind` 也不新增持久政策状态，只描述玩家可施行的一次性项目及四线展示分组、成本、收益和风险。
- `diplomacyState` 保存国家/集团/关系；v4.1 起 `canAttack`、`isHostile`、`isFriendly`、`canEnterTerritory` 是新敌我判断入口。
- `victoryConditions` 保存剧本 JSON 的胜利条件；`BattleObjectiveSummary` 优先读取它生成明末目标线，旧存档或缺失条件默认空数组并走兼容 fallback。
- `turnOrder` 决定多势力轮转；`humanControlledFactions` / `aiControlledFactions` 决定当前 active faction 由玩家还是 AI 控制。
- `eventLog` 给 UI 和调试看。
- `warDirectiveRecords` 记录战争指令执行回放，供 v0.36+ 后续接 LLM / 聊天命令审计。

### 1.2 MapState / Hex

源码：`WWIIHexV0/Core/MapState.swift`、`WWIIHexV0/Core/Terrain.swift`

`MapState` 的底层是 hex：

```text
width / height
tiles: [HexCoord: HexTile]
supplySources: [SupplySource]
objectives: [Objective]
regions: [RegionId: RegionNode]
hexToRegion: [HexCoord: RegionId]
regionEdges: Set<RegionEdge>
```

`HexTile` 关键字段：

```text
coord
baseTerrain
hasRoad
riverEdges
controller: Faction?
cityName / fortressName
isPassable
regionId: RegionId?
```

当前语义：

- `HexCoord` 是 axial q/r 坐标，移动、攻击、距离、邻接都基于 hex。
- `HexTile.controller` 是真实占领权威；中立 hex 的 controller 为 `nil`。
- `HexTile.regionId` 是聚合标记，不参与寻路/战斗权威判断。
- `MapState.region(for:)` 优先读 `hexToRegion`，fallback 读 `tile.regionId`。
- `MapState.supplySources(for:)` 会通过 `controllingFaction(for:)` 判断补给源当前归属，优先看 supply hex 的 controller，再 fallback region controller，再 fallback 原始 supply faction。

### 1.3 Region

源码：`WWIIHexV0/Core/Region.swift`

`RegionNode` 是省份/区块规则层：

```text
id / name
owner
controller
terrain
neighbors
displayHexes
representativeHex
city
infrastructure / supplyValue / factories / resources
coreOf
occupationState
isPassable
```

当前语义：

- Region 是战略聚合层，不替代 hex。
- `displayHexes` 声明该 region 覆盖哪些 hex。
- `representativeHex` 是 UI 和某些 region->hex 转换的默认点。
- `neighbors` / `regionEdges` 是省份邻接图，但 v0.358 后不能单独拿它判断动态前线。前线必须看真实 hex 邻接。
- `RegionNode.controller` 不是直接推进权威。它由 `RegionOccupationRules.aggregateControl` 从 hex controller 加权派生。

### 1.4 Theater

源码：`WWIIHexV0/Core/Theater.swift`、`WWIIHexV0/Rules/TheaterSystem.swift`

`TheaterState` 关键字段：

```text
initialSnapshot: TheaterInitialSnapshot?
theaters: [TheaterId: TheaterNode]
hexToTheater: [HexCoord: TheaterId]
regionToTheater: [RegionId: TheaterId]
lastUpdatedTurn
```

`TheaterNode` 关键字段：

```text
id / name / status
regionIds
neighborTheaterIds
controllingFaction
controlRatios
victoryPointArea
frontWeight
unitIds
supportEligibleUnitIds
spilloverPolicy
recentThreats
```

当前语义必须分清三件事：

1. `initialSnapshot.regionToTheater`
   - 开局时捕获。
   - 只读初始战区布局。
   - UI 的 `initialTheater` 图层读取这里。
   - 地图编辑器导出的 region->theater assignment 会进入这里。

2. `regionToTheater`
   - 当前基础/初始战区单位。
   - 作为动态战区生成、合并、formalization、退役的参照。
   - 不代表运行时推进结果。
   - 不允许“占领一个 hex 后把整个 region 的 `regionToTheater` 改掉”。

3. `hexToTheater`
   - 运行时动态战区权威。
   - 单位突破进入某个 hex 后，只把这个 hex 改到进攻方动态战区。
   - 前线、动态战区图层、部署层都应以它为准。

`TheaterSystem.updateTheaters` 的派生刷新包括：

```text
seedMissingHexAssignments
  -> 给未填的 hexToTheater 填基础 regionToTheater
rebuildDynamicRegionMembership
  -> TheaterNode.regionIds 变为“该动态战区当前覆盖到的 region 集合”
rebuildNeighborTheaters
  -> 按 hexToTheater 的真实 hex 邻接生成战区邻接
assignUnits
  -> 按单位所在 hex 的 dynamicTheaterId 分配 theater.unitIds
calculateMetrics
  -> 按动态 theater 内 hex controller 计算 controlRatios / controllingFaction / frontWeight
```

`formalizationThreshold` 当前默认 0.70。它用于 formalized / provisional 状态判断，不阻止前线按单个 hex 推进。

### 1.5 FrontLine

源码：`WWIIHexV0/Core/FrontLine.swift`、`WWIIHexV0/Core/FrontSegment.swift`、`WWIIHexV0/Core/FrontLineState.swift`、`WWIIHexV0/Rules/FrontLineManager.swift`

`FrontLineState` 关键字段：

```text
frontLines: [FrontLineId: FrontLine]
regionStates: [RegionId: RegionFrontState]
enemyNeighborCache: [RegionId: [RegionId]]
dirtyRegionIds
diagnostics
```

`FrontLine`：

```text
id
theaterId
opposingTheaterIds
factionA / factionB
segments: [FrontSegment]
type: normal / breakthrough / encirclement
state: stable / pressured / collapsing 等
```

`FrontSegment`：

```text
regionA
regionB
edgeType
pressureLevel
supplyImpact
isEncirclementCandidate
```

当前前线生成逻辑：

```text
对每个 active theater:
  对 theater.regionIds 中的每个 region:
    只看该 region 内 dynamicTheaterId == theater.id 的 hex
    扫描这些 hex 的六向邻接 hex
    如果邻接 hex 属于另一个 dynamic theater
       且对方 theater 的 sourceFaction 不是 friendlyFaction:
         形成 enemy region 接触
         生成 FrontSegment(regionA: friendly region, regionB: enemy region)
```

重要结论：

- 前线不是 region 边界。
- 前线不是 initial theater 边界。
- 前线不是 `regionToTheater` 的邻接。
- 前线是真实动态战区 hex 接触。
- 同一个 region 被两个动态战区切开时，允许出现 `regionA == regionB` 的突破前线。这是 v0.358 后确认的合法状态。
- `FrontLine.type == .breakthrough` 的一个来源是：segment 的 `regionA` 仍由敌方 region controller 控制，但已有我方动态 theater hex 突入。

### 1.6 WarDeployment / FrontZone

源码：`WWIIHexV0/Core/WarDeploymentState.swift`、`WWIIHexV0/Core/FrontZone.swift`、`WWIIHexV0/Core/FrontZoneSegment.swift`、`WWIIHexV0/Rules/WarDeploymentManager.swift`

`WarDeploymentState` 关键字段：

```text
frontZones: [FrontZoneId: FrontZone]
hexToFrontZone: [HexCoord: FrontZoneId]
regionToFrontZone: [RegionId: FrontZoneId]
dirtyRegionIds
diagnostics
```

`FrontZone`：

```text
id / name
faction
regionIds
neighbors
frontSegments
unitsFront
unitsDepth
unitsGarrison
pressure
state
isCoreZone
```

当前部署层权威：

- `hexToFrontZone` 是动态部署归属权威。
- `regionToFrontZone` 是 dominant / fallback，不是突破推进权威。
- `FrontZoneId` 当前通常复用 `TheaterId.rawValue`。
- `WarDeploymentManager.advanceHex` 只推进一个 hex 的 zone 归属。
- `DeploymentLayer` / `UnitDeploymentRole` 当前落地为：
  - `frontUnit`
  - `depthUnit`
  - `garrisonUnit`

单位分配逻辑要点：

```text
每个 division:
  先按 division.coord 查 hexToFrontZone，fallback regionToFrontZone
  如果该 zone.faction == division.faction:
    使用该 zone
  否则如果所在 region 周边有己方 zone:
    分到相邻己方 zone
  否则 fallback 到该 faction 的 primary combat zone

  如果 hex 接触敌 zone
     或 assignedZoneId != 当前 hex zoneId
     或所在 hex controller != assignedZone.faction:
       unitsFront
  否则如果 zone.isCoreZone 或 region 有 city/factory/core:
       unitsGarrison
  否则:
       unitsDepth
```

这层是 AI 调度能否“看见部队”的关键。历史上的“AI 看起来不动”根因之一就是突破后的单位被误判成 garrison，从 `unitsFront` 调度池消失。现在前线/敌区/敌控 hex 会强制把这种单位归到 front。

### 1.7 后续统治者层预留

v0.5 当前不接入统治者层。工作树中可能存在 `WWIIHexV0/Core/DiplomacyState.swift`、`WWIIHexV0/Agents/RulerAgent.swift` 等其他版本方向文件，但它们不是本 v0.5 分支的默认战争 AI 主链路，`TurnManager` 当前不调用 `RulerAgent`。

后续若加入统治者层，必须满足这些边界：

- 统治者只能位于元帅上游，输出国家级姿态、优先方向或约束条件。
- 统治者不得直接生成底层 `Command`，不得绕过 `MarshalAgent` / `ZoneDirective`。
- 统治者不得直接修改 `HexTile.controller`、`Division.coord`、`regionToTheater`、`hexToTheater` 或 `hexToFrontZone`。
- 若需要审计记录，必须单独设计数据 schema，并在 `md/flow/*`、`README.md`、`update_log.md` 中同步说明。

### 1.8 EconomyState / EconomyRules

源码：`WWIIHexV0/Core/EconomyState.swift`、`WWIIHexV0/Rules/EconomyRules.swift`

经济层是 faction 级总账，不是第三套地图权威。v4.4 首片不新增复杂 grand strategy，只把既有 v0.8 经济闭环迁成明末钱粮口径，并把 AI 能看到的钱粮摘要接入上下文。

`EconomyState`：

```text
ledgers: [Faction: FactionEconomyLedger]
lastResolvedTurn
```

`FactionEconomyLedger`：

```text
faction
stockpile: EconomyResources
lastIncome
lastUpkeep
lastReinforcementSpend
productionQueue: [ProductionOrder]
lastUpdatedTurn
```

`EconomyResources` 仍只包含三项兼容字段，显示语义已经迁移：

```text
manpower -> 民力 / 兵源
industry -> 银两 / 军费
supplies -> 粮草
```

`EconomyResources.displaySummary` 用完整口径输出“民力 / 银两 / 粮草”，`compactDisplaySummary` 用于 HUD、州府面板和生产成本等紧凑 UI。

`EconomyPanelView` 当前以府库牌展示 `FactionEconomyLedger`，把库存、入账、军粮维护、补员消耗、募兵筹粮和营造队列放在同一钱粮界面；它只读 ledger 并提交生产命令，不直接写 `EconomyState`。

收入算法：

```text
对 faction 控制且 passable 的每个 region:
  如果该 region 没有任何真实己方控制 hex，跳过
  cityLevel = EconomyRules.cityLevel(region, map)
  coreBonus = region.coreOf 为空或包含 faction ? 1 : 0
  基础民力 = max(1, cityLevel.manpowerGrowth + coreBonus * 4 + infrastructure)
  基础银两 = max(0, factories + cityLevel.industryValue + infrastructure / 3)
  基础粮草 = max(1, supplyValue * 3 + factories + infrastructure / 2)
  钱粮修正 = OccupationState.economicYieldPercent
  最终产出 = 基础产出 * 钱粮修正 / 100
```

`OccupationState` 当前明末显示语义：

```text
resistance -> 民变 / 治安压力
compliance -> 顺服 / 行政掌控
economicYieldPercent = clamp(50...110, 100 + (compliance - 70) / 5 - resistance / 2)
```

默认 `stable` 口径为 `resistance=0, compliance=70`，对应 100% 产出。该修正只影响经济收入与州府面板显示，不改变 hex 控制权、region controller 或任何动态战区归属。

城市等级不是单独 JSON schema，当前从既有字段推导：

- capital、victoryPoints >= 5 或 factories >= 5 -> `metropolis`。
- victoryPoints >= 2、factories >= 2 或 supplyValue >= 3 -> `town`。
- 有 city / fortress / factory 但不满足上面条件 -> `village`。
- 没有城市、堡垒或工厂信号 -> `none`。

生产队列由 `Command.queueProduction(kind:)` 进入规则系统：

```text
EconomyPanelView
  -> AppContainer.queueProduction
  -> Command.queueProduction
  -> RuleEngine
  -> CommandValidator.validateProduction
  -> CommandExecutor.executeQueueProduction
  -> EconomyRules.queueProduction
```

生产项显示口径：

```text
infantryDivision -> 募营兵
panzerDivision -> 募精骑
motorizedDivision -> 募哨骑
artilleryDivision -> 造炮队
supplyStockpile -> 筹粮
```

排产时预付资源，完成时才部署新单位或发放粮草。完成单位只能放到本方控制、passable、空置、非敌邻，且位于首都、城镇/大都会、工坊、高基建、高粮草 region 或 supply source 的后方 hex。找不到安全部署点时订单保留到下回合继续尝试。

明末势力生产完成后不再生成 legacy 装甲/摩托化组件：

```text
募营兵 -> 步军 + 火器 + 骑兵
募精骑 -> 旗骑 + 骑兵 + 火器
募哨骑 -> 骑兵 + 步军 + 团练
造炮队 -> 炮队 + 攻城器械 + 步军
```

Germany / Allies legacy 生产仍使用 `.infantry/.panzer/.motorized/.artillery` 工厂方法，避免破坏旧阿登 fallback。

自动补员在 active faction 结束回合时发生，只处理：

```text
本阵营
未毁灭
未撤退
supplied
strength < maxStrength
不与敌军相邻
```

每个单位每回合最多恢复 2 strength，并按机动、火力和单位组成扣民力、银两、粮草。当前仍不恢复 organization。

AI 摘要：

- `AgentContext.economySummary` 给 legacy Agent D / prompt builder 提供库存、上回合收入、军粮维护、补员消耗、民力/银两/粮草缺口和治理压力。
- `AgentContext.courtSummary` 从钱粮、治理、补给、前线和火器/炮队状态派生朝议摘要，让 legacy prompt builder 能看到政策、经济、科技、军事四线压力。
- `MarshalBattlefieldSummary.economySummary` 给元帅层和模拟 LLM prompt 提供同一钱粮摘要；`MarshalBattlefieldSummary.courtSummary` 提供朝廷四线摘要；schemaVersion 已升到 8。
- 钱粮摘要只读 `economyState`，不直接改变生产、占领或补给。
- 朝廷摘要同样只读；玩家若要施行征饷、赈济、修城、整训团练、火器整备或粮台转运，必须从 `CourtPanelView` 提交 `Command.enactCourtProject(kind:)`，再由 `CommandValidator` 校验资源和 phase，最后由 `EconomyRules.enactCourtProject` 扣资源并施加轻量效果。

---

## 2. 数据启动流程

### 2.1 默认启动路径

源码：`WWIIHexV0/Data/DataLoader.swift`、`WWIIHexV0/App/AppContainer.swift`

主入口：

```text
AppContainer.bootstrap()
  -> DataLoader().loadInitialGameState()
  -> RuleEngine()
  -> GameAgent.guderian(...)
  -> StrategicStateBootstrapper().bootstrapIfNeeded(...)
  -> TurnManager(... commanderPool: buildCommanderPool(state: bootstrappedState))
  -> AppContainer(...)
```

`DataLoader.loadInitialGameState()` 当前优先走明末编辑器兼容 JSON：

```text
loadGameState(
  scenarioName: "chongzhen_1642_scenario",
  regionName: "chongzhen_1642_regions"
)
```

这组数据当前是 `崇祯十五年：天下裂变` 首片：

- 12x10 共 120 个 hex。
- 30 个 region，69 条 region edge，`hexToRegion` 覆盖 120 个 hex。
- 9 个补给源，12 个 objective，14 个 key location。
- 5 个规则势力：`ming`、`qing`、`dashun`、`daxi`、`localNeutral`。
- 回合顺序为 `ming -> qing -> dashun -> daxi`，玩家默认明廷，清 / 大顺 / 大西由 AI 控制。
- 初始单位 22 个，显示名和 `templateId` 都已切到明末首批 template，例如 `ming_banner_cavalry`、`ming_garrison`、`qing_artillery_train`、`dashun_camp`、`daxi_raiders`、`local_tuanlian`。legacy `infantry_division` / `motorized_division` / `artillery_division` / `garrison_division` 仍保留给阿登 fallback。

如果明末 JSON 失败，才 fallback 到：

```text
loadGameState(
  scenarioName: "ardennes_v0_scenario",
  regionName: "ardennes_v02_regions"
)
```

若阿登编辑器兼容 JSON 也失败，最后才 fallback 到老的 `GameState.initial()` + v0.2 region 叠加路径。

### 2.2 loadGameState 的完整链条

源码：`WWIIHexV0/Data/DataLoader.swift`

```text
loadScenarioDefinition(named:)
loadRegionDataSet(named:)
  -> makeMapState(from: scenario)
     - ScenarioTileDefinition -> HexTile
     - tile.controller 字符串转 Faction；"neutral" 转 nil
     - tile.regionId 写入 HexTile.regionId
     - supply source / objective 写入 MapState
  -> apply(regionData, to: map)
     - regionData.toRegions()
     - regionData.toHexToRegion()
     - regionData.toRegionEdges()
     - 反填 HexTile.regionId
     - validateRegionGraph()
  -> RegionOccupationRules().mapByAggregatingControllers(in: map)
     - 从 hex controller 派生 region controller
  -> makeDivisions(from: scenario.initialUnits)
  -> makeTheaterState(map, regionData, divisions, turn)
     - 优先使用 regionData.regions[].theaterId
     - 没有 assignment 时使用 TheaterSystem.makeInitialFixedTheaters
     - TheaterSystem.updateTheaters seed hexToTheater 并刷新派生字段
     - capture initialSnapshot
  -> FrontLineManager.makeInitialState(...)
  -> WarDeploymentManager.makeInitialState(...)
  -> GameState(...)
     - turnOrder / humanControlledFactions / aiControlledFactions 来自 scenario 字段
     - 若旧 JSON 缺这些字段，回退 playerFaction / aiFaction
```

DEBUG 下资源读取优先源码目录 `WWIIHexV0/Data/*.json`，不是旧 bundle。旧 simulator 进程不会自动重载，改默认地图后需要重新运行 app。

### 2.3 StrategicStateBootstrapper

源码：`WWIIHexV0/Core/StrategicStateBootstrapper.swift`

它有两个用途：

1. `bootstrapIfNeeded`
   - 只补缺失层。
   - 先用 `EconomyRules.bootstrapIfNeeded` 为旧状态补 faction 经济总账。
   - 如果 state 有 region 但缺 theater/front/deployment，会从当前 map/divisions 生成。
   - App 初始化、命令提交后会用它兜底。

2. `refreshRuntimeState`
   - 强制刷新运行时派生层。
   - 先聚合 region controller。
   - 强制 `TheaterSystem.updateTheaters(force: true)`。
   - 重新 `FrontLineManager.makeInitialState`。
   - 重新 `WarDeploymentState.bootstrapFrontZones`。
   - AI 行动前会调用，确保指令读取的是当前动态层。

---

## 3. 地图编辑器流程

### 3.1 MapEditorDocument

源码：`MapEditor/MapEditorDocument.swift`

编辑器自己的文档模型：

```text
id / displayName
width / height
hexes: [HexCoord: MapEditorHex]
regions: [RegionId: MapEditorRegionDraft]
theaters: [TheaterId: MapEditorTheaterDraft]
regionTheaterAssignments: [RegionId: TheaterId]
initialUnits: [MapEditorUnitDraft]
backgroundImage
```

四种编辑模式：

```text
hexPainter         地块
regionBuilder      省份
theaterAssignment  战区
unitPlanner        部队
```

编辑动作：

```text
idle
adding
deleting
```

地块工具：

```text
paint   覆盖已有 hex
extend  在已有 hex 邻位扩展稀疏地图
```

关键行为：

- `MapEditorDocument.contains(_:)` 判断实际存在的 hex，支持稀疏地图。
- `addHex(at:)` 只能在已有 hex 邻位扩展，避免凭空造孤岛。
- `deleteHex(at:)` 会删除该 hex 上初始部队；如果某 region 已无 hex，会删除 region 和 theater assignment。
- `resize` 会裁剪外部 hex、清理无效 region assignment 和越界单位。
- 底图 `backgroundImage` 只存在编辑器文档，不写入游戏 JSON。

### 3.2 编辑会话

源码：`MapEditor/MapEditorViewModel.swift`

典型流程：

```text
选择 mode
  -> beginAdding / beginDeleting
  -> 点击或拖拽 canvas
  -> applyPrimaryAction(at:)
  -> stage 或直接编辑
  -> finishEditing
  -> commitPendingRegion / commitPendingTheater / commitPendingUnits
```

不同模式行为：

- `hexPainter`
  - adding + paint：写 terrain、road、controller、supply。
  - adding + extend：尝试在相邻空位生成 plain hex。
  - deleting：删除 hex。

- `regionBuilder`
  - adding：把点击 hex 先放进 `pendingRegionHexes`，完成时统一 assign 到选中或新建 region。
  - deleting / erase：把 hex 的 regionId 清空。

- `theaterAssignment`
  - 点击 hex 后先取该 hex 的 regionId。
  - adding：把 region 放进 `pendingTheaterRegions`，完成时统一 assign 到选中或新建 theater。
  - deleting：清除 region 的 theater assignment。

- `unitPlanner`
  - adding：点击 hex 放入 `pendingUnitHexes`，完成时按模板、阵营、朝向、HP 生成初始单位。
  - 同一 hex 新 stamp 会先删除原单位。
  - deleting / erase：删除该 hex 上初始单位。

快捷键：

- `N`：添加。
- `M`：完成。

### 3.3 导出链路

源码：`MapEditor/MapEditorExporter.swift`

导出产物：

```text
ScenarioDefinition JSON
RegionDataSet JSON
```

导出前校验：

- 所有 hex 必须有 regionId，否则 `unassignedHex`。
- 所有被引用 region 必须在 `document.regions` 里定义。
- 每个导出的 region 必须至少有一个 hex，否则 `emptyRegion`。

`ScenarioDefinition` 写入：

- map width/height/isSparse。
- 每个 `MapEditorHex` 写为 `ScenarioTileDefinition`。
- terrain / road / controller / city / fortress / supply / objective / regionId。
- factions、initialTurn、initialPhase、playerFaction、aiFaction。
- turnOrder、humanControlledFactions、aiControlledFactions 会从文档中的势力推导；明末势力文档默认玩家为 `ming`，AI 为其他参战势力；legacy 文档仍导出 Allies 玩家 / Germany AI。
- `initialUnits` 从 `MapEditorUnitDraft` 写入。
- 底图不写入。

`RegionDataSet` 写入：

```text
hexToRegion:
  每个 hex 的 coord key -> regionId

regions:
  每个 MapEditorRegionDraft -> RegionNodeDefinition
  theaterId = document.regionTheaterAssignments[draft.id]
  displayHexes = 属于该 region 的 hex
  representativeHex = displayHexes 几何中心最近 hex
  terrain = region 内 dominant terrain
  city = 第一处 city / fortress / city terrain
  neighbors = 从 hex 邻接自动推导

edges:
  从跨 region hex 邻接自动推导
  两侧 hex 都有 road 时 hasRoad = true

supplySources / objectives:
  从对应 hex 自动归到 region
```

重要：region 邻接和 edge 不是人工手填权威，而是在导出时从真实 hex 邻接推导。这和运行时前线必须看 hex 邻接是一致的。

### 3.4 默认资源桥

源码：`MapEditor/MapEditorGameResourceBridge.swift`

默认读写路径：

```text
WWIIHexV0/Data/chongzhen_1642_scenario.json
WWIIHexV0/Data/chongzhen_1642_regions.json
```

流程：

```text
loadDefaultDocument()
  -> 读取默认 ScenarioDefinition + RegionDataSet
  -> makeDocument(...)
     - scenario tile -> MapEditorHex
     - regionData.toHexToRegion 优先填 regionId
     - region definitions -> MapEditorRegionDraft
     - region theaterId -> regionTheaterAssignments
     - scenario initialUnits -> MapEditorUnitDraft

overwriteDefaultGameResources(document:)
  -> MapEditorExporter.export(... 固定默认文件名)
  -> 写回 WWIIHexV0/Data
```

相关测试确认：

- 编辑器 document、导出 JSON、游戏加载后的 `hexToRegion` / `regionToTheater` / `tile.regionId` / `region.name` 必须一致。
- 游戏和编辑器 hex layout 的垂直方向必须一致。
- 默认开局单位不能出现在敌对初始 theater 中。
- App bootstrap 不应自动跑 AI 或移动开局单位。

---

## 4. 主游戏 UI 与输入流程

### 4.1 AppContainer

源码：`WWIIHexV0/App/AppContainer.swift`

`AppContainer` 是 SwiftUI 和规则层之间的中介。它持有：

```text
@Published gameState
selectedUnitId / selectedHex / selectedRegionId
movementHighlights / attackHighlights
interactionLog
lastCommandMessage
lastAgentDecisionRecord
lastWarDirectiveRecords
observerModeEnabled
mapDisplayLayer
```

玩家提交命令：

```text
submit(command)
  -> commandHandler.execute(command, in: gameState)
  -> StrategicStateBootstrapper.bootstrapIfNeeded(result.state)
  -> lastCommandMessage = result.message
  -> appendInteractionEvent(...)
  -> refreshSelectionAfterStateChange()
  -> runAIIfNeeded()
```

点击地图：

```text
handleBoardTap(coord)
  -> selectedHex = coord
  -> selectedRegionId = MapDisplayAdapter.regionId(for: coord)
  -> 如果已有己方可行动单位选中，且点击处有敌军:
       submit(.attack)
     else 如果点击处有单位:
       handleDivisionTap
     else 如果已有己方可行动单位选中:
       submit(.move)
     else:
       清空选择
```

玩家可行动单位必须满足：

- 非 observer mode。
- 单位属于 `activeFaction`。
- 当前 active faction 在 `humanControlledFactions` 中，且 `phase.allowsHumanCommands == true`；当前兼容 `.humanAction` 和 legacy `.alliedPlayer`。
- 未行动。

### 4.2 RootGameView

源码：`WWIIHexV0/UI/RootGameView.swift`

主界面元素：

- `BoardSceneView`：SpriteKit 地图。
- `HUDView`：朝报令条，读取当前势力、回合、胜负、钱粮总账、入账、营造队列和 `CourtStrategySummary` 四线压力；结束回合与新局仍由 `RootGameView` 传入回调。
- `MapDisplayLayer` segmented picker：
  - `hex / province / initialTheater / dynamicTheater / frontLine / deployment` 仍是底层 layer rawValue。
  - 玩家可见标签由 `MapDisplayLayer.displayName` 控制，当前显示为舆图、州府、初划、战局、前线、布防。
  - `MapDisplayLayer.systemImageName`、`legendTitle` 和 `legendDetail` 只服务顶部舆图图例，不参与 overlay 计算。
- “观战” toggle。
- “粮道” toggle，仅控制 hex 图层的粮道显示；顶部图例条解释城池、关隘、粮台、军牌、势力旗、军令计划和粮道虚线。
- “信息”按钮展开/收起信息面板，内含：
  - 军队 + 州府 + 军令
  - 州府
  - 将领
  - 塘报战记
  - 钱粮
  - 朝廷
  - 天下：`DiplomacyPanelView` 读取 `DiplomacyState` 和只读 `CourtStrategySummary`，展示天下急势、战意条、战和关系和朝议/军议摘要。
  - AI
- `UnitTooltipView`。

v4.4-v4.6 首片中，HUD、CommandPanel、EconomyPanel、RegionInspector、UnitInspector、UnitTooltip、DiplomacyPanel、CourtPanel、GeneralCommandPanel、GeneralProfile、AgentPanel 和 EventLog 分类已改为明末中文展示；`MingDesignTokens` 统一面板圆角、间距、触控高度和朱砂/金/青瓷等色彩；`HUDView` 已升级为朝报令条，把回合、当前势力、胜负、钱粮和朝议四线压力前置到第一屏；`CommandPanelView` 已升级为军令牌，把当前势力/阶段、选中军情、兵力、粮草、退守、行动、固守/退守/补给处置和军令回执组织成可扫读的军事指令界面；`EventLogView` 已升级为塘报战记，把最近 60 条事件按战事、粮草、州府和天下分类展示；`EconomyPanelView` 已升级为府库牌，把民力、银两、粮草、入账、维护、补员、募兵筹粮和营造队列组织成可扫读的钱粮界面；`RegionInspectorView` 已升级为州府牌，按城关粮坊、地方治理、钱粮城防、战局归属和当前格组织 `RegionInspectorState` 只读信息；底层图层枚举、源码类型名和部分 JSON schema 字段仍保留开发兼容名。

当前开局不会在 `RootGameView` 自动 `.task { runAIIfNeeded() }`。AI 行动由 `advanceOrRunAI()` 或命令提交后的 `runAIIfNeeded()` 触发。

### 4.3 v1.1 主游戏 macOS target

源码：

- `WWIIHexV0/App/WWIIHexV0MacApp.swift`
- `WWIIHexV0/SpriteKit/BoardSceneView.swift`
- `WWIIHexV0/SpriteKit/BoardScene.swift`
- `WWIIHexV0/UI/PlatformStyles.swift`

v1.1 新增独立 macOS 主游戏 target：

```text
WWIIHexV0Mac
  -> WWIIHexV0MacApp
  -> AppContainer.bootstrap()
  -> RootGameView(container:)
  -> BoardSceneView
  -> BoardScene
```

这个 target 和既有 target 的边界：

- `WWIIHexV0`：iOS 主游戏 target。
- `WWIIHexV0Mac`：macOS 主游戏 target。
- `MapEditorMac`：macOS 地图编辑器 target，不是主游戏入口。

`WWIIHexV0Mac` 复用主游戏数据和规则，不新增一套 mac 专用规则。resource phase 包含：

```text
ardennes_v0_scenario.json
ardennes_v02_regions.json
general_agents.json
generals.json
terrain_rules.json
unit_templates.json
```

DEBUG 下 `DataLoader` 仍优先读源码目录 `WWIIHexV0/Data/*.json`；bundle resources 是 release / fallback 路径。

`BoardSceneView` 现在有平台分支：

```text
iOS:
  UIViewRepresentable
  -> SKView
  -> BoardScene touch input

macOS:
  NSViewRepresentable
  -> BoardEventSKView
  -> BoardScene mouse / scroll / magnify input
```

macOS 输入桥接逻辑：

```text
鼠标点击
  -> BoardScene.mouseDown / mouseUp
  -> layout.pixelToHex
  -> onHexTapped(coord)
  -> AppContainer.handleBoardTap

鼠标拖拽
  -> BoardScene.mouseDragged
  -> camera.position 更新
  -> clampCamera

滚轮 / 触控板缩放
  -> BoardEventSKView.scrollWheel / magnify
  -> scene.convertPoint(fromView:)
  -> BoardScene.handleScrollWheel / handleMagnify
  -> zoomCamera(anchor:)
  -> clampCamera
```

注意：macOS 点击仍只进入 `AppContainer.handleBoardTap`。移动、攻击、结束回合和 AI 行动仍由 `RuleEngine` / `WarCommandExecutor` 处理；v1.1 不允许通过 AppKit 或 SpriteKit 直接修改 `GameState`。

---

## 5. 命令执行流程

### 5.1 Command / RuleEngine

源码：`WWIIHexV0/Commands/Command.swift`、`WWIIHexV0/Rules/RuleEngine.swift`、`WWIIHexV0/Rules/CommandValidator.swift`、`WWIIHexV0/Rules/CommandExecutor.swift`

底层 `Command` 当前包括：

```text
move(divisionId, destination)
attack(attackerId, targetId)
hold(divisionId)
allowRetreat(divisionId)
resupply(divisionId)
queueProduction(kind)
endTurn
```

执行总入口：

```text
RuleEngine.execute(command, in: state)
  -> EconomyRules.bootstrapIfNeeded(state)
  -> CommandValidator.validate(command, in: preparedState)
  -> invalid: 返回 CommandResult，state 不变
  -> valid: CommandExecutor.execute(command, in: preparedState)
```

### 5.2 校验规则

`CommandValidator` 的关键校验：

移动：

```text
phaseAllowsCommands
division exists
division.faction == activeFaction
division 未行动、未撤退、canAct
destination 在地图内
destination passable
destination 没有其他单位
忽略 movement 的最短路径 cost <= division.movement
真实 shortestPath 存在
```

攻击：

```text
attacker 可行动
target exists
DiplomacyState.canAttack(attacker: attacker.faction, target: target.faction)
distance <= attacker.range
```

恢复/姿态：

```text
phase 合法
division exists
faction 匹配 activeFaction
未行动、未毁灭、未撤退
```

结束回合：

```text
phaseAllowsCommands
```

生产排队：

```text
phaseAllowsCommands
active faction economy ledger 有足够民力 / 银两 / 粮草
```

### 5.3 移动与占领

`CommandExecutor.executeMove` 真实链路：

```text
记录 origin
sourceZoneId = warDeploymentState.zoneId(for: origin)
更新 facing
division.coord = destination
division.hasActed = true

if OccupationRules.canOccupy(division, destination, state):
  tile.controller = division.faction
  map.setTile(tile)

  if destinationRegionId && sourceZoneId:
    applyStrategicAdvance(
      regionId: destinationRegionId,
      hex: destination,
      sourceZoneId: sourceZoneId,
      faction: division.faction
    )

  StrategicStateSynchronizer.synchronizeAfterOccupationChange(
    affectedRegionIds: [destinationRegionId]
  )

appendEvent("moved")
```

`OccupationRules.canOccupy` 很小，但非常关键：

```text
tile exists
tile.isCapturable
tile.controller != division.faction
destination 没有其他单位
```

注意：

- 只有移动会触发占领。
- 攻击造成伤害/撤退/消灭，不会自动把攻击者推进到目标 hex。
- 移动进敌控空 hex 时，先改 hex controller，再同步战略层。
- 移动进有敌单位的 hex 会在 validator 被 `destinationOccupied` 拒绝。

### 5.4 动态战区推进

`CommandExecutor.applyStrategicAdvance` 的语义：

```text
advancingTheaterId = TheaterId(sourceZoneId.rawValue)
如果 theater 不存在，return
如果 destination hex 已经属于 advancingTheater，return
如果 shouldAdvanceDynamicTheater == false，return

TheaterSystem.expandDynamicTheater(
  breakthroughHex: destination,
  advancingTheaterId,
  faction
)

oldZoneId = warDeploymentState.zoneId(for: destination)
如果 oldZoneId != sourceZoneId:
  WarDeploymentManager.advanceHex(destination, from: oldZoneId, to: sourceZoneId)

appendEvent("Hex q,r reassigned to dynamic theater ...")
```

`shouldAdvanceDynamicTheater` 当前判断：

- 如果目标 hex 当前 zone 属于其他 faction，则可以推进。
- 否则如果目标 hex controller 不是本方，也可以推进。
- 否则不推进。

这确保动态推进是 hex 级，不会把整个 region 拉走。

### 5.5 Region / Theater / Front / Deploy 同步

源码：`WWIIHexV0/Rules/StrategicStateSynchronizer.swift`

占领变化后：

```text
RegionOccupationRules.aggregateControl(in: &state)
  -> changedRegionIds

affected = affectedRegionIds + changedRegionIds

TheaterSystem.updateTheaters(force: true)

FrontLineManager.update(
  events:
    changed -> regionControllerChanged
    unchanged -> occupationChanged
)

WarDeploymentManager.update(
  events: affected.map(regionControllerChanged)
)

可选写 region owner change event
```

Region controller 聚合权重：

- 每个已控制 hex 基础权重 1。
- `representativeHex` 加 region city VP。
- city / fortress / city terrain / fortress terrain 再加权。
- 中立 hex 不计入。
- 并列第一时不改 region controller。

### 5.6 攻击、撤退、补给、结束回合

攻击流程：

```text
计算 attackDamage
attacker.hasActed = true
attacker.facing = 面向 defender
对 defender 扣 strength
resolveCombatResult
  -> retreatable 且 lossRatio >= 0.35 时 shouldRetreat
  -> hold 模式追加损失
  -> encircled 且撤退触发追加损失
  -> destroyed 则 removeDivision + victory record
如果 defender 没撤退且可反击:
  defender counterattack
  attacker 也可能撤退/毁灭
```

v4.3 明末军队首步：

- `ComponentType` 保留 legacy `tank` / `motorizedInfantry` / `infantry` / `artillery`，并新增 `cavalry`、`firearm`、`bannerCavalry`、`militia`、`siegeEngine`。
- `Division.isMobileUnit` 统一识别 legacy 机动单位、骑兵和旗骑；`ZoneCommanderAgent` 与 `WarCommandExecutor` 的机动战术选择读取这个 helper。
- `Division.hasFireSupport` 识别火器、炮队和攻城器械。
- `Division.isSiegeCapable` 识别炮队和攻城器械；攻击 city / fortress hex 时获得首步攻城加成。
- `TacticName.displayName` 提供明末展示名：正攻、疾袭、突骑破阵、破围、合围、火器压制、佯攻、流动作战、固守、诱敌退守、层层设防、死守城关。

注意：v4.4-v4.5 首片只迁移资源展示、生产单位组件、AI 钱粮摘要和只读朝议摘要；v4.6 第二片新增一次性朝廷项目入口，后续片新增四线项目分组，但仍不新增独立 morale、payStatus、grainCarry、灾荒事件、多回合政策状态、完整科技树或多回合 siege state。粮草仍沿用 `SupplyRules` / `SupplyState`，完整粮道、军饷、治安、政策科技和围城事件链后续继续推进。

结束回合：

```text
SupplyRules.updateSupplyStates
EconomyRules.resolveFactionTurn(for: activeFaction)
  -> 收入入账
  -> 支付战略补给维护费
  -> 粮草短缺时 supplied 单位降为 lowSupply
  -> 安全后方自动补员
  -> 推进生产队列并部署完成单位
SupplyRules.advanceRetreats
SupplyRules.applyEncirclementAttrition
VictoryRules.updateVictoryState
  -> 明末剧本先读取 BattleObjectiveSummary：
     四条胜负线优先由 GameState.victoryConditions 编译，城关控制方、objective points 领先方都从 GameState / MapState 派生
  -> chongzhen_1642 剧本走明末胜负链：
     清：山海关 + 北京
     大顺：开封 + 洛阳 + 西安
     大西：荆州 + 武昌
     明：最终回合守住北京 + 山海关 + 武昌
     最终未触发明确条件时按 objective points 判定
  -> legacy 其他剧本保留阿登巴斯托涅 / St. Vith / 单位毁灭 / 装甲断补条件

CommandExecutor.appendBattleCueEvents
  -> chongzhen_1642 剧本把 BattleObjectiveSummary.cues 写入 eventLog
  -> relatedRecordId = battle-cue-<turn>-<faction>-<cue id>，同回合同势力同 cue 去重
  -> 只写塘报，不改变 hex、region、economy、victory 或 AI 指令权威

CommandExecutor.appendBattleTaskEvents
  -> chongzhen_1642 剧本把 BattleObjectiveSummary.tasks 中的急务/主线写入 eventLog
  -> 最多写 3 条，relatedRecordId = battle-task-<turn>-<faction>-<task id>，同回合同势力同 task 去重
  -> 只写塘报，不保存任务进度，不改变 hex、region、economy、victory 或 AI 指令权威

activeFaction:
  按 GameState.resolvedTurnOrder 找到下一个 faction
  到达队列末尾时回到第一个 faction，并 turn += 1
  phase = actionPhase(for: nextActiveFaction)
    legacy Germany AI -> germanAI
    legacy Allies human -> alliedPlayer
    human controlled -> humanAction
    otherwise -> aiAction

resetActionsForActiveFaction
StrategicStateBootstrapper.refreshRuntimeState
appendEvent("Turn advanced ...")
```

---

## 6. AI / 战争指令流程

### 6.1 v0.5 默认元帅决策链

源码：`WWIIHexV0/Turn/TurnManager.swift`、`WWIIHexV0/Agents/ZoneCommanderAgent.swift`、`WWIIHexV0/Commands/WarDirective.swift`、`WWIIHexV0/Commands/WarCommandExecutor.swift`

v0.5 分支默认路径：

```text
AppContainer.runAIIfNeeded
  -> runAISequence
  -> TurnManager.runAITurn(... pipelineMode: .marshalDirective)
  -> MarshalAgent.resolve
  -> MarshalBattlefieldSummarizer.summary
  -> SimulatedMarshalLLMClient.completeTheaterDirectiveJSON
  -> TheaterDirectiveDecoder.parse
  -> TheaterDirectiveCompiler.compile
  -> DirectiveEnvelope / ZoneDirective
  -> WarCommandExecutor.execute(directive, in: state)
  -> RuleEngine.execute(Command)
  -> WarDirectiveRecord
  -> RuleEngine.execute(.endTurn)
```

`MarshalAgent` 是元帅层，不是单位，也不是新规则执行器。它只读取降维摘要并输出 `TheaterDirectiveEnvelope` JSON：

```text
TheaterDirectiveEnvelope
  schemaVersion = 5
  issuerId / turn / faction
  strategicIntent
  directives: [TheaterDirective]

TheaterDirective
  zoneId
  category offense/defense
  tactic
  priority
  targetTheaterId
  weightedRegions / focusRegionId / supportRegionIds
  reserveBias
  intensity / maxCommittedUnits / exploitDepth
  rationale
```

`TheaterDirectiveDecoder` 负责从模拟 LLM 文本中提取 fenced JSON，使用 `JSONDecoder` 解码，并校验 schemaVersion、issuerId、turn、faction、zone 存在性、zone 阵营、region id、target theater/front zone 与 tactic/category 一致性。解码或校验失败时，不执行半成品 JSON，`MarshalAgent` fallback 到 `TheaterCommanderPool`。

`TheaterDirectiveCompiler` 把元帅意图降级到现有 `ZoneDirective`：

- offense -> `ZoneDirective.attack`，保留 target theater、weighted/focus/support regions、intensity、maxCommittedUnits、exploitDepth。
- defense -> `ZoneDirective.defend`，把 reserveBias 转成 targetReserves，把 focus/weighted regions 转成 strongpointRegionIds，把 supportRegionIds 转成 fallbackRegionIds。
- 某个 zone 没有元帅 directive 或编译失败时，使用 `TheaterCommanderPool` 给该 zone 的旧 directive。

最终执行由 `TurnManager.executeDirectiveEnvelope` 统一完成。`.marshalDirective` 和显式 `.zoneDirective` 共享同一段 WarCommandExecutor 执行、WarDirectiveRecord 记录、endTurn 推进逻辑。

`CourtStrategySummary` 已作为只读朝议摘要进入元帅摘要，但统治者层仍是后续预留方向；当前 v0.5 主路径不调用 `RulerAgent`，也不在 `DirectiveEnvelope` 与执行层之间插入统治者姿态塑形。朝廷项目属于玩家显式提交的 `Command`，不是元帅/Ruler 自动下发的政策层。

Legacy Agent D 仍存在，但只在显式 `.legacyAgentOrder` 分支运行：

```text
AgentContextBuilder
  -> DecisionProvider
  -> AgentDecisionParser
  -> AgentCommandMapper
  -> RuleEngine
```

默认不得把 Legacy 管线接回战争 AI 主路径。

v0.37 直接将军池路径仍可显式使用：

```text
TurnManager.runAITurn(... pipelineMode: .zoneDirective)
  -> TheaterCommanderPool.envelope
  -> ZoneCommanderAgent.makeDirective
  -> DirectiveEnvelope
  -> WarCommandExecutor
```

### 6.2 AI 触发条件

`AppContainer.shouldRunAI`：

```text
如果 phase == resolution:
  不运行
如果 activeFaction 在 aiControlledFactions:
  运行 AI
否则如果 observerModeEnabled 且 activeFaction 在 humanControlledFactions:
  运行 observer AI
否则:
  等待玩家操作
```

`runAISequence`：

- 非 observer mode：最多跑 1 个 AI step。
- observer mode：最多跑 2 个 AI step，因此一次按钮推进可让当前 AI 阵营行动，若回合切到另一个 AI 控制阵营，也继续行动一次。

### 6.3 ZoneCommanderAgent 如何做决策

`TheaterCommanderPool` 会对当前 faction 的每个有 `frontSegments` 的 `FrontZone` 生成 directive。

每个 zone：

```text
visibleEnemyStrengthByRegion
friendlyFrontStrength
mobileFriendlyStrength
artillerySupportStrength
friendlyDepthStrength
pressure / supplyWarningCount
hasContestedForwardPresence
hasRecentStaticDefense
  -> BinaryTacticClassifier.classify
```

`BinaryTacticClassifier`：

```text
ratio = friendlyStrength / visibleEnemyStrength
如果 visibleEnemyStrength == 0，则 ratio = friendlyStrength
styleBoost:
  aggressive +0.15
  balanced 0
  cautious -0.15

shouldAttack =
  adjustedRatio >= attackThreshold(默认 1.2)
  或 hasContestedForwardPresence
  或 hasStaticDefense
```

分类结果：

- offense：
  - `blitzkrieg`：机动兵力占比高且 adjustedRatio >= 1.65。
  - `spearhead`：机动兵力可用，adjustedRatio >= 1.35，且有可见敌 region；用于定点矛头。
  - `breakthrough`：adjustedRatio >= 1.35，向弱点突破。
  - `fireCoverage`：炮兵/远程支援可用但优势不足，先火力覆盖。
  - `feint`：优势不足但需要牵制时少量佯攻。
  - `guerrillaWarfare`：机动兵力可用、敌 region 多、优势有限时袭扰纵深。
  - `standardAttack`：普通进攻 fallback。
- defense：
  - `lastStand`：极端劣势、无纵深预备队且压力高时死守。
  - `defenseInDepth`：有纵深预备队且压力/劣势明显时纵深防御。
  - `elasticDefense`：压力、补给警告或劣势时弹性防御。
  - `holdPosition`：普通防御 fallback。

`TacticConditionChecker` 不再恒放行：闪电战/游击战要求机动单位，火力覆盖要求炮兵或远程单位，佯攻要求前线单位，纵深防御要求 depth 预备队；不满足条件会降级为 `holdPosition`。

进攻 directive：

```text
ZoneDirective(
  zoneId,
  attack: AttackParameters(
    targetTheaterId,
    weightedRegions,
    intensity,
    focusRegionId,
    supportRegionIds,
    convergenceRegionId,
    coordinatedZoneIds,
    maxCommittedUnits,
    exploitDepth
  ),
  category: .offense,
  tactic: blitzkrieg / spearhead / breakthrough / pincerMovement / fireCoverage / feint / guerrillaWarfare / standardAttack,
  commandTarget: .region(focusRegionId) 或 .theater(target)
)
```

定点突破目标选择：

```text
priorityRegions =
  focusRegionId
  + commandTarget.region
  + convergenceRegionId
  + weightedRegions
  + supportRegionIds

若 tactic weakPointFocus:
  对候选 region 评分：
    enemyStrength 越低越优先
    terrain.movementCost 越低越优先
    region 内有 road 越优先
    city victoryPoints + supplyValue + factories + infrastructure 越高越优先
  最优 region 放到候选首位
```

钳形攻势数据层：

```text
pincerMovement 使用 convergenceRegionId + coordinatedZoneIds
每个 zone 仍各自编译成一条 ZoneDirective
执行器只推进本 zone 成功移动的具体 hex
会师/包围效果仍交给补给、前线、动态战区同步派生
```

防御 directive：

```text
ZoneDirective(
  zoneId,
  defense: DefenseParameters(
    targetReserves,
    stance,
    fallbackRegionIds,
    counterattackRegionIds,
    strongpointRegionIds,
    maxFrontCommitment
  ),
  category: .defense,
  tactic: holdPosition / elasticDefense / defenseInDepth / lastStand,
  commandTarget: .theater(self)
)
```

`AttackIntensity` 仍是参数字段；v0.7/v1.0 的真实分流主要由 `tactic` 决定。v1.0 已把 `.infiltration` 解释为默认低投入上限，但执行器不绕过 `RuleEngine` 给强度加直接伤害。

### 6.4 WarCommandExecutor 如何翻译指令

入口：

```swift
func execute(_ directive: ZoneDirective, in state: GameState) -> WarCommandExecutionResult
```

它不需要 `ZoneCommanderAgent` 实例，不需要 issuer。手写合法 `ZoneDirective` 可以直接执行，这是 v0.4 玩家命令 UI / 聊天命令要复用的后端能力。

执行路由：

```text
如果 directive.tactic 存在:
  standardAttack / blitzkrieg / spearhead / breakthrough / pincerMovement / fireCoverage / feint / guerrillaWarfare
    -> executeAttack(tactic)
  holdPosition / elasticDefense / defenseInDepth / lastStand
    -> executeDefense(tactic)
否则按 parameters:
  attack -> executeAttack
  defend -> executeDefense
```

防御翻译：

```text
zone 必须存在且有 frontSegments
lastStand:
  不保留 depth，全力 holdLine
elasticDefense:
  stance 强制 flexible，前线单位优先 allowRetreat
defenseInDepth:
  前线单位 allowRetreat
  保留 targetReserves 个 depth 预备队
  其余 depth 机动单位优先反击可见敌军，否则向 fallback/strongpoint region 移动
普通防御:
  unitIds = unitsFront + 部分 unitsDepth（保留 targetReserves）
对每个可行动单位:
  找 lightestFrontRegion
  如果单位已在该 region:
    holdLine -> .hold
    flexible -> .allowRetreat
  否则如果能找到 tacticalDestination:
    .move
  否则:
    hold / allowRetreat
  run(command, fallback: hold)
```

进攻翻译：

```text
zone 必须存在
targetZoneId = AttackParameters.targetTheaterId.rawValue
segments = 指向 targetZone 的 frontSegments，若为空则用全部 frontSegments

按 tactic 得到 AttackTacticProfile:
  blitzkrieg / spearhead:
    includeDepthUnits = true
    mobileOnlyWhenAvailable = true
    weakPointFocus = true
    holdNonCommittedFront = true
  breakthrough:
    includeDepthUnits = true
    weakPointFocus = true
  pincerMovement:
    includeDepthUnits = true
    mobileOnlyWhenAvailable = true
    convergenceRegionId 可作为深目标
  fireCoverage:
    artilleryFirst = true
    attackOnly = true；没有射程目标则 hold，不主动推进
  feint:
    只投入 maxCommittedUnits 或默认约 1/3 前线单位
  guerrillaWarfare:
    mobileOnlyWhenAvailable = true
    allowDeepTarget = true
    默认只投入约半数前线+纵深单位

attackingUnitIds =
  unitsFront
  + profile.includeDepthUnits ? unitsDepth : unitsFront 为空时 fallback unitsDepth
  -> 过滤可行动单位
  -> 需要时优先机动单位
  -> 按 artillery / mobile / attack / movement / strength 排序
  -> 应用 maxCommittedUnits

对每个可行动单位:
  targetEnemyRegion =
    focus / commandTarget.region / convergence / weighted / support 中仍相邻或允许深目标的 region
    或 front segment 相邻敌 region
    weakPointFocus 时用敌军强度、地形、道路、战略价值重排
  如果射程内有 visible enemy division:
    .attack
  否则如果 fireCoverage:
    .hold
  否则如果能找到 tacticalDestination:
    .move
  否则:
    .hold
  run(command, fallback: hold)
```

`run` 包装层会：

- 先记录 acting division 的 logical source zone。
- 调 `RuleEngine.execute(command, in: state)`。
- 如果被拒绝，写日志；如果原命令非法但 fallback hold 合法，则执行 fallback。
- 成功后做防御性同步：
  - 计算 affected region。
  - 尝试 `applyDirectiveOccupation`（通常普通 `CommandExecutor` 已处理过）。
  - 尝试 `applyStrategicAdvance`（确保 directive move 也推进 dynamic theater）。
  - `StrategicStateSynchronizer.synchronizeAfterOccupationChange`。
  - 记录 region owner change / front change event。

TurnManager 外层会为每条 directive 生成 `WarDirectiveRecord`：

```text
issuerId
turn
faction
zoneId
directiveType
targetRegionIds
commandResults
diagnostics
category
tactic
commanderAgentId
commandTarget
```

直接调用 `WarCommandExecutor.execute` 不会自动写 `WarDirectiveRecord`；记录职责在 `TurnManager.runDirectiveTurn` 外层。

---

## 7. UI / 地图显示流程

### 7.1 BoardScene

源码：`WWIIHexV0/SpriteKit/BoardScene.swift`

绘制顺序：

```text
drawTiles
drawLayerOverlay
drawRegionOverlays（仅 hex layer）
drawRoads
drawRivers
drawUnits（frontLine layer 隐藏单位）
```

点击：

```text
touchesEnded
  -> layout.pixelToHex(point)
  -> state.map.contains(coord)
  -> onHexTapped(coord)
```

平移：

- 触摸移动 camera。
- `clampCamera` 限制在地图边界附近。

v4.6 首片中，空地图/加载失败时的标题改为“明末棋策舆图”。`UnitNode` 不再绘制 NATO APP-6 椭圆/斜线/圆形兵牌，而是按单位组件显示中文军牌徽记：`城` 表示攻城/炮队，`旗` 表示旗骑/重骑，`火` 表示火器支援，`骑` 表示机动部队，`步` 表示步军；底部用兵力和 `守` / `退` 显示退守模式。势力旗号首片后，`Faction.bannerGlyph` 为明廷、后金/清、大顺、大西和地方中立提供“明/清/顺/西/乡”短旗号，地图军牌顶端显示该旗号，`UnitInspectorView` 和 `CommandPanelView` 的军牌印面同步显示旗号。`HexNode` 继续把城池、关隘/堡寨和补给源标成“城 / 关 / 粮”舆图 badge，旧 `FORT` 与 `SUP A/G` 主地图文案已改为“关隘”“粮台”。`BoardScene.drawSupplyRoutes` 会在 hex 图层读取 `SupplyRules.supplyPath(for:in:)`，把玩家势力当前可达粮台的 hex 线路画成金色虚线；线路 zPosition 低于 fog，高于道路/河流，避免穿透未探索格；显示受 `AppContainer.showsSupplyRoutes` 和顶部“粮道”按钮控制。`BoardScene.drawPlannedOperations` 读取当前回合玩家 `PlayerCommandState.plannedOperations`，把进取计划画成朱砂箭头和“进”令牌，把固守计划画成青绿“守”令牌；它只说明已记录的计划，不新建或执行计划。`RootGameView` 顶部图层名已改为舆图、州府、初划、战局、前线、布防，并在图例条中解释城池、关隘、粮台、军牌、势力旗、军令计划、粮道和非 hex 图层含义。`RegionInspectorView` 已把州府详情做成州府牌，显示州府徽记、地方治理、民力/银两/粮草、粮台/工坊/驿道、目标、友敌军和当前格归属。以上变化只影响 SpriteKit/SwiftUI 展示，不改变 `Division` 组件、移动、攻击、补给、占领、经济、region 聚合或战区规则。

### 7.2 MapDisplayAdapter

源码：`WWIIHexV0/SpriteKit/MapDisplayAdapter.swift`

职责：

- hex -> region 查询。
- 视野判断。
- 单位显示位置/堆叠。
- Region inspector state。
- Unit inspector strategic state。

Inspector 中关键字段：

```text
selectedHexController
selectedHexDynamicTheaterId
selectedHexFrontZoneId
theaterId = dominantDynamicTheaterId(region)
frontZoneId = dominantDynamicFrontZoneId(region)
frontPressure
friendlyDivisions
visibleEnemyDivisions
```

单位 strategic state：

```text
coord
regionId
dynamicTheaterId
frontLineIds
frontZoneId
deploymentRole
```

### 7.3 MapDisplayLayer

源码：`WWIIHexV0/Core/MapDisplayLayer.swift`、`WWIIHexV0/SpriteKit/MapLayerOverlayCalculator.swift`、`WWIIHexV0/SpriteKit/MapLayerOverlayNode.swift`

当前 layer：

```text
hex
province
initialTheater
dynamicTheater
frontLine
deployment
```

bucket 来源：

| Layer | 数据来源 |
|---|---|
| `hex` | 每个 hex 自己 |
| `province` | `map.region(for: hex)` |
| `initialTheater` | `theaterState.initialSnapshot?.regionToTheater[regionId]` |
| `dynamicTheater` | `theaterState.dynamicTheaterId(for: hex, map:)` |
| `frontLine` | `frontLineState.regionStates[regionId].frontLines` |
| `deployment` | 该 hex 上单位的 `WarDeploymentManager.deploymentRole` |

前线 overlay 的线段来源：

```text
frontLineSegments()
  -> 遍历 FrontLine.segments
  -> friendlyBoundaryHexes(
       friendlyRegionId: segment.regionA,
       enemyRegionId: segment.regionB,
       friendlyTheaterId: frontLine.theaterId
     )
  -> 只取 friendly region 内、且 dynamicTheaterId == friendly theater 的 hex
  -> 这些 hex 必须邻接 enemy region 中另一个 dynamic theater 的 hex
  -> 用这些 friendly hex center 画线
```

这意味着前线视觉画在我方动态战区侧，不画敌我中间共用边，也不画初始 theater 边界。

`frontLineChains()` 会把相邻 hex 点串成拓扑链。不同 segment 起点有分隔符，多敌 theater 接触会加 dashed overlay。

---

## 8. 关键链路示例

### 8.1 玩家移动占领一个敌控空 hex

```text
玩家点击己方单位
  -> AppContainer.selectDivision
  -> MovementRules 生成 movementHighlights

玩家点击敌控空 hex
  -> AppContainer.submit(.move)
  -> RuleEngine.validate(move)
  -> CommandExecutor.executeMove
     - division.coord = destination
     - tile.controller = division.faction
     - TheaterSystem.expandDynamicTheater 只推进 destination hex
     - WarDeploymentManager.advanceHex 只推进 destination hex 的 FrontZone
     - StrategicStateSynchronizer
       - RegionOccupationRules 聚合 region controller
       - TheaterSystem.updateTheaters
       - FrontLineManager.update dirty region
       - WarDeploymentManager.update dirty region
  -> AppContainer.bootstrapIfNeeded
  -> UI 刷新 dynamic theater / front / deployment overlay
  -> 如果现在轮到 AI，则 runAIIfNeeded
```

不得发生：

- 不得把 destination 所在整个 region 的 `regionToTheater` 改成进攻方。
- 不得绕过 `OccupationRules.canOccupy`。
- 不得只改 region controller 而不改 hex controller。

### 8.2 AI 进攻一个前线 zone

```text
用户点下一回合 / AI faction active
  -> AppContainer.runAIIfNeeded
  -> StrategicStateBootstrapper.refreshRuntimeState
  -> TurnManager.runAITurn(.zoneDirective)
  -> TheaterCommanderPool 选出该 faction 有 frontSegments 的 FrontZone
  -> ZoneCommanderAgent 计算兵力比/可见敌军/前沿存在
  -> 生成 standardAttack ZoneDirective
  -> WarCommandExecutor.execute
     - 找 zone.unitsFront
     - 选 targetEnemyRegion
     - 能打则 attack，不能打则 move，不能 move 则 hold
     - 每个 command 都走 RuleEngine
     - 同步占领/动态战区/前线/部署
  -> TurnManager 写 WarDirectiveRecord
  -> RuleEngine.execute(.endTurn)
  -> AppContainer 写 lastAgentDecisionRecord / lastWarDirectiveRecords
```

AI 看到的前线单位池来自 `WarDeploymentState`。如果某单位没有进入 `unitsFront` / `unitsDepth`，该 zone 的 AI 就不会调度它。

### 8.3 地图编辑器改默认地图后进入游戏

```text
MapEditorGameResourceBridge.loadDefaultDocument
  -> 读现有 scenario + region JSON
  -> 用户编辑 hex / region / theater / unit
  -> overwriteDefaultGameResources
     - MapEditorExporter.export
       - 校验所有 hex 有 region
       - 从 hex 邻接推导 region neighbors / edges
       - 写 scenario JSON
       - 写 region JSON
     - 覆盖 WWIIHexV0/Data 默认资源

重新运行游戏 app
  -> DataLoader DEBUG 优先读源码 JSON
  -> loadGameState
  -> map / regions / theater initialSnapshot / front / deploy 全部重建
```

注意：已经启动的旧 simulator app 不会自动重新加载默认 JSON。

---

## 9. 调试断点与排查顺序

遇到“AI 不动、前线不对、地图不一致、占领不同步、拒绝率异常”时，按这条链查，不要直接改大块逻辑：

```text
1. 数据加载
   - DataLoader 是否读的是源码 JSON 还是旧 bundle？
   - ScenarioDefinition tiles / initialUnits 是否正确？
   - RegionDataSet.hexToRegion / regions[].theaterId 是否正确？
   - map.validateRegionGraph() 是否为空？

2. Hex 层
   - Division.coord 是否真的变化？
   - HexTile.controller 是否真的变化？
   - 目标 hex 是否被其他单位占据？
   - OccupationRules.canOccupy 是否允许？

3. Region 层
   - state.map.region(for: hex) 是否正确？
   - RegionOccupationRules.aggregateControl 后 region.controller 是否改变？
   - 是否出现权重并列导致 controller 不变？

4. Theater 层
   - initialSnapshot.regionToTheater 是否保持不变？
   - regionToTheater 是否被错误当成动态推进层？
   - hexToTheater[destination] 是否只改了目标 hex？
   - dynamicTheaterId(for:) 是否 fallback 到 regionToTheater 造成误读？

5. Front 层
   - FrontLineManager 是否扫描到真实相邻 hex？
   - fixture 是否只写了 Region.neighbors 但没有真实 hex 邻接？
   - split region 是否需要允许 regionA == regionB？
   - frontLineState.diagnostics.updatedRegionIds 是否包含目标 region？

6. Deploy 层
   - hexToFrontZone[destination] 是否更新？
   - regionToFrontZone 是否只是 dominant/fallback？
   - 单位为什么是 front/depth/garrison？
   - zone.unitsFront 是否包含应该行动的单位？

7. Directive 层
   - TheaterCommanderPool 是否为该 faction 生成 directive？
   - ZoneCommanderAgent 是否因为 zone.frontSegments 为空而返回 nil？
   - visibleEnemyStrength / friendlyFrontStrength 是否合理？
   - tactic/category 是否被记录？

8. Executor / RuleEngine 层
   - WarCommandExecutor.generatedCommands 是否为空？
   - CommandValidator 拒绝原因是什么？
   - fallback hold 是否执行？
   - WarDirectiveRecord.diagnostics 是否记录了拒绝？

9. UI 层
   - 当前 MapDisplayLayer 读的是 initial 还是 dynamic？
   - frontLine overlay 是否画在 friendlyBoundaryHexes？
   - observerMode 是否导致玩家不能选中行动单位？
```

---

## 10. 当前已知边界

- 真 LLM 尚未接入；当前只用 `SimulatedMarshalLLMClient` 模拟 fenced JSON 输出和解码流程。
- 默认 AI 上游已是 `MarshalAgent -> TheaterDirectiveEnvelope -> TheaterDirectiveDecoder -> TheaterDirectiveCompiler`，下游执行必须是 `ZoneDirective -> WarCommandExecutor -> RuleEngine`。
- 元帅层不能直接输出底层 `Command`，不能直接修改地图、单位、hex controller 或动态战区权威。
- 统治者层只作为未来方向预留，当前 v0.5 不在主链路调用。
- 当前工作树存在外交/经济/UI 等非 v0.5 方向残留，合并前需要单独审查文件归属和 public API 冲突。
- `AttackIntensity.infiltration` 已在 `WarCommandExecutor` 中解释为默认低投入上限；`.limitedCounter` 和 `.allOut` 仍主要依赖 tactic profile 与显式 `maxCommittedUnits`。
- `TacticConditionChecker` 当前总是允许现有战术。
- 战区互助接口 `requestSupport` / `getAvailableForces` / `notifyThreat` 有模型但没有主流程调用方。
- 攻击不会自动占领目标 hex，只有移动会占领。
- Legacy Agent D 管线仍保留，不应删除，也不应默认接回主战争 AI。
- `RegionCommand` / AgentOrder v2 仍可桥接到 hex command，但当前默认战争 AI 是 ZoneDirective。
- 地图编辑器的 theater assignment 是初始战区划分，不是运行时动态战区脚本。
- 历史回退的 Cabinet/Minister/StrategicDirective 管线仍不得恢复；v0.5 当前实现没有把内阁或部长塞进 `GameState`。

---

## 11. 轻量检查入口与历史回归参考

检查规范以 `md/test/test.md` 为准。当前默认不跑 Xcode / XCTest / 模拟器 / 性能类验证，只做轻量语法、格式和配置检查。

历史上这些回归曾用于守住核心语义，但现在只作只读参考，不作为每轮默认执行项：

- Probe：`WWIIHexV0Probes`
  - 数据启动、region graph、theater、frontline、deployment。
  - v0.358 动态 hex 战区推进。
  - v0.36 tactic/directive。
  - v0.37 手写 directive issuer-agnostic 执行。
- Dynamic Theater Regression：`WWIIHexV0Tests/Stage0355DynamicTheaterTests`
  - 守住 `regionToTheater` 不动态推进、`hexToTheater` 单 hex 推进、split region front、deployment split。
- MapEditor：`WWIIHexV0Tests/MapEditorOutputTests`
  - 守住编辑器输出与游戏加载一致、默认资源一致、视角一致、开局不自动 AI。
- Stage Regression：
  - Theater / FrontLine / WarDeployment / CommandSystem / Agent / Observer / LayeredMap。

默认允许的检查方向：

- 文档改动：尾随空白、旧测试口径残留、人工阅读一致性。
- JSON 改动：对改动文件运行 `jq empty`。
- Xcode project / scheme 改动：运行 `plutil -lint` 或 `xmllint --noout`。
- 少量 Swift 改动：仅在不会触发全项目构建时，对直接改动文件做单文件语法检查。

多分支或多子 Agent 并发后，即使不跑测试，也必须检查文件重叠、public API 分叉、数据 schema 分叉、Xcode project 冲突和文档口径冲突。未完成冲突检查前，不得声称候选分支可合并。

---

## 12. v1.0 UI / AI / Playtest 分支收口

v1.0 分支名：`v1.0-ui-ai-playtest`。

该分支不改变战术权威和命令权威，只让当前主游戏更适合人工初版试玩和后续调参：

```text
GameState / WarDirectiveRecord / EventLog
  -> RootGameView
  -> HUD + Info tabs
  -> AgentPanelView 展示 raw JSON / command results / zone directives
  -> EventLogView 塘报战记展示最近 60 条分类日志

BoardScene
  -> 缓存 unit display hex
  -> 排序绘制单位
  -> deployment 图层复用 WarDeploymentManager 计算 role

Marshal / ZoneDirective
  -> AttackParameters.intensity
  -> WarCommandExecutor.attackTacticProfile
  -> infiltration 低投入上限
  -> RuleEngine 仍是唯一执行权威
```

算法变化：

- AI 面板从只展示 `AgentDecisionRecord` 扩展为同时展示 `WarDirectiveRecord`，每条 directive 可看到 zone、attack/defend、tactic、命令成功/拒绝数量和目标 region。
- 日志面板用 `LogDisplayEntry` 保存 entry + category，避免 body 内对同一条日志重复分类。
- 单位绘制先缓存 `unitDisplayHex` 再排序，避免 comparator 重复计算。
- `AttackIntensity.infiltration` 在无显式 `maxCommittedUnits` 时默认只投入约半数前线/纵深候选单位，避免渗透/袭扰全线压上。

试玩观察重点：

- UI：HUD、Info tabs、Economy、Diplomacy、AI panel 是否可读。
- 地图：hex/province/initial/dynamic/front/deploy 图层是否清晰。
- AI：raw JSON、zone directive、diagnostics 是否能解释 AI 回合。
- 规则：玩家和 AI 行动是否仍能追溯到 `CommandResultSummary` / `WarDirectiveRecord`。
- 性能体感：地图拖动、图层切换、日志面板滚动是否有明显卡顿。

当前限制：

- 未跑 Xcode / XCTest / 模拟器 / 性能测试。
- 当前工作树含多版本未提交改动，v1.0 合并前必须重新审查 `project.pbxproj`、Swift 新文件引用、AI schema 和文档版本口径。

---

## 13. v0.4 将军养成、将军 UI 与玩家双轨命令

v0.4 分支名：`v0.4-generals-command-ui-final`。

该分支把 0.41-0.48 的将军与玩家命令链路收口到当前代码，仍保持命令权威不变：

```text
Data/generals.json
  -> DataLoader.loadGeneralRegistry
  -> GeneralRegistry / GeneralDispatcher
  -> FrontZone.generalAssignment
  -> AppContainer.selectedGeneral*
  -> GeneralCommandPanelView / GeneralProfileView

玩家微操单位
  -> AppContainer.submit(Command)
  -> RuleEngine
  -> PlayerCommandState.micromanagedDivisionIds
  -> WarCommandExecutor.execute(... excluding: lockedIds)

玩家宏观将军命令
  -> GeneralCommandPanelView 按钮
  -> AppContainer 组装 ZoneDirective
  -> WarCommandExecutor
  -> RuleEngine
  -> WarDirectiveRecord + PlayerPlannedOperation
  -> BoardScene 计划线 / 金色微操单位圈
```

核心算法：

- 将军数据：`GeneralData` 从 `generals.json` 读取，包含阵营、军衔、倾向、技能、头像占位、履历、偏好 theater/region、忠诚和满意度基线。
- 初始分配：`RegionNodeDefinition.assignedGeneralId` 可由地图 JSON / MapEditor 写入。`DataLoader` 在生成 `WarDeploymentState` 后收集 region 种子，调用 `GeneralDispatcher.assignGenerals`。
- 指派规则：
  1. 如果 FrontZone 已有合法同阵营 `generalAssignment`，保留该将军，只刷新 `assignedDivisionIds`。
  2. 否则优先使用该 zone 下 region 的 `assignedGeneralId`。
  3. 再按将军 `preferredTheaterIds` / `preferredRegionIds` 匹配。
  4. 最后从同阵营未占用将军池取第一名；没有可用将军时安全空岗。
- HQ 逻辑：不生成占格子的 HQ 单位。`GeneralAssignment.hqRegionId` 指向战区内友方城市或最大 region，`GeneralDispatcher.isHQUnderAttack` 通过 region controller 判断 HQ 是否被夺。
- 将军养成初步：`GeneralAssignment` 保存 `loyalty`、`satisfaction`、`interventionCount`。玩家直接微操某个将军辖下单位时，记录干预次数并轻微降低满意度。
- 微操锁：玩家在己方 phase 对具体师执行 move/attack/hold/resupply/allowRetreat 后，该师 id 写入 `PlayerCommandState.micromanagedDivisionIds`。本回合玩家再下达战区宏观命令时，`WarCommandExecutor.execute(... excluding:)` 会跳过这些师，避免同一回合被将军指令覆盖。`endTurn` 或 active faction / turn 改变时清空锁。
- 半自动指令：`GeneralCommandPanelView` 的 `Hold Line` 生成 defense `ZoneDirective`，`Attack Region` 根据当前选中敌方 region 和相邻玩家 FrontZone 生成 attack `ZoneDirective`，直接复用 `WarCommandExecutor -> RuleEngine`，不通过 `TurnManager.runDirectiveTurn`，因此不会自动结束玩家回合。
- 记录与反馈：玩家宏观命令写入 `WarDirectiveRecord` 和 `PlayerPlannedOperation`。`BoardScene` 只读 `PlayerCommandState.plannedOperations`，画源 region 到目标 region 的箭头；防御命令画源点圆环。玩家微操锁定单位在 `UnitNode` 上显示金色底圈。
- UI：`RootGameView` 新增 `General` tab，Unit tab 也嵌入 `GeneralCommandPanelView`。`GeneralProfileView` 用 sheet 展示将军身份、履历、技能、忠诚/满意度、干预次数、HQ 状态和辖下部队。

边界：

- v0.4 不让将军或 UI 直接修改 `GameState` 战术权威；所有行动仍要走 `Command` / `ZoneDirective -> WarCommandExecutor -> RuleEngine`。
- v0.4 没有实现真正抗命、政变、完整 RPG 成长树或真实 LLM 聊天解析；当前是忠诚/满意度和干预次数的可视化与数据底座。
- v0.4 没有做自由手绘前线。采用 region 锚点法：选择战区/目标 region 后自动画箭头，符合 0.44 文档中的移动端妥协方案。
- 当前工作树混有 v0.5、v0.7、v0.9、v1.x 外部改动；合并前必须重新做文件/API/schema/project 冲突审查。

---

## 14. v4.6 明末 UI、朝廷项目与四线分组

v4.6 首片先做 UI 和 SpriteKit 展示收口；第二片把朝廷面板中的六类主议/备议推进为一次性可执行项目；后续片把这些项目按政策、经济、科技、军事四线分组呈现。三者仍共享一个边界：UI 不直接改 `GameState`，所有执行必须走统一命令/规则管线。

```text
MingDesignTokens
  -> HUDView 朝报令条
  -> CommandPanelView 军令牌
  -> GeneralCommandPanelView 将印军令
  -> GeneralProfileView 将领名帖
  -> AgentPanelView 军机复盘牌
  -> EventLogView 塘报战记
  -> RootGameView
  -> UnitInspectorView / UnitTooltipView
  -> CourtPanelView
  -> UnitInspectorView 军情牌
  -> RegionInspectorView 州府牌
  -> EconomyPanelView 府库牌

CommandPanelView 军令牌
  -> 读取 selectedDivision / activeFaction / phase / playerFaction / observerModeEnabled
  -> 展示选中军情 / 兵力 / 粮草 / 退守 / 行动 / 军令回执
  -> onHold / onAllowRetreat / onResupply / onEndTurn
  -> AppContainer 原有回调
  -> Command / RuleEngine

GeneralData + GeneralAssignment + FrontZone
  -> GeneralCommandPanelView 将印军令
  -> 防区 / 压力 / 战态 / 主将 / 忠诚 / 军心 / 干预 / 麾下军伍 / 目标 / 军令计划
  -> onHoldLine / onAttackRegion
  -> AppContainer 原有回调
  -> ZoneDirective / WarCommandExecutor / RuleEngine

GeneralData + GeneralAssignment + Division
  -> GeneralProfileView 将领名帖
  -> 印信 / 统兵风格 / 履历奏记 / 君臣关系 / 将略 / 麾下军伍
  -> 只读展示，不修改将领、部署或命令规则

AgentDecisionRecord + RulerDecisionRecord + WarDirectiveRecord
  -> AgentPanelView 军机复盘牌
  -> 决策摘要 / 最高意志 / 战区指令 / 命令回执 / 异常塘报 / 原始 JSON
  -> 只读展示，不修改 AI、命令或规则执行链

GameLogEntry
  -> EventLogView 塘报战记
  -> 战事 / 粮草 / 州府 / 天下分类计数
  -> 最近 60 条塘报 / 回合 / 势力 / 阶段 / 回执
  -> 只读展示，不修改日志 schema 或规则执行链

FactionEconomyLedger
  -> HUDView 朝报令条
  -> 当前库存 / 入账 / 营造队列
  -> EconomyPanelView 府库牌
  -> 库存 / 入账 / 维护 / 补员 / 募兵筹粮 / 营造队列
  -> Command.queueProduction

CourtStrategySummary
  -> HUDView 朝报令条
  -> 政策 / 经济 / 科技 / 军事四线压力

CourtProjectDomain + CourtProjectKind
  -> CourtPanelView 朝议争点
  -> CourtPanelView 四线项目分组
  -> Command.enactCourtProject
  -> CommandValidator
  -> CommandExecutor
  -> EconomyRules.enactCourtProject

DiplomacyState + CourtStrategySummary
  -> DiplomacyPanelView 天下急势
  -> 当前势力 / 主要对手 / 战意
  -> 政策 / 经济 / 科技 / 军事四线压力只读展示

SupplyRules.supplyPath
  -> AppContainer.showsSupplyRoutes
  -> BoardRenderState.showsSupplyRoutes
  -> BoardScene.drawSupplyRoutes
  -> 粮道虚线只读展示 / RootGameView 舆图图例

PlayerCommandState.plannedOperations
  -> BoardScene.drawPlannedOperations
  -> 朱砂“进”令牌箭头 / 青绿“守”令牌
  -> RootGameView 军令计划图例
  -> 只读展示，不创建、不删除、不执行计划

Division.faction / Faction.bannerGlyph
  -> UnitNode 地图军牌顶端势力旗
  -> UnitInspectorView / CommandPanelView 军牌印面势力旗
  -> RootGameView 势力旗图例
  -> 只读展示，不改变控制权、外交或命令执行

MapDisplayLayer
  -> displayName 舆图 / 州府 / 初划 / 战局 / 前线 / 布防
  -> systemImageName / legendTitle / legendDetail
  -> RootGameView 顶部图层说明

BoardScene / HexNode / UnitNode
  -> 明末舆图空态
  -> 城 / 关 / 粮地图 badge
  -> 中文军牌徽记
  -> 守/退状态

RegionInspectorState
  -> RegionInspectorView 州府牌
  -> 城关粮坊 / 治理 / 钱粮城防
  -> 方面 / 防区 / 目标 / 友敌军 / 当前格
```

当前完成点：

- `CourtPanelView` 独立成文件并加入 iOS/macOS source phase，仍从 `CourtStrategySummary.from(faction:state:)` 只读派生朝议摘要，并按政策、经济、科技、军事四线展示压力值、朝议争点、关注点、项目成本收益和风险。
- 信息按钮、图层 picker、观战 toggle、新局按钮、军令/将领名帖/单位/塘报战记/AI 面板做明末中文 polish。
- `MingDesignTokens` 提供共享设计常量，避免每个面板继续散落不同圆角、padding 和背景色。
- `HUDView` 以朝报令条展示当前 active faction、回合、胜负、民力/银两/粮草、入账、营造队列和 `CourtStrategySummary` 四线压力；它只负责 SwiftUI 展示，结束回合和新局仍通过 `RootGameView` 注入的 `onEndTurn` / `onNewGame` 执行。
- `CommandPanelView` 以军令牌展示当前 active faction、phase、选中军情、兵力、粮草、退守、行动、固守/退守/补给处置和最近军令回执；它只负责 SwiftUI 展示，固守、准许退守、就地补给和结束回合仍通过 `RootGameView` 注入的 `AppContainer` 回调进入原命令链。
- `GeneralCommandPanelView` 以将印军令展示当前防区、压力、战态、主将、忠诚、军心、干预次数、麾下军伍、目标和军令计划；固守防线和进取州府仍通过 `RootGameView` 注入的 `AppContainer` 回调进入原指令链。
- `GeneralProfileView` 以将领名帖展示 `GeneralData` 的印信、势力、官职、统兵风格、履历奏记、君臣关系、将略和麾下军伍；它只负责 SwiftUI 展示，不写入将领、部署或命令状态。
- `AgentPanelView` 以军机复盘牌展示 AI 与军机记录，读取 `AgentDecisionRecord` 的主事、来源、意图、局势摘要、legacy command results、错误和 raw JSON；读取 `RulerDecisionRecord` 的最高意志、姿态、重心、目标、攻势阈、留营、天下判断和朱批理由；读取 `WarDirectiveRecord` 的战区、势力、军机、督师、战术、目标、指向、命令成功/驳回数量和 diagnostics。它只负责 SwiftUI 展示，不写入 `GameState`，也不改变 `MarshalAgent`、`RulerAgent`、`WarCommandExecutor`、`Command`、`CommandValidator` 或 `RuleEngine`。
- `EventLogView` 以塘报战记展示最近 60 条 `GameLogEntry`，顶部用“报”印、候报/有军情/粮情/战局/天下状态和战事/粮草/州府/天下计数组织当前局势；每条塘报保留回合、势力、阶段、分类图标、正文和相关回执。它只负责 SwiftUI 展示，不改变 `GameLogEntry` schema、事件写入点、命令执行或任何规则权威。
- `UnitInspectorView` 以军情牌展示选中部队，读取 `Division` 的兵力、补给、退守、行动、`effectiveStats` 和兵种组件，以及 `UnitInspectorStrategicState` 的坐标、州府、动态方面、防区、部署和前线归属；它只负责 SwiftUI 展示，不写入任何战术或战略状态。
- `RegionInspectorView` 以州府牌展示选中州府，读取 `RegionInspectorState` 的州府、治理、钱粮产出、目标、友敌军、方面/防区和当前 hex 归属；它只负责 SwiftUI 展示，不写入 hex、region、economy、front、deployment 或命令状态。
- `EconomyPanelView` 以府库牌展示当前 active faction 的 `FactionEconomyLedger`，读取库存、入账、维护、补员、生产成本和 `ProductionOrder` 进度；生产入口仍只调用 `onQueueProduction -> AppContainer.queueProduction -> Command.queueProduction`，不直接写入 `EconomyState`。
- `DiplomacyPanelView` 的“天下急势”读取当前势力外交关系、主要对手、战意和朝议四线压力；诸方势力列表用势力色和战意条增强中华世界局势可读性，不改变外交状态。
- `UnitNode` 改用中文军牌徽记，移除默认主地图上的 NATO 风格兵牌；军牌顶端读取 `Faction.bannerGlyph` 显示明/清/顺/西/乡等势力旗号。
- `BaseTerrain.displayName` 改为平原、林地、山地、丘陵、城池、关隘/堡寨；`HexNode` 增加“城 / 关 / 粮”badge，并把粮台和关城标识中文化。
- `SupplyRules` 新增只读 `supplyPath` helper，复用既有补给成本和通行规则返回 hex 路径；`BoardScene` 在 hex 图层绘制粮道虚线，选中单位路线优先显示。
- `AppContainer.showsSupplyRoutes` 默认开启，只通过 `BoardRenderState` 进入 SpriteKit；`RootGameView` 顶部“粮道”按钮可在 hex 图层开关显示，并用图例标出金色虚线含义。
- `BoardScene.drawPlannedOperations` 读取 `PlayerCommandState.plannedOperations` 并只显示当前回合、当前 viewer faction 的计划，进取计划显示朱砂箭头和“进”令牌，固守计划显示青绿“守”令牌；它不修改 `PlayerCommandState`，也不触发 `ZoneDirective` 或 `WarCommandExecutor`。
- `MapDisplayLayer.displayName` 改为舆图、州府、初划、战局、前线、布防；顶部图例条按当前 layer 展示图标、说明和城/关/粮/步/军令计划/粮道符号，只作 SwiftUI 说明，不改变底层 rawValue 或 overlay 计算。
- `CourtProjectDomain` 目前包含政策、经济、科技、军事四类，`CourtProjectKind` 目前包含征饷、赈济安民、修城固守、整训团练、火器整备、粮台转运六项；粮台转运显示为经济/军事交叉项目，但 UI 以主领域分组避免重复列表。
- `CourtDebateSection` 只在朝廷面板中读取现有压力值、州府数、火器/炮队数和前线数，展示安民与征饷、火器与团练、粮道与城防三组争点，不写入 `GameState`，也不影响 `CourtProjectKind` 的执行可用性。
- `Command.enactCourtProject(kind:)` 与生产命令同级，`actingDivisionId` 为 nil；校验只允许可行动 phase 且资源足够时执行。
- `EconomyRules.enactCourtProject` 会扣除项目成本、追加即时资源收益，并按项目轻量调整地方治理、州府 infrastructure/supplyValue、生产队列、火器/炮队兵力或缺粮部队状态。

仍未完成：

- 未加入真实美术资产、地图纹理、旗帜图案资产、头像、截图检查清单或运行时视觉验收。
- 未新增多回合政策/科技 directive、完整科技树、独立粮道状态/漕运资源规则或灾荒/军饷事件。
- 未改变 `Command` / `ZoneDirective -> WarCommandExecutor -> RuleEngine` 执行权威。

---

## 15. 云端协作与 main 直推验证链路

本节记录协作制度，不改变 WWIIHexV0 的业务规则、AI 管线或地图权威边界。当前默认开发闭环是：

```text
人工提出目标
  -> Agent A 本地分析并写版本化提示词
  -> Agent B 同步 origin/main，在 main 上实现
  -> Agent B 本机只跑轻量检查
  -> Agent B commit 并 push 到 origin/main
  -> GitHub Actions 运行静态检查和 Xcode 云端 build
  -> Actions 上传未加密 ci-results artifact
  -> Agent C 下载 artifact，核对 manifest / JUnit / 日志 / failure summary
      -> 失败：退回 Agent B 在 main 上追加修复 commit
      -> 通过：Agent C 确认最新 main run 并更新文档
  -> 人工复核，进入下一轮
```

关键约束：

- `main` 是默认唯一上传、提交、推送和云端验证分支。
- 不创建 PR，不默认使用 `smalldata_test`、`develop`、`codeb/...` 或其他候选分支。
- Agent B push 前必须确认当前分支是 `main`、目标远端是 `origin/main`、提交范围只包含本轮相关文件。
- 本机默认只跑 `md/test/test.md` 允许的轻量检查；Xcode build/test、Probe、Smoke、Stage Regression、Dynamic Theater Regression、Full 和模拟器验证默认交给云端或人工明确授权后执行。
- Agent C 只验收 `origin/main` 最新 commit 对应的 workflow run 和 artifact，不能验收旧 run 或旧结果包。

GitHub Actions 当前入口：

```text
.github/workflows/ci-results.yml
  -> push main / workflow_dispatch
  -> git diff --check
  -> plutil / xmllint / jq
  -> xcodebuild target WWIIHexV0Mac Debug build
  -> ci-results/ci-artifact-manifest.json
  -> ci-results/junit.xml
  -> ci-results/xcodebuild.log
  -> ci-results/static-checks.log
  -> ci-results/ci-failure-summary.md
  -> upload-artifact
```

Agent C 下载缓存位置：

```text
/private/tmp/wwiihexv0-c-review-<run_id>/
```

这条云端协作流只迁移 AITRANS 的协作制度和验证骨架；不复制其漫画探针、GGUF、模型 Release、`test/1.png`、`smalldata_test` 等项目特例。
