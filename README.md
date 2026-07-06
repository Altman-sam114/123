# WWIIHexV0 — 明末迁移中的 iOS / macOS AI 战略战棋工程

> **当前状态：代码仍以 WWIIHexV0 / 阿登 legacy 底座为兼容主线，文档大纲已切换到 v4.0-v4.8 明末迁移路线。当前工作树已推进到 v4.7 明末胜负链首片和 v4.6 发布级明末 UI、朝廷项目、地图标识首片：`Faction` 可表达明廷、后金/清、大顺、大西和地方中立，`DataLoader.loadInitialGameState()` 优先加载 `崇祯十五年：天下裂变` 明末 JSON，失败才回退阿登；默认明末初始单位已切到关宁铁骑、八旗骑营、红衣炮队、流民军老营、地方团练等明末 template；生产和经济 UI 已以民力、银两、粮草、募营兵、募精骑、造炮队、筹粮口径展示，钱粮面板已升级为府库牌，集中展示库存、入账、军粮维护、补员消耗、收支急报、净民力/银两/粮草、募兵筹粮和营造队列；地方治理会影响州府钱粮，州府详情已升级为明末州府牌，集中展示州府主值、政粮械兵四要点、城关粮坊、治理、钱粮修正、控制方旗号、原属章、战局归属、目标、友敌军和当前格旗号；天下局势面板展示诸方势力、战和关系和朝议/军议，并新增“天下急势”摘要、势力旗号、主战标记、战意条、离散值、阵营名义卡、战和张力条和朝议四线压力；朝廷面板和 AI 摘要开始显示政策、经济、科技、军事四线压力与议题建议，并新增只读朝议总纲以及安民与征饷、火器与团练、粮道与城防三组只读朝议争点；朝廷面板还会复用 `BattleObjectiveSummary.CampaignLineBrief` 展示只读天下五线态势，让朝议直接看到天下、政策、经济、科技、军事五线的战役压力和急务数；顶部 HUD 已升级为朝报令条，前置展示当前势力、回合、胜负、胜负理由、民力、银两、粮草、入账、营造队列和朝议四线压力；部队详情已升级为明末军情牌，显示军牌字、势力旗号、兵力条、粮草/退守/行动、攻守行程察指标、兵种编成条和驻防归属；明末舆图军牌浮签首片已让 `UnitTooltipView` 只读展示选中地图部队的势力旗号、兵力条、粮草/行动/退守状态、攻守行程察指标和兵种组件 chip；军令面板已升级为明末军令牌，展示当前势力/阶段、选中军情、势力旗号、兵力、粮草、退守、行动、固守/退守/补给处置和军令回执；将领面板已升级为将印军令和将领名帖，展示防区态势、主将履历、忠诚、军心、手令干预、麾下军伍和军令计划；事件日志已升级为塘报战记，按急务、战役、战事、粮草、州府和天下分类展示最近塘报，并把本旬任务、战役提示和目标换手回执中文化；朝廷面板还提供征饷、赈济安民、招抚乡绅、农政屯田、修城固守、整训团练、火器整备、红衣炮维护、粮台驿道九类可执行朝廷项目，项目已按政策、经济、科技、军事四线分组显示压力、关注点、成本收益、风险和可批/尚缺/待本方/观战行动状态，交叉项目会出现在全部相关线组并标为兼线；整训团练作为政策/军事兼线项目，会保留 1 回合地方守备队列，并轻量稳定最多 2 个己控不稳州府；粮台驿道会补粮、恢复缺粮部队并整修己控粮道州府的驿道基础，不新增持久科技树或改变补给判定权威；默认主地图已把地形名切为平原、林地、山地、丘陵、城池、关隘/堡寨，并用“城 / 关 / 粮”标识城池、关隘和粮台；hex 图层会按现有 `SupplyRules` 为玩家势力有路可达的军队绘制粮道虚线，当前回合玩家军令计划会以“进/守”令牌和朱砂/青绿计划线显示，军牌顶端会以“明/清/顺/西/乡”等旗号显示势力归属，军牌新增旗色侧条、兵种印面和兵力小签底板，顶部图层已改为舆图、州府、初划、战局、前线、布防等中文名，并新增只读“天下急势”舆图条前置展示领先方、急务/主线任务数和天下/政策/经济/科技/军事五线压力，同时提供城/关/粮、步/骑/火/城/旗兵种军牌、粮草与堆叠、势力旗、军令计划和粮道图例条。明末胜负规则首片已按 `chongzhen_1642` 剧本接入：清破山海关/北京、大顺控开封/洛阳/西安、大西控荆州/武昌、明廷最终守北京/山海关/武昌，以及最终 objective points 归属；“目标”面板还新增只读天下五线态势、本旬任务链和阶段战局链，用天下、政策、经济、科技、军事五线压力提示当前 1-20 回合的中华世界局势重点；同一五线态势已进入 `AgentContext`、`MarshalBattlefieldSummary`、朝廷面板和军机复盘牌，`AgentPanelView` 会只读显示五线压力与当旬急务，并在每条战区指令里读取 `ZoneCommanderDoctrine.profile(for:)` 显示势力军略、指挥风格、技能标签和战术偏向，元帅摘要 schemaVersion 升到 9，让 legacy Agent prompt 与默认 Marshal strategic intent 都能读取明末名分、粮链、火器和军政压力；朝廷摘要也会读取明末战役线压力，把破关入京、河南秦陕粮链、湖广粮道和终局名分线转成修城、粮台驿道、火器、红衣炮、赈济、招抚、农政或征饷的主议/备议权重；legacy 阿登胜负链保留。军令按钮仍通过 `RootGameView -> AppContainer` 注入的原有回调提交到底层命令链，朝廷项目按钮仍通过 `Command.enactCourtProject -> CommandValidator -> EconomyRules -> RuleEngine` 执行，募兵筹粮按钮仍通过 `Command.queueProduction -> CommandValidator -> EconomyRules` 执行，不绕过规则系统；`CourtPanelView` 的朝议总纲、朝廷项目行动状态、`RegionInspectorView` 的州府主值、`UnitTooltipView` 的舆图军牌浮签也都只读现有摘要/状态，不改规则或命令。灾荒、军饷士气链、历史事件执行器、教程、真实美术资产和发布级截图验收仍未完成。历史测试基线曾达到 v0.37 Probe 18/0、Stage Regression 69/0、Full 226/0；当前工作流默认不跑 Xcode / XCTest / 模拟器测试，只按 `md/test/test.md` 做轻量检查。**

> v4.7 目标面板最新增量：`BattleObjectivePanelView` 在目标面板 header 后新增只读“天下棋眼”区，从 `BattleObjectiveSummary` 派生要冲分领先方、当前最急五线、本旬先手任务和可定位目标，让玩家进入“目标”tab 后先看到中华世界局势、政策/经济/科技/军事压力和本旬落点。该增量只改变 SwiftUI 展示；目标按钮仍沿用已有 `onFocusObjective -> AppContainer.focusObjective(_:)` UI 定位回调，不提交命令，不写塘报，不改变 `BattleObjectiveSummary`、`VictoryRules`、`Command`、`WarCommandExecutor`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威。

> v4.7 目标面板最新增量：`BattleObjectivePanelView` 在“天下棋眼”后新增只读“要冲缺口”区，从 `BattleObjectiveSummary.tracks` 和 `Target.isControlled` 按胜负线展示尚缺城关、最高分缺口、现控制方和定位入口，让玩家能从清破关入京、大顺中原秦陕、大西湖广粮道、明廷名分线快速回到舆图落点。该增量只改变 SwiftUI 展示；定位按钮仍沿用已有 `onFocusObjective -> AppContainer.focusObjective(_:)` UI 定位回调，不提交命令，不写塘报，不新增任务进度，不改变 `BattleObjectiveSummary`、`VictoryRules`、`Command`、`WarCommandExecutor`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威。

> v4.7 舆图要冲分布最新增量：`RootGameView` 顶部 `MingMapSituationStrip` 在“天下急势”内新增只读“要冲分布”横向小条，从 `BattleObjectiveSummary.scoreRows` 展示明廷、后金/清、大顺、大西等势力当前 objective points 和控制要冲数量，并用旗号与冠标标出领先方。该增量只改变 SwiftUI 展示，不提供目标定位按钮，不写塘报，不新增持久状态，不改变 `BattleObjectiveSummary`、`VictoryRules`、`Command`、`WarCommandExecutor`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威。

> v4.7 舆图本旬先手最新增量：`RootGameView` 顶部 `MingMapSituationStrip` 在“要冲分布”后新增只读“本旬先手”提示，从 `BattleObjectiveSummary.tasks` 选取当前最高优先级任务，并用 `tracks.targets` 补出目标城关、当前控制方和要冲分，让玩家在地图首屏直接看到中华世界局势的本旬落点。该增量只改变 SwiftUI 展示，不提供目标定位按钮，不写塘报，不新增持久状态，不改变 `BattleObjectiveSummary`、`VictoryRules`、`Command`、`WarCommandExecutor`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威。

