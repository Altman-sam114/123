# Prompt 工作流说明

本目录保存各阶段 Agent A 写给 Agent B 的实现提示词、迁移路线和验收记录。当前默认协作制度已经升级为 `main` 直推 + GitHub Actions 云端验证 + Agent C 下载结果包复判。

## 1. 当前路线索引

- 当前明末迁移主入口：`md/plan/plan.md`。该大纲已把“中华世界局势与代入感”“政策/经济/科技/军事四线并重”“地图、部队、朝廷和核心面板美观可用”列为后续每轮明末任务的目标和验收硬约束；Agent A 写提示词时必须引用并落实这些约束。
- 明末迁移总提示词：`md/prompt/v4.0-明末迁移/codex-v4.0-明末aiagent迁移总提示词.md`。
- v4.0 审计与合同阶段文档：`md/prompt/v4.0-明末迁移/v4.0_audit_and_contract.md`。
- v4.1 多势力实现提示词：`md/prompt/v4.0-明末迁移/v4.1_powers_turns_prompt.md`；当前工作树已开始按该提示词落地兼容层。
- v4.2 明末默认数据记录：`md/prompt/v4.0-明末迁移/v4.2_ming_scenario_data_record.md`；当前默认新局优先读取 `崇祯十五年：天下裂变` 明末 JSON，失败才回退阿登，兵种模板、经济和发布级 UI 仍未完成。
- v4.3 明末军队与战术首步记录：`md/prompt/v4.0-明末迁移/v4.3_ming_units_tactics_record.md`；首批明末 unit template、默认单位 templateId、战术展示名、攻城/火器首步修正和 MapEditor 默认单位口径已开始落地。
- v4.4 明末钱粮、地方治理与天下局势记录：`md/prompt/v4.0-明末迁移/v4.4_ming_economy_governance_record.md`；当前已落地民力/银两/粮草显示、募兵/筹粮生产口径、明末生产单位组件、民变/行政掌控收入修正、天下局势面板和 AI 钱粮/治理摘要，政策/科技、灾荒、完整军饷士气链仍后置。
- v4.5 明末朝廷、政策科技与四线摘要记录：`md/prompt/v4.0-明末迁移/v4.5_ming_court_policy_record.md`；当前已落地只读 `CourtStrategySummary`、朝廷 tab、AgentContext 和 MarshalBattlefieldSummary 朝议摘要，政策/科技 directive 和执行器仍后置。
- v4.6 明末 UI polish 与朝廷项目记录：`md/prompt/v4.0-明末迁移/v4.6_ming_ui_polish_record.md`；当前已落地明末设计 token、独立朝廷面板、军令/将领名帖/塘报战记/AI 中文 polish、单位中文军牌、明末舆图空态、城/关/粮地图 badge、田/林/山/丘/城/关地貌底纹、粮道虚线可视化，以及征饷、赈济、招抚、农政、修城、团练、火器、红衣炮、粮台驿道九类 `Command.enactCourtProject` 轻量执行入口；粮台驿道会补粮、恢复缺粮部队并整修己控粮道州府基础，但不改变 hex 补给路径判定；粮道可通过顶部“粮道”按钮和图例控制显示，图层名已中文化为舆图、州府、初划、战局、前线、布防，顶部舆图控件已新增只读“天下急势”条，显示领先方、急务/主线任务数和天下/政策/经济/科技/军事五线压力，顶部舆图图例解释城/关/粮、步/骑/火/城/旗兵种军牌、粮草与堆叠、势力旗、军令计划和粮道符号；地图上当前回合玩家进取/固守计划已显示为“进/守”令牌和计划箭头，地图军牌、部队详情、部队浮签和军令面板已用“明/清/顺/西/乡”等势力旗号标识归属，地图军牌新增旗色侧条、兵种印面、兵力小签底板和只读战备小签，可显示溃散、退中、被围、缺粮或已行；顶部 HUD 已升级为明末朝报令条，展示当前势力、回合、胜负、民力/银两/粮草、入账、营造队列和朝议四线压力；军令面板已升级为明末军令牌，展示当前势力/阶段、选中军情、势力旗号、兵力、粮草、退守、行动、固守/退守/补给处置和军令回执；将领面板已升级为明末将印军令和将领名帖，展示防区态势、主将履历、忠诚、军心、麾下军伍和军令计划；AI 面板已升级为明末军机复盘牌，展示最高意志、决策摘要、军机五线态势、势力军略、战区指令、命令回执、异常塘报和军机底稿，并把主事、来源、主上、重心、目标和指向等 id 只读转成明末可读名称，未知值保留原 id 以便审计；事件日志已升级为明末塘报战记，展示最近塘报、急务/战役/战事/粮草/州府/天下计数、分类图标和中文回执，并只读识别本旬任务、战役提示和目标换手 relatedRecordId；钱粮面板已升级为明末府库牌，展示民力/银两/粮草库存、入账、维护、补员、收支急报、净民力/银两/粮草、募兵筹粮和营造队列；部队详情已升级为明末军情牌，展示军牌字、势力旗号、兵力、粮草、退守、军令战备、攻守行程察、兵种编成和驻防归属；`UnitTooltipView` 已升级为明末舆图军牌浮签，只读展示选中地图部队的势力旗号、兵力条、粮草/行动/退守状态、军位、方面、防区、部署、要冲牵引、本旬任务、目标落点、相距格数、攻守行程察指标和兵种组件 chip，不改 `Division`、规则或命令；州府详情已升级为明末州府牌，展示州府主值、州府四线牵引、政粮械兵四要点、城关粮坊、治理、钱粮城防、控制方旗号、原属章、战局归属、目标、友敌军和当前格旗号；朝廷项目已按政策、经济、科技、军事四线分组展示压力、关注点、成本收益、风险和“可批 / 尚缺民力、银两、粮草 / 待本方 / 观战”行动状态，交叉项目会出现在全部相关线组并标为兼线；朝廷面板已新增只读“朝议总纲”，把主议、备议、推荐项目归属和四线压力整合成奏疏式扫读区，并已新增安民与征饷、火器与团练、粮道与城防三组只读朝议争点，复用 `BattleObjectiveSummary.CampaignLineBrief` 展示只读“天下五线态势”；天下面板已新增“天下急势”、势力战意条、朝议四线压力摘要、诸方势力旗号、主战标记、阵营名义卡和战和张力条，强化中华世界局势扫读；明末迁移仍要求中华世界局势代入感与政策、经济、科技、军事，以及地图、部队、朝廷界面并重；真实美术资产、截图验收、完整响应式交互、多回合政策和科技树仍后置。
- v4.6 明末地名/防区可读化增量：`MingMapLabelFormat` 已从 `AgentPanelView` 私有 helper 抽成共享 UI formatter，供军机复盘、天下、部队军情牌、舆图军牌浮签和州府牌共用；州府、方面、防区、前线、国家、阵营、agent 和格位 id 只在 UI 层转成明末可读名称，不改变任何 Codable schema、`GameState`、外交/战区/部署权威或命令执行链。
- v4.6 舆图军牌军位增量：`RootGameView` 向 `UnitTooltipView` 注入现有 `selectedUnitInspectorStrategicState`，舆图军牌浮签新增只读“军位”区，展示动态方面、防区和前线/纵深/驻防部署角色。该增量只改 SwiftUI 展示，不新增状态，不改变 `UnitInspectorStrategicState`、`WarDeploymentState`、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何规则权威。
- v4.6/v4.7 舆图军牌要冲牵引增量：`RootGameView` 向 `UnitTooltipView` 注入 `BattleObjectiveSummary.from(state:)` 和 `MapState`，舆图军牌浮签新增只读“要冲牵引”区，展示当前最高优先级本旬任务、目标落点和选中部队到 objective 的 hex 距离。该增量只改 SwiftUI 展示，不新增任务状态，不自动定位目标，不写塘报，不提交命令，不改变 `BattleObjectiveSummary`、`MapState`、`VictoryRules`、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何规则权威。
- v4.6/v4.7 部队军情牌要冲牵引增量：`RootGameView` 向 `UnitInspectorView` 注入同一 `BattleObjectiveSummary.from(state:)` 和 `MapState`，部队详情牌新增只读“要冲牵引”区，展示当前最高优先级本旬任务、目标落点、现控制方、选中部队到 objective 的 hex 距离和本军兵势说明。该增量只改 SwiftUI 展示，不新增任务状态，不自动定位目标，不写塘报，不提交命令，不改变 `BattleObjectiveSummary`、`MapState`、`VictoryRules`、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何规则权威。
- v4.6 舆图判读图例增量：`RootGameView` 的非 hex 图层图例新增只读“舆图判读”芯片，分别提示州府层的政令/钱粮/民变、初划层的开局方面/督抚分防、战局层的动态推进/军机方面、前线层的真实接敌/守关截援、布防层的前军/纵深/驻守；hex 图层势力旗图例补齐明/清/顺/西/乡。该增量只改 SwiftUI 图例说明，不改变 `MapDisplayLayer` rawValue、overlay 计算、SpriteKit 绘制或任何规则权威。
- v4.6 天下牵引增量：`DiplomacyPanelView` 新增只读“天下牵引”区，从 `DiplomacyState`、当前 active faction 的 `CourtStrategySummary` 和最近 `RulerDecisionRecord.diplomacySummary` 派生战和格局、朝议牵引、政策/经济/科技/军事四线压力和御前奏报，帮助天下面板联读主要敌手、朝廷主议和军政钱粮火器重点。该增量不新增外交状态，不写塘报，不触发目标定位或朝廷项目，不改变命令、经济、胜负或规则权威。
- v4.6/v4.7 天下棋势增量：`RootGameView` 向 `DiplomacyPanelView` 注入 `BattleObjectiveSummary.from(state:)`，天下面板新增只读“天下棋势”区，读取 `scoreRows`、`lineBriefs`、`tasks` 和 `tracks.targets`，展示要冲分领先方、最急五线、本旬落点和各势力要冲分/控制数，让天下 tab 直接联读中华世界局势、政策/经济/科技/军事压力和胜负目标。该增量只改 SwiftUI 展示，不新增按钮，不定位目标，不写塘报，不提交命令，不改变外交、胜负、摘要、命令或规则权威。
- v4.6 军机/塘报 raw 显示中文化增量：`AgentPanelView` 继续只在展示边界把 `AgentDecisionRecord.errors`、`CommandResultSummary.errors` 中的 `CommandValidationError.rawValue` 转为 `mingDisplayText`，并把 `Mapping failed.`、`No AI faction was active.`、未知 provider 和未收录 doctrine skill 转成军机案卷口径；`EventLogView` 对非战役/急务/目标换手的 `relatedRecordId` 按前缀显示战区军令、军机回执、朱批回执或系统回执。该增量不改变 `AgentDecisionRecord`、`CommandResultSummary`、`GameLogEntry` schema，不改变命令映射、校验、塘报写入、AI 或规则权威。
- v4.6 军令牌舆图提示增量：`CommandPanelView` 在战术处置区新增只读“舆图军令”提示，按当前观战、选军、敌军、阶段、已行动和粮草状态解释移动/攻击应在地图点目标格，固守、准退、补给仍在军令牌按钮批令；坐标显示复用 `MingMapLabelFormat.coordinate`。该增量只改 SwiftUI 展示，不新增状态，不改变 `Command`、`CommandValidator`、`WarCommandExecutor`、`RuleEngine` 或任何移动/攻击/补给规则。
- v4.6 明末命令交互回执增量：`AppContainer` 会在玩家提交 `Command` 前按当前 `GameState` 生成 UI-only 中文军令摘要，并把普通命令成功/驳回、`CommandValidationError`、玩家将令诊断、目标定位、单位点选、AI 回合摘要和 fallback mock commander 名称改为明末中文口径；`RulerAgent` 生成的最高意志理由和上下文也改为中文朱批式文本。该增量只影响 `lastCommandMessage`、`interactionLog`、`RulerDecisionRecord.rationale/theaterContext` 的可读文案，不改变 `Command.displayName`、记录 ID、命令校验、执行结果、`CommandValidator`、`WarCommandExecutor`、`RuleEngine` 或任何规则权威。
- v4.6 默认可见文案本地化增量：`RootGameView` 信息面板 AI 入口改为“军机”，`DataLoader` 初始载入塘报改为中文；`AgentPanelView` 只在显示边界把旧 `Command.displayName` 前缀映射为中文短令，`RuleEngine`、`CommandExecutor` 和 `SupplyRules` 的默认命令/战斗/补给/退守/回合塘报改为中文并补显式分类。该增量不改变 `Command.displayName` 本体、Codable 记录、AI prefix 判定、命令校验、战斗补给结果或规则权威。
- v4.6 军机/战区诊断本地化增量：`CommandValidationError.mingDisplayText` 统一玩家回执、军机记录和战区日志中的中文驳回原因；`TurnManager` 的无军令、战区指令为空、指令未生成军令、军令被驳回、防区缺失和结束阶段失败诊断，以及 `WarCommandExecutor` 的战区军令驳回、州府控制权变化、单格动态方面推进和接敌线变化塘报，均改为明末中文口径。该增量只影响 `AgentDecisionRecord.errors`、`WarDirectiveRecord.diagnostics` 和 `eventLog` 可读文案，不改变 `CommandValidationError.rawValue`、`Command.displayName`、AI JSON、`ZoneDirective`、命令校验、执行结果或规则权威。
- v4.6 部队军械火力增量：`UnitInspectorView` 新增只读“军械火力”区，从现有 `Division.components`、`effectiveStats.range`、`hasFireSupport`、`isSiegeCapable`、兵力和粮草状态派生军械占比、火器/炮队/攻城比例、射程、火力姿态和粮草对火器炮队的影响说明。该增量帮助部队牌联读科技、火器、攻城和军事经营，不新增 `Division` 字段，不改变 `ComponentType`、`CombatRules`、补给、命令、AI 或规则权威。
- v4.6 钱粮军饷民心增量：`EconomyPanelView` 新增只读“军饷民心”区，从 `FactionEconomyLedger`、当前势力未毁部队补给状态和 `GovernanceAISummary` 派生军伍、缺粮、军饷余势、民心综合和压力文案，帮助钱粮面板联读经济、军事和地方治理；该增量不新增军饷、士气、民心或灾荒字段，不改变经济、部队、治理、补给、生产、命令或规则权威。
- v4.6 府库生产状态增量：`EconomyPanelView` 在“募兵与筹粮”生产行显示“可开工 / 尚缺民力、银两、粮草 / 待本方 / 观战”，缺口只由 `FactionEconomyLedger.stockpile` 与 `ProductionKind.cost` 只读计算；军饷民心说明改为“账房奏报”口吻。该增量不新增经济字段，不改变生产成本、队列、`Command.queueProduction`、`CommandValidator`、`EconomyRules`、`RuleEngine` 或任何规则权威。
- v4.6 朝廷项目行动状态增量：`CourtPanelView` 在四线项目按钮显示“可批 / 尚缺民力、银两、粮草 / 待本方 / 观战”，缺口只由 `FactionEconomyLedger.stockpile` 与 `CourtProjectKind.cost` 只读计算；按钮可用性仍与该状态一致，VoiceOver 会读取状态值。该增量不新增朝廷或经济字段，不改变项目成本、收益、`Command.enactCourtProject`、`CommandValidator`、`EconomyRules`、`RuleEngine` 或任何规则权威。
- v4.6 州府主值增量：`RegionInspectorView` 在州府牌新增只读“州府主值”区，按目标、前线压力、关隘、粮台、工坊、驿道和治理压力说明该州府当前更偏战局要冲、前线承压、城关屏障、粮台重地、工坊军械、驿道节点或治理承压，并用政/粮/械/兵四个 chip 联读政策、经济、科技、军事价值。该增量不新增状态，不改变 `RegionInspectorState`、hex/region 控制、经济、前线、部署、命令或规则权威。
- v4.6 州府本州入局增量：`RegionInspectorView` 在“州府主值”后新增只读“本州入局”区，从既有目标、前线、治理、粮台、工坊、驿道和友敌军派生要冲入局、接敌入局、地方入局、经略入局或后方入局总批，并用天下、政粮、军械 chip 联读中华世界局势、政策、经济、科技和军事。该增量不新增 `RegionInspectorState` 字段，不触发目标定位，不写塘报，不提交命令，不改变 hex/region 控制、经济、前线、部署、胜负或规则权威。
- v4.6 州府四线牵引增量：`RegionInspectorView` 在“州府主值”后新增只读“州府四线牵引”，从现有州府、治理、钱粮、目标、友敌军和前线压力派生政策、经济、科技、军事四格，显式说明民变行政、民力银粮、工坊驿道和军事压力。该增量不新增状态，不改变 `RegionInspectorState`、`RegionNode`、hex/region 控制、经济、前线、部署、命令或规则权威。
- v4.6 朝议批票增量：`CourtPanelView` 新增只读“朝议批票”，从 `CourtStrategySummary`、推荐 `CourtProjectKind` 和明末 `BattleObjectiveSummary.CampaignLineBrief` 派生本旬票拟项目、四线最高压力、战役最急线、成本、收益和风险，强化朝廷将中华世界局势落到政策/经济/科技/军事项目的因果感；该增量不新增状态、不自动执行项目、不改变朝议排序、项目成本收益、命令校验、经济规则或规则权威。
- v4.6 整训团练地方驻防增强：整训团练现在作为政策/军事兼线项目展示，玩家执行仍走 `Command.enactCourtProject -> CommandValidator -> EconomyRules -> RuleEngine`；效果保留 1 回合地方守备队列，并轻量稳定最多 2 个己控不稳州府的民变/行政，不新增独立治安资源、真实驻防层、控制权变化、外交变化、补给判定变化或多回合政策状态。
- v4.7 明末胜负链记录：`md/prompt/v4.0-明末迁移/v4.7_ming_victory_record.md`；当前已落地明末胜负规则和目标面板首片，`Objective.points` 保留剧本分值，`DataLoader` 会把 `ScenarioDefinition.victoryConditions` 写入 `GameState.victoryConditions`，`BattleObjectiveSummary` 优先从剧本条件派生清破关入京、大顺据中原秦陕、大西据湖广粮区、明廷最终守住京师关口和 objective points 归属，并派生松锦余波、催饷安民、火器与城防、粮道告急、军机复盘、开封围城压力和目标线压力等只读战役提示；`Cue.Kind` 已包含“军械”，只用于解释红衣炮维护、火器整备和修城固守，不新增科技树或事件效果；同一摘要还派生天下五线态势、本旬任务链和阶段战局链，按当前压力给出天下、政策、经济、科技、军事五线压力，以及军事守关、救援开封压力、政策征饷安民、经济粮链、科技火器修城和终局名分等任务，并派生山海关屏障、河南秦陕粮链、湖广粮道、朝廷四线取舍、火器修城和终局名分线等只读阶段战局链；`CourtPanelView` 在明末剧本中也复用同一 `CampaignLineBrief` 展示朝廷五线态势；`CampaignAISummary` 已把同一五线态势转入 `AgentContext`、`AgentPromptBuilder`、`TurnManager.contextSummary`、`MarshalBattlefieldSummary` 和 `AgentPanelView`，元帅摘要 `schemaVersion` 升到 9，让 AI/军机链路和军机复盘牌都能读取中华世界局势、名分、粮链、火器和军政压力；`CourtStrategySummary` 也会读取同一胜负线压力，把破关入京、河南秦陕粮链、湖广粮道和终局名分线加权到朝廷主议/备议；目标面板的城关 chip 会只读显示当前控制方旗号和要冲分，城关 chip 和任务定位按钮可定位对应 hex / 州府并切到州府牌，`BoardScene` 会只读 `focusedObjectiveId` 与同一摘要显示“标”令牌、脉冲圈、目标名、当前控制方和同胜负线城关连线；`CommandExecutor` 会在结束回合时把这些 cue 去重写入塘报日志，并把急务/主线任务最多 3 条写入任务塘报；明末 objective hex 因合法移动占领换手时记录目标换手塘报；开封围城压力当前只读派生，不新增真实 siege state；`VictoryRules` 与“目标”面板共用该摘要；legacy 阿登胜负链继续保留。
- v4.7 目标面板天下棋眼增量：`BattleObjectivePanelView` 在 header 后新增只读“天下棋眼”区，从 `BattleObjectiveSummary` 派生要冲分领先方、最急五线、本旬先手任务和目标定位入口，让目标 tab 首屏先呈现中华世界局势、政策/经济/科技/军事压力和当旬落点。该增量只改 SwiftUI 展示；定位按钮仍走 `onFocusObjective -> AppContainer.focusObjective(_:)`，不提交命令，不写塘报，不改变胜负、摘要、命令或规则权威。
- v4.7 目标面板国势四策增量：`BattleObjectivePanelView` 在 header 后新增只读“国势四策”区，从 `BattleObjectiveSummary`、当前势力 `CourtStrategySummary` 和 `FactionEconomyLedger` 派生政策、经济、科技、军事四张扫读牌，联读要冲分领先方、主议/备议、府库银粮、火器攻城军和前线压力。该增量只改 SwiftUI 展示，不新增按钮，不定位目标，不写塘报，不执行朝廷项目，不提交命令，不改变胜负、朝议、经济、命令或规则权威。
- v4.7 目标面板要冲缺口增量：`BattleObjectivePanelView` 在“天下棋眼”后新增只读“要冲缺口”区，从 `BattleObjectiveSummary.tracks` 和 `Target.isControlled` 派生每条胜负线尚缺城关、最高分缺口、现控制方和定位入口。该增量只改 SwiftUI 展示；定位按钮仍走 `onFocusObjective -> AppContainer.focusObjective(_:)`，不提交命令，不写塘报，不新增任务状态，不改变胜负、摘要、命令或规则权威。
- v4.7 舆图要冲分布增量：`RootGameView` 顶部 `MingMapSituationStrip` 在“天下急势”内新增只读“要冲分布”横向小条，从 `BattleObjectiveSummary.scoreRows` 展示各势力 objective points 和控制要冲数量，并标出当前领先方。该增量只改 SwiftUI 展示，不提供定位按钮，不写塘报，不新增状态，不改变胜负、摘要、命令或规则权威。
- v4.7 舆图本旬先手增量：`RootGameView` 顶部 `MingMapSituationStrip` 在“要冲分布”后新增只读“本旬先手”提示，从 `BattleObjectiveSummary.tasks` 和 `tracks.targets` 派生当前最高优先级任务、目标城关、当前控制方和要冲分，让地图第一视野直接显示本旬落点。该增量只改 SwiftUI 展示，不提供定位按钮，不写塘报，不新增状态，不改变胜负、摘要、命令或规则权威。
- v4.6/v4.7 朝报要冲增量：`HUDView` 新增只读“朝报要冲”区，从 `BattleObjectiveSummary.from(state:)` 派生棋势领先方、最急五线、本旬任务和目标城关/控制方，让地图第一屏直接显示中华世界局势、胜负目标和四线压力。该增量只改 SwiftUI 展示，不新增按钮，不定位目标，不写塘报，不提交命令，不改变胜负、摘要、朝议、命令或规则权威。
- v4.6/v4.7 舆图点验增量：`RootGameView` 在“天下急势”后新增只读“舆图点验”，从当前 `selectedRegionInspectorState` 派生选中格位/州府、控制方、动态方面、防区、友敌军、要冲和前线压力；当前继续新增“四线 / 粮道 / 部队”chip，读取现有 `BattleObjectiveSummary.lineBriefs`、选中 `Division` 和粮道开关状态，展示最急五线、军粮状态、路线显隐、兵力和行动态势，帮助玩家点选地图后直接联判该点的战局归属、中华世界局势、粮道和当前军牌兵势。该增量只改 SwiftUI 展示，不新增状态，不提交命令，不写塘报，不改变 `RegionInspectorState`、`BattleObjectiveSummary`、`Division`、`SupplyRules`、`MapDisplayAdapter`、`GameState` 或任何规则权威。
- v4.7 朝廷面板廷议要冲增量：`CourtPanelView` 在“朝议批票”后新增只读“廷议要冲”区，从 `BattleObjectiveSummary.scoreRows` 展示各势力要冲分、控制要冲数、本方分值和领先方，让朝廷 tab 把中华世界局势直接接回政策、经济、科技、军事取舍。该增量只改 SwiftUI 展示，不提供定位按钮，不写塘报，不执行朝廷项目，不改变胜负、朝议摘要、命令或规则权威。
- v4.7 钱粮面板府库四线牵引增量：`EconomyPanelView` 在“收支急报”后新增只读“府库四线牵引”区，从 `FactionEconomyLedger` 和当前势力 `CourtStrategySummary` 派生政策、经济、科技、军事四线压力、库存、营造队列、主议和备议，帮助钱粮面板联读朝廷、经济、火器和军事接战压力。该增量只改 SwiftUI 展示，不新增经济/朝廷/科技字段，不触发生产或朝廷项目，不改变命令、经济或规则权威。
- v4.7 钱粮面板经世策眼/民食灾荒增量：`EconomyPanelView` 在“府库四线牵引”后新增只读“经世策眼”区，从 `BattleObjectiveSummary`、`CourtStrategySummary` 和 `FactionEconomyLedger` 派生 objective points 领先方、最急天下五线、府库粮银余势、本旬主议和备议；当前又在“经世策眼”后新增只读“民食灾荒”区，从现有库存粮、本旬粮差、民变/行政和缺粮/断粮军伍派生民食余势与灾荒风险，让府库牌从钱粮视角联读中华世界局势、政策、经济、科技、军事与民食压力。该增量只改 SwiftUI 展示，不新增状态或按钮，不触发生产、朝廷项目、目标定位、AI、灾荒事件、塘报或规则执行。
- v4.6/v4.7 主入口与阶段显示去调试前缀增量：`RootGameView` 底部抽屉入口改为“军情”，旧折叠入口 `InfoPanelToggle` 也同步改为“军情”，紧凑目标面板入口改为“国势”，`BattleObjectivePanelView` 中“目标线”改为“胜负线”；`GamePhase.displayName` 对 legacy `.germanAI` / `.alliedPlayer` 与通用 `.aiAction` / `.humanAction` 统一显示“军机行动 / 玩家行令”，不再在玩家可见阶段名中带 `Legacy`。该增量只改显示层文案，不改变 raw value、Codable 兼容、`allowsHumanCommands`、目标摘要、胜负判定、回合推进、AI 控制方、命令校验或规则权威。
- v4.6/v4.7 军令牌要冲军令增量：`CommandPanelView` 新增只读“要冲军令”区，由 `RootGameView` 注入 `BattleObjectiveSummary.from(state:)`，把本旬急务、目标落点和选中部队兵势接到军令牌内，让调动前能同时扫读中华世界局势、军事落点和本军状态。该增量只改 SwiftUI 展示，不新增按钮，不定位目标，不写塘报，不提交命令，不改变胜负、朝廷、经济、AI、移动/攻击/补给或规则权威。
- v4.6/v4.7 军令牌落点现势与朝议四线增量：`CommandPanelView` 的只读“要冲军令”区继续读取 `BattleObjectiveSummary.tracks.targets` 和 `lineBriefs`，把目标落点补成胜负线、现控制方和要冲分，并新增政策、经济、科技、军事四线压力 chip。该增量只改 SwiftUI 展示，不新增按钮，不定位目标，不写塘报，不提交命令，不改变胜负、摘要、朝廷、经济、AI、移动/攻击/补给或规则权威。
- v4.6 将领面板帷幄四线增量：`GeneralCommandPanelView` 在“方面态势”后新增只读“帷幄四线”区，从现有 `FrontZone`、`GeneralData`、`GeneralAssignment`、麾下 `Division`、目标 `RegionNode` 和本营受压状态派生政策、经济、科技、军事四格，展示将心军心、粮道驿道、火器攻城/工坊、防区压力和可调军伍。该增量只改 SwiftUI 展示，不新增状态，不新增按钮，不提交命令，不改变固守/进取回调、将领状态、部署、胜负、朝廷、经济、AI、`Command`、`ZoneDirective`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何规则权威。
- v4.6/v4.7 将领面板督师要冲增量：`GeneralCommandPanelView` 新增只读“督师要冲”区，由 `RootGameView` 注入 `BattleObjectiveSummary.from(state:)` 和 `MapState`，在将印军令内展示本旬任务、目标落点、现控制方、要冲分、最近麾下军伍距目标的 hex 格数、可调营数、火器攻城和粮道状态。该增量只改 SwiftUI 展示，不新增任务状态，不自动定位目标，不写塘报，不提交命令，不改变胜负、将领、部署、朝廷、经济、AI、`Command`、`ZoneDirective`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何规则权威。
- v4.7 明末 AI doctrine 记录：`md/prompt/v4.0-明末迁移/v4.7_ming_ai_doctrine_record.md`；当前已新增 `ZoneCommanderDoctrine`，让 `TheaterCommanderPool` fallback、`AppContainer` 空将领 registry fallback、显式 `.zoneDirective` 路径、`MockAICommander` 和 `SimulatedMarshalLLMClient` 默认配置/战术选择按明廷谨慎、清/大顺/大西进取、地方中立自保生成差异：`ZoneCommanderAgent` 和模拟元帅 JSON 都会按 doctrine 把同态进攻映射为明廷火器压制、清方突骑破阵/合围、大顺破围、大西流动作战；当前又把明末模拟元帅 `strategicIntent`、`TheaterDirective.rationale`、编译摘要、`TheaterCommanderPool.contextSummary`、`MockAICommander.theaterContext` 和 fallback 诊断改成军机/督师中文口径；`AgentPanelView` 也会在军机复盘牌中只读展示该 doctrine 的势力军略、风格、技能标签和战术偏向；当前又把 legacy Agent D 的 `AgentPromptBuilder`、`MockAIClient`、`TurnManager.contextSummary`、`GameAgent.sample` 和 `GamePhase.displayName` 按明末势力改为军机、粮草、城关、州府、火器和天下五线口径，并把明末 prompt/MockAI 理由里的粮草 raw 值改为“有粮/缺粮/断粮被围”；当前补充 `RegionId.mingDisplayTitle`，让明末 prompt 的目标/军伍/邻接州府、治理最低行政州府和 MockAI 前线接敌理由显示州府名而非 `region_*` raw id；legacy 德/盟分支保留阿登/Bastogne 回归文案；该片只改变 directive 生成偏置、legacy prompt/模拟理由和显示文本，不新增 AI 管线，不绕过 `TheaterDirective -> TheaterDirectiveCompiler -> ZoneDirective -> WarCommandExecutor -> RuleEngine`。
- v4.7 军机面板诸势军略增量：`AgentPanelView` 在明末剧本下新增只读“诸势军略”区，遍历 `Faction.mingLaunchCases` 并读取 `ZoneCommanderDoctrine.profile(for:)`，集中比较明廷、后金/清、大顺、大西和地方中立的军略名、指挥风格、技能标签和战术偏向。该增量只改 SwiftUI 展示，不新增 doctrine 状态，不改变 AI prompt、tactic 偏置、命令、胜负、经济、外交或任何规则权威。
- v4.8 发布候选记录：`md/prompt/v4.0-明末迁移/v4.8_ming_release_candidate_record.md`；当前已落地本机单槽自动保存与继续战局首片，成功命令、玩家将令和 AI 回合结算后保存完整 `GameState`，HUD/macOS 战局菜单可继续最近战局，新开战局会清除旧存档；该片只恢复规则权威状态，不保存选中态、高亮、图层开关或交互日志，不改变命令、AI、胜负、经济或 hex/region/theater/front/deploy 权威。
- 当前真实运行链路仍以 `md/flow/flow.md` 和 `md/flow/flowchart.md` 为准；明末路线是迁移目标，不等于源码已完成迁移。
- `v0.*（已完成）` 是 WWIIHexV0 历史实现资料；`v2.0`、`v3.0`、`v5.0`、`v6.0` 等其他题材迁移目录只作参考，不是当前明末主线。