> v4.7 朝廷面板最新增量：`CourtPanelView` 在“朝议批票”后新增只读“廷议要冲”区，从 `BattleObjectiveSummary.scoreRows` 和 `leadingFaction` 展示各势力要冲分、控制要冲数、本方分值与领先方，并把要冲归属写入“廷议会看”摘要，帮助朝廷面板把中华世界局势落回政策、经济、科技、军事取舍。该增量只改变 SwiftUI 展示，不提供定位按钮，不写塘报，不执行朝廷项目，不改变 `CourtStrategySummary`、`BattleObjectiveSummary`、`VictoryRules`、`Command.enactCourtProject`、`CommandValidator`、`EconomyRules`、`WarCommandExecutor`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威。

> v4.7 钱粮面板最新增量：`EconomyPanelView` 在“收支急报”后新增只读“府库四线牵引”区，从现有 `FactionEconomyLedger` 和当前势力的 `CourtStrategySummary` 派生政策、经济、科技、军事四线压力、库存、营造队列、主议和备议，让府库面板直接联读朝廷取舍、钱粮余势、火器支点与接战压力。该增量只改变 SwiftUI 展示，不新增经济、朝廷、科技或军饷字段，不触发生产或朝廷项目，不改变 `EconomyState`、`CourtStrategySummary`、`Command.queueProduction`、`Command.enactCourtProject`、`CommandValidator`、`EconomyRules`、`WarCommandExecutor`、`RuleEngine` 或任何规则权威。

> v4.7 钱粮面板最新增量：`EconomyPanelView` 在“府库四线牵引”后新增只读“经世策眼”区，复用 `BattleObjectiveSummary`、`CourtStrategySummary` 和 `FactionEconomyLedger`，把 objective points 领先方、最急天下五线、府库粮银余势、本旬主议与备议放进府库牌，帮助玩家从钱粮视角联读中华世界局势、政策、经济、科技和军事压力。该增量只改变 SwiftUI 展示，不新增按钮，不触发生产、朝廷项目、目标定位、AI 决策或塘报写入，不改变胜负、经济、朝廷、命令或任何规则权威。

> v4.6/v4.7 军令牌最新增量：`CommandPanelView` 在“舆图军令”提示后新增只读“要冲军令”区，由 `RootGameView` 注入 `BattleObjectiveSummary.from(state:)`，把本旬急务、目标落点和选中部队兵势放到同一张军令牌内扫读。该区只读取 `BattleObjectiveSummary` 与当前 `Division`，不提供按钮，不自动定位目标，不写塘报，不提交 `Command`，不改变胜负、朝廷、经济、AI、移动/攻击/补给或任何 hex/region/theater/front/deploy 权威。

> v4.7 最新增量：`DataLoader` 会把 `ScenarioDefinition.victoryConditions` 写入 `GameState.victoryConditions`，`BattleObjectiveSummary` 优先从剧本条件编译明末胜负线和 objective points 领先方，并额外派生松锦余波、催饷安民、火器与城防、粮道告急、军机复盘、开封围城压力和目标线压力等只读战役提示；结束回合时这些 cue 会以去重 `relatedRecordId` 入塘报日志；同一摘要还派生只读天下五线态势、本旬任务链和阶段战局链，让目标面板用天下、政策、经济、科技、军事五线压力，以及守山海关与京师、救援开封压力、定征饷安民尺度、巡河南湖广粮根、补火器与城防、终局名分线等任务解释当前可玩重点；朝廷面板也复用同一五线态势，帮助朝议主线与中华世界局势对齐。`BattleObjectiveSummary.Cue.Kind` 现在含“军械”类，只用于提示红衣炮维护、火器整备和修城固守的局势意义，不新增科技树或事件效果。`CampaignAISummary` 会把同一五线态势转成 Codable 摘要，进入 `AgentContext`、`AgentPromptBuilder`、`TurnManager.contextSummary` 和 `MarshalBattlefieldSummary`，使 AI/军机链路也能看到当前中华世界局势压力；军机复盘牌同时从当前 `GameState` 只读派生同一摘要，显示五线压力、告急状态和当旬急务；`CourtStrategySummary` 也会读取同一胜负线压力，把破关入京、河南秦陕粮链、湖广粮道和终局名分线加权到朝廷主议与备议。回合末还会把急务/主线任务最多 3 条写入任务塘报，帮助玩家在塘报战记里复盘当旬军政钱粮火器重点，但不执行事件效果。`VictoryRules` 与新增“目标”信息面板共用该摘要，玩家现在可在局内查看清破关入京、大顺据中原秦陕、大西据湖广粮区和明廷守京师关口各差哪些城关；目标城关 chip 会只读显示当前控制方旗号和要冲分，并可点击目标城关 chip 或任务定位按钮定位对应 hex / 州府，便于从胜负线回到舆图和州府牌；目标定位后，舆图会显示“标”令牌、脉冲圈、目标名、当前控制方和同胜负线城关连线，只读强化天下目标落点。明末 objective 因真实移动占领换手时，`CommandExecutor` 还会追加目标换手塘报，让北京、山海关、开封等关键城关变化进入复盘。开封围城压力当前只是只读提示和任务，不新增多回合围城状态或城防损耗。

> v4.7 AI doctrine 最新增量：新增 `ZoneCommanderDoctrine`，让默认 `TheaterCommanderPool`、`AppContainer` 空将领 registry fallback、显式 `.zoneDirective` 路径和 `MockAICommander` 按明末势力生成不同 `ZoneCommanderAgentConfig`：明廷谨慎守京畿和粮道，清方进取偏旗骑合围与截援，大顺进取偏破弱城扩粮，大西进取偏流动作战与夺粮，地方中立谨慎自保。`ZoneCommanderAgent` 还会在分类后按 doctrine 映射 tactic，让同态进攻下清方偏突骑破阵/合围、大顺偏破围、大西偏流动作战。`SimulatedMarshalLLMClient` 的默认元帅 JSON 上游也读取同一势力 doctrine，在相同 front 摘要下区分明廷火器压制、清方合围/突骑、大顺破围和大西流动作战。军机复盘牌现在也只读显示该 doctrine 的军略名、风格、技能标签和战术偏向，帮助玩家解释不同势力 AI 倾向。Legacy Agent D 的 `AgentPromptBuilder`、`MockAIClient`、`TurnManager.contextSummary` 和 fallback `GameAgent.sample` 也已按明末势力改成军机、粮草、城关、州府、火器和天下五线口径；legacy 德/盟分支仍保留阿登/Bastogne 回归文案。该片只影响 directive 生成偏置、legacy Agent prompt/模拟理由和 UI 可读文案；最终仍必须走 `TheaterDirective -> TheaterDirectiveCompiler -> ZoneDirective -> WarCommandExecutor -> RuleEngine`。

> v4.7 军机面板最新增量：`AgentPanelView` 在“军机五线”后新增只读“诸势军略”区，明末剧本下遍历 `Faction.mingLaunchCases` 并读取 `ZoneCommanderDoctrine.profile(for:)`，用势力旗号、军略名、指挥风格、前两项技能标签和战术偏向横向比较明廷、后金/清、大顺、大西与地方中立的 AI 性格。该增量只改变 SwiftUI 展示，不读取或写入 `WarDirectiveRecord` 以外的新状态，不提交命令，不写塘报，不改变 doctrine 配置、AI prompt、tactic 偏置、`WarCommandExecutor`、`Command`、`CommandValidator`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威。

> v4.6 舆图判读图例最新增量：`RootGameView` 的非 hex 图层图例新增“舆图判读”芯片，按州府、初划、战局、前线和布防分别提示政令/钱粮/民变、开局方面、动态推进、真实接敌和前军/纵深/驻守等读局重点；hex 图层的势力旗图例也从明/清/顺补齐为明/清/顺/西/乡。该增量只改变 SwiftUI 图例说明，不改变 `MapDisplayLayer` rawValue、`MapLayerOverlayCalculator`、SpriteKit 绘制、hex/region/theater/front/deploy 权威或任何命令规则。

> v4.6 天下局势最新增量：`DiplomacyPanelView` 在“天下概览”后新增只读“天下牵引”区，从现有 `DiplomacyState`、当前势力的 `CourtStrategySummary` 和最近 `RulerDecisionRecord.diplomacySummary` 派生战和格局、朝议牵引、政策/经济/科技/军事四线压力和御前奏报，帮助玩家把天下关系、朝廷取舍和军令重点连起来。该增量只改变 SwiftUI 展示，不新增外交状态，不写塘报，不执行朝廷项目，不改变 `GameState`、`DiplomacyState`、`CourtStrategySummary`、`Command`、`CommandValidator`、`WarCommandExecutor`、`EconomyRules`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威。

> v4.6 军机/塘报显示最新增量：`AgentPanelView` 在显示边界继续消除 raw 调试感，把 `AgentDecisionRecord.errors`、`CommandResultSummary.errors` 中的已知 `CommandValidationError.rawValue` 转为 `mingDisplayText`，把 `Mapping failed.`、`No AI faction was active.`、未知 provider 和未收录 doctrine skill 转成军机案卷口径；`EventLogView` 对非战役/急务/目标换手的 `relatedRecordId` 按前缀显示为战区军令、军机回执、朱批回执或系统回执，不再默认直出 raw id。该增量只改变 SwiftUI 展示，不修改 `AgentDecisionRecord`、`CommandResultSummary`、`GameLogEntry` 或任何 Codable schema，也不改变 AI、命令映射、校验、塘报写入或规则权威。

> v4.6 军令牌 UI 最新增量：`CommandPanelView` 在“战术处置”区新增只读“舆图军令”提示，按观战、未选军、敌军、非本方阶段、已行动、缺粮/断粮等现有状态说明下一步应在舆图点目标格调动/攻击，还是在军令牌内批固守、准退、补给；坐标显示也统一走 `MingMapLabelFormat.coordinate` 的“舆图格”口径。该增量只帮助玩家理解地图落子与面板按钮的分工，不新增状态，不改变 `Command`、`CommandValidator`、`WarCommandExecutor`、`RuleEngine` 或任何移动/攻击/补给规则。

> v4.6 UI 最新增量：`RegionInspectorView` 的州府牌新增控制方旗号、原属章和当前格控制旗号，帮助玩家在州府牌里直接看见明/清/顺/西/乡归属；`EconomyPanelView` 的府库牌新增“收支急报”，从现有 `FactionEconomyLedger` 只读派生净民力、净银两、净粮草、粮草/补员压力和营造待部署状态；`DiplomacyPanelView` 的天下局势面板继续 polish，诸方势力用势力旗号、主战标记、战意条和离散值展示，战和关系用双方旗号、关系状态、张力条和起始回合展示，阵营名义改为旗号、成员摘要和当前阵营高亮卡片；`EventLogView` 的塘报战记会只读识别 `battle-task-`、`battle-cue-` 和 `objective-control-` 回执，把本旬急务、战役提示和目标换手从普通事件中凸显出来；`UnitNode` 的地图军牌新增旗色侧条、兵种印面和兵力小签底板，顶部舆图图例同步解释步/骑/火/城/旗军牌、粮草圆点、断粮警示和堆叠数；`UnitTooltipView` 的明末舆图军牌浮签会只读展示选中地图部队的势力旗号、兵力条、粮草/行动/退守状态、攻守行程察指标和兵种组件 chip；`CourtPanelView` 新增只读“朝议总纲”，把主议、推荐项目归属、备议和政策/经济/科技/军事四线压力聚合为奏疏式扫读区；`AppContainer` 的玩家命令回执、将令诊断、目标定位、单位点选和 AI 回合摘要已改成明末中文口径，并把底层 `CommandValidationError` 转成中文驳回原因；`RulerAgent` 生成的最高意志理由和上下文也改为中文朱批式文本。四线项目分组继续读取 `CourtProjectKind.domains`，让农政屯田、红衣炮维护、粮台驿道等交叉项目同时出现在经济/科技/军事等相关线组，并在说明中标为“兼线”。整训团练也升级为政策/军事兼线项目，执行时仍排入 1 回合地方守备队列，并轻量稳定最多 2 个己控不稳州府的民变/行政。该片不改变 `GameState` 权威、`RegionInspectorState`、`EconomyState`、`DiplomacyState`、`GameLogEntry`、`SupplyRules`、`Division`、`CourtStrategySummary`、`AgentDecisionRecord`、`RulerDecisionRecord`、`WarDirectiveRecord`、`Command`、`CommandValidator`、`WarCommandExecutor`、`RuleEngine` 或 `Command.enactCourtProject -> EconomyRules -> RuleEngine` 执行链。

> v4.6 州府主值最新增量：`RegionInspectorView` 在州府牌头部后新增只读“州府主值”区，按目标、前线压力、关隘、粮台、工坊、驿道和治理压力优先级说明该州府当前更偏战局要冲、前线承压、城关屏障、粮台重地、工坊军械、驿道节点或治理承压，并用政/粮/械/兵四个 chip 联读政策、经济、科技、军事价值。该增量只读取 `RegionInspectorState`、`RegionNode`、`OccupationState` 和既有钱粮/战局字段，不新增状态，不改变 hex、region、economy、front、deployment、command 或规则权威。

> v4.6 UI/塘报文案最新增量：默认信息面板的 AI 入口改为“军机”，明末剧本载入塘报改为中文；`AgentPanelView` 在显示边界把旧 Agent D / 战区指令结果中的稳定 `Command.displayName` 前缀映射为调动、攻击、固守、准退、补给整备、营造筹备和结束阶段，但不改 `Command.displayName` 本体、Codable 记录、AI prefix 判定或历史测试数据；`RuleEngine` 回执、`CommandExecutor` 行军/战斗/固守/退守/回合推进/动态方面推进塘报和 `SupplyRules` 补给、退守、合围消耗塘报改为明末中文，并补充战斗、退守、补员、粮草、合围等显式分类，降低默认塘报里的英文调试感。该增量只影响可读文案和日志分类，不改变命令 schema、校验、战斗/补给/占领结果、`WarCommandExecutor` 或规则权威。

> v4.6 钱粮 UI 最新增量：`EconomyPanelView` 的府库牌新增只读“军饷民心”区，复用 `FactionEconomyLedger` 的银两库存、补员消耗、军粮维护和 `Division.supplyState`、`GovernanceAISummary` 的民变/行政摘要，派生军伍数、缺粮/被围数、军饷余势、民心综合和“军粮压顶/军饷吃紧/民心承压/军饷可支”等扫读状态。该增量只帮助玩家在钱粮面板联读经济、军队补给和地方治理压力，不新增军饷、士气、民心、灾荒字段或真实效果，不改变 `EconomyState`、`Division`、治理、补给、生产、命令或规则权威。

> v4.6 府库生产状态最新增量：`EconomyPanelView` 在“募兵与筹粮”每个生产行新增只读状态，按当前是否观战、是否本方可行动以及 `FactionEconomyLedger.stockpile` 与 `ProductionKind.cost` 的差额显示“可开工 / 尚缺民力、银两、粮草 / 待本方 / 观战”，并把“军饷民心”说明改为“账房奏报”口吻。该增量只改变 SwiftUI 展示，不新增经济字段，不改变生产成本、队列、`Command.queueProduction`、`CommandValidator`、`EconomyRules`、`RuleEngine` 或任何规则权威。

> v4.6 朝廷项目状态最新增量：`CourtPanelView` 在四线项目按钮右侧新增只读行动状态，按观战、本方行动阶段和 `FactionEconomyLedger.stockpile` 与 `CourtProjectKind.cost` 的差额显示“可批 / 尚缺民力、银两、粮草 / 待本方 / 观战”。该增量只改变 SwiftUI 展示和 VoiceOver 提示，不新增朝廷或经济状态，不改变 `Command.enactCourtProject`、`CommandValidator`、`EconomyRules`、`RuleEngine` 或任何规则权威。

> v4.6 朝廷 UI 最新增量：`CourtPanelView` 在“朝议总纲”之后新增只读“朝议批票”，把 `CourtStrategySummary` 的推荐项目、四线最高压力和 `BattleObjectiveSummary.CampaignLineBrief` 中最急的天下五线态势合成票拟摘要，并展示项目成本、收益与风险。该增量只帮助玩家理解本旬为什么批某个政策/经济/科技/军事项目，不新增朝廷状态，不自动执行项目，不改变 `CourtStrategySummary` 排序、`CourtProjectKind` 成本收益、命令校验、经济规则或规则权威。

> v4.6 军机/战区诊断最新增量：`CommandValidationError` 新增只读 `mingDisplayText`，供玩家回执、军机记录和战区军令日志统一显示中文驳回原因；`TurnManager` 会把无军令、战区指令为空、指令未生成可执行军令、军令被驳回、部署层缺防区和结束阶段失败等诊断写成明末军机口径；`WarCommandExecutor` 的战区军令驳回、州府控制权变化、单格动态方面推进和接敌线变化塘报也改为中文，并使用部队/州府/方面名称而不是裸英文命令包装。该增量只影响 `AgentDecisionRecord.errors`、`WarDirectiveRecord.diagnostics` 和 `eventLog` 可读文案，不改变 `CommandValidationError.rawValue`、`Command.displayName`、Codable schema、AI JSON、`ZoneDirective` 生成、命令校验、执行结果、hex/region/theater/front/deploy 权威或规则链。

> v4.6 部队 UI 最新增量：`UnitInspectorView` 在“军令战备”之后新增只读“军械火力”区，复用 `Division.components`、`effectiveStats.range`、`hasFireSupport`、`isSiegeCapable`、兵力和粮草状态派生军械占比、火器/炮队/攻城比例、射程、火力姿态和断粮/缺粮对火器炮队的影响说明。该增量只帮助玩家在部队牌内理解火器、炮队、攻城器械与军事/科技线的关系，不新增 `Division` 字段，不改变 `ComponentType`、`CombatRules`、补给、命令、AI 或规则权威。

---

## 项目定位