## 2. 角色召唤

- 用户消息以 `agenta`、`a:` 或 `A:` 开头，表示召唤 Agent A。
- 用户消息以 `agentb`、`b:` 或 `B:` 开头，表示召唤 Agent B。
- 用户消息以 `agentc`、`c:` 或 `C:` 开头，表示召唤 Agent C。
- 没有这些前缀时，按普通 Codex 任务处理；若任务需要 A/B/C 边界，应提醒用户指定角色或说明本轮按普通任务执行。

身份标识：

- Agent A 最终回复第一行必须写：`我是 Agent A。`
- Agent B 最终回复第一行必须写：`我是 Agent B。`
- Agent C 最终回复第一行必须写：`我是 Agent C。`

## 3. Agent A 提示词必须写清

Agent A 生成阶段提示词时，必须包含：

1. 目标与非目标。
2. 当前架构依据和必须阅读的源码 / 文档。
3. 本轮只使用 `main`：Agent B 开始前同步 `origin/main`，完成后 commit 并直接 push 到 `origin/main`。
4. 本机检查范围：只跑 `md/test/test.md` 允许的轻量检查；未获人工授权不得本机跑 Xcode build/test、模拟器、Probe、Smoke、Stage Regression、Dynamic Theater Regression、Full 或性能测试。
5. 云端验证要求：push 到 `main` 后由 `.github/workflows/ci-results.yml` 触发 GitHub Actions。
6. CI 结果包要求：未加密 artifact 必须包含 manifest、failure summary、JUnit、主构建日志、静态检查日志和项目原生结果包。
7. Agent C 验收要求：只验收 `origin/main` 最新 commit 对应的 run；必须下载 artifact 并核对 `commitSha`、`runId`、`runAttempt`、日志和摘要。
8. 云端失败处理：不回滚；退回 Agent B 在 `main` 上追加修复 commit 并重新 push。
9. 文档同步要求：若流程、验证、核心逻辑或版本状态变化，必须更新 `AGENTS.md`、`md/test/test.md`、`md/flow/*`、`README.md`、`update_log.md` 或本目录相关文档。
10. 验收标准、风险提示和最终交付格式。