一款 iOS / macOS 回合制 AI 策略战棋工程。现有可运行底座来自二战阿登原型，当前迁移目标是 `明末棋策 Agent`：保留 hex / region / dynamic theater / front / deployment / command pipeline 等成熟架构，逐步替换为明末多势力、天下局势、政策/经济/科技/军事经营、粮草军饷、朝廷/督师/将领 Agent 和发布级舆图 UI。

**核心参考：**
- 《统一指挥2》：六角格战棋、补给、攻击（战术层参照）
- 《钢铁雄心4》：大战略、省份占领、前线、补给、生产、国家管理（战略层参照）
- EasyTech《钢铁命令》：战役推进、将领、战术操作
- 《世界征服者4》：移动端轻量化策略体验

**核心创新：本地部署 LLM 驱动游戏 AI**
- 将领、元帅已进入当前指挥链；国家统治者、部长只作为后续方向预留
- agent 根据视野、战况摘要、性格和历史背景输出结构化 JSON 命令
- 游戏规则系统负责校验并执行，LLM 不直接绕过规则修改状态

---

## 地图 / 战区架构（核心决策）

**分层叠加，不是替换。** 六角格保留作战术/战斗层，省份与战区负责战略聚合。

```
Hex（战术层 / 真实占领与移动）
  ↓ hexToRegion
Region（省份规则层 / 资源、人力、补给、胜利点聚合）
  ↓ regionToTheater（初始战区基本单位，只读基准）
Initial Theater Layout（地图编辑器初始划分 / 只读 snapshot）
  ↓ hexToTheater
Dynamic Theater State（运行时动态战区 / 随 hex 推进变化）
  ↓ 动态 hex 邻接
FrontLine / FrontSegment（前线与分段，按动态战区接触生成）
  ↓
WarDeploymentState（FRONT / DEPTH / GARRISON 部署池）
  ↓
ZoneDirective / WarCommandExecutor / RuleEngine
```

**为什么分层：**
- 全球地图纯 hex ≈ 16 万节点，iOS 跑不动（尤其带 LLM agent）
- HOI4 证明：省是规则原子，全球 ~1-2 万省可实时跑
- 战术级 hex（UC2 风格）提供精细操作，战略级省提供全球性能
- **同一局内可切换**：大战略模式看省，zoom 进某省切 hex 板战术微操
- **v0.358 之后的关键语义**：
  - `regionToTheater` = 初始战区基本单位，服务地图编辑器、动态战区生成/合并/消亡的参照，不是运行时推进层。
  - `hexToTheater` = 运行时动态战区权威映射。单位占领一个 hex，只推进这个 hex 的动态战区归属，不能把整个 region 拉走。
  - 前线 = 我方动态战区与敌方动态战区的 hex 邻接接触，按 region 形成 `FrontSegment`。

**v0.2 以来的长期原则**：省份作为战略层叠加，**不替换** hex 坐标系。现有 hex 规则全保留，省作为聚合视图 + 省级规则并行运行。

---

## 技术栈

| 层级 | 技术 |
|------|------|
| 平台 | iOS；v1.1 新增 macOS 主游戏 target `WWIIHexV0Mac` |
| 语言 | Swift |
| UI 框架 | SwiftUI（面板、按钮、日志、单位详情） |
| 地图渲染 | SpriteKit（六角格地图、单位显示、移动/攻击反馈） |
| AI 接口 | `DecisionProvider` 协议（MockAI 已实现，预留本地 LLM） |

---

## 协作与云端验证

当前默认协作流使用 `main` 作为唯一上传、提交、推送和云端验证分支。Agent B 在本机只跑 `md/test/test.md` 允许的轻量检查，提交后直接 push 到 `origin/main` 触发 GitHub Actions；Agent C 使用 GitHub CLI 下载未加密 CI 结果包，核对 manifest、JUnit、构建日志和失败摘要后再验收。角色召唤、身份标识、main 直推规则和结果包复判细节以 `AGENTS.md`、`md/test/test.md`、`md/flow/flow.md` 与 `md/prompt/README.md` 为准。

---

## 项目架构

```
WWIIHexV0/
├── Core/          — 核心数据模型（Division、GameState、HexTile、HexCoord、MapState 等）
├── Commands/      — 命令系统（Command、CommandResult、CommandValidation、GameCommandHandling）
├── Rules/         — 规则引擎（RuleEngine、CombatRules、SupplyRules、MovementRules、VictoryRules、CommandExecutor、CommandValidator）
├── Agents/        — AI Agent 管线（旧 Agent D + ZoneCommanderAgent / MarshalAgent）
├── Turn/          — 回合管理器（TurnManager，德军 AI 回合编排）
├── SpriteKit/     — 地图渲染（BoardScene、UnitNode、HexNode、HexLayout、TerrainStyle、BoardSceneAdapter）
├── UI/            — 界面组件（UnitInspectorView、EventLogView、HUDView、CommandPanelView、AgentPanelView、RootGameView）
├── App/           — 入口（AppContainer、WWIIHexV0App、WWIIHexV0MacApp）
├── Data/          — 场景数据（DataLoader、ScenarioDefinition JSON、general_agents.json、generals.json、unit_templates.json、terrain_rules.json）
├── Probes/        — 历史高速探针测试 target（默认不执行）
└── Tests/         — 历史单元测试 / 集成测试 / 真实战局模拟（默认不执行）
```

### 明末默认数据首片

- 默认新局优先读取 `WWIIHexV0/Data/chongzhen_1642_scenario.json` 与 `WWIIHexV0/Data/chongzhen_1642_regions.json`。
- 剧本名为 `崇祯十五年：天下裂变`，当前规模为 120 个 hex、30 个 region、69 条 region edge、9 个补给源、12 个 objective、22 个初始单位。
- 初始势力为明廷、后金/清、大顺、大西、地方中立；玩家默认明廷，清 / 大顺 / 大西为 AI。
- 若明末 JSON 加载失败，仍保留阿登 legacy fallback，方便兼容旧数据和旧调试路径。
- 当前明末初始单位使用 `ming_banner_cavalry`、`qing_banner_cavalry`、`qing_artillery_train`、`dashun_camp`、`daxi_raiders`、`local_tuanlian` 等明末 template；legacy 阿登 template 仍保留作 fallback。
- v4.3 已加入明末兵种组件和攻城/火器首步修正。
- v4.4 首片已把经济资源展示迁为民力、银两、粮草，生产项展示为募营兵、募精骑、募哨骑、造炮队、筹粮；底层 `EconomyResources.manpower/industry/supplies` 字段暂作兼容存储名。
- v4.4 第二片已让 `OccupationState.resistance/compliance` 以民变/行政掌控口径影响州府钱粮产出，并进入州府面板和 AI 钱粮摘要。
- v4.4 当前界面已把外交入口改为“天下”/“天下局势”，展示当前势力、名义主体、战事态势、主要对手、诸方势力、战和关系和朝议/军议。
- v4.5 首片新增 `CourtStrategySummary`，从钱粮、治理、前线、补给和火器/炮队状态派生政策、经济、科技、军事四线压力；Root 信息面板新增“朝廷”tab，AI 摘要和元帅摘要可看到朝议建议；v4.7 后朝廷摘要会把明末胜负线压力加权进主议/备议，元帅摘要 schemaVersion 已升到 9，并额外携带战役五线态势。
- v4.6 首片开始发布级 UI 收口：`MingDesignTokens` 统一明末面板色彩/圆角/间距；`CourtPanelView` 从 `RootGameView` 拆出并改为奏疏/印玺风格；军令、将领名帖、单位详情、单位浮窗、塘报战记、AI 决策、信息按钮和新局按钮继续中文化；`UnitNode` 不再绘制 NATO APP-6 兵牌，改为“城/旗/火/骑/步”和“守/退”中文军牌，当前进一步在地图军牌上只读显示“溃散/退中/被围/缺粮/已行”战备小签；地图空态标题改为“明末棋策舆图”。
- v4.6 朝报令条首片继续 polish 顶部 HUD：`HUDView` 从普通指标 grid 升级为朝报令条，读取 `FactionEconomyLedger` 和只读 `CourtStrategySummary` 展示当前势力、回合、胜负、民力、银两、粮草、入账、营造队列和政策/经济/科技/军事四线压力；结束回合和新局按钮仍使用原回调，不直接改规则状态。
- v4.6 府库牌首片继续 polish 钱粮界面：`EconomyPanelView` 从表格/按钮列表升级为府库牌，读取 `FactionEconomyLedger` 展示民力、银两、粮草库存、本回合入账、军粮维护、补员消耗、收支急报、净民力/银两/粮草、军饷民心只读态势、募兵筹粮和营造队列；当前生产行会只读提示“可开工 / 尚缺民力、银两、粮草 / 待本方 / 观战”，生产按钮仍只调用 `onQueueProduction -> AppContainer.queueProduction -> Command.queueProduction`，不直接改经济账本。
- v4.6 部队军情牌首片继续 polish 部队界面：`UnitInspectorView` 以军情牌展示选中部队，读取 `Division` 的兵力、补给、退守、行动、`effectiveStats` 和兵种组件，以及 `UnitInspectorStrategicState` 的州府、动态方面、防区、部署和前线归属；后续增强新增“军令战备”只读摘要，用现有 `Division.canAct`、粮草、兵力、退守、攻城/火器/机动定位派生可调/已行/断粮、粮道、战力和用兵提示；当前新增“军械火力”只读区，用现有火器、炮队和攻城器械组件比例、射程、粮草和兵力状态解释火力姿态；当前进一步通过 `MingMapLabelFormat` 把州府、方面、防区、前线和格位 id 转成明末可读名称，去掉“玩家/只读”等调试感文案；该片只影响 SwiftUI 展示，不改变战斗、补给、部署或命令规则。
- v4.6 舆图军牌浮签首片继续 polish 地图选中部队反馈：`UnitTooltipView` 使用明末军牌浮签展示势力旗号、兵力条、粮草/行动/退守状态、攻守行程察指标和兵种组件 chip，只读服务选中地图部队的快速扫读；当前把裸坐标改为“舆图格”、把“退中/退守N”改为“退守中/余 N 旬”；该片不改变 `Division`、战斗/补给/部署规则、`Command` 或 `WarCommandExecutor`，只强化地图与部队界面的中华世界局势代入感。
- v4.6 朝议总纲首片继续 polish 朝廷界面：`CourtPanelView` 在朝廷 header 后新增只读“朝议总纲”，读取 `CourtStrategySummary.displaySummary`、`recommendedFocus`、`secondaryFocuses` 和 `CourtProjectKind(focus:)`，把主议、推荐项目归属、备议与政策/经济/科技/军事四线压力整合成可扫读奏疏区；该片不改变 `CourtStrategySummary`、朝廷项目、资源校验、`Command` 或 `EconomyRules`。
- v4.6 军令牌首片继续 polish 军事指令界面：`CommandPanelView` 从简单按钮列表升级为军令牌，展示当前势力/阶段、选中军情、兵力、粮草、退守、行动、固守/退守/补给处置和最近军令回执；固守、准许退守、就地补给和结束回合仍只调用 `RootGameView` 注入的 `AppContainer` 回调，不直接改 `GameState`。
- v4.6 命令交互回执继续 polish 军令代入感：`AppContainer` 在提交 `Command` 前按当前 `GameState` 生成 UI-only 中文命令摘要，把移动、攻击、固守、退守许可、补给、募兵筹粮、朝廷项目和结束阶段转成军令口径；普通命令成功/失败、将令提交/诊断、目标定位、单位点选、AI 回合摘要和 fallback mock commander 名称都改为中文，`CommandValidationError` 在显示层转为中文驳回原因。当前进一步在 `AgentPanelView` 显示边界把 legacy `Command.displayName` 前缀映射为中文短令，并让 `RuleEngine` 成败回执使用中文军令文案；该片只影响可读展示，不改变 `Command.displayName`、命令校验、执行结果、记录 ID、`Command`、`CommandValidator`、`WarCommandExecutor`、`RuleEngine` 或任何规则权威。
- v4.6 将领面板首片继续 polish 督师/总兵界面：`GeneralCommandPanelView` 升级为将印军令，展示防区、压力、战态、主将履历、忠诚、军心、干预、麾下军伍、目标和军令计划；`GeneralProfileView` 升级为将领名帖，展示印信、统兵风格、履历奏记、君臣关系、将略和麾下军伍；固守/进取仍只调用原回调，不直接改规则状态。
- v4.6 军机复盘牌首片继续 polish AI 决策界面：`AgentPanelView` 从调试字段列表升级为军机复盘牌，展示最高意志、决策摘要、军机五线态势、战区指令、势力军略、命令回执、异常塘报和军机底稿；当前增强会通过共享 `MingMapLabelFormat` 把主事、来源、主上、重心、目标、指向等 id 只读转成明末可读名称，未知值仍回退可读化 id，并保留原始案卷供审计；它只读取 `AgentDecisionRecord`、`RulerDecisionRecord`、`WarDirectiveRecord`、`CampaignAISummary` 与 `ZoneCommanderDoctrine.profile(for:)`，不改变 AI、命令或规则执行链。
- v4.6 塘报战记首片继续 polish 事件日志界面：`EventLogView` 从简单战报列表升级为塘报战记，展示最近塘报数量、急务/战役/战事/粮草/州府/天下分类计数、最新分类、回合/势力/阶段和相关回执；当前增强会只读识别 `battle-task-`、`battle-cue-` 和 `objective-control-` 前缀，把本旬急务、战役提示和目标换手显示为中文回执。当前进一步把行军、战斗、固守、准退、补给、退守、合围消耗、回合推进、动态方面推进和剧本载入等默认塘报源头改为中文，并在写入时补足 combat / retreat / reinforce / supply / encircle / theaterChange 分类；该片只读取和写入既有 `GameLogEntry` 字段，不改变日志 schema、命令执行或规则权威。
- v4.6 州府牌首片继续 polish 州府界面：`RegionInspectorView` 从字段列表升级为州府牌，读取 `RegionInspectorState` 展示州府主值、政粮械兵四要点、城关粮坊、地方治理、钱粮城防、控制方旗号、原属章、方面/防区/目标、友敌军和当前格旗号；当前进一步把州府和当前格的方面/防区 raw id、裸坐标转成“关宁防线”“畿辅防区”“舆图格”等可读文案；该片只影响 SwiftUI 展示，不改变 hex 控制、region 聚合、经济结算、动态战区、前线或命令规则。
- v4.6 天下急势首片继续 polish 天下局势面板：顶部摘要从 `DiplomacyState` 和只读 `CourtStrategySummary` 派生当前势力、战局态势、主要对手、战意和政策/经济/科技/军事四线压力；诸方势力列表改为带势力旗号、主战标记、战意条和离散值，战和关系列表改为双方旗号、关系状态和张力条，阵营名义改为旗号与成员卡片；当前朝议/军议主事和重心、国家/阵营 fallback 也走共享明末 formatter，仍不改变外交规则或朝廷项目执行链。
- v4.6 第二片新增 `CourtProjectKind` 与 `Command.enactCourtProject(kind:)`，朝廷面板可按主议推荐执行征饷、赈济、招抚、农政、修城、团练、火器、红衣炮和粮台驿道项目；执行层统一走 `CommandValidator` 与 `EconomyRules`，轻量影响民力/银两/粮草、地方治理、城防/粮道、生产队列、火器/炮队补整和缺粮部队，其中招抚乡绅只改善己控地方州府的民变/行政，不直接改变控制归属；农政屯田只改善己控州府粮草和基础设施，不直接补现粮或新增科技树；整训团练作为政策/军事兼线项目，仍追加 1 回合地方守备队列，并轻量稳定最多 2 个己控不稳州府，不新增驻防状态或治安系统；红衣炮维护只校修受损攻城炮队或追加造炮队订单，不新增持久科技树；粮台驿道只补粮、恢复缺粮部队并改善己控粮道州府 infrastructure / supplyValue，不改变 hex 补给路径判定。第五片新增 `CourtProjectDomain`，把可行项目按政策、经济、科技、军事四线分组展示，并在项目按钮显示可批、尚缺、待本方或观战状态；后续片新增只读“朝议争点”，把安民与征饷、火器与团练、粮道与城防的压力差做成可扫读摘要，让玩家更快看出朝廷项目的取舍。
- v4.6 地图标识首片继续 polish 默认主地图：`BaseTerrain.displayName` 改为明末中文地形名，`HexNode` 为城池、关隘/堡寨和补给源增加“城 / 关 / 粮”舆图 badge，并把旧 `FORT` 与 `SUP A/G` 主地图标记改为“关隘”“粮台”；该变化只影响 SpriteKit 展示，不改补给、占领或战区规则。
- v4.6 粮道线路首片复用 `SupplyRules` 的 hex 级补给路径，在默认 hex 图层为玩家势力有有效补给线的军队绘制粮道虚线；路线位于战争迷雾下方、军牌下方，只作可视化，不新增粮道状态或改变补给判定。后续片新增 `showsSupplyRoutes` UI 状态、顶部“粮道”按钮和舆图图例，玩家可在 hex 图层切换粮道显示；`MapDisplayLayer.displayName` 已改为舆图、州府、初划、战局、前线、布防，顶部控件会提示当前图层的明末语义。
- v4.6 军令计划线首片继续 polish 地图可读性：`BoardScene.drawPlannedOperations` 只读 `PlayerCommandState.plannedOperations`，把当前回合玩家进取/固守计划画成朱砂进取箭头、青绿固守令牌和“进/守”小令牌；`RootGameView` 顶部舆图图例新增“军令计划 / 进取 / 固守”，不改变计划记录、战区指令或规则执行。
- v4.6 势力旗号首片继续 polish 地图和部队归属：`Faction.bannerGlyph` 为明廷、后金/清、大顺、大西和地方中立提供“明/清/顺/西/乡”短旗号，`UnitNode` 在地图军牌顶端显示势力旗，并在军牌内按既有兵力、退守、粮草、退却和行动状态只读显示异常战备小签，帮助玩家不点开面板也能扫读缺粮、被围、退中和已行动部队；`UnitInspectorView` 与 `CommandPanelView` 的军牌印面同步显示旗号，`RootGameView` 舆图图例新增“势力旗”。该片只影响 UI/SpriteKit 展示，不改变阵营、外交、单位状态、补给、命令或规则执行。
- v4.6 舆图天下急势首片继续 polish 地图第一视野：`RootGameView` 顶部舆图控件在明末剧本下复用 `BattleObjectiveSummary` 新增只读“天下急势”条，显示 objective points 领先方、急务/主线任务数，以及天下、政策、经济、科技、军事五线压力 chip，让玩家在看地图前先扫读中华世界局势和当前军政钱粮火器重点。该片只影响 SwiftUI 展示，不调用目标定位、不写塘报、不新增持久状态，不改变胜负、朝廷、AI、命令或规则执行。
- v4.7 目标定位首片补齐目标面板到舆图的交互：`BattleObjectivePanelView` 的目标城关 chip 会只读显示当前控制方旗号和要冲分，并可调用 `AppContainer.focusObjective(_:)`，只更新 `selectedHex`、`selectedRegionId`、`focusedObjectiveId` 和 UI 高亮，在紧凑信息面板切到州府牌；`BoardScene` 只读该状态与 `BattleObjectiveSummary` 绘制“标”令牌、脉冲圈、目标名、当前控制方和同胜负线城关连线，顶部舆图图例同步解释“目标定位 / 胜负线城关”；它不会提交 `Command`、不会改变 objective 控制权、hex 控制、胜负判定或任何规则权威。
- v4.7 目标换手塘报首片补齐关键城关变化反馈：明末剧本中单位通过合法移动占领 objective hex 后，`CommandExecutor` 按占领前后的 `HexTile.controller` 追加 `regionOwnerChange` 类塘报，记录原控制方、新控制方和要冲分；该片只追加日志，不新增事件效果，不改变胜负判定、占领规则或目标摘要来源。
- v4.7 AI doctrine 首片让 `TheaterCommanderPool`、`AppContainer` 空将领 registry fallback、显式 `.zoneDirective`、`MockAICommander` 和 `SimulatedMarshalLLMClient` 共用明末势力 doctrine：明廷默认谨慎，清/大顺/大西默认进取，地方中立默认谨慎自保；同态进攻下清方、大顺、大西会分别偏向突骑破阵/合围、破围和流动作战，元帅 JSON 上游也能输出同样的势力战术差异；`AgentPanelView` 现在会在军机复盘牌中只读展示该势力军略、风格、技能标签和战术偏向。这只改变 `ZoneCommanderAgentConfig.commandStyle`、`skills`、战术分类边界、tactic 偏置和 UI 解释，不改变执行权威。
- 明末生产完成后会生成明末组件单位；legacy Germany / Allies 生产仍使用旧 `.infantry/.panzer/.motorized/.artillery` 工厂方法。
- 当前朝廷摘要仍是派生建议层；朝廷项目是一次性轻量执行入口，不是完整政策法令、科技树或统治者 Agent。灾荒、民心扩展、拖欠军饷影响士气/忠诚和多回合围城链仍属于后续 v4.5+。