## 4. Agent B 实现提示词模板要点

Agent B 的提示词应明确：

```text
先同步：
git fetch origin
git switch main
git pull --ff-only origin main

本机只跑轻量检查：
git diff --check
按改动类型追加 plutil / xmllint / jq / YAML parse。

完成后：
git add 相关文件
git commit -m "vX.Y: 简要说明"
git push origin main
记录 workflow run id、attempt、artifact 名称和未跑本机重测试的原因。
```

## 5. Agent C 验收提示词模板要点

Agent C 的提示词应明确：

```text
gh auth status
gh run list --workflow "WWIIHexV0 CI Results" --branch main --limit 5
gh run download <run_id> --dir /private/tmp/wwiihexv0-c-review-<run_id>
```

必须打开并核对：

- `ci-artifact-manifest.json`
- `junit.xml`
- `xcodebuild.log`
- `static-checks.log`
- `ci-failure-summary.md`

只有 `manifest.commitSha == origin/main 最新 commit` 且 run / artifact 与最新 main 提交一致时，才可验收通过。

## 6. 禁止项

- 不把 AITRANS 的漫画探针、GGUF、模型 Release、`test/1.png`、`smalldata_test` 等项目特例复制到 WWIIHexV0。
- 不把旧 artifact、旧 output 或 checkout 自带报告冒充本轮云端结果。
- 不创建 PR 或候选分支流程；本轮默认就是 `main` 直推。
- 不提交模型、大数据、证书、密码或 secret。