### 核心架构原则

- **规则与 UI 解耦**：游戏状态只能由 `RuleEngine` 修改，UI 只读取状态
- **命令管线**：玩家 / AI → `Command` → `CommandValidator` 校验 → `CommandExecutor` 执行 → 日志
- **AI 接口可替换**：`DecisionProvider` 协议，MockAI 已实现，未来可插入本地 LLM
- **地图分层**：hex（战术层，`HexCoord`）+ region（省份层，`RegionId`）+ dynamic theater（运行时战区，`hexToTheater`），不替换
- **AI 命令与玩家命令共用同一管线**：都经 `RuleEngine` 校验执行

---

## AI / 指令管线接口（已落地）

当前同时保留两条管线：

- **Legacy Agent D 管线**：`AgentContextBuilder → DecisionProvider → AgentDecisionParser → AgentCommandMapper → RuleEngine`。已保留作回归参考，默认不再作为战争 AI 主路径。
- **ZoneDirective 管线（执行权威）**：`ZoneDirective → WarCommandExecutor → RuleEngine → WarDirectiveRecord`。`WarCommandExecutor.execute(_ directive:in:)` 不依赖具体 `ZoneCommanderAgent` 实例，手写合法 `ZoneDirective` 也可执行。
- **v0.5 元帅管线（默认上游）**：`MarshalAgent → MarshalBattlefieldSummarizer → SimulatedMarshalLLMClient → TheaterDirectiveDecoder → TheaterDirectiveCompiler → DirectiveEnvelope / ZoneDirective`。它只做战略意图、JSON I/O、解码校验和 fallback，不直接修改 `GameState`。
- **后续统治者层（未接入 v0.5 主链路）**：未来只能位于元帅上游，输出国家级姿态或约束条件；不得绕过 `ZoneDirective -> WarCommandExecutor -> RuleEngine`。

| 文件 | 职责 | 关键类型/协议 |
|------|------|--------------|
| `Agents/DecisionProvider.swift` | 统一 AI 接口 | `protocol DecisionProvider { func decide(context:) async throws -> AgentDecisionEnvelope }` |
| `Agents/GameAgent.swift` | 运行时 agent 模型 | `GameAgent`（精简版，无 Cabinet/DirectiveDomain，v0.5 污染已剔除；明末 fallback 角色/人格已用军机口径） |
| `Agents/AgentConfiguration.swift` | agent 加载 | `GameAgent.guderian(from:state:)`，优先 `general_agents.json`，失败 fallback |
| `Agents/AgentContexts.swift` | agent 能看到的摘要 | `AgentContext` + `AgentContextBuilder`（无 organization，适配 v0.1） |
| `Agents/AgentDecision.swift` | 结构化决策 DTO | `AgentDecisionEnvelope` / `AgentOrder` / `AgentOrderType`（move/attack/hold/resupply） |
| `Agents/AgentDecisionParser.swift` | JSON → envelope | 校验 schemaVersion / agentId / turn，malformed 抛 typed error |
| `Agents/AgentCommandMapper.swift` | order → Command | `AgentCommandMapper.map(_:agentId:) -> IssuedCommand`，缺字段抛 error |
| `Agents/AgentDecisionRecord.swift` | 决策记录 | `AgentDecisionRecord` / `CommandResultSummary`（UI 读） |
| `Agents/MockAIClient.swift` | Legacy Agent D fallback provider | 启发式：resupply → attack → objective-oriented move → hold；明末势力生成中文军令 intent/reason，legacy 德/盟保留 Bastogne 回归文案；默认战争 AI 主路径不回退到旧 Agent D |
| `Agents/LLMClient.swift` | Legacy LLM 接口预留 | `protocol LLMClient` + `LLMRequest`（旧 Agent D 用，默认不启用） |
| `Agents/LocalLLMDecisionProvider.swift` | 本地 LLM provider | 注入 `LLMClient` + `AgentPromptBuilder` + parser，失败由上层 fallback MockAI |
| `Agents/AgentPromptBuilder.swift` | prompt 构造 | system + user prompt，明末势力提示词强调中华世界局势、粮草、城关、州府、火器和五线压力，同时强制保留 JSON schema |
| `Turn/TurnManager.swift` | legacy 方法名下的 AI 回合编排 | `runGermanAITurn(state:) async -> AgentTurnOutcome` 仍保留兼容名，实际调用方按当前 active faction 构造 commander pool 并推进 endTurn |
| `App/AppContainer.swift` | AI 接线 | `runAIIfNeeded()` 读取 `activeFaction`、`phase`、`aiControlledFactions` / `humanControlledFactions`，为当前 AI 势力触发 Task 并写 state/record |
| `UI/AgentPanelView.swift` | 军机复盘 | 读 `AgentDecisionRecord`、`RulerDecisionRecord`、`WarDirectiveRecord`、`CampaignAISummary` 与 `ZoneCommanderDoctrine`，展示最高意志、军机五线、势力军略、战区指令、命令回执、异常和军机底稿；id 仅在 UI 层转成明末可读名称 |
| `UI/RootGameView.swift` | 玩家入口 | 结束回合按钮走 `advanceOrRunAI()`；当前开局不自动 `.task` 跑 AI |

**Legacy MockAI 行为（guderian，装甲突破风格）：**
跳过已行动单位 → 低补给/包围优先 resupply → 射程内低 hp 敌军优先 attack（炮兵优先打城市/要塞）→ 向当前 objective 推进 → 否则 hold。明末默认 AI 主路径仍以 `MarshalAgent / ZoneDirective / WarCommandExecutor` 为收口，旧 Agent D 只作兼容和回归参考。

**v0.7 ZoneDirective 战术行为：**
`ZoneCommanderAgent` 读取所属 `FrontZone` 的前线/部署摘要，`BinaryTacticClassifier` 会结合兵力比、机动兵力、炮兵支援、纵深预备队、压力和补给警告，在 `standardAttack`、`blitzkrieg`、`spearhead`、`breakthrough`、`pincerMovement`、`fireCoverage`、`feint`、`guerrillaWarfare`、`holdPosition`、`elasticDefense`、`defenseInDepth`、`lastStand` 之间分类；`WarCommandExecutor` 将这些战术降级为 `move / attack / hold / allowRetreat`，仍统一交给 `RuleEngine` 校验执行。`WarDirectiveRecord` 记录 `category` / `tactic` / `commanderAgentId` / `commandTarget`，便于后续接真 LLM 回放与审计。

**v0.5 MarshalDirective 行为：**
`MarshalBattlefieldSummarizer` 把 `GameState` 降维为元帅摘要，只包含 front zone、strength ratio、补给警告、目标和事件，不把全量 hex 网格喂给模型。`SimulatedMarshalLLMClient` 生成 fenced JSON 形式的 `TheaterDirectiveEnvelope`；`TheaterDirectiveDecoder` 提取并校验 JSON；`TheaterDirectiveCompiler` 把元帅意图编译成现有 `ZoneDirective`。v0.7 后 `TheaterDirective` 可携带 `convergenceRegionId` / `coordinatedZoneIds` 支持钳形会师意图；解码或编译失败时 fallback 到 `TheaterCommanderPool`，不执行半成品 LLM 输出。

**后续 Ruler / Diplomacy 边界：**
统治者层不在 v0.5 当前主链路中。多势力、外交关系、朝廷摘要和轻量朝廷项目已进入兼容层；后续如要扩展多回合政策、科技、招抚或统治者 agent，必须先设计独立 schema，并保持底层战争规则仍由当前 active faction、`DiplomacyState`、`Command` / `ZoneDirective`、`WarCommandExecutor` 和 `RuleEngine` 收口。

---

## 当前完成进度

### ✅ v0：六角格测试板（已完成）

**场景**：阿登测试战场（Ardennes），德军 vs 盟军，11×9 六角格地图

| 功能模块 | 状态 |
|----------|------|
| 六角格 axial 坐标系统 | ✅ |
| 地形系统（平原/森林/山地/城市/道路/河流/要塞） | ✅ |
| 移动系统（地形消耗、道路加成、跨河惩罚、敌方阻挡） | ✅ |
| 战斗系统（近战/炮兵远程、地形防御修正、反击） | ✅ |
| 侧翼/背后加成 | ✅ |
| 占领系统（城市控制权变更） | ✅ |
| 补给系统（supplied / lowSupply / encircled） | ✅ |
| 包围判定与惩罚 | ✅ |
| 回合系统（德军 AI 先手 → 盟军玩家 → 结算） | ✅ |
| MockAI 将领 agent（guderian，装甲突破风格） | ✅ |
| 结构化 JSON 命令解析与校验 | ✅ |
| AI 决策日志面板（AgentPanelView 读 AgentDecisionRecord） | ✅ |
| 胜利条件（巴斯托涅占领 / 消灭 3 单位 / 切断补给） | ✅ |

---

### ✅ v0.1：strength、撤退与补员（已完成）

| 功能模块 | 状态 |
|----------|------|
| `Division` 升级为 strength/maxStrength，保留 hp/maxHP 兼容 | ✅ |
| 战斗改为 strength 伤害（organization 已移除） | ✅ |
| 撤退状态：自动寻找安全相邻格撤退 | ✅ |
| 撤退失败施加额外惩罚 | ✅ |
| `resupply/rest` 恢复 strength | ✅ |
| 包围每回合扣 strength | ✅ |
| UI 显示 Strength、Retreating 状态 | ✅ |
| 日志按 combat/retreat/reinforce/encircle/supply 分类 | ✅ |
| 死守 / 允许撤退（RetreatMode）按钮与 HOLD 防御加成 | ✅ |

**v0.1 最终模型：** 只看兵力，无 organization。`RetreatMode`（retreatable/hold）控制撤退：HOLD 防御 +20%，RETREATABLE 单次损失比例 ≥ 35% 自动撤退。

---

### ✅ Agent D：AI/Agent 决策管线（已完成）

| 功能模块 | 状态 |
|----------|------|
| `DecisionProvider` 协议（MockAI + LocalLLM 共用） | ✅ |
| `AgentContext` / `AgentContextBuilder`（Codable 摘要，无 UI/SpriteKit 对象） | ✅ |
| `AgentDecisionEnvelope` / `AgentOrder` JSON schema | ✅ |
| `AgentDecisionParser`（校验 schema/agent/turn） | ✅ |
| `AgentCommandMapper`（order → Command，缺字段抛 error） | ✅ |
| `MockAIClient`（legacy 启发式；明末势力按当前要冲和五线任务生成中文军令理由，德/盟保留 Bastogne 回归） | ✅ |
| `LLMClient` / `LocalLLMDecisionProvider` / `AgentPromptBuilder`（预留，v0 默认关；明末 prompt 已切到军机语境） | ✅ |
| `TurnManager`（德军 AI 回合编排，含 endTurn） | ✅ |
| `AppContainer.runAIIfNeeded()`（启动自动跑 AI 回合） | ✅ |
| `AgentDecisionRecord` + `AgentPanelView`（UI 读决策记录） | ✅ |
| `AgentPipelineTests`（8 测试：context/MockAI/parser/mapper/provider 失败/非法命令） | ✅ |

---

### ✅ v0.2 Agent 1：省份图架构（已完成）

省份图规则层模型。**叠加，不替换 hex。** hex 仍战术层权威坐标，province 是战略层聚合。

| 文件 | 职责 |
|------|------|
| `Core/Region.swift` | `RegionId`（RawRepresentable<String>）、`RegionNode`、`RegionEdge`、`RegionGraph`、`CityInfo`、`ResourceAmount`、`ResourceType`、`OccupationState`、`RegionEdgeKey`（对称键）、`RegionValidationError`（9 case） |
| `Core/MapState.swift`（改） | 加 `regions`/`hexToRegion`/`regionEdges` 字段（默认空）；加 province 查询：`region(for:)`/`region(id:)`/`neighbors(of:)`/`areAdjacent`/`edgeBetween`/`representativeHex`/`regionDistance`/`regionGraph`；加 `validateRegionGraph()` |
| `Core/Terrain.swift`（改） | `HexTile` 加 `regionId: RegionId?`（默认 nil） |
| `RegionGraph.validate()` | idMismatch/emptyDisplayHexes/representativeHexNotInDisplayHexes/neighborNotFound/neighborNotBidirectional/edgeEndpointNotFound/edgeNotInNeighbors |
| `MapState.validateRegionGraph()` | 复用上图校验 + hexToRegionPointsToMissingRegion + displayHexesOverlap |
| `Tests/RegionGraphTests.swift` | 19 测试：编解码/neighbors/areAdjacent/hexToRegion/representativeHex/validate 全错误类型+valid+empty |

**设计约束（Agent 1 已守）：**
- hex 规则全保留，province 默认空不破现有行为
- `MapState.ardennesV0()` 不改（保持纯 hex，测试用）
- 省份挂载在 Data 层（DataLoader），Core 不依赖 Data

---

### ✅ v0.2 Agent 2：省份数据层（已完成）

阿登 v0.2 省份图数据 + 加载。17 省覆盖全部 99 hex，零重叠，邻接双向一致。

| 文件 | 职责 |
|------|------|
| `Data/ardennes_v02_regions.json` | 17 省/41 边/99 hex 映射/2 补给源/4 目标。schemaVersion 2 |
| `Data/RegionDataSet.swift` | `RegionDataSet` + Codable 定义（`RegionNodeDefinition`/`CityInfoDefinition`/`ResourceAmountDefinition`/`OccupationStateDefinition`/`RegionEdgeDefinition`/`RegionSupplySourceDefinition`/`RegionObjectiveDefinition`）+ 映射 `toRegions()`/`toRegionEdges()`/`toHexToRegion()` |
| `Data/DataLoader.swift`（改） | 加 `loadArdennesV02Regions()` + `validate(_ regionData:)`（复用 validateRegionGraph）；`loadInitialGameState()` 叠加省份数据（try? 失败 fallback 纯 hex）+ 反向填 HexTile.regionId |

**省份设计：**
- 德方控制：german_east_depot（补给源）、eifel_approach、schnee_eifel
- 盟方控制：allied_west_depot（补给源）、bastogne（主目标 VP5）、bastogne_fortress、st_vith、western_approach
- 中立（原 allies 领土中立化，owner/controller null 映射回退 .allies）：meuse_approach、houffalize、luxembourg_road、ardennes_forest_north/central/south、northern_ridge、southern_ridge、northern_frontier
- 路径：german_east_depot→bastogne=2，allied_west_depot→bastogne=3

| `Tests/ArdennesV02DataTests.swift` | 17 测试：解码/region 数/hexToRegion 覆盖/validate/邻接双向/repHex/路径连通/补给源/目标/关键省/控制权 |

---

### ✅ v0.3：战区、前线、部署、战争指令（当前主线，已推进至 v0.37）

| 版本 | 主题 | 关键内容 |
|------|------|----------|
| **v0.31** | Theater 战区层 | 四战区初始化、控制比例、70% 阈值、扩张/退役接口 |
| **v0.32** | FrontLine 前线层 | 动态前线、segment、dirty 更新、简化包围识别 |
| **v0.33** | WarDeployment 部署层 | FRONT / DEPTH / GARRISON 分层，FrontZone 单元池 |
| **v0.34** | 地图编辑器 | 默认地图与项目 schema 打通 |
| **v0.351** | 初级战争指令 | `ZoneDirective` / `WarCommandExecutor` / `MockAICommander` |
| **v0.352** | 新管线唯一化 | `WarPipelineMode.zoneDirective` 默认，观察者模式，分层战略 UI |
| **v0.353** | 默认地图验收 | hex controller 成为归属权威，补给归属跟随占领者 |
| **v0.354** | 联动修复 | 占领→region→theater→frontline 同回合联动，ZOC 友军穿越修正，拒绝率治理 |
| **v0.355** | 动态/初始战区分离 | `initialSnapshot` 与运行时动态战区分离，前线 overlay 与观察者 UI |
| **v0.356-v0.357** | 地图/前线 UI 修正 | 编辑器与游戏视角统一、开局单位越界检查、前线按战区/segment 着色 |
| **v0.358** | hex 动态战区语义收口 | 动态战区改跟 `hexToTheater`，region 基础战区只作初始/生成参照；AI/部署/前线测试同步更新 |
| **v0.36** | 命令层扩展与多将领 MockAI | `CommandCategory` / `TacticName` / `DirectiveTarget` / `ZoneCommanderAgent` / `TheaterCommanderPool` |
| **v0.37** | 命令层统一整合 | 移除 `TurnManager` 的 `MockAICommander` fallback，默认路径收口到 `TheaterCommanderPool`；补 issuer-agnostic executor 探针 |
| **v0.5** | 元帅层与模拟 LLM JSON | `MarshalAgent` / `TheaterDirectiveEnvelope` / decoder / compiler / marshal fallback |
| **v0.7** | 高级战术与命令扩展 | 闪电战、定点矛头、突破、钳形攻势、火力覆盖、佯攻、游击战、弹性防御、纵深防御、死守 |

### ⏳ 后续方向

| 版本 | 主题 | 关键内容 |
|------|------|----------|
| **v0.4** | 聊天命令与角色服从 | 玩家通过聊天框命令将领；将领根据性格/忠诚回应；命令可被质疑/拖延/抗命 |
| **v0.5** | 元帅决策链与模拟 LLM JSON | `MarshalAgent`、`TheaterDirectiveEnvelope`、JSON decoder、compiler、fallback；统治者只预留为后续上游，不恢复 Cabinet/Minister |
| **v1.0** | 大战略原型 | 经济/科技/生产；空军实体化；简化海军；天气；多国家多战区；全球地图；美术资源 |
| **v1.x** | 多回合战术行动 | 撤退命令、突破/闪电战、装甲差异化、`AttackIntensity` 深度分流等复杂多回合行动骨架 |

**v0.37 决策记录：** 撤退、突破、闪电战、装甲差异化和 `AttackIntensity` 深度分流推迟至 1.x。v1.0 只先把 `infiltration` 解释为默认低投入上限，不引入额外伤害、绕规则推进或多回合追踪行动。

---

## 核心设计约束

**LLM 使用原则（必须始终遵守）：**
1. 不让每个单位每回合都调用 LLM
2. LLM 只读取摘要，不读取完整地图
3. LLM 输出必须经过 `CommandValidator` 校验才能执行
4. 非法命令先尝试自动修复，修复失败则丢弃并记录日志
5. 没有 LLM 时，MockAI 接管所有决策

**架构扩展约束（后续 agent 必须遵守）：**
- 不要跳过命令管线直接修改 `GameState`
- **不要替换 HexCoord 坐标系**：hex 是战术层，province 是叠加的战略层，两者共存
- **不要把 `regionToTheater` 当动态战区推进层**：运行时战区归属看 `hexToTheater`，突破只推进 hex。
- **不要给 Division 加回 organization**：v0.1 已移除，只看兵力
- **不要引入 v0.5 Cabinet/StrategicDirective/Minister 污染**：v0.5 误删事件已发生，GameAgent 保持精简版
- 新增系统通过 `DecisionProvider` / `RuleEngine` / `Command` 接入，不直接改核心规则
- 保持核心语义不退步；默认只做轻量检查，Xcode / XCTest / 模拟器等重测试必须由人工明确授权。

---

## 文档索引

```
md/
├── plan/
│   └── plan.md
│       当前项目 md 大纲；已切换为明末迁移路线入口。
├── flow/
│   ├── flow.md
│   │   当前真实运行链路，仍以源码现状为准。
│   ├── flowchart.md
│   │   Mermaid 核心流程图总览。
│   └── 01_*.mermaid / 02_*.mermaid / 03_*.mermaid / 04_*.mermaid
│       独立流程图片段。
├── test/
│   └── test.md
│       本机轻量检查、云端验证、禁止项和交付写法。
└── prompt/
    ├── README.md
    │   Agent A/B/C 提示词工作流和路线索引。
    ├── v4.0-明末迁移/
    │   ├── codex-v4.0-明末aiagent迁移总提示词.md
    │   ├── v4.0_audit_and_contract.md
    │   ├── v4.1_powers_turns_prompt.md
    │   ├── v4.2_ming_scenario_data_record.md
    │   └── v4.3_ming_units_tactics_record.md
    │       明末迁移总合同、阶段提示词和阶段实现记录。
    ├── v0.*（已完成）/
    │   WWIIHexV0 历史实现资料。
    ├── v2.0-三国迁移/、v3.0-拿战迁移/、v5.0-唐宋迁移/、v6.0-现代战争迁移/
    │   其他题材迁移参考，不是当前明末主线。
    └── old/、anti生成/、claude生成/
        历史资料、打捞记录和反例归档。
```

> 明末迁移是当前文档大纲的目标方向，但源码事实仍以 `md/flow/flow.md` 和当前代码为准；不要把目标文案当成已完成实现。

---

## 给后续 Claude Code 的提示

**你接手时的代码库状态：**
- v0.5 分支已引入元帅层与模拟 LLM JSON/decoder/ compiler；历史测试基线曾达到 v0.37 Probe 18/0、Stage Regression 69/0、Full 226/0。当前默认不跑重测试，只做 `md/test/test.md` 允许的轻量检查。
- 战斗模型：兵力伤害为主，`RetreatMode`（retreatable/hold）控制撤退，无 organization。
- 默认战争 AI 管线：`MarshalAgent` 读取摘要并模拟输出 `TheaterDirectiveEnvelope` JSON，经 `TheaterDirectiveDecoder` 与 `TheaterDirectiveCompiler` 降级成 `ZoneDirective`，再走 `WarCommandExecutor`。`TheaterCommanderPool` / `ZoneCommanderAgent` 仍作为 fallback 和显式 `.zoneDirective` 路径。
- Legacy Agent D 管线保留但默认不调用。
- 地图坐标系：hex 仍是战术权威；Region 是省份规则层；动态战区看 `hexToTheater`。

**继续开发前请先阅读：**
1. 本 README（地图架构三层决策 + Agent D 接口表）
2. `WWIIHexV0/Core/Division.swift`（当前 Division 模型）
3. `WWIIHexV0/Core/MapState.swift` / `Region.swift` / `Theater.swift`
4. `WWIIHexV0/Rules/TheaterSystem.swift` / `FrontLineManager.swift` / `WarDeploymentManager.swift`
5. `WWIIHexV0/Commands/WarDirective.swift` / `WarCommandExecutor.swift`
6. `WWIIHexV0/Agents/ZoneCommanderAgent.swift` / `MockAICommander.swift`
7. `md/prompt/anti生成/v0.5/anti/0.50_v0.5_marshal_implementation_record.md`

**当前必须遵守：**
- 不删 `HexCoord`，不把运行时战区推进退回 region 粒度。
- `Initial Theater Layout` / `regionToTheater` 是地图编辑器与动态演化基准，不是实时前线。
- `Dynamic Theater State` / `hexToTheater` 是游戏战区层权威。
- 前线 UI 和 AI target 选择必须基于动态 hex 邻接；历史测试 fixture / 语义文档也必须构造真实相邻 hex，不能只声明 region 邻接。
- `ZoneDirective` 新字段必须保持 Codable 向后兼容。
- 元帅层和未来统治者层不得绕过 `ZoneDirective -> WarCommandExecutor -> RuleEngine`。
- 当前 v0.5 只模拟 LLM JSON 接口，不接真实模型；真实 LLM 接入必须保留 decoder 校验与 fallback。

**轻量检查**（每轮先读 [`md/test/test.md`](md/test/test.md)，默认禁止 Xcode / XCTest / 模拟器 / 性能类测试）：
```bash
rg -n "[[:blank:]]+$" AGENTS.md README.md update_log.md md/test/test.md md/flow/flow.md
```
旧测试口径残留、JSON / project / scheme 检查按 `md/test/test.md` 追加执行。未获人工授权时，不跑历史 Probe / Stage / Full。
