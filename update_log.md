# WWIIHexV0 v 版本更新记录

本文档记录项目从 v0 到 v0.37 的正式 v 版本演进。资料来源包括 `git log`、`README.md`、阶段文档与测试/验收报告。

维护规则：

- 每完成一个新的 v 版本任务后，必须在本文档追加对应版本记录。
- 记录应包含：版本号、完成日期、核心变更、关键文件/系统、验证结果、遗留事项。
- 若本轮只是文档整理、目录迁移、回滚或打捞，不应伪装成新 v 版本；可写入“历史维护记录”。
- 若 README、测试规范或源码语义发生变化，应同步更新本日志。

## 明末迁移滚动记录

- 2026-07-07：v4.6 明末府库牌“户工施政盘”只读小片落地：`EconomyPanelView` 在“经世策眼”之后新增只读施政盘，从既有 `FactionEconomyLedger`、`CourtStrategySummary`、`BattleObjectiveSummary`、`CourtProjectKind`、`ProductionKind` 与当前军伍状态派生政策、经济、科技、军事四格，展示可票拟/府库待蓄/营造待发、可批项目数、募兵筹粮可开数、营造队列、最急五线、缺粮军伍和火器攻城支点，帮助玩家从府库视角扫读钱粮余势和施政取舍。该片只影响 SwiftUI 展示，不新增 `GameState`、经济、朝廷、科技、军饷、民心、工部或项目持久字段，不触发生产或朝廷项目，不写塘报，不提交命令，不改变 `Command.queueProduction`、`Command.enactCourtProject`、`CommandValidator`、`EconomyRules`、`WarCommandExecutor`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威。
- 2026-07-07：v4.7 军机复盘“军机急奏”补齐：`AgentPanelView` 在军机复盘头部新增只读急奏条，把要冲领先方、最急五线和当旬急务从既有 `CampaignAISummary` 前置到成令/驳回/战区统计下方，让军机界面第一眼能联读天下局势、政策、经济、科技和军事压力。该片只读取既有 `CampaignAISummary.leadingFaction`、`lineBriefs` 与 `activeTasks`，非明末剧本静默隐藏，不新增按钮，不触发目标定位，不写塘报，不提交命令，不改变 AI prompt、doctrine、`Command`、`ZoneDirective`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威。
- 2026-07-07：v4.6 将领名帖“帷幄四策”补齐：`GeneralProfileView` 在印信摘要后新增政策、经济、科技、军事四格，只读展示忠诚/军心/手令/本营压力、缺粮营数与粮道、火器攻城军械、防区压力与可调营数，让将领名帖和将印军令同样能联读明末军政钱粮火器处境。该片只读取既有 `GeneralData`、`GeneralAssignment`、`FrontZone` 与 `Division` 状态，不新增按钮，不触发目标定位，不写塘报，不提交命令，不改变 `GameState`、`Command`、`ZoneDirective`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威。
- 2026-07-07：v4.7 天下局势“诸方要冲筹码”补齐：`DiplomacyPanelView` 在“诸方势力”行中只读显示各势力要冲分、控制要冲数和领先冠标，并让“天下牵引”的要冲分榜按分值/控制数排序，帮助天下面板把战意、阵营和明末胜负筹码放在同一处扫读。该片只读取既有 `BattleObjectiveSummary.scoreRows` 与 `leadingFaction`，非明末剧本静默隐藏，不新增按钮，不触发目标定位，不写塘报，不提交命令，不改变 `GameState`、胜负、AI、经济、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威。
- 2026-07-07：v4.6 明末地图军牌“令签”首片落地：`UnitNode` 在 `isPlayerManaged` 为真时，于地图军牌顶端显示朱砂“令”签，配合既有金色 halo 让本方可调军牌在第一视野更像可批令部队；`RootGameView` 舆图图例同步补充“令签 / 可调”说明。该片只读既有 `playerCommandState.micromanagedDivisionIds` 经 `BoardScene` 传入的 `isPlayerManaged`，不新增 `Division`、`PlayerCommandState` 或地图 schema，不改变选中、移动、高亮、AI、命令提交、`GameState`、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威。
- 2026-07-07：v4.6 明末城关粮台控制方旗号补齐：`HexNode` 对城池、关隘/堡寨和粮台 hex 的左下控制点改为势力字旗，复用既有 `Faction.bannerGlyph` 与 `TerrainStyle.controllerColor(for:)` 显示“明 / 清 / 顺 / 西 / 乡 / 德 / 盟”等归属；普通 controlled hex 继续保留低噪声圆点。该片只影响 SpriteKit 展示，从现有 `HexDisplayState.controller` 与 `supplySourceFaction` 只读派生，不改变 `HexTile.controller`、补给源归属、粮道、占领、胜负、`GameState`、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何规则权威。
- 2026-07-07：v4.6/v4.7 明末军情入口与军机摘要本地化补齐：`InfoPanelToggle` 的折叠入口从“信息”改为“军情”，补齐主入口文案收口；`TheaterCommanderPool.contextSummary` 与 `MockAICommander.theaterContext` 在明末势力下输出“防区军令/军机试拟”中文摘要，legacy 德/盟分支继续保留 `zone directive(s)` / `mock directive(s)` 英文回归文案。该片只影响 SwiftUI 入口标签和 `DirectiveEnvelope.theaterContext` 可读文本，不改变 `ZoneDirective` 生成、AI tactic 偏置、JSON schema、命令校验、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何规则权威。并发子 Agent Epicurus 只读建议后续可做舆图地貌纹理，本轮先采纳更低风险的军机可读性切片；Harvey 超时未阻塞主线。
- 2026-07-07：v4.6 明末舆图地貌底纹首片落地：`TerrainStyle` 新增平原/林地/山地/丘陵/城池/关隘的低透明地貌字与颜色 token，`HexNode` 在 controller overlay 之后、移动/攻击高亮与城关粮台 badge 之前绘制“田 / 林 / 山 / 丘 / 城 / 关”底纹，让默认 hex 底图更像明末舆图。该片只影响 SpriteKit 展示，不新增地形类型，不改变 `BaseTerrain`、移动成本、战斗修正、补给、控制权、fog、目标、道路/河流、军牌、`GameState`、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何规则权威。
- 2026-07-07：v4.7 目标面板“国势四策”五线摘要补齐：`BattleObjectiveFourPolicyBoard` 的政策、经济、科技、军事四张卡现在优先读取同名 `BattleObjectiveSummary.CampaignLineBrief`，把天下五线派生出的“政策线 / 经济线 / 科技线 / 军事线”压力、急务和主线说明直接写入四策卡；缺少对应 brief 时仍回退到既有朝议、府库、火器和前线说明。该片只改 `BattleObjectivePanelView` 的 SwiftUI 只读展示，不新增按钮，不定位目标，不写塘报，不执行朝廷项目，不改变 `BattleObjectiveSummary` 生成、`CourtStrategySummary`、`EconomyRules`、`VictoryRules`、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何规则权威。

## v0 - 六角格测试板

完成日期：2026-06-14 至 2026-06-15

核心更新：

- 建立 iOS 二战回合制战棋原型，技术栈为 Swift + SwiftUI + SpriteKit。
- 创建阿登测试战场，使用 11x9 左右的 axial hex 地图。
- 落地地形、移动、战斗、占领、补给、包围、胜利条件、回合流程。
- 建立德军 MockAI 将领 `guderian`，按局势摘要生成结构化命令，再经规则系统校验执行。
- 建立 SwiftUI HUD、命令面板、事件日志、单位详情和 SpriteKit 六角格渲染。

关键系统：

- `Core/HexCoord.swift`
- `Core/MapState.swift`
- `Core/Division.swift`
- `Rules/RuleEngine.swift`
- `Rules/MovementRules.swift`
- `Rules/CombatRules.swift`
- `Rules/SupplyRules.swift`
- `Rules/VictoryRules.swift`
- `SpriteKit/BoardScene.swift`
- `UI/RootGameView.swift`

备注：

- v0 的核心边界是“可玩测试板”，不做空军、海军、经济、生产、外交、多级指挥链和真实 LLM。
- 后续所有版本都必须保留 hex 作为战术层权威。

## v0.1 - strength、撤退与补员

完成日期：2026-06-15 前后

核心更新：

- `Division` 战斗模型升级为 `strength/maxStrength`，保留 `hp/maxHP` 兼容。
- 战斗伤害从 HP 语义转向兵力语义，后续明确不恢复 organization。
- 引入撤退状态与 `RetreatMode`：`retreatable` 可自动撤退，`hold` 获得防御加成。
- 撤退失败会施加额外惩罚；无补给、包围会影响战斗与回合损耗。
- `resupply/rest` 能恢复兵力。
- UI 和日志补充 Strength、Retreating、combat/retreat/reinforce/encircle/supply 分类。

关键系统：

- `Core/Division.swift`
- `Rules/CombatRules.swift`
- `Rules/SupplyRules.swift`
- `Rules/RuleEngine.swift`
- `UI/UnitInspectorView.swift`
- `UI/HUDView.swift`

备注：

- v0.1 最终模型只看兵力，不引入 organization。
- `HOLD` 防御约 +20%，`RETREATABLE` 在单次损失比例达到阈值时自动撤退。

## Agent D - AI/Agent 决策管线

完成日期：2026-06-15

核心更新：

- 打捞并恢复早期 Agent D 管线，修复此前异常删除。
- 建立 `DecisionProvider` 协议，为 MockAI 与未来本地 LLM 共用。
- 建立 `AgentContext` / `AgentContextBuilder`，只传 Codable 摘要，不暴露 UI/SpriteKit 对象。
- 建立 `AgentDecisionEnvelope` / `AgentOrder` JSON schema。
- 建立 parser、command mapper、decision record 与 AI 决策展示面板。
- `TurnManager` 负责德军 AI 回合编排，`AppContainer.runAIIfNeeded()` 接入启动流程。

关键系统：

- `Agents/DecisionProvider.swift`
- `Agents/AgentContexts.swift`
- `Agents/AgentDecision.swift`
- `Agents/AgentDecisionParser.swift`
- `Agents/AgentCommandMapper.swift`
- `Agents/MockAIClient.swift`
- `Agents/LocalLLMDecisionProvider.swift`
- `Turn/TurnManager.swift`
- `UI/AgentPanelView.swift`
- `Tests/AgentPipelineTests.swift`

备注：

- Agent D 是重要历史管线，但 v0.37 后默认战争 AI 主路径已改为 ZoneDirective。
- 后续不得删除 Legacy Agent D；只能隔离、退役或作为回归参考。

## v0.2 - Region 战略层叠加

完成日期：2026-06-15 至 2026-06-16

核心更新：

- 明确废弃旧版“用 province 替换 hex”的方案，改为 Region 战略层叠加。
- `MapState` 同时持有 hex 与 region：`regions`、`hexToRegion`、`regionEdges`。
- 新增 `RegionId`、`RegionNode`、`RegionEdge`、`RegionGraph` 与校验错误类型。
- 建立阿登 v0.2 省份数据：17 省、41 边、99 hex 全覆盖、零重叠。
- `DataLoader` 加载 `ardennes_v02_regions.json` 并反向填充 `HexTile.regionId`。
- 新增 Region 规则层：移动、战斗、占领、补给、视野、胜利、pathfinder、rule system。
- 新增 `RegionCommand`、`CommandIntentAdapter`、AgentOrder schema v2，支持 region 命令与 hex 命令互转。
- UI 增加 `MapDisplayAdapter`、Region overlay 与 `RegionInspectorView`，hex 仍为唯一渲染对象。

关键系统：

- `Core/Region.swift`
- `Core/MapState.swift`
- `Data/RegionDataSet.swift`
- `Data/ardennes_v02_regions.json`
- `Rules/RegionRuleSystem.swift`
- `Rules/RegionMovementRules.swift`
- `Rules/RegionCombatRules.swift`
- `Rules/RegionOccupationRules.swift`
- `Rules/RegionSupplyRules.swift`
- `Rules/RegionVisibilityRules.swift`
- `Rules/RegionVictoryRules.swift`
- `Commands/RegionCommand.swift`
- `Commands/CommandIntentAdapter.swift`
- `SpriteKit/MapDisplayAdapter.swift`
- `UI/RegionInspectorView.swift`

验证记录：

- v0.2 Agent 6 验收：132 tests, 0 failures。
- 关键覆盖：RegionGraph、ArdennesV02Data、Region rules、Agent region command、MapDisplayAdapter、Board interaction、RuleEngineCore。

备注：

- v0.2 达成 Hex x Region 双轨架构稳定状态。
- 技术债：中立省 owner/controller 为 null 时仍回退到 `.allies`，因为 `Faction` 暂无 neutral case。

## v0.21 - 界面优化与重置流程

完成日期：2026-06-16

核心更新：

- 新增 `InfoPanelToggle`，信息面板默认收起，通过 `[ INFO ]` 展开。
- 新增 `UnitTooltipView`，右下角固定展示选中单位摘要。
- 新增 `NewGameButton` 与 `AppContainer.resetGame()`，支持重载初始地图/单位/Region 并清空选择与日志。
- `RootGameView` 在常规、竖屏、横屏布局中接入 Info toggle 与单位 tooltip。
- 任务 6 zoom 按设计跳过，保留固定放大 hex 与 camera drag。

关键系统：

- `UI/InfoPanelToggle.swift`
- `UI/UnitTooltipView.swift`
- `UI/NewGameButton.swift`
- `UI/RootGameView.swift`
- `UI/HUDView.swift`
- `App/AppContainer.swift`

验证记录：

- 135 tests, 0 failures。
- `swiftc -parse`、`plutil -lint`、`git diff --check` 通过。
- 模拟器烟测通过，截图记录为 `/tmp/wwiihex_v021_smoke2.png`。

## v0.31 - Theater 战区系统

完成日期：2026-06-17

核心更新：

- 新增战区数据结构：`TheaterId`、`TheaterNode`、`TheaterState`、支援请求和 AI 摘要。
- 新增 `TheaterSystem`，从 v0.2 Region 生成四个固定战区。
- 建立 `hex -> region -> theater` 映射与控制比例/胜利点聚合。
- 引入 70% 控制阈值，用于战区扩张正式化、退役和单位池重分配。
- 在 `GameState` 中加入 `theaterState`，兼容旧存档解码。
- `DataLoader` 在加载 Region 后自动生成 v0.31 四战区。

关键系统：

- `Core/Theater.swift`
- `Rules/TheaterSystem.swift`
- `Core/GameState.swift`
- `Data/DataLoader.swift`
- `Tests/TheaterSystemTests.swift`

验证记录：

- `plutil -lint WWIIHexV0.xcodeproj/project.pbxproj` 通过。
- 全量测试：146 tests, 0 failures。

备注：

- v0.31 不做 FrontLine、自动布防、攻势规划、LLM 决策、UI 重构或战斗/hex 规则改动。

## v0.32 - FrontLine 前线层

完成日期：2026-06-17

核心更新：

- 新增前线模型：`FrontLine`、`FrontSegment`、`RegionFrontState`、`FrontLineState`。
- 新增 `FrontLineManager`，支持 turn rebuild 与 event-driven dirty update。
- 建立 `enemyNeighborCache`，简化包围识别。
- 单战区面对多敌战区时，仍暴露一条主 `FrontLine` 给 AI/UI 聚合使用。
- `GameState` 增加 `frontLineState` 并兼容旧存档 empty。
- `DataLoader` 初始加载 Region/Theater 后生成 FrontLine。

关键系统：

- `Core/FrontLine.swift`
- `Core/FrontSegment.swift`
- `Core/RegionFrontState.swift`
- `Core/FrontLineState.swift`
- `Rules/FrontLineManager.swift`
- `Tests/FrontLineCreationTests.swift`
- `Tests/FrontLineUpdateTests.swift`
- `Tests/MultiEnemyFrontTests.swift`

验证记录：

- v0.32 专项测试：9 tests, 0 failures。
- 全量测试：155 tests, 0 failures。
- `project.pbxproj` lint 通过。

备注：

- v0.32 未改 UI、SpriteKit、AI agent、LLM、命令系统、RegionGraph 或 TheaterSystem 结构。

## v0.33 - WarDeployment 部署层

完成日期：2026-06-17

核心更新：

- 新增 `FrontZone`、`FrontZoneSegment`、`WarDeploymentState` 与 `WarDeploymentManager`。
- 从 v0.31 Theater 生成 v0.33 `FrontZone`。
- 建立 region 粒度前线 segment 与 `FRONT / DEPTH / GARRISON` 三层单位池。
- 支持推进、崩溃、战区消亡与事件更新。
- dirty region + neighbor zone 局部重建，避免每次全图前线扫描。
- 新增前线、segment、部署、战争演化和局部更新性能测试。

关键系统：

- `Core/FrontZone.swift`
- `Core/FrontZoneSegment.swift`
- `Core/WarDeploymentState.swift`
- `Core/WarDeploymentTypes.swift`
- `Rules/WarDeploymentManager.swift`
- `Tests/WarDeploymentFrontLineTests.swift`
- `Tests/WarDeploymentSegmentTests.swift`
- `Tests/WarDeploymentDeploymentTests.swift`
- `Tests/WarEvolutionTests.swift`

验证记录：

- v0.33 选定测试：13 tests, 0 failures。
- 全量测试：168 tests, 0 failures。
- `plutil -lint` 通过。

备注：

- v0.33 未改 UI/SpriteKit、AI/LLM/命令系统，也未引入复杂路径搜索。

## v0.331 - v0.31 至 v0.33 总测试

完成日期：2026-06-18

核心更新：

- 对 v0.31 战区、v0.32 前线、v0.33 部署进行阶段集成测试。
- 清理和巩固测试 fixture，使战区、前线、部署三层能稳定共同回归。
- 优化探针检测，准备后续地图编辑器和战争命令系统接入。

关键系统：

- `Tests/TheaterSystemTests.swift`
- `Tests/FrontLine*Tests.swift`
- `Tests/WarDeployment*Tests.swift`
- `Tests/Stage035CampaignSimulationTests.swift`

备注：

- 本阶段主要是集成验收和测试基线整理，不是新玩法版本。

## v0.34 - 地图编辑器

完成日期：2026-06-18 至 2026-06-19

核心更新：

- 在 `MapEditor/` 下加入项目专属地图编辑器骨架。
- 使用 SwiftUI 管理工具面板，SpriteKit 管理六角格交互视口。
- 编辑器直接导出项目自有 `ScenarioDefinition` 与 `RegionDataSet` JSON，不再引入 Tiled 中间件。
- 新增 macOS 独立 target `MapEditorMac`。
- 支持地块、省份、战区、初始部队编辑。
- `DataLoader` 增加任意文件名加载入口和 MapEditor 输出专用加载路径。
- 地形补充 `hill`，并同步 `terrain_rules.json`、颜色和 inspector 显示。

关键系统：

- `MapEditor/MapEditorDocument.swift`
- `MapEditor/MapEditorHexMath.swift`
- `MapEditor/MapEditorExporter.swift`
- `MapEditor/MapEditorViewModel.swift`
- `MapEditor/MapEditorCanvasScene.swift`
- `MapEditor/MapEditorView.swift`
- `MapEditor/MapEditorMacApp.swift`
- `MapEditor/MapEditorGameResourceBridge.swift`
- `Tests/MapEditorOutputTests.swift`

验证记录：

- `MapEditorOutputTests` 覆盖编辑器输出到 `GameState` 的集成链路。

## v0.341 - macOS 独立编辑器

完成日期：2026-06-18

核心更新：

- 新增 `MapEditorMac` target，作为独立 macOS app 运行。
- 默认窗口适配宽屏/全屏地图编辑。
- 左侧 SwiftUI split panel 管理地图、模式、参数、文件操作。
- 右侧 SpriteKit canvas 渲染六角格。
- 支持鼠标拖拽连续涂色、滚轮/触控板缩放、右键/中键/Option+左键平移。
- 默认工作流读写 `WWIIHexV0/Data/ardennes_v0_scenario.json` 与 `ardennes_v02_regions.json`。

备注：

- MapEditor 不接入 iOS 主入口，避免污染游戏 app 启动流程。

## v0.342 - 地图编辑器中文化与显式编辑流

完成日期：2026-06-18

核心更新：

- 地图编辑器左侧面板改为中文。
- 模式拆成：地块、省份、战区、部队。
- 各模式采用统一 `添加 / 删除 / 完成 / 取消` 显式编辑会话。
- 切换模式会取消当前编辑会话，避免误操作。
- 分层显示只突出当前模式相关数据。
- `MapEditorOutputTests.testEditorSessionActionsReflectInGameState` 覆盖地块、省份、战区、部队完整编辑与导出读取。

## v0.343 - 地图编辑器视口稳定、稀疏扩图与快捷键

完成日期：2026-06-18

核心更新：

- 平移改用 view-space 指针增量，避免 camera 移动导致拖动抖动。
- 滚轮/触控板缩放以鼠标所在 scene point 为锚点，减少视口漂移。
- `MapEditorDocument.contains(_:)` 改为判断实际存在 hex，支持稀疏地图。
- 地块模式新增扩展地块动作，允许在已有 hex 邻位生成新 hex。
- 删除 hex 会清理该 hex 上的初始部队，并移除空 region/theater assignment。
- region/theater 名称由 UI 输入，内部 ID 自动递增。
- 新增快捷键：`N` 添加，`M` 完成。

验证记录：

- `MapEditorOutputTests` 扩展覆盖自动 ID、邻接扩展、虚空造地失败、删除清理、平移/缩放数学。

## v0.344 - 地图编辑器交互修复、信息面板与底图层

完成日期：2026-06-19

核心更新：

- macOS 画布改用 `NSViewRepresentable + SKView`，直接接收 `keyDown`。
- 修复 SpriteKit 抢焦点后 SwiftUI `Button.keyboardShortcut` 不稳定的问题。
- 滚轮缩放与水平/Shift 滚轮平移接入 `SKView.scrollWheel`。
- 右键短按选择 hex，并在左侧信息面板展示/编辑坐标、地形、道路、region、theater 信息。
- Region/Theater 颜色改用固定高对比色板按 ID hash 取色。
- 新增编辑器底图层：导入图片、设置透明度、缩放和位置；底图不写入游戏 JSON。

验证记录：

- `MapEditorOutputTests` 扩展覆盖快捷键、右键信息选择、名称保存、底图文档状态与移动增量。

## v0.351 - 初步战争命令系统

完成日期：2026-06-19

核心更新：

- 新增战争指令协议：`DirectiveEnvelope` / `ZoneDirective`。
- 新增 `WarCommandExecutor`，将 zone 级 attack/defend 意图翻译为底层 `Command`。
- 新增 `MockAICommander`，按兵力比阈值输出 attack/defend。
- AI 指令与玩家命令最终都走 `RuleEngine` / `CommandValidator` 校验执行。
- 为后续 LLM 输出 JSON 指令预留协议层。

关键系统：

- `Commands/WarDirective.swift`
- `Commands/WarCommandExecutor.swift`
- `Agents/MockAICommander.swift`
- `Core/WarDirectiveRecord.swift`
- `Tests/CommandSystemTests.swift`

备注：

- v0.351 只是初级战争命令，不做复杂战术、撤退命令、装甲差异化或真实 LLM。

## v0.352 - 新管线唯一化、观察者模式与分层 UI

完成日期：2026-06-19

核心更新：

- 新增/强化 `WarPipelineMode.zoneDirective`，默认战争 AI 走新 ZoneDirective 管线。
- Legacy Agent D 保留但不作为默认战争 AI 主路径。
- 引入观察者模式，支持双方由 AI 自动对战，但回合推进仍受玩家操作控制。
- 新增 `WarDirectiveRecord`，记录 directive、结果、诊断和 UI 回放信息。
- UI 支持 hex/province/theater/frontLine 等图层切换。
- `MockAICommander` attack 阈值从 1.5 调整到 1.2，使战局更容易推进。

关键系统：

- `Core/WarPipelineMode.swift`
- `Turn/TurnManager.swift`
- `App/AppContainer.swift`
- `Core/WarDirectiveRecord.swift`
- `Core/MapDisplayLayer.swift`
- `SpriteKit/MapLayerOverlayNode.swift`
- `SpriteKit/MapLayerOverlayCalculator.swift`

## v0.353 - 默认地图验收与归属权威重构

完成日期：2026-06-19

核心更新：

- 默认地图接入真实战局模拟验收。
- 确立 hex controller 为归属权威。
- region controller、theater 控制比例、补给站归属改为从 hex controller 派生。
- 避免继续依赖静态阵营标签判断动态占领结果。
- 观察者模式下新地图可用于战争模拟和回归测试。

关键系统：

- `Rules/OccupationRules.swift`
- `Rules/StrategicStateSynchronizer.swift`
- `Rules/TheaterSystem.swift`
- `Rules/RegionOccupationRules.swift`
- `Tests/ObserverModeIntegrationTests.swift`
- `Tests/Stage035CampaignSimulationTests.swift`

备注：

- 本阶段是后续 v0.354/v0.355 修复“AI 不动、联动不及时、占领不对称”的地基。

## v0.354 - 联动修复、拒绝率治理与玩家/AI 对称性

完成日期：2026-06-19 至 2026-06-20

核心更新：

- 修复占领后 region、theater、frontline、visibility 不在同一回合联动的问题。
- 修复 ZOC 友军穿越误判，避免友军互相阻挡。
- 定位“德军若干回合后不动”的真实病灶：推进过深的部队被部署层误判为 garrison，从前线兵力池消失。
- 统一玩家与 AI 的占领判定入口，避免 AI 能占玩家地、玩家不能占 AI 地的不对称。
- 改善 RuleEngine 拒绝率诊断，避免非法命令被静默吞掉。

关键系统：

- `Rules/OccupationRules.swift`
- `Rules/StrategicStateSynchronizer.swift`
- `Rules/WarDeploymentManager.swift`
- `Rules/CommandValidator.swift`
- `Commands/WarCommandExecutor.swift`
- `Tests/WarEvolutionTests.swift`
- `Tests/ObserverModeIntegrationTests.swift`

备注：

- v0.354 期间有多轮 debug 与修复提交，包括 `v0.354 优化1`、`v0.354修复`、`0.354debug`。

## v0.355 - 动态/初始战区分离、前线 UI 与观察者收尾

完成日期：2026-06-20 至 2026-06-23

核心更新：

- 正式分离 `TheaterState.initialSnapshot` 与运行时动态战区状态。
- 修复战区阵营身份不能从动态控制比例反推的问题。
- 图层拆分为 `hex`、`province`、`initialTheater`、`dynamicTheater`、`frontLine`。
- 前线 overlay 改为按 `FrontSegment` 连线绘制。
- 观察者模式开关接入主界面 UI。
- 执行 20 回合观察者模式模拟与阶段分析，记录 directive、拒绝原因、省份换手和补给/包围趋势。

关键系统：

- `Core/Theater.swift`
- `Core/MapDisplayLayer.swift`
- `SpriteKit/MapLayerOverlayNode.swift`
- `SpriteKit/MapLayerOverlayCalculator.swift`
- `UI/RootGameView.swift`
- `Tests/Stage035CampaignSimulationTests.swift`
- `Tests/Stage0355DynamicTheaterTests.swift`

验证记录：

- 历史记录显示 v0.355 阶段曾达到 Probe 9/0、Smoke 4/0、Stage Regression 63/0、Full 198/0。
- 20 回合观察者模拟：57 条 directive，拒绝率约 10%，主要拒绝原因为移动力不足与无路径。

备注：

- 文档 `0.355-迄今概览.md` 记录该阶段架构总结与后续注意事项。

## v0.356 - 默认资源一致性与前线 UI 修正

完成日期：2026-06-24

核心更新：

- DEBUG 下 `DataLoader` 优先读取源码 `WWIIHexV0/Data/*.json`，避免编辑器覆盖保存后游戏仍读取旧 bundle 资源。
- 新增默认资源一致性测试，确保编辑器 document、导出 JSON、游戏加载后的 `hexToRegion`、`regionToTheater`、`tile.regionId`、`region.name` 一致。
- 前线 UI 改为在我方动态战区侧绘制，用 `segment.regionA` 内接敌 hex 的中心点连线。
- 不同 theater 前线使用固定不同基色。
- 每个 segment 单独绘制，并在 segment 起点加分隔符，避免被看成一整条红线。

验证记录：

- 定向 MapEditorOutputTests + Stage0355DynamicTheaterTests：10 tests, 0 failures。
- Probe：9 tests, 0 failures。
- Smoke：4 tests, 0 failures。
- Full regression：200 tests, 0 failures。
- `git diff --check` 通过。

备注：

- 如果模拟器中仍运行旧 app 进程，需要重新运行 app 才会读到 DEBUG 源码 JSON。

## v0.357 - 地图视角、开局单位与前线 UI 修正

完成日期：2026-06-24

核心更新：

- 修复地图编辑器与游戏内视角上下颠倒/不一致问题。
- 修复部队初始部署异常与跨阵营战区问题。
- 修正开局不应立即让 AI 自动行动的行为，开局应先显示真实初始部队状态。
- 继续优化前线 UI，使动态战区、segment 与视觉表达一致。

关键系统：

- `MapEditor/*`
- `Data/DataLoader.swift`
- `App/AppContainer.swift`
- `SpriteKit/MapLayerOverlayNode.swift`
- `Tests/Stage0355DynamicTheaterTests.swift`

## v0.358 - 动态 hex 战区语义收口

完成日期：2026-06-24

核心更新：

- 确认核心语义：`regionToTheater` 是初始/基础战区映射，`hexToTheater` 是运行时动态战区权威。
- 单位占领一个 hex 只推进该 hex 的动态战区归属，不能把整个 region 拖入进攻方 theater。
- 部署层同步引入/强化 `hexToFrontZone`，避免 region 粒度误判 FRONT/DEPTH/GARRISON。
- 前线改按动态 hex 邻接生成，测试 fixture 必须构造真实相邻 hex，不能只声明 region 邻接。
- AI target、WarDeployment、overlay、probe 和 stage tests 同步适配动态 hex 语义。

关键系统：

- `Core/Theater.swift`
- `Core/WarDeploymentState.swift`
- `Rules/TheaterSystem.swift`
- `Rules/FrontLineManager.swift`
- `Rules/WarDeploymentManager.swift`
- `Tests/Stage0355DynamicTheaterTests.swift`
- `Probes/WWIIHexV0ProbeTests.swift`

备注：

- 这是 v0.3 主线的重要铁律：运行时动态战区跟 hex 走，不跟 region 走。

## v0.359 - 前线 UI 优化

完成日期：2026-06-25

核心更新：

- 继续优化前线 overlay 的可读性。
- 强化不同战区/不同 segment 的视觉区分。
- 保留 encirclement/collapsing 等警示状态的红色与加粗表达。
- 使前线 UI 更接近真实动态战区接触，而不是静态 region/theater 边界。

关键系统：

- `SpriteKit/MapLayerOverlayNode.swift`
- `SpriteKit/MapLayerOverlayCalculator.swift`
- `UI/RootGameView.swift`

## v0.3510 - 颜色优化

完成日期：2026-06-25

核心更新：

- 优化地图分层 UI 的颜色表达。
- 强化 province、initialTheater、dynamicTheater、frontLine 等 layer 的辨识度。
- 避免相邻 region/theater 颜色过近导致误判。

关键系统：

- `SpriteKit/TerrainStyle.swift`
- `SpriteKit/MapLayerOverlayNode.swift`
- `SpriteKit/MapLayerOverlayCalculator.swift`

备注：

- 该版本号沿用提交历史中的 `v0.3510`，语义上属于 v0.35x UI 收尾序列，不是 v0.351 的子补丁。

## v0.3511 - UI 修复优化

完成日期：2026-06-25

核心更新：

- 继续修复和优化主游戏 UI。
- 配合 v0.359/v0.3510 的颜色和前线显示调整，改善可读性。
- 为 v0.36 命令层扩展前的界面状态收口。

关键系统：

- `UI/*`
- `SpriteKit/*`

备注：

- 该版本号同样来自提交历史，属于 v0.35x 收尾序列。

## v0.36 - 命令层扩展与多将领 MockAI

完成日期：2026-06-25

核心更新：

- `ZoneDirective` 扩展 `CommandCategory`、`TacticName`、`DirectiveTarget`。
- 新增 `ZoneCommanderAgent`，每个动态战区可由独立将领 agent 生成 directive。
- 新增 `BinaryTacticClassifier`，在 `standardAttack` 与 `holdPosition` 之间做初步分类。
- 新增 `TheaterCommanderPool`，为动态战区提供将领配置，未知新战区使用 fallback commander。
- `WarDirectiveRecord` 增加 category、tactic、commanderAgentId、commandTarget 等字段，便于回放和审计。
- `MockAICommander` 转为兼容 facade，不作为未来扩展主入口。
- 修复旧测试 fixture，使其符合 v0.358 动态 hex 邻接语义。

关键系统：

- `Commands/WarDirective.swift`
- `Commands/WarCommandExecutor.swift`
- `Core/WarDirectiveRecord.swift`
- `Agents/ZoneCommanderAgent.swift`
- `Agents/MockAICommander.swift`
- `Turn/TurnManager.swift`
- `App/AppContainer.swift`
- `Tests/CommandSystemTests.swift`
- `Probes/WWIIHexV0ProbeTests.swift`

验证记录：

- Probe：17 tests, 0 failures。
- Stage Regression：63 tests, 0 failures。
- Full Regression：213 tests, 0 failures。
- 静态检查：`plutil`、`xmllint`、`jq`、`git diff --check` 通过。

备注：

- `AttackIntensity` 字段仍存在，但没有实际分流执行逻辑。
- 战区互助接口仍无调用方。
- 真 LLM 尚未接入。

## v0.37 - 命令层统一整合

完成日期：2026-06-27

核心更新：

- 默认战争 AI 路径收口为：

```text
TheaterCommanderPool -> ZoneCommanderAgent -> ZoneDirective -> WarCommandExecutor -> RuleEngine -> WarDirectiveRecord
```

- 移除 `TurnManager` 中 `MockAICommander` fallback，避免默认路径语义模糊。
- `.zoneDirective` 分支只通过显式 `commanderPool` 或 `TheaterCommanderPool.automatic(for:)` 产生 envelope。
- Legacy Agent D 只在显式 `.legacyAgentOrder` 或测试回归中使用。
- 保留 `MockAICommander` 作兼容/阈值行为测试用途，但不再作为 `TurnManager` 默认备用入口。
- 确认 `WarCommandExecutor.execute(_ directive:in:)` 不依赖具体 `ZoneCommanderAgent` 实例，手写合法 `ZoneDirective` 可直接执行。
- 新增 v0.37 手写 directive 探针，为 v0.4 玩家 UI 共用命令管线预留后端能力。
- 决定将撤退命令、突破/闪电战、装甲差异化、`AttackIntensity` 实际分流推迟到 1.x。

关键系统：

- `Turn/TurnManager.swift`
- `Commands/WarCommandExecutor.swift`
- `Commands/WarDirective.swift`
- `Agents/ZoneCommanderAgent.swift`
- `Agents/MockAICommander.swift`
- `Core/WarDirectiveRecord.swift`
- `Tests/CommandSystemTests.swift`
- `Probes/WWIIHexV0ProbeTests.swift`

验证记录：

- Probe：18 tests, 0 failures。
- CommandSystemTests：15 tests, 0 failures。
- Stage Regression：69 tests, 0 failures。
- Full Regression：226 tests, 0 failures。

备注：

- v0.37 是命令层地基工程，不新增玩法机制。
- v0.4 可以在此基础上接玩家聊天/命令 UI，但必须继续共用 `ZoneDirective -> WarCommandExecutor -> RuleEngine`。

## v0.5 - 元帅层、模拟 LLM JSON 与决策链规范化

完成日期：2026-07-04

目标分支：`v0.5-marshal-decision-chain`

分支审计：本轮开始时创建并切换过该分支；后续轻量审计中当前 checkout 先后显示为 `v0.9-ruler-diplomacy`、`v0.4-generals-command-ui-resume`、`v1.1-macos-main-game`、`v1.0-ui-ai-playtest` 等非 v0.5 分支，且工作树已有多批其他版本未提交改动。用户同意切换后，当前 checkout 已确认回到 `v0.5-marshal-decision-chain`；合并前仍必须审查 dirty worktree 中非 v0.5 文件归属和文件级冲突。

核心更新：

- 新增元帅层 `MarshalAgent`，在战区将军上游读取降维战场摘要并产出战役级意图。
- 默认战争 AI 管线升级为：

```text
MarshalAgent
  -> MarshalBattlefieldSummarizer
  -> SimulatedMarshalLLMClient
  -> TheaterDirectiveDecoder
  -> TheaterDirectiveCompiler
  -> ZoneDirective
  -> WarCommandExecutor
  -> RuleEngine
```

- 新增 `TheaterDirectiveEnvelope` / `TheaterDirective` 作为 v0.5 LLM-facing JSON schema。
- 新增 `TheaterDirectiveDecoder`，支持 fenced JSON 提取、`JSONDecoder` 解码、schemaVersion / issuer / turn / faction / zone / region / tactic-category 校验。
- 新增 `SimulatedMarshalLLMClient`，只模拟 LLM 接口和 JSON 输出，不接真实网络、本地模型或云端 API。
- 新增 `TheaterDirectiveCompiler`，把元帅意图降级为现有 `ZoneDirective`；缺失或失败时 fallback 到 `TheaterCommanderPool`。
- `WarPipelineMode` 新增 `.marshalDirective`，`AppContainer` 和 `TurnManager` 默认使用该模式；旧 `.zoneDirective` 和 `.legacyAgentOrder` 仍保留为显式路径。
- `TurnManager` 抽出公共 `executeDirectiveEnvelope`，确保元帅链路和旧将军池链路共享同一执行、记录和 endTurn 逻辑。
- v0.5 收口时移除 v0.9 旁支曾插入的 `RulerAgent` 塑形调用；当前 `.marshalDirective` 与显式 `.zoneDirective` 都不写统治者记录，统治者仅作为后续上游预留。
- 新增实现记录文档，详细写明本分支算法、边界、fallback 和轻量验证。

关键系统：

- `WWIIHexV0/Commands/WarDirective.swift`
- `WWIIHexV0/Agents/ZoneCommanderAgent.swift`
- `WWIIHexV0/Turn/TurnManager.swift`
- `WWIIHexV0/Core/WarPipelineMode.swift`
- `WWIIHexV0/App/AppContainer.swift`
- `md/prompt/anti生成/v0.5/anti/0.50_v0.5_marshal_implementation_record.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `README.md`

验证记录：

- `git rev-parse --abbrev-ref HEAD`：`v0.5-marshal-decision-chain`。
- 轻量单文件语法检查通过：
  - `swiftc -parse WWIIHexV0/Commands/WarDirective.swift`
  - `swiftc -parse WWIIHexV0/Agents/ZoneCommanderAgent.swift`
  - `swiftc -parse WWIIHexV0/Turn/TurnManager.swift`
  - `swiftc -parse WWIIHexV0/App/AppContainer.swift`
  - `swiftc -parse WWIIHexV0/Core/WarPipelineMode.swift`
- `plutil -lint WWIIHexV0.xcodeproj/project.pbxproj`：OK。
- `jq empty` 已通过：
  - `WWIIHexV0/Data/ardennes_v02_regions.json`
  - `WWIIHexV0/Data/general_agents.json`
  - `WWIIHexV0/Data/generals.json`
  - `WWIIHexV0/Data/terrain_rules.json`
  - `WWIIHexV0/Data/unit_templates.json`
- 文档尾随空白扫描：无命中。
- 旧默认测试口径扫描（`AGENTS.md`、`md/flow/flow.md`）：无命中。
- Cabinet/Minister 旧污染源码扫描：无命中。
- v0.5 当前文档与 `TurnManager` 的 `RulerAgent` 默认接入残留扫描：无命中。
- `git diff --check`：通过，无输出。

未跑：

- 未跑 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full；原因是当前 `AGENTS.md` 与 `md/test/test.md` 规定默认只做轻量检查，且本轮用户明确禁止跑 Xcode。

备注：

- 本轮没有恢复历史回退的 `CabinetState`、`DirectiveBoard`、`MinisterDecisionProvider`、`RulerDirectiveFactory`、`national_cabinet.json` 或部长系统。
- 统治者层仅作为未来元帅上游预留方向，不在 v0.5 当前实现中落地。
- 当前工作树还存在不属于本 v0.5 核心目标的高级战术、外交、经济、UI 和地图编辑器方向未提交改动；v0.5 实现选择兼容现有工作树，不回滚其他改动。

## v0.8 - 初级经济、生产、城市、地形与补兵

完成日期：2026-07-04

目标分支：`codex/v0.8-economy-production`

分支审计：本轮早期创建 v0.8 分支曾因 `.git` 写入权限受限失败；期间当前 checkout 先后观察到其他版本分支，且工作树已有多批其他版本未提交改动。最终已通过受控审批成功创建 `codex/v0.8-economy-production`，但创建后仍观察到外部 checkout 漂移。因此本记录描述当前工作树中的 v0.8 经济系统实现，合并前必须重新确认当前分支、分支基点、文件级冲突、public API 冲突和 Xcode project 引用。

核心更新：

- 新增 `EconomyState`，建立 faction 级 manpower、industry、supplies 总账、生产队列、上回合收入/维护费/补员消耗。
- 新增 `EconomyRules`，从真实己方 hex 控制证据、region 城市、工厂、基础设施和补给值聚合收入。
- `GameState` 增加 `economyState`，旧存档缺失时 fallback `.empty`。
- `StrategicStateBootstrapper` 与 `RuleEngine` 在需要时 bootstrap 经济总账，保证旧状态第一次执行命令也有经济账本。
- `Command` 新增 `queueProduction(kind:)`，经 `CommandValidator` 检查 phase 和资源，经 `CommandExecutor` 调 `EconomyRules.queueProduction` 预付成本并入队。
- `CommandExecutor.executeEndTurn` 增加 active faction 经济结算：收入、战略补给维护费、短缺降级、自动补兵、生产队列推进和完成部署。
- 自动补兵只处理本阵营、未毁灭、未撤退、supplied、非敌邻、strength 未满的单位，每回合每单位最多恢复 2 strength，按兵种权重扣资源。
- 生产完成单位只能部署到本方控制、passable、空置、非敌邻，且位于首都、城镇/大都会、工厂、高基建、高补给 region 或 supply source 的后方 hex；找不到安全部署点时订单保留。
- `BaseTerrain`、`MovementRules`、`CombatRules` 增加地形加成：装甲进困难地形额外移动成本，装甲攻击平原加成，攻击困难地形惩罚，步兵在森林/城市/堡垒防御加成。
- 新增 `EconomyPanelView`，`RootGameView` 接入 Economy tab，`HUDView` 展示经济摘要，Region inspector 展示城市等级和经济产出。
- `project.pbxproj` 当前已有 `EconomyState.swift`、`EconomyRules.swift`、`EconomyPanelView.swift` 引用，未新增重复 UUID。
- 新增 v0.8 实现记录，详细写明规则算法、接入点、非目标、轻量检查和风险。

关键系统：

- `WWIIHexV0/Core/EconomyState.swift`
- `WWIIHexV0/Rules/EconomyRules.swift`
- `WWIIHexV0/Core/GameState.swift`
- `WWIIHexV0/Core/StrategicStateBootstrapper.swift`
- `WWIIHexV0/Commands/Command.swift`
- `WWIIHexV0/Rules/CommandValidator.swift`
- `WWIIHexV0/Rules/CommandExecutor.swift`
- `WWIIHexV0/Rules/RuleEngine.swift`
- `WWIIHexV0/Core/Terrain.swift`
- `WWIIHexV0/Rules/MovementRules.swift`
- `WWIIHexV0/Rules/CombatRules.swift`
- `WWIIHexV0/UI/EconomyPanelView.swift`
- `WWIIHexV0/UI/RootGameView.swift`
- `WWIIHexV0/UI/HUDView.swift`
- `WWIIHexV0/SpriteKit/MapDisplayAdapter.swift`
- `WWIIHexV0/UI/RegionInspectorView.swift`
- `md/prompt/anti生成/v0.8/anti/0.80_v0.8_economy_implementation_record.md`
- `md/prompt/anti生成/v0.8/anti/0.80_overall_analysis_report.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`

验证记录：

- 轻量 Swift parse 通过：
  - 核心规则集合，含 `EconomyState.swift`、`EconomyRules.swift`、`GameState.swift`、`Command.swift`、`CommandValidator.swift`、`CommandExecutor.swift`、`RuleEngine.swift`、`StrategicStateBootstrapper.swift`、`MovementRules.swift`、`CombatRules.swift` 等。
  - 核心规则集合 + `PlatformStyles.swift` + `EconomyPanelView.swift`。
  - 核心规则集合 + `MapDisplayAdapter.swift` + `PlatformStyles.swift` + `EconomyPanelView.swift` + `HUDView.swift` + `RegionInspectorView.swift`。
- `plutil -lint WWIIHexV0.xcodeproj/project.pbxproj`：通过。
- `jq empty WWIIHexV0/Data/ardennes_v02_regions.json`：通过。
- 改动文档尾随空白检查：通过。
- 旧默认测试口径残留检查：通过。

未跑：

- 未跑 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full / 性能测试；原因是当前规范和用户要求均禁止本轮主动跑 Xcode 与重测试。

备注：

- v0.8 不接真实 LLM 经济部长、不做完整商品价格网、不恢复 organization、不做空军/海军/战略轰炸/工厂损毁。
- `RegionDataSet.toRegions()` 仍有历史 fallback：owner/controller 缺失最终落到 `.allies`。v0.8 经济收入已加真实 hex 控制守卫，但数据层中立语义建议后续单独修。
- 当前 AI 不会主动排产；规则层已支持 active faction 通过统一 `Command` 排产，AI 经济策略留后续版本。

## v1.0 - UI / AI / 初版试玩收口

完成日期：2026-07-04

分支：`v1.0-ui-ai-playtest`

分支审计：续接收尾时当前 checkout 曾显示为 `v1.1-macos-main-game`，切回 `v1.0-ui-ai-playtest` 后又在轻量检查期间漂到 `v0.9-ruler-diplomacy` 和 `v0.5-marshal-decision-chain`。`v1.0-ui-ai-playtest` 分支已存在且与当前基线一致；交付前最后一次即时核对显示当前分支为 `v1.0-ui-ai-playtest`。由于当前工作树存在外部 checkout 漂移风险，合并前必须重新做分支与冲突审查。

核心更新：

- 创建并切换到 1.0 分支，围绕主游戏 UI、MockAI 行为、轻量性能和试玩记录做收口。
- `AgentPanelView` 接入 `WarDirectiveRecord`，AI tab 现在展示 zone、directive type、tactic、成功/拒绝命令数、目标 region 和 diagnostics。
- `EventLogView` 改为 `LogDisplayEntry` 展示模型，最近 60 条日志每条只计算一次分类，并补充 diplomacy 日志分类。
- `BoardScene.drawUnits` 缓存单位显示 hex 后排序，部署图层复用同一个 `WarDeploymentManager` 计算 role。
- `WarCommandExecutor` 开始解释 `AttackIntensity.infiltration`，无显式投入上限时限制默认投入单位数；佯攻/袭扰保留低投入策略。
- `PlatformStyles` 补充跨平台面板样式；Economy / Diplomacy 面板收口到跨平台背景和更可读字号。
- 新增 1.0 分支实现记录，写明 UI、性能、MockAI、试玩观察点、风险和未跑重测试原因。

关键系统：

- `WWIIHexV0/UI/PlatformStyles.swift`
- `WWIIHexV0/UI/RootGameView.swift`
- `WWIIHexV0/UI/AgentPanelView.swift`
- `WWIIHexV0/UI/EventLogView.swift`
- `WWIIHexV0/UI/EconomyPanelView.swift`
- `WWIIHexV0/UI/DiplomacyPanelView.swift`
- `WWIIHexV0/SpriteKit/BoardScene.swift`
- `WWIIHexV0/Commands/WarCommandExecutor.swift`
- `md/prompt/anti生成/v1.0/anti/1.00_v1.0_ui_ai_playtest_implementation_record.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`

验证记录：

- `git branch --show-current`：切回后曾返回 `v1.0-ui-ai-playtest`，但后续轻量检查期间又返回 `v0.9-ruler-diplomacy` 和 `v0.5-marshal-decision-chain`；分支漂移未完全消除。
- `plutil -lint WWIIHexV0.xcodeproj/project.pbxproj`：OK。
- `jq empty WWIIHexV0/Data/ardennes_v02_regions.json`：通过，无输出。
- `jq empty WWIIHexV0/Data/generals.json`：通过，无输出。
- `git diff --check`：通过，无输出。
- `rg -n "[[:blank:]]+$" AGENTS.md README.md update_log.md md/test/test.md md/flow/flow.md md/flow/flowchart.md md/prompt/anti生成/v1.0/anti/1.00_v1.0_ui_ai_playtest_implementation_record.md`：无命中。
- `rg -n "默认先跑|默认 Probe|Probe -> Smoke|Stage Regression -> Full|代码改动按 .*Probe" AGENTS.md md/flow/flow.md`：无命中。
- 冲突标记扫描（AGENTS.md、README.md、update_log.md、md/flow、WWIIHexV0、MapEditor）：无命中。

未跑：

- 未跑 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full / 性能测试；原因是 `AGENTS.md`、`md/test/test.md` 和用户要求均禁止本轮主动跑重测试。

备注：

- 本轮并发子 agent 中 UI 只读定位完成，AI / 性能子 agent 因外部 503 失败，主线程接回实现。
- 当前工作树仍含 v0.5 / v0.7 / v1.1 等方向未提交改动，合并前必须做文件级、public API、schema、Xcode project 和文档口径冲突审查。

## v0.9 - 统治者、多国家、阵营集团与初步外交状态

完成日期：2026-07-04

分支：`v0.9-ruler-diplomacy`

核心更新：

- 新增 `DiplomacyState`，在 `GameState` 中保存国家、阵营集团、国家间外交关系和统治者决策记录。
- 新增 `CountryProfile`、`DiplomaticBloc`、`DiplomaticRelation`、`DiplomaticStatus`、`RulerStrategicPosture`、`RulerDecisionRecord` 等数据结构。
- 开局外交种子：
  - Germany 规则阵营：`German Reich`，`Axis`，`ruler_germany`。
  - Allies 规则阵营：`United States`、`United Kingdom`、`Belgium`，`Allied Coalition`，主统治者 `ruler_allies`。
  - 同阵营关系为 `allied`，跨阵营关系为 `atWar`。
- 新增 `RulerAgent`：读取外交、前线、部署、历史战争指令记录，生成 `RulerStrategicSnapshot`，选择 `offensive` / `defensive` / `coalitionMaintenance` / `stabilizeFront` 姿态。
- `RulerAgent` 只塑形 `DirectiveEnvelope`：
  - offensive：攻击强度提升为 `allOut`，按 region priority 重排目标。
  - defensive：攻击 directive 转为 `holdLine` 防御 directive。
  - coalitionMaintenance：提高防御预备队。
  - stabilizeFront：降低 `allOut` 为 `limitedCounter`，或采用 `flexible` 防御。
- `TurnManager` 在 `.marshalDirective` 与显式 `.zoneDirective` 路径中执行 `applyRuler`，写入 `RulerDecisionRecord` 和 `.diplomacy` 日志后，再交给 `WarCommandExecutor -> RuleEngine`。
- `DataLoader` 和 `StrategicStateBootstrapper` 会为新局或旧存档补齐外交状态。
- 新增 `DiplomacyPanelView`，`RootGameView` 增加 `Diplomacy` 面板，`AgentPanelView` 展示最近统治者 posture / focus。
- `GameLogCategory` 新增 `diplomacy`。
- 修复 `RulerStrategicSnapshot` 静态去重调用；修复 `hostileCountryIds(to:)` 在多盟友共享同一敌国时重复计数的问题。
- 新增 v0.9 实现记录，详细写明本分支算法、边界、冲突情况和未跑重测试原因。

关键系统：

- `WWIIHexV0/Core/DiplomacyState.swift`
- `WWIIHexV0/Agents/RulerAgent.swift`
- `WWIIHexV0/Core/GameState.swift`
- `WWIIHexV0/Core/StrategicStateBootstrapper.swift`
- `WWIIHexV0/Data/DataLoader.swift`
- `WWIIHexV0/Core/GameLogEntry.swift`
- `WWIIHexV0/Turn/TurnManager.swift`
- `WWIIHexV0/UI/DiplomacyPanelView.swift`
- `WWIIHexV0/UI/AgentPanelView.swift`
- `WWIIHexV0/UI/RootGameView.swift`
- `WWIIHexV0.xcodeproj/project.pbxproj`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `README.md`
- `md/prompt/anti生成/v0.9/anti/0.90_v0.9_ruler_diplomacy_implementation_record.md`

验证记录：

- `git branch --show-current`：`v0.9-ruler-diplomacy`。
- `plutil -lint WWIIHexV0.xcodeproj/project.pbxproj`：OK。
- `jq empty WWIIHexV0/Data/ardennes_v02_regions.json`：通过，无输出。
- `jq empty WWIIHexV0/Data/generals.json`：通过，无输出。
- `rg -n "[[:blank:]]+$" AGENTS.md README.md update_log.md md/test/test.md md/flow/flow.md md/flow/flowchart.md md/prompt/anti生成/v0.9/anti/0.90_v0.9_ruler_diplomacy_implementation_record.md`：无命中。
- `rg -n "默认先跑|默认 Probe|Probe -> Smoke|Stage Regression -> Full|代码改动按 .*Probe" AGENTS.md md/flow/flow.md`：无命中。
- 冲突标记扫描（README.md、update_log.md、md/flow、v0.9 实现记录与相关 Swift 文件）：无命中。
- `swiftc -parse WWIIHexV0/Core/DiplomacyState.swift WWIIHexV0/Agents/RulerAgent.swift WWIIHexV0/UI/DiplomacyPanelView.swift`：通过，无输出。

未跑：

- 未跑 Xcode / XCTest / 模拟器 / app 启动 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full；原因是当前规范与本轮用户要求均禁止主动跑 Xcode 和重测试。

备注：

- 本轮尝试把国家/外交、AI 管线、文档三块拆给子 Agent 并行，但子 Agent 调用返回 503，没有可用产物；最终由主 Agent 在当前分支内完成实现和整合。
- 当前工作树已有 v0.5 元帅层、经济层、v1.1 macOS target、地图编辑器和 UI 等未提交改动；v0.9 选择兼容当前源码，不回滚其他改动。合并前仍需做文件级冲突审查。
- 多国家当前是战略身份层，底层规则阵营仍是 `Faction.germany` / `Faction.allies`。后续若要国家级参战、中立、投降、宣战或外交行动，需要先设计国家级权限和命令入口。

## v1.1 - 主游戏 macOS target

完成日期：2026-07-04

分支：`v1.1-macos-main-game`

核心更新：

- 新增独立主游戏 macOS app target `WWIIHexV0Mac`，区别于既有 iOS 主游戏 target `WWIIHexV0` 和地图编辑器 target `MapEditorMac`。
- 新增 macOS 主入口 `WWIIHexV0MacApp`，复用 `AppContainer.bootstrap()` 与 `RootGameView(container:)`，默认窗口 1440x900，最小内容区域 1200x760。
- `WWIIHexV0Mac` resource phase 接入主游戏默认 JSON：`ardennes_v0_scenario.json`、`ardennes_v02_regions.json`、`general_agents.json`、`generals.json`、`terrain_rules.json`、`unit_templates.json`。
- `BoardSceneView` 增加 macOS `NSViewRepresentable` 分支，用 `BoardEventSKView` 承载 `BoardScene`，iOS 继续使用 `UIViewRepresentable` 分支。
- `BoardScene` 增加 macOS 鼠标点击、拖拽平移、滚轮/触控板缩放；点击仍只回调 `onHexTapped`，后续由 `AppContainer.handleBoardTap -> RuleEngine` 处理。
- 新增 `PlatformStyles`，将主游戏 UI 的 `Color(.systemBackground)` / `Color(.tertiarySystemBackground)` 替换为 iOS/macOS 条件背景色。
- 因当前工作树已有经济、外交、统治者、将领 registry 等源码引用，`project.pbxproj` 同步把这些已被引用的支持文件和 `generals.json` 接入相关 target phase，但本轮不改这些业务逻辑。
- 新增 v1.1 实现记录，详细写明 target 设计、输入桥接算法、资源加载、轻量检查和风险。

关键系统：

- `WWIIHexV0.xcodeproj/project.pbxproj`
- `WWIIHexV0/App/WWIIHexV0MacApp.swift`
- `WWIIHexV0/SpriteKit/BoardScene.swift`
- `WWIIHexV0/SpriteKit/BoardSceneView.swift`
- `WWIIHexV0/UI/PlatformStyles.swift`
- `WWIIHexV0/UI/RootGameView.swift`
- `md/prompt/anti生成/v1.1/anti/1.10_v1.1_macos_main_game_implementation_record.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `README.md`

验证记录：

- `plutil -lint WWIIHexV0.xcodeproj/project.pbxproj` 通过。

未跑：

- 未跑 Xcode / XCTest / 模拟器 / macOS app 启动 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full；原因是当前规范与用户要求均禁止本轮主动跑 Xcode 和重测试。

备注：

- v1.1 是平台承载和输入桥接分支，不改变 `Command` / `ZoneDirective` / `WarCommandExecutor` / `RuleEngine` 规则权威链路。
- 当前工作树存在多条其他方向的未提交改动；v1.1 选择兼容当前源码引用并记录风险，不回滚其他人改动。

## v0.7 - 高级战术与命令扩展

完成日期：2026-07-04

目标分支：`v0.7-tactical-upgrade`

分支审计：本轮曾创建并切换到 `v0.7-tactical-upgrade`，但连续接力时当前 checkout 多次显示为其他分支，且工作树已有多批 v0.5 / v1.0 / v1.1 / UI / 经济 / 外交方向未提交改动。按项目规则，本轮未回滚这些改动；合并前必须重新确认分支归属和文件级冲突。

核心更新：

- `TacticName` 扩展为进攻 8 类、防御 4 类：
  - 进攻：`standardAttack`、`blitzkrieg`、`spearhead`、`breakthrough`、`pincerMovement`、`fireCoverage`、`feint`、`guerrillaWarfare`。
  - 防御：`holdPosition`、`elasticDefense`、`defenseInDepth`、`lastStand`。
- `AttackParameters` 新增 `focusRegionId`、`supportRegionIds`、`convergenceRegionId`、`coordinatedZoneIds`、`maxCommittedUnits`、`exploitDepth`，支持定点突破、钳形会师、投入上限和纵深目标意图。
- `DefenseParameters` 新增 `fallbackRegionIds`、`counterattackRegionIds`、`strongpointRegionIds`、`maxFrontCommitment`，支持弹性防御、纵深防御和死守口径。
- `TheaterDirective` 新增 `convergenceRegionId` / `coordinatedZoneIds`，并补自定义 decode，旧 JSON 缺字段时仍兼容。
- `TheaterDirectiveDecoder` 校验 convergence region 和 coordinated zone 存在性，继续校验 tactic/category 一致性。
- `BinaryTacticClassifier` 从二元分类升级为读取兵力比、机动兵力、炮兵支援、纵深预备队、压力和补给警告的战术分类器。
- `TacticConditionChecker` 从恒 true 改为按战术最低条件放行：机动战术要求机动单位，火力覆盖要求炮兵/远程单位，佯攻要求前线单位，纵深防御要求 depth 预备队。
- `WarCommandExecutor` 新增 `AttackTacticProfile`，按战术控制单位来源、机动优先、炮兵优先、只攻击不推进、弱点聚焦、深目标候选、非矛头单位 hold 和投入上限。
- 定点突破弱点评分落地：

```text
enemyStrength 越低越优先
terrain.movementCost 越低越优先
region 内有 road 越优先
city.victoryPoints + supplyValue + factories 越高越优先
guerrillaWarfare 额外参考 infrastructure
```

- `defenseInDepth` 新增独立执行路径：一线 `allowRetreat`，保留预备队，其余 depth 机动单位尝试反击，否则向 fallback / strongpoint 防御地形移动。
- `fireCoverage` 落地为炮兵/远程优先、能打则打、无目标则 hold，不主动推进。
- `feint` 落地为少量前线单位牵制，默认约 1/3 前线投入。
- `blitzkrieg` / `spearhead` 落地为机动优先、集中弱点、可使用 depth 单位，非矛头前线单位 hold。
- `pincerMovement` 落地为 convergence / coordinated 数据层和单 zone 执行器 profile；多 zone 会师由元帅层或人工下发多条 directive，包围效果交给动态战区/前线/补给派生。
- `MockAICommander` 保留新增 attack 参数，避免 allOut 包装时丢失 focus/convergence/coordinated 字段。
- 新增 v0.7 实现记录文档，详细写明算法、边界、冲突风险和轻量检查口径。

关键系统：

- `WWIIHexV0/Commands/WarDirective.swift`
- `WWIIHexV0/Commands/WarCommandExecutor.swift`
- `WWIIHexV0/Agents/ZoneCommanderAgent.swift`
- `WWIIHexV0/Agents/MockAICommander.swift`
- `md/prompt/anti生成/v0.7/anti/0.70_v0.7_tactical_upgrade_implementation_record.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/flow/03_ai_zone_directive_pipeline.mermaid`
- `README.md`

验证记录：

- 轻量单文件语法检查通过：
  - `swiftc -parse WWIIHexV0/Commands/WarDirective.swift`
  - `swiftc -parse WWIIHexV0/Commands/WarCommandExecutor.swift`
  - `swiftc -parse WWIIHexV0/Agents/ZoneCommanderAgent.swift`
  - `swiftc -parse WWIIHexV0/Agents/MockAICommander.swift`

未跑：

- 未跑 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full；原因是当前 `AGENTS.md` 与 `md/test/test.md` 规定默认只做轻量检查，且本轮用户明确禁止跑 Xcode。

遗留风险：

- 未做运行时战局验证，战术效果和 AI 行为只通过源码与轻量 parse 检查确认语法层可用。
- 当前工作树混有其他版本改动，合并前必须做文件/API/schema/文档冲突检查。

## v0.4 - 将军养成初步、将军 UI 与玩家双轨命令

完成日期：2026-07-04

目标分支：`v0.4-generals-command-ui-final`

分支审计：本轮从一个已混入 v0.9 / v0.5 / v1.x 外部未提交改动的工作树创建 0.4 续作分支。期间 checkout 又被外部切到 `codex/v0.8-economy-production`，最终已重新固定到 `v0.4-generals-command-ui-final`。按项目规则，本轮没有回滚外部改动；只在当前分支继续补齐 0.4 将军和玩家命令链路。合并前必须重新审查 project、public API、JSON schema 和文档口径冲突。

核心更新：

- 新增实体将军数据链：`generals.json`、`GeneralData`、`GeneralRegistry`、`GeneralDispatcher`。
- `RegionNodeDefinition` / MapEditor region draft 支持 `assignedGeneralId`，默认阿登 region JSON 已给蒙哥马利、魏刚、古德里安、里布写入初始种子。
- `FrontZone` 增加 `generalAssignment`，记录将军 id、HQ region、辖下 division、忠诚、满意度和玩家干预次数。
- `WarDeploymentState.preservingGeneralAssignments` 与 AppContainer 刷新逻辑保留/补齐将军分配，避免部署层重建后将军丢失。
- `TheaterCommanderPool` 在 AppContainer 构造时可由 `GeneralDispatcher.commanderPool` 使用真实将军配置，缺失时仍 fallback 到自动 commander。
- 新增 `PlayerCommandState` 和 `PlayerPlannedOperation`，保存本回合微操锁和玩家战区计划。
- 玩家微操 move/attack/hold/resupply/allowRetreat 成功后锁定该师，降低所属将军满意度并增加干预次数；结束回合或阵营/回合变化时清空锁。
- `WarCommandExecutor.execute` 新增兼容参数 `excluding excludedDivisionIds`，在进攻、防御、纵深防御和非矛头 hold 阶段跳过玩家微操部队。
- `AppContainer` 新增玩家宏观将军命令：`Hold Line` 生成 defense `ZoneDirective`，`Attack Region` 根据当前选中敌方 region 和相邻玩家 FrontZone 生成 attack `ZoneDirective`，执行后不自动结束回合。
- 新增 `GeneralCommandPanelView` 与 `GeneralProfileView`，展示将军头像占位、军衔、风格、技能、履历、忠诚/满意度、HQ 状态、辖下部队和计划操作。
- `RootGameView` 新增 `General` tab，Unit tab 也嵌入将军命令面板。
- `BoardScene` 根据 `PlayerPlannedOperation` 画进攻箭头/防御圆环，`UnitNode` 对本回合玩家微操单位画金色圈。
- `WarDirectiveRecord` 记录玩家宏观指令结果，AI 面板与日志可继续共用同一复盘数据。

关键系统：

- `WWIIHexV0/Data/generals.json`
- `WWIIHexV0/Agents/GeneralRegistry.swift`
- `WWIIHexV0/Core/GeneralAssignment.swift`
- `WWIIHexV0/Core/PlayerCommandState.swift`
- `WWIIHexV0/Core/FrontZone.swift`
- `WWIIHexV0/Core/WarDeploymentState.swift`
- `WWIIHexV0/Data/DataLoader.swift`
- `WWIIHexV0/Data/RegionDataSet.swift`
- `MapEditor/MapEditorDocument.swift`
- `MapEditor/MapEditorExporter.swift`
- `MapEditor/MapEditorGameResourceBridge.swift`
- `WWIIHexV0/App/AppContainer.swift`
- `WWIIHexV0/Commands/WarCommandExecutor.swift`
- `WWIIHexV0/UI/GeneralCommandPanelView.swift`
- `WWIIHexV0/UI/GeneralProfileView.swift`
- `WWIIHexV0/UI/RootGameView.swift`
- `WWIIHexV0/SpriteKit/BoardScene.swift`
- `WWIIHexV0/SpriteKit/UnitNode.swift`
- `WWIIHexV0.xcodeproj/project.pbxproj`
- `md/prompt/anti生成/0.4/v0.4_generals_command_ui_branch_record.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`

验证记录：

- `jq empty WWIIHexV0/Data/generals.json` 通过。
- `jq empty WWIIHexV0/Data/ardennes_v02_regions.json` 通过。
- `plutil -lint WWIIHexV0.xcodeproj/project.pbxproj` 通过，输出 `OK`。
- `git diff --check` 通过。
- 文档尾随空白检查无匹配。
- 单文件轻量 parse 通过：`PlayerCommandState.swift`、`GeneralAssignment.swift`、`GeneralRegistry.swift`、`GeneralCommandPanelView.swift`、`GeneralProfileView.swift`、`WarCommandExecutor.swift`、`AppContainer.swift`、`BoardScene.swift`、`UnitNode.swift`、`RootGameView.swift`。

未跑：

- 未跑 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full；原因是当前 `AGENTS.md`、`md/test/test.md` 和用户要求均禁止本轮主动跑 Xcode 与重测试。

遗留风险：

- 未做运行时 UI 点击和 SpriteKit 视觉验证，按钮行为、sheet 展示、计划线位置仍需后续人工或授权轻量运行确认。
- 当前工作树混有其他版本改动，合并前必须重新做文件/API/schema/project 冲突审查。

## 历史维护记录

以下提交不作为正式 v 版本，但影响项目资料完整性：

- 2026-07-07：v4.6/v4.7 明末主入口与阶段显示去调试口径小片落地：`RootGameView` 底部抽屉入口从“信息”改为“军情”，accessibility 文案同步为军情面板；紧凑信息面板里的“目标”tab 改为“国势”，`BattleObjectivePanelView` 的“目标线”指标改为“胜负线”；`GamePhase.displayName` 对 legacy `.germanAI` / `.alliedPlayer` 兼容阶段与通用 `.aiAction` / `.humanAction` 统一显示“军机行动 / 玩家行令”，避免默认明末 UI、HUD、军令牌、日志或复盘继续出现 `Legacy` 前缀的阶段调试口径。该片只影响显示层文案，不改变 `GamePhase` raw value、Codable 兼容、`GamePhase.allowsHumanCommands`、`turnOrder`、AI 控制方、目标摘要、胜负判定、命令校验、回合推进、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威；并发子 Agent Lagrange、Raman 分别只读探查低风险 UI 文案候选和文档同步范围，主线程采纳主入口/阶段显示小切片，并同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。

- 2026-07-07：v4.6/v4.7 明末府库牌“民食灾荒”只读小片落地：`EconomyPanelView` 在“经世策眼”后新增“民食灾荒”区，从现有 `FactionEconomyLedger`、`GovernanceAISummary` 和当前势力未毁 `Division.supplyState` 只读派生民食余势、本旬粮差、不稳州府、缺粮军伍与断粮被围军伍，让钱粮面板能把库存粮、军粮维护、补员耗粮、地方民变/行政和军伍补给联读成灾荒风险提示。该片只影响 SwiftUI 展示，不新增 `EconomyState`、region、灾荒、民心、军饷、士气或事件字段，不写塘报，不触发生产、朝廷项目、AI 或命令，不改变 `Command.queueProduction`、`Command.enactCourtProject`、`EconomyRules`、`CommandValidator`、`WarCommandExecutor`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。

- 2026-07-07：v4.7 明末 Agent 州府名可读化 polish 小片落地：`RegionId` 新增只读 `mingDisplayTitle`，供明末 `AgentPromptBuilder` 的目标/军伍/邻接州府摘要、`GovernanceAISummary.displaySummary` 的最低行政州府和 `MockAIClient` 的前线接敌/固守理由显示“开封、山海关、武昌”等州府名，避免军机 prompt 和 MockAI 案卷继续直出 `region_*` raw id；legacy 德/盟 prompt、MockAI 理由与阿登/Bastogne 回归文案保持原口径。该片只改变 Agent / UI 可读文本，不改变 `RegionId.rawValue`、Codable schema、地图数据、AI 决策结构、`Command`、`ZoneDirective`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.7_ming_ai_doctrine_record.md`。

- 2026-07-07：v4.7 明末模拟元帅军机文案 polish 小片落地：`SimulatedMarshalLLMClient` 在明末势力下把默认元帅 `strategicIntent`、每条 `TheaterDirective.rationale` 和结果 envelope 摘要改成军机/督师中文口径，`TheaterDirectiveCompiler` 的编译摘要改为“已编成 N 道防区军令”，`MarshalAgent.resolve` 的势力不匹配与解码/编成失败 fallback 诊断也改为明末中文，避免军机复盘中出现 `Simulated marshal JSON`、`Compiled zone directive(s)`、`Fallback TheaterCommanderPool used` 等调试文案；legacy 德/盟分支保留英文诊断用于阿登回归。该片只改变 `TheaterDirectiveEnvelope.summary`、`TheaterDirective.rationale`、`DirectiveEnvelope.theaterContext` 和 `MarshalDirectiveResolution.diagnostics` 的可读文本，不改变 JSON schema、decoder、compiler 选择、fallback 执行、`ZoneDirective`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.7_ming_ai_doctrine_record.md`。

- 2026-07-07：v4.6/v4.7 明末舆图点验“四线粮道部队联判”小片落地：`RootGameView` 顶部只读“舆图点验”在原有格位、方面、防区、要冲 chip 外新增“四线 / 粮道 / 部队”三枚 chip，继续读取现有 `selectedRegionInspectorState`，并只读 `BattleObjectiveSummary.lineBriefs`、选中 `Division` 和粮道显示开关，展示最急五线、军粮状态、路线显隐、兵力和可调/已行，让地图第一视野能直接联读中华世界局势、政策/经济/科技/军事压力、粮道和当前军牌兵势。该片只影响 SwiftUI 展示，不新增 `GameState`、`RegionInspectorState`、目标、任务、粮道、AI 或命令字段，不新增按钮，不触发目标定位，不写塘报，不提交命令，不改变 `BattleObjectiveSummary`、`Division`、`SupplyRules`、`MapDisplayAdapter`、hex/region/theater/front/deploy、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何规则权威；按 cavecrew 分工规则评估后，当前工具面板未暴露新建子 Agent 调用，主线程采用并行只读文件探查完成小片，并同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。

- 2026-07-06：v4.7 明末 Agent prompt / MockAI 粮草文案 polish 首片落地：`AgentPromptBuilder` 在明末势力下把部队摘要和总体补给摘要中的粮草状态从 `SupplyState.rawValue` 改为“有粮 / 缺粮 / 断粮被围”，`MockAIClient` 的明末整粮与前线回粮理由也改用同一口径，避免军机案卷和本地 LLM prompt 直出 `lowSupply`、`encircled` 等调试值；legacy 德/盟分支继续保留英文 raw 值和 Bastogne / v0.33 deployment 回归文案。该片只影响 legacy Agent D / 本地 LLM 预留 prompt 和模拟 AI 可读理由，不改变 `AgentDecisionEnvelope`、`AgentOrder`、parser、mapper、`Command`、`ZoneDirective`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.7_ming_ai_doctrine_record.md`。

- 2026-07-06：v4.8 明末发布候选“自动保存与继续战局”首片落地：`AppContainer` 新增本机 `SavedGameSnapshot(schemaVersion, savedAt, state)` 单槽存档 envelope，玩家底层命令成功、玩家将令提交和 AI 回合结算后会自动保存完整 `GameState`；HUD 的“战局”菜单和 macOS “战局”菜单可继续最近战局，新开战局会清除旧存档；AI 异步回合增加 run token，避免续战或新局后旧 task 回写当前局。该片只保存/恢复规则权威 `GameState`，续战会重建将领分配并清空选中态、高亮、信息面板、图层开关和临时交互日志，不新增多存档槽、云同步、设置面板或存档迁移器，不改变 `Command`、`ZoneDirective`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine`、胜负、经济、AI 决策或任何 hex/region/theater/front/deploy 权威。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和新增 `v4.8_ming_release_candidate_record.md`。本机尝试 `swiftc -parse WWIIHexV0/App/AppContainer.swift WWIIHexV0/UI/NewGameButton.swift WWIIHexV0/UI/HUDView.swift WWIIHexV0/UI/RootGameView.swift WWIIHexV0/App/WWIIHexV0MacApp.swift`，但当前环境缺少 `swiftc`，未完成 Swift parse；本轮仍未做本机 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full 或运行时续战验收。

- 2026-07-07：v4.6 明末州府牌“本州入局”小片落地：`RegionInspectorView` 在“州府主值”后新增只读“本州入局”区，从现有 `RegionInspectorState`、`RegionNode` 和 `OccupationState` 派生要冲入局、接敌入局、地方入局、经略入局或后方入局总批，并用天下、政粮、军械三枚 chip 联读州府控制归属、目标/前线、民变行政、钱粮、粮台、工坊、驿道和友敌军，让玩家点选州府后更快理解该地为什么牵动中华世界局势、政策、经济、科技和军事。该片只影响 SwiftUI 展示，不新增 `GameState`、`RegionInspectorState`、州府、目标、朝廷、经济、AI 或命令字段，不触发目标定位，不写塘报，不提交命令，不改变 `MapDisplayAdapter`、`RegionNode`、hex/region/theater/front/deploy、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何规则权威；并发子 Agent Aristotle 只读探查州府牌并建议同类州府天下判读切片，Archimedes 只读探查舆图联判候选留作后续，主线程采纳单文件州府牌小片，并同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。

- 2026-07-07：v4.6/v4.7 明末军令牌“要冲军令落点现势与朝议四线”小片落地：`CommandPanelView` 的只读“要冲军令”区继续读取现有 `BattleObjectiveSummary.tasks`、`lineBriefs` 和 `tracks.targets`，把目标落点从泛用提示升级为目标名、胜负线、现控制方和要冲分，并新增只读“朝议四线”压力 chip，展示政策、经济、科技、军事四线的状态、压力和急务/任务数，让玩家在军令牌内联读中华世界局势、目标现势、本军兵势和军政钱粮火器压力。该片只影响 SwiftUI 展示，不新增 `GameState`、任务、目标、朝廷、经济、AI 或命令字段，不新增按钮，不触发目标定位，不写塘报，不提交命令，不改变 `BattleObjectiveSummary`、`VictoryRules`、`CourtStrategySummary`、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威；并发子 Agent Singer、Noether 只读探查州府牌和军令牌候选，主线程采纳无需改调用链的军令牌小切片，并同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。

- 2026-07-06：v4.7 明末目标面板“国势四策”首片落地：`BattleObjectivePanelView` 在目标面板 header 后新增只读“国势四策”区，从 `BattleObjectiveSummary`、当前势力 `CourtStrategySummary` 和 `FactionEconomyLedger` 派生政策、经济、科技、军事四张扫读牌，展示要冲分领先方、朝议主议/备议、府库银粮、火器攻城军、前线压力和最急经济/军事提示，让“目标”tab 第一屏直接联读中华世界局势、胜负目标、朝廷四线取舍和府库兵势。该片只影响 SwiftUI 展示，不新增 `GameState`、胜负、任务、目标、塘报、AI、朝廷、经济、科技或军事规则字段，不新增按钮，不自动定位目标，不执行朝廷项目，不写塘报，不提交命令，不改变 `BattleObjectiveSummary`、`CourtStrategySummary`、`EconomyRules`、`VictoryRules`、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.7_ming_victory_record.md`。本机轻量检查通过：`swiftc -parse WWIIHexV0/UI/BattleObjectivePanelView.swift`、`git diff --check`、文档/Swift 尾随空白扫描、行首冲突标记扫描、旧默认测试口径扫描；本轮仍未做本机 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full 或截图验收。

- 2026-07-06：v4.6/v4.7 明末朝报令条“朝报要冲”首片落地：`HUDView` 从 `BattleObjectiveSummary.from(state:)` 派生只读“朝报要冲”，读取 `leadingFaction`、`scoreRows`、`lineBriefs`、`tasks` 和 `tracks.targets`，展示棋势领先方、最急天下五线、本旬任务、目标城关与当前控制方，让玩家进入地图第一屏时即可看到中华世界局势、胜负目标和政策/经济/科技/军事压力。该片只影响 SwiftUI 展示，不新增 `GameState`、胜负、任务、目标、AI、朝廷、经济、科技或军事规则字段，不新增按钮，不自动定位目标，不写塘报，不提交命令，不改变 `BattleObjectiveSummary`、`VictoryRules`、`CourtStrategySummary`、朝廷项目、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。本机轻量检查通过：`swiftc -parse WWIIHexV0/UI/HUDView.swift`、`git diff --check`、文档/Swift 尾随空白扫描、行首冲突标记扫描、旧默认测试口径扫描；本轮仍未做本机 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full 或截图验收。

- 2026-07-06：v4.6/v4.7 明末天下局势“天下棋势”首片落地：`RootGameView` 向 `DiplomacyPanelView` 注入 `BattleObjectiveSummary.from(state:)`，天下面板新增只读“天下棋势”区，展示要冲分领先方、最急天下五线、本旬落点和明廷、后金/清、大顺、大西等势力的 objective points / 控制要冲数，让“天下”tab 直接联读中华世界局势、胜负目标、政策/经济/科技/军事压力和当旬落点。该片只影响 SwiftUI 展示，不新增 `GameState`、外交、胜负、任务、目标、AI、朝廷或经济字段，不新增按钮，不自动定位目标，不写塘报，不提交命令，不改变 `DiplomacyState`、`BattleObjectiveSummary`、`VictoryRules`、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。

- 2026-07-06：v4.6/v4.7 明末将领面板“督师要冲”首片落地：`RootGameView` 向 `GeneralCommandPanelView` 注入 `BattleObjectiveSummary.from(state:)` 与 `MapState`，将印军令新增只读“督师要冲”区，展示当前最高优先级本旬任务、目标落点、现控制方、要冲分、麾下最近未溃军伍到目标 objective 的相距格数、可调营数、火器攻城和粮道状态，让督师/总兵面板直接联读中华世界局势、本旬军事落点和麾下兵势。该片只影响 SwiftUI 展示，不新增 `GameState`、任务、目标、将领、AI、朝廷或经济字段，不自动定位目标，不写塘报，不提交命令，不改变 `GeneralData`、`GeneralAssignment`、`FrontZone`、`Division`、`BattleObjectiveSummary`、`MapState`、`VictoryRules`、`WarDeploymentState`、`Command`、`ZoneDirective`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。

- 2026-07-06：v4.6/v4.7 明末部队军情牌要冲牵引首片落地：`RootGameView` 向 `UnitInspectorView` 注入 `BattleObjectiveSummary.from(state:)` 与 `MapState`，部队军情牌新增只读“要冲牵引”区，展示当前最高优先级本旬任务、目标落点、现控制方、选中部队到 objective 的相距格数和本军兵势说明，让玩家在部队详情里直接联读中华世界局势、本旬军事落点和该军战备。该片只影响 SwiftUI 展示，不新增 `GameState`、任务、目标、AI、朝廷或经济字段，不自动定位目标，不写塘报，不提交命令，不改变 `Division`、`BattleObjectiveSummary`、`MapState`、`VictoryRules`、`WarDeploymentState`、`CombatRules`、`SupplyRules`、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。本机轻量检查通过：`swiftc -parse WWIIHexV0/UI/UnitInspectorView.swift`、`swiftc -parse WWIIHexV0/UI/RootGameView.swift`、`git diff --check`、文档/Swift 尾随空白扫描、行首冲突标记扫描、旧默认测试口径扫描；本轮仍未做本机 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full 或截图验收。

- 2026-07-06：v4.6/v4.7 明末舆图军牌要冲牵引首片落地：`RootGameView` 向 `UnitTooltipView` 注入 `BattleObjectiveSummary.from(state:)` 与 `MapState`，舆图军牌浮签新增只读“要冲牵引”区，展示当前最高优先级本旬任务、目标落点和选中部队到目标 objective 的 hex 距离，并把该信息并入可访问性说明，让玩家在地图点选部队时直接联读中华世界局势、本旬落点和本军位置。该片只影响 SwiftUI 展示，不新增 `GameState`、任务、目标、AI、朝廷或经济字段，不自动定位目标，不写塘报，不提交命令，不改变 `Division`、`BattleObjectiveSummary`、`MapState`、`VictoryRules`、`WarDeploymentState`、`CombatRules`、`SupplyRules`、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。本机轻量检查通过：`swiftc -parse WWIIHexV0/UI/UnitTooltipView.swift`、`swiftc -parse WWIIHexV0/UI/RootGameView.swift`、`git diff --check`、文档/Swift 尾随空白扫描、行首冲突标记扫描、旧默认测试口径扫描；本轮仍未做本机 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full 或截图验收。

- 2026-07-06：v4.6 明末舆图军牌军位首片落地：`RootGameView` 将现有 `selectedUnitInspectorStrategicState` 注入 `UnitTooltipView`，舆图军牌浮签新增只读“军位”区，展示动态方面、防区和前线/纵深/驻防部署角色，让玩家在地图上点选部队时不打开详情面板也能扫读该军所属方面、防区和布防位置。该片只影响 SwiftUI 展示，不新增 `GameState` 字段，不改变 `UnitInspectorStrategicState`、`Division`、`WarDeploymentState`、`CombatRules`、`SupplyRules`、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。本机轻量检查通过：`swiftc -parse WWIIHexV0/UI/UnitTooltipView.swift`、`swiftc -parse WWIIHexV0/UI/RootGameView.swift`、`git diff --check`、文档/Swift 尾随空白扫描、行首冲突标记扫描、旧默认测试口径扫描；本轮仍未做本机 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full 或截图验收。

- 2026-07-06：v4.6/v4.7 明末舆图点验首片落地：`RootGameView` 在顶部 `MingMapSituationStrip` 后新增只读“舆图点验”，从现有 `selectedRegionInspectorState` 派生选中格位/州府、控制方旗号、动态方面、防区、友敌军、要冲和前线压力，让玩家点选 hex、部队或目标后能在地图第一视野直接看见该点的战局归属。该片只强化 SwiftUI 展示，不新增 `GameState`、地图、胜负、任务、目标、塘报、AI、朝廷或经济字段，不新增按钮，不提交命令，不写塘报，不改变 `RegionInspectorState`、`MapDisplayAdapter`、`BattleObjectiveSummary`、`VictoryRules`、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威。并发子 Agent Kant、Russell 只读探查舆图点验和部队浮签候选，均建议优先采纳 `RootGameView` 舆图点验；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。

- 2026-07-06：v4.6 明末州府四线牵引首片落地：`RegionInspectorView` 在“州府主值”后新增只读“州府四线牵引”，从现有 `RegionInspectorState`、`RegionNode`、`OccupationState`、钱粮产出、目标、友敌军和前线压力派生政策、经济、科技、军事四格，显式展示民变/行政、民力/银两/粮台、工坊/驿道和前线/目标/友敌军，让州府牌更直接承接中华世界局势、地方治理、钱粮军械和军事压力。该片只强化 SwiftUI 展示，不新增 `RegionInspectorState` 字段，不改变 `RegionNode` schema、hex 控制、region 聚合、经济结算、动态战区、前线、部署、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何规则权威。并发子 Agent Nietzsche、Mendel 分别只读探查州府四线和舆图点验候选，主线程采纳州府四线小切片；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。本机轻量检查通过：`swiftc -parse WWIIHexV0/UI/RegionInspectorView.swift`、`git diff --check`、文档/Swift 尾随空白扫描、行首冲突标记扫描、旧默认测试口径扫描；本轮仍未做本机 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full 或截图验收。

- 2026-07-06：v4.6 明末将领面板“帷幄四线”首片落地：`GeneralCommandPanelView` 在“方面态势”后新增只读“帷幄四线”区，复用现有 `FrontZone`、`GeneralData`、`GeneralAssignment`、麾下 `Division`、目标 `RegionNode` 和本营受压状态，按政策、经济、科技、军事展示将心军心、粮道驿道、火器攻城/工坊、防区压力和可调军伍，让玩家在将印军令里联读中华世界局势下的军政钱粮火器取舍。该片只影响 SwiftUI 展示，不新增 `GameState`、将领、部署、经济、朝廷、科技、AI 或任务字段，不新增按钮，不写塘报，不提交命令，不改变固守/进取回调、`Command`、`ZoneDirective`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威。并发子 Agent Kuhn 只读探查天下面板候选，Sagan 只读探查将领面板候选；主线程采纳更窄的将领面板小切片，并同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。

- 2026-07-06：v4.7 明末舆图“本旬先手”首片落地：`RootGameView` 顶部 `MingMapSituationStrip` 在“要冲分布”后新增只读“本旬先手”提示，复用现有 `BattleObjectiveSummary.tasks` 和 `tracks.targets`，按优先级、五线压力和标题选取当前任务，展示任务线别/优先级、任务标题、目标城关、当前控制方和要冲分，让玩家在地图第一视野直接看到中华世界局势的本旬落点。该片只影响 SwiftUI 展示，不新增 `GameState`、胜负、任务、目标、塘报、AI、朝廷或经济字段，不新增按钮，不自动定位目标，不写塘报，不提交命令，不改变 `BattleObjectiveSummary`、`VictoryRules`、`CourtStrategySummary`、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威。并发子 Agent Lovelace、Hubble 只读探查舆图与天下候选，主线程采纳更贴近地图首屏的 `RootGameView` 小切片；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md`、`v4.6_ming_ui_polish_record.md` 和 `v4.7_ming_victory_record.md`。

- 2026-07-06：v4.7 明末军机面板“诸势军略”首片落地：`AgentPanelView` 在“军机五线”后新增只读“诸势军略”区，明末剧本下遍历 `Faction.mingLaunchCases`，读取 `ZoneCommanderDoctrine.profile(for:)` 和既有 `AgentPanelFormat` 文案，集中展示明廷、后金/清、大顺、大西、地方中立的势力旗号、军略名、指挥风格、前两项技能标签和战术偏向，帮助玩家在军机复盘牌中横向理解诸方 AI 性格与中华世界局势。该片只影响 SwiftUI 展示，不新增 `GameState`、doctrine、AI、胜负、经济、外交或事件字段，不提交命令，不写塘报，不改变 `ZoneCommanderDoctrine` 默认配置、tactic 偏置、`MarshalAgent`、`RulerAgent`、`WarCommandExecutor`、`Command`、`CommandValidator`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威。并发子 Agent Chandrasekhar 只读复核军机面板插入点与字段边界，Dalton 只读探查后续部队面板候选；本轮主线程采纳军机面板小切片并同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md`、`v4.6_ming_ui_polish_record.md` 和 `v4.7_ming_ai_doctrine_record.md`。

- 2026-07-06：v4.6/v4.7 明末军令牌“要冲军令”首片落地：`CommandPanelView` 在“舆图军令”后新增只读“要冲军令”区，`RootGameView` 注入 `BattleObjectiveSummary.from(state:)`，复用本旬任务、五线态势、目标 track 和选中 `Division`，展示本旬急务、目标落点与本军兵势，帮助玩家在军令牌内联读中华世界局势、军事落点和当前军伍状态。该片只影响 SwiftUI 展示，不新增 `GameState` 字段，不新增按钮，不自动定位目标，不写塘报，不提交命令，不改变胜负、朝廷、经济、AI、移动、攻击、补给、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威。并发子 Agent Kuhn、Locke 作为只读探索运行；主线程保持本片范围集中，并同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md`、`v4.6_ming_ui_polish_record.md` 和 `v4.7_ming_victory_record.md`。

- 2026-07-06：v4.7 明末钱粮面板“经世策眼”首片落地：`EconomyPanelView` 在“府库四线牵引”后新增只读“经世策眼”区，复用现有 `BattleObjectiveSummary`、`CourtStrategySummary` 和 `FactionEconomyLedger`，展示 objective points 领先方与分值、当前最急天下五线、府库粮银余势、本旬主议和备议，让府库牌从钱粮视角联读中华世界局势、政策、经济、科技、军事压力与本旬取舍。该片只影响 SwiftUI 展示，不新增 `GameState`、经济、朝廷、科技、军饷、任务或 AI 字段，不新增按钮，不触发生产、朝廷项目、目标定位或塘报写入，不改变 `BattleObjectiveSummary`、`EconomyState`、`CourtStrategySummary`、`VictoryRules`、`Command.queueProduction`、`Command.enactCourtProject`、`CommandValidator`、`EconomyRules`、`WarCommandExecutor`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威。并发子 Agent Curie 只读复核插入点、可用字段、compile 风险和 UI-only 边界，结论与本片实现一致；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.7_ming_victory_record.md`。

- 2026-07-06：v4.7 明末目标面板“要冲缺口”首片落地：`BattleObjectivePanelView` 在“天下棋眼”后新增只读“要冲缺口”区，复用现有 `BattleObjectiveSummary.tracks`、`Track.targets`、`Target.isControlled`、`Target.controllerName` 和 `Target.points`，按清破关入京、大顺中原秦陕、大西湖广粮道、明廷名分线展示尚缺城关、最高分缺口、当前控制方和定位入口，让玩家更快把中华世界局势与下一处落点接回舆图。该片只影响 SwiftUI 展示；定位按钮仍沿用 `onFocusObjective -> AppContainer.focusObjective(_:)` UI 定位回调，不提交命令，不写塘报，不新增任务进度，不改变 `BattleObjectiveSummary`、`VictoryRules`、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威。并发子 Agent Mencius 只读探查目标面板缺口候选；Parfit 只读探查府库/天下候选，建议后续可做 `EconomyPanelView` “经世策眼”，本轮未采纳以保持提交范围集中。

- 2026-07-06：v4.7 明末朝廷面板“廷议要冲”首片落地：`CourtPanelView` 在“朝议批票”后新增只读“廷议要冲”区，复用现有 `BattleObjectiveSummary.scoreRows`、`leadingFaction` 和当前 active faction，展示明廷、后金/清、大顺、大西等势力的 objective points、控制要冲数量、本方分值和领先方，并用“廷议会看”摘要把要冲归属接回当前 `CourtStrategySummary.recommendedFocus`，让朝廷 tab 更直接把中华世界局势落到政策、经济、科技、军事取舍。该片只影响 SwiftUI 展示，不提供目标定位按钮，不写塘报，不执行朝廷项目，不新增 `GameState`、胜负、任务、目标、AI、朝廷或经济字段，不改变 `BattleObjectiveSummary`、`CourtStrategySummary`、`VictoryRules`、`Command.enactCourtProject`、`CommandValidator`、`EconomyRules`、`WarCommandExecutor`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威。并发子 Agent Newton、Boyle 分别只读探查朝廷/府库/天下与军机/AI 候选；主线程采纳朝廷面板小切片并保留其他候选给后续迭代。

- 2026-07-06：v4.7 明末舆图“要冲分布”首片落地：`RootGameView` 顶部 `MingMapSituationStrip` 在“天下急势”内新增只读“要冲分布”横向小条，复用现有 `BattleObjectiveSummary.scoreRows` 展示明廷、后金/清、大顺、大西等势力的 objective points 和控制要冲数量，并用旗号与冠标标出当前领先方，让玩家不进入目标面板也能在地图第一视野扫读中华世界局势与要冲归属。该片只影响 SwiftUI 展示，不提供目标定位按钮，不写塘报，不新增 `GameState`、胜负、任务、目标或 AI 字段，不改变 `BattleObjectiveSummary`、`VictoryRules`、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威。并发子 Agent Darwin 只读复核文档同步边界；Ohm 代码定位子任务未在主线等待窗口内返回，主线程按既有代码插入点完成小切片并做整合检查。

- 2026-07-06：v4.7 明末钱粮面板“府库四线牵引”首片落地：`EconomyPanelView` 在“收支急报”后新增只读“府库四线牵引”区，复用现有 `FactionEconomyLedger` 与当前势力 `CourtStrategySummary` 展示政策、经济、科技、军事四线压力、民力/银两/粮草库存、营造队列、主议和备议，让玩家在府库牌里直接联读朝廷取舍、钱粮余势、火器支点和接战压力。该片只影响 SwiftUI 展示，不新增经济、朝廷、科技、军饷或任务字段，不触发生产或朝廷项目，不改变 `EconomyState`、`CourtStrategySummary`、`Command.queueProduction`、`Command.enactCourtProject`、`CommandValidator`、`EconomyRules`、`WarCommandExecutor`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威。并发子 Agent Godel 只读复核经济面板插入点、可用字段和 compile 风险；Huygens 只读探查地图“舆图要冲分布”候选，建议后续在 `RootGameView` 顶部控件附近做独立小片，本片不纳入地图改动。

- 2026-07-06：v4.7 明末目标面板天下棋眼首片落地：`BattleObjectivePanelView` 在目标面板 header 后新增只读“天下棋眼”区，复用现有 `BattleObjectiveSummary` 展示要冲分领先方、当前最急天下/政策/经济/科技/军事线、本旬先手任务和可定位目标，让玩家进入“目标”tab 后先扫读中华世界局势、四线压力和当旬落点。该片只影响 SwiftUI 展示，不新增 `GameState`、胜负、任务、目标、塘报或 AI 字段；天下棋眼定位按钮仍沿用 `onFocusObjective -> AppContainer.focusObjective(_:)` UI 定位回调，不提交命令，不写塘报，不改变 `BattleObjectiveSummary`、`VictoryRules`、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威。并发子 Agent McClintock、Chandrasekhar 分别只读探查地图/目标与钱粮/朝廷候选；本轮主线程已先采纳目标面板小切片，两个候选“舆图要冲分布”和“府库四线牵引”记录为后续可选增量。

- 2026-07-06：v4.6 明末天下牵引首片落地：`DiplomacyPanelView` 在“天下概览”后新增只读“天下牵引”区，复用现有 `DiplomacyState`、当前 active faction 的 `CourtStrategySummary` 和最近 `RulerDecisionRecord.diplomacySummary`，展示战和格局、主要敌手、朝议牵引、政策/经济/科技/军事四线压力和御前奏报，帮助玩家从天下局势回看朝廷、钱粮、科技和军令重点。该片只影响 SwiftUI 展示，不新增 `GameState` 或外交字段，不写塘报，不触发目标定位，不执行朝廷项目，不改变 `DiplomacyState`、`CourtStrategySummary`、`Command`、`CommandValidator`、`WarCommandExecutor`、`EconomyRules`、`VictoryRules`、`RuleEngine` 或任何 hex/region/theater/front/deploy 权威。并发子 Agent Pauli、Lovelace 分别只读探查外交面板插入点和文档同步边界；本轮采纳外交面板小切片。

- 2026-07-06：v4.6 明末舆图判读图例增量落地：`RootGameView` 的非 hex 图层图例新增只读“舆图判读”芯片，按州府、初划、战局、前线、布防分别提示政令/钱粮/民变、开局方面/督抚分防、动态推进/军机方面、真实接敌/守关截援、前军/纵深/驻守等读局重点；hex 图层势力旗图例补齐明/清/顺/西/乡，强化明廷、后金/清、大顺、大西和地方势力同场角力的地图代入感。该片只影响 SwiftUI 展示，不新增状态，不改变 `MapDisplayLayer` rawValue、`MapLayerOverlayCalculator`、SpriteKit overlay 绘制、hex/region/theater/front/deploy 权威、补给、命令、AI 或 `RuleEngine`。并发子 Agent Jason、Franklin 分别只读探查地图图例和战线/朝廷/外交 UI 候选，主线程采纳地图图例小切片；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。本轮仍未做本机 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full 或截图验收。

- 2026-07-06：v4.6 州府主值提示首片落地：`RegionInspectorView` 在州府牌头部后新增只读“州府主值”区，按目标、前线压力、关隘、粮台、工坊、驿道和治理压力优先说明该州府当前偏战局要冲、前线承压、城关屏障、粮台重地、工坊军械、驿道节点或治理承压，并用政/粮/械/兵四个 chip 联读政策、经济、科技、军事价值。该片只强化州府牌的中华世界局势和地方价值扫读，不新增 `RegionInspectorState` 字段，不改变 `RegionNode` schema、hex 控制、region 聚合、经济结算、动态战区、前线、部署、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何规则权威。并发子 Agent Euler、Mill 只读复核实现插入点、可用字段、UI-only 风险和文档同步位置；本轮采纳州府主值小切片。
- 2026-07-06：v4.6 朝廷项目行动状态提示首片落地：`CourtPanelView` 在政策、经济、科技、军事四线项目按钮内新增只读行动状态，按观战、本方可行动、`FactionEconomyLedger.stockpile` 与 `CourtProjectKind.cost` 差额显示“可批 / 尚缺民力、银两、粮草 / 待本方 / 观战”；按钮可用性继续与规则前置条件一致，空间不足时状态落到第二行，VoiceOver 通过状态值读取。该片只强化朝廷面板的政策/经济/科技/军事项目决策可读性，不新增朝廷或经济字段，不改变项目成本、收益、`Command.enactCourtProject`、`CommandValidator`、`EconomyRules`、`RuleEngine` 或任何规则权威。并发子 Agent Hubble、Lagrange 只读复核 UI-only 边界、Dynamic Type 风险和文档缺漏；本轮采纳朝廷项目按钮状态小切片。
- 2026-07-06：v4.6 府库生产状态提示首片落地：`EconomyPanelView` 在“募兵与筹粮”每个生产行新增只读状态，按观战、本方可行动、`FactionEconomyLedger.stockpile` 与 `ProductionKind.cost` 差额显示“可开工 / 尚缺民力、银两、粮草 / 待本方 / 观战”，并把“军饷民心”说明改成“账房奏报”口吻。该片只强化钱粮面板的经济/军事决策可读性，不新增经济字段，不改变生产成本、队列、`Command.queueProduction`、`CommandValidator`、`EconomyRules`、`RuleEngine` 或任何规则权威。并发子 Agent Heisenberg、Mendel 只读定位府库生产和朝廷项目禁用状态候选；本轮采纳府库生产状态小切片。
- 2026-07-06：v4.6 军机/塘报 raw 显示中文化首片落地：`AgentPanelView` 只在显示边界把 `AgentDecisionRecord.errors`、`CommandResultSummary.errors` 中的已知 `CommandValidationError.rawValue` 转成 `mingDisplayText`，并把 `Mapping failed.`、`No AI faction was active.`、未知 provider 和未收录 doctrine skill 转成军机案卷口径；`EventLogView` 对非急务、战役、目标换手的 `relatedRecordId` 按前缀显示战区军令、战区回执、军机回执、朱批回执或系统回执，避免默认直出 raw id。该片只强化 SwiftUI 展示和明末代入感，不修改 `AgentDecisionRecord`、`CommandResultSummary`、`GameLogEntry`、`WarDirectiveRecord`、`RulerDecisionRecord` schema，不改变 AI prompt、命令映射、校验、执行、塘报写入、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何规则权威。
- 2026-07-06：v4.6 军令牌“舆图军令”提示首片落地：`CommandPanelView` 在战术处置区新增只读提示，按观战、未选军、敌军、非本方阶段、已行动和粮草状态说明移动/攻击应在舆图点目标格，固守、准退、补给仍在军令牌按钮批令；坐标显示统一走 `MingMapLabelFormat.coordinate` 的“舆图格”口径。该片只强化 SwiftUI 展示和新手可用性，不新增 `GameState` 字段，不改变 `Division`、移动、攻击、补给、退守、`Command`、`CommandValidator`、`WarCommandExecutor`、`RuleEngine` 或任何规则权威。并发子 Agent Leibniz、Anscombe、Ramanujan 只读定位面板、残留文案和地图候选；本轮采纳军令牌小切片，军机复盘/塘报 raw 文案和地图舆图符号建议留作后续。
- 2026-07-06：v4.6 地图军牌“战备小签”只读态势首片落地：`UnitNode` 在明末地图军牌内新增单个优先战备小签，复用现有 `Division.isDestroyed`、`isRetreating`、`supplyState` 和 `hasActed` 派生 `溃散`、`退中`、`被围`、`缺粮`、`已行`，让玩家在舆图第一视野直接扫读部队是否断粮、被围、退守中或已经行动。该片只强化 SpriteKit 展示，不新增 `Division` 字段，不改变补给、退守、行动、战斗、部署、`Command`、AI、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何规则权威。并发子 Agent Kepler、Bohr、Linnaeus 只读定位面板 UI、地图可视化和残留文案候选；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。
- 2026-07-06：v4.6 部队“军械火力”只读态势首片落地：`UnitInspectorView` 在“军令战备”之后新增“军械火力”区，复用现有 `Division.components`、`effectiveStats.range`、`hasFireSupport`、`isSiegeCapable`、兵力和粮草状态派生军械占比、火器/炮队/攻城比例、射程、火力姿态，以及断粮/缺粮对火器炮队发挥的影响说明，让玩家在部队牌内联读科技、火器、攻城器械和军事经营。该片只强化 SwiftUI 展示，不新增 `Division` 字段，不改变 `ComponentType`、`CombatRules`、补给、命令、AI、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何规则权威。并发子 Agent Hypatia、Ptolemy、Singer 只读定位下一切片候选和残留文案风险；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。
- 2026-07-06：v4.6 军机/战区诊断中文化首片落地：`CommandValidationError` 新增只读 `mingDisplayText`，让 `AppContainer`、`TurnManager` 和 `WarCommandExecutor` 共用中文驳回原因，保留 `rawValue` 和 Codable 语义不变；`TurnManager` 把军机回合方/阶段不符、无军令、旧 Agent D 军令驳回/映射失败、战区指令为空、未生成可执行军令、防区缺失和结束阶段失败等诊断改为明末中文口径；`WarCommandExecutor` 把战区军令驳回、州府控制权变化、单个 hex 划入动态方面和接敌线变化写成中文塘报，并使用既有部队、州府和方面名称。该片只影响 `AgentDecisionRecord.errors`、`WarDirectiveRecord.diagnostics` 和 `eventLog` 可读文案，不改变 `CommandValidationError.rawValue`、`Command.displayName`、AI JSON、`ZoneDirective` 生成、命令校验、执行结果、hex/region/theater/front/deploy 权威或 `RuleEngine`。并发子 Agent Tesla、Maxwell 只读定位 `TurnManager` 与 `WarCommandExecutor` 的英文诊断；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。
- 2026-07-06：v4.6 朝廷“朝议批票”只读票拟首片落地：`CourtPanelView` 在朝议总纲之后新增“朝议批票”区，复用 `CourtStrategySummary`、推荐 `CourtProjectKind` 和明末 `BattleObjectiveSummary.CampaignLineBrief` 派生本旬票拟项目、四线最高压力、战役最急线、成本、收益和风险，帮助玩家理解朝廷如何把中华世界局势落到政策、经济、科技、军事项目。该片只强化 UI 代入感，不新增朝廷状态，不保存票拟，不自动执行朝廷项目，不改变 `CourtStrategySummary` 排序、项目成本收益、命令校验、经济规则或规则权威。并发子 Agent Schrodinger、James、Gibbs 只读定位下一切片候选；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。
- 2026-07-06：v4.6 府库“军饷民心”只读态势首片落地：`EconomyPanelView` 在府库收支急报与内政钱粮之间新增“军饷民心”区，复用 `FactionEconomyLedger`、当前势力未毁 `Division.supplyState` 和 `GovernanceAISummary` 派生军伍、缺粮/被围、军饷余势、民心综合和军粮压顶/军饷吃紧/民心承压等状态，帮助玩家在钱粮面板联读经济、军队补给和地方治理压力。该片只强化 UI 代入感，不新增军饷、士气、民心或灾荒字段，不改变经济、部队、治理、补给、生产、命令或规则权威。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。
- 2026-07-06：v4.6 默认可见命令/塘报文案本地化首片落地：`RootGameView` 信息面板 AI 入口改为“军机”，`DataLoader` 初始剧本载入日志改为中文；`AgentPanelView` 在显示边界把 legacy `Command.displayName` 前缀映射为调动、攻击、固守、准退、补给整备、营造筹备和结束阶段，保留 `Command.displayName` 本体供 Codable 记录、AI prefix 判定和历史测试使用；`RuleEngine` 成败回执改为中文军令口径，`CommandExecutor` 行军、战斗、固守、准退、回合推进和动态方面推进塘报改为中文，`SupplyRules` 补给、退守、退守失败、合围消耗和退守整顿完成塘报改为中文，并补充 combat / retreat / reinforce / supply / encircle / theaterChange 分类；`RuleEngineCoreTests` 中两处退守日志断言改为检查分类和中文语义。该片只影响默认可见文案与日志分类，不改变命令 schema、`Command.displayName`、移动/战斗/补给/退守结果、`CommandValidator`、`WarCommandExecutor`、`RuleEngine` 权威或 `GameState` 持久字段。并发子 Agent Volta、Dirac、Wegener 只读定位命令显示、执行日志和 UI 残留；本机仅跑轻量检查，不跑 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full。
- 2026-07-06：v4.7 明末战役提示“军械”分类首片落地：`BattleObjectiveSummary.Cue.Kind` 新增 `technology`，目标面板显示为“军械”并使用 hammer 图标和青瓷色；明廷开局提示链新增 `firearms_fortification_pressure`，把红衣炮维护、火器整备和修城固守与山海关、北京、武昌等城关承压联系起来。`Cue.eventCategory` 对军械提示仍映射为普通 `.event`，结束回合只按既有 `battle-cue-<turn>-<faction>-<cue id>` 写入塘报，不新增科技树、事件执行器、持久状态、胜负条件或命令入口；`RuleEngineCoreTests` 增加开局军械 cue 语义断言作为参考，本机不跑 XCTest。并发子 Agent Goodall 只读核对 cue 扩展点和 UI 消费者；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.7_ming_victory_record.md`。
- 2026-07-06：v4.6/v4.7 明末钱粮界面“内政钱粮”扫读首片落地：`EconomyPanelView` 在府库总账和收支急报后新增只读 `TreasuryGovernanceSection`，复用 `GovernanceAISummary.from(faction:map:)` 展示当前势力控制州府、不稳州府、平均民变、平均行政和最低行政州府，并通过 `MingMapLabelFormat.regionTitle` 避免 raw region id 直出。该片强化钱粮界面对地方治理、民变、行政掌控和州府钱粮修正的代入感，只读现有 `GameState.map` / `GovernanceAISummary`，不新增状态、不提交命令、不改变 `EconomyState`、`EconomyRules`、`Command.queueProduction`、`CommandValidator` 或 `RuleEngine`。并发子 Agent Planck 只读定位 UI 入口和可用数据；同步更新 `md/flow/flow.md`。本机仅跑轻量检查，不跑 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full 或截图验收。
- 2026-07-06：v4.7 明末经济规则外交敌对判定修复：`EconomyRules.isEnemyAdjacent` 不再用 `other.faction != faction` 把所有非本势力军伍视为敌军，而是统一走 `GameState.diplomacyState.isHostile(faction, other.faction)`；该判断会影响自动补员避开接敌军伍，以及生产部署选择安全落点。修复后地方中立、停战、通行、协战或同盟等非敌对势力不再误阻补员/部署，真正敌对或交战势力仍按原距离语义阻断。本片不改变 `DiplomacyState` 数据、外交关系生成、补员资源消耗、生产队列、hex/region 控制、`Command`、`WarCommandExecutor` 或 `RuleEngine` 管线。并发子 Agent Poincare 只读定位该问题；本机仅跑轻量检查，不跑 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full。
- 2026-07-06：v4.7 明末 legacy Agent D / 本地 LLM 预留链路语境同步首片落地：`AgentPromptBuilder` 在明末势力下把 system / user prompt 改为军机语境，强调中华世界局势、军政钱粮、火器城防、方面军调度和天下五线压力，同时继续强制 JSON schema、命令 enum 和校验边界不变；`MockAIClient` 在明末势力下不再围绕 Bastogne 生成 intent / reason，而是按当前未控要冲、`CampaignAISummary.activeTasks`、粮草、城关、前线/纵深/驻防三层生成中文军令理由，legacy 德/盟分支继续保留 Bastogne / v0.33 deployment 回归文案；`TurnManager.contextSummary` 在明末势力下输出本方军伍、已知敌情、要冲、钱粮、朝议和五线态势中文摘要；`GameAgent.sample` 为明末 fallback agent 提供军机职责人格 prompt，`AgentRole.displayName` 与 `GamePhase.displayName` 显示为主上/督师/总兵、军机行动/玩家行令。该片只影响 legacy Agent D prompt、模拟 AI 说明和 UI/记录可读文本，不把 Legacy Agent D 重新设为默认战争 AI 主路径，不改变 `AgentDecisionEnvelope`、`AgentOrder` schema、parser、mapper、`Command`、`ZoneDirective`、`WarCommandExecutor`、`RuleEngine` 或默认元帅执行权威。并发子 Agent Feynman、Hegel 分别只读探查政策/经济/科技/军事链路和默认 UI/AI 残留，主线程采纳其中 Agent prompt / MockAI / contextSummary / GamePhase 小切片；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.7_ming_ai_doctrine_record.md`。本机轻量检查通过：`swiftc -parse WWIIHexV0/Agents/AgentPromptBuilder.swift WWIIHexV0/Agents/MockAIClient.swift WWIIHexV0/Agents/GameAgent.swift WWIIHexV0/Turn/TurnManager.swift WWIIHexV0/Core/GamePhase.swift`、`git diff --check`、文档/Swift 尾随空白扫描、行首冲突标记扫描、旧默认测试口径扫描；本轮仍未做本机 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full 或截图验收。
- 2026-07-06：v4.6 明末命令交互回执中文化首片落地：`AppContainer` 在提交玩家 `Command` 前按当前 `GameState` 生成 UI-only 中文军令摘要，把移动、攻击、固守、退守许可、补给整备、募兵筹粮、朝廷项目和结束阶段转成明末军令口径；普通命令成功/驳回、`CommandValidationError`、玩家将令提交/诊断、目标定位、单位点选、AI 回合摘要和 fallback mock commander 名称都改为中文，避免交互日志和军令回执继续出现 `Command accepted/rejected`、`General order`、`Selected hex/region`、`Mock Commander` 等英文调试文案。`RulerAgent` 的最高意志理由和上下文也改为中文朱批式文本，并对常见 front zone / theater id 做源头中文化，避免 `Ruler sees...`、`target none` 和裸 zone id 进入复盘。该片只影响 `lastCommandMessage`、`interactionLog`、`RulerDecisionRecord.rationale/theaterContext` 和默认 AI 名称的可读文案，不新增 `GameState` 字段，不改变 `Command.displayName`、`CommandResult` schema、`WarDirectiveRecord` / `PlayerPlannedOperation` 记录 ID、命令校验、执行结果、`CommandValidator`、`WarCommandExecutor`、`RuleEngine` 或任何规则权威。并发子 Agent Zeno、Avicenna 分别只读探查 `RulerAgent`/外交链路和 `AppContainer` 交互文案，主线程整合为显示层小切片；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。本机轻量检查通过：`swiftc -parse WWIIHexV0/Agents/RulerAgent.swift WWIIHexV0/App/AppContainer.swift`、`git diff --check`、文档/Swift 尾随空白扫描、行首冲突标记扫描、旧英文交互关键词扫描、旧默认测试口径扫描；本轮仍未做本机 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full 或截图验收。
- 2026-07-06：v4.6 明末地名/防区可读化首片落地：新增共享 UI-only `MingMapLabelFormat`，把 ruler / marshal / country / bloc / region / theater / front zone / front line / hex 格位等底层 id 转成明末可读名称，并让 `AgentPanelView`、`DiplomacyPanelView`、`UnitInspectorView`、`UnitTooltipView` 和 `RegionInspectorView` 共用同一 formatter。部队军情牌不再直出州府、方面、防区和前线 raw id，并把“玩家/只读”改为“本方可调/他方军情”；舆图军牌浮签把裸坐标和退守短码改为“舆图格”“退守中”“余 N 旬”；州府牌把当前州府和当前格的方面/防区 raw id 改成可读防区名；天下面板把朝议/军议主事、重心以及国家/阵营 fallback 转成明末称谓；军机复盘牌复用共享 formatter，避免私有映射分叉。该片只影响 SwiftUI 展示，不新增 `GameState` 字段，不改变 `DiplomacyState`、`RegionInspectorState`、`UnitInspectorStrategicState`、`AgentDecisionRecord`、`RulerDecisionRecord`、`WarDirectiveRecord` schema，不改变 AI、外交、胜负、经济、补给、战斗、部署、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何规则权威。并发子 Agent Descartes、Averroes、Russell 分别只读探查天下、部队/浮签、州府面板 raw id 和调试感残留，主线程整合为共享 formatter 小切片；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。本机轻量检查通过：`swiftc -parse WWIIHexV0/UI/PlatformStyles.swift WWIIHexV0/UI/AgentPanelView.swift WWIIHexV0/UI/DiplomacyPanelView.swift WWIIHexV0/UI/UnitInspectorView.swift WWIIHexV0/UI/UnitTooltipView.swift WWIIHexV0/UI/RegionInspectorView.swift`、`git diff --check`、文档/Swift 尾随空白扫描、行首冲突标记扫描、旧默认测试口径扫描；本轮仍未做本机 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full 或截图验收。
- 2026-07-06：v4.6 明末军机底稿可读化首片落地：`AgentPanelView` 将军机复盘中的“原始 JSON”改为“军机底稿”，空态改为审计原稿说明，并在主事、来源、主上、重心、目标和指向等位置用 UI-only helper 把明末 ruler / marshal / theater / front zone / region id 转成可读名称；未知值仍回退原 id，`record.rawJSON` 仍保留 monospaced 与 `textSelection(.enabled)` 作为审计底稿。该片只影响 SwiftUI 展示，不新增 `GameState` 字段，不改变 `AgentDecisionRecord`、`RulerDecisionRecord`、`WarDirectiveRecord` schema，不改 AI prompt、doctrine、命令映射、`WarCommandExecutor`、`Command`、`CommandValidator`、`RuleEngine` 或任何规则权威。并发子 Agent Lovelace 只读探索 `AgentPanelView` 与记录类型并给出最小替换点；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。本机轻量检查通过：`swiftc -parse WWIIHexV0/UI/AgentPanelView.swift`；本轮仍未做本机 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full 或截图验收。
- 2026-07-06：v4.6 明末朝议总纲首片落地：`CourtPanelView` 在朝廷 header 后新增只读“朝议总纲”，读取 `CourtStrategySummary.displaySummary`、`recommendedFocus`、`secondaryFocuses`、四线压力和推荐 `CourtProjectKind`，把主议、备议、推荐项目归属与政策/经济/科技/军事压力做成奏疏式扫读区，让朝廷界面更直接呈现明末军政钱粮火器取舍。该片只影响 SwiftUI 展示，不新增 `GameState` 字段，不改变 `CourtStrategySummary` 排序，不触发朝廷项目，不改变 `Command.enactCourtProject`、资源校验、项目成本、`EconomyRules` 或任何规则权威。并发探索子 Agent 分别从文档路线和 UI 源码给出候选，本轮采纳朝廷面板小片；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。本机轻量检查通过：`swiftc -parse WWIIHexV0/UI/CourtPanelView.swift`；本轮仍未做本机 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full 或截图验收。
- 2026-07-06：v4.6 明末舆图军牌浮签首片落地：`UnitTooltipView` 从旧表格式摘要浮窗升级为明末舆图军牌浮签，只读展示选中地图部队的势力旗号、部队名、兵种定位、坐标、兵力条、粮草/行动/退守状态、攻守行程察指标和兵种组件 chip；该片服务地图与部队界面的明末代入感，和政策、经济、科技、军事及地图/部队/朝廷界面并重的迁移目标保持一致。该片只影响 SwiftUI 展示，不新增 `GameState` 字段，不改变 `Division`、`CombatRules`、`SupplyRules`、`WarDeploymentState`、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何规则权威。并发文档子 Agent Turing 同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`；本机轻量检查通过：`swiftc -parse WWIIHexV0/UI/UnitTooltipView.swift`；本轮仍未做本机 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full 或截图验收。
- 2026-07-05：v4.6 明末塘报急务战役分类首片落地：`EventLogView` 在塘报战记中只读识别 `GameLogEntry.relatedRecordId` 前缀，把 `battle-task-` 记录显示为“急务 / 本旬急务”，把 `battle-cue-` 记录显示为“战役 / 战役提示”，把 `objective-control-` 回执显示为“目标换手”，并在顶部摘要中新增急务/战役计数，让本旬任务、战役提示和目标换手不再混在普通事件里。该片只影响 SwiftUI 展示与文档同步，不新增 `GameLogCategory`，不改变 `GameLogEntry` schema，不改变 `CommandExecutor.appendBattleCueEvents`、`appendBattleTaskEvents`、`appendObjectiveControlEventIfNeeded` 写入逻辑，不触发命令、不写塘报、不改变胜负、AI、经济、外交、hex/region/theater/front/deploy 或任何规则权威。并发子 agent Hilbert 只读探索建议下一片优先做 `UnitTooltipView` 舆图军牌浮签，本片先收口主线程塘报分类。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。本机轻量检查通过：`swiftc -parse WWIIHexV0/UI/EventLogView.swift`；本轮仍未做本机 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full 或截图验收。
- 2026-07-05：v4.6 明末舆图天下急势首片落地：`RootGameView` 顶部舆图控件新增只读“天下急势”条，在明末剧本下复用 `BattleObjectiveSummary` 展示 objective points 领先方、急务/主线任务数，以及天下、政策、经济、科技、军事五线压力 chip，让玩家进入地图第一视野时先扫读中华世界局势和当前军政钱粮火器重点。该片只影响 SwiftUI 展示与文档同步，不调用 `AppContainer.focusObjective(_:)`，不写塘报，不新增 `GameState` 字段，不保存任务状态，不改变 `BattleObjectiveSummary`、`VictoryRules`、`CourtStrategySummary`、AI、`Command`、`CommandValidator`、`WarCommandExecutor`、`RuleEngine` 或 hex/region/theater/front/deploy 权威。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。本机轻量检查通过：`swiftc -parse WWIIHexV0/UI/RootGameView.swift`；并发子 agent Copernicus 只读审查未发现阻断提交问题；本轮仍未做本机 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full 或截图验收。
- 2026-07-05：v4.6 明末部队军令战备首片落地：`UnitInspectorView` 在军情牌内新增只读“军令战备”区，基于现有 `Division.canAct`、`supplyState`、`strengthRatio`、退守状态和攻城/火器/机动 helper 派生可调/已行/断粮、粮道、战力和用兵定位，让玩家在部队面板内先扫读能否下令、是否缺粮、战力是否危急和适合攻城/火器/机动/守线。该片只影响 SwiftUI 展示与文档同步，不新增 `GameState` 字段，不改变 `Division`、`SupplyRules`、`CombatRules`、`WarDeploymentState`、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何规则权威。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。本机轻量检查通过：`swiftc -parse WWIIHexV0/UI/UnitInspectorView.swift`、`git diff --check`、文档/Swift 尾随空白扫描、行首冲突标记扫描、旧默认测试口径扫描；本轮仍未做本机 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full 或截图验收。
- 2026-07-05：v4.6 明末州府归属旗号首片落地：`RegionInspectorView` 的州府牌头部新增当前控制方 `MingFactionFlagBadge` 和原属章，当前格控制行也新增控制方旗号，让玩家在州府牌内能直接扫读明、清、顺、西、乡等州府/hex 归属。该片只影响 SwiftUI 只读展示与文档同步，不新增 `GameState` 字段，不改变 `RegionInspectorState`、`RegionNode`、`HexTile.controller`、hex/region 控制聚合、经济、前线、部署、目标定位、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine`、外交或胜负；州府和当前格归属仍以既有 `MapState` / `RegionInspectorState` 为权威。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。本机轻量检查通过：`swiftc -parse WWIIHexV0/UI/RegionInspectorView.swift`、`git diff --check`、文档/Swift 尾随空白扫描、行首冲突标记扫描、旧默认测试口径扫描；本轮仍未做本机 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full 或截图验收。
- 2026-07-05：v4.6 明末府库收支急报首片落地：`EconomyPanelView` 在府库总账和募兵筹粮之间新增“收支急报”区，从现有 `FactionEconomyLedger` 只读派生净民力、净银两、净粮草、粮草/补员压力、营造项数和待部署状态，让玩家在执行募兵、筹粮或朝廷钱粮项目前先看到当前财政军粮压力。该片只影响 SwiftUI 只读展示与文档同步，不新增 `GameState` 字段，不改变 `EconomyState`、`FactionEconomyLedger`、`EconomyRules`、生产成本、补员、补给、`Command.queueProduction`、`CommandValidator`、`RuleEngine`、外交、胜负或 hex/region 控制权；生产按钮仍通过 `onQueueProduction -> AppContainer.queueProduction -> Command.queueProduction -> CommandValidator -> EconomyRules` 执行。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。本机轻量检查通过：`swiftc -parse WWIIHexV0/UI/EconomyPanelView.swift`、`git diff --check`、文档/Swift 尾随空白扫描、行首冲突标记扫描、旧默认测试口径扫描；本轮仍未做本机 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full 或截图验收。
- 2026-07-05：v4.6 明末天下局势面板 polish 首片落地：`DiplomacyPanelView` 的诸方势力行现在用 `MingFactionFlagBadge` 显示势力旗号，并补充主战标记、战意条和离散值；战和关系行改为双方旗号、关系状态、张力条和起始回合；阵营名义改为旗号、成员摘要和当前阵营高亮卡片，让玩家更快扫读明廷、清、大顺、大西和地方势力之间的中华世界局势。该片只影响 SwiftUI 只读展示与文档同步，不新增 `GameState` 字段，不改变 `DiplomacyState`、`CountryProfile`、`DiplomaticRelation`、`CourtStrategySummary`、`RulerAgent`、AI 指令、`Command`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine`、经济、胜负或 hex/region 控制权；外交判断和朝廷项目仍走既有规则链。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。本机轻量检查通过：`swiftc -parse WWIIHexV0/UI/DiplomacyPanelView.swift`、`git diff --check`、文档/Swift 尾随空白扫描、行首冲突标记扫描、旧默认测试口径扫描；本轮仍未做本机 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full 或截图验收。
- 2026-07-05：v4.7 明末目标城关控制方旗号首片落地：`BattleObjectivePanelView` 的目标城关 chip 现在会读取 `BattleObjectiveSummary.Target.controller`，只读显示当前控制方旗号和要冲分；无人控制时显示“无”，帮助玩家在清破关入京、大顺中原秦陕、大西湖广粮道和明廷名分线之间快速扫读关键城关归属。该片只影响 SwiftUI 展示与文档同步，不新增 `GameState` 字段，不改变 `Objective`、`BattleObjectiveSummary`、`VictoryRules`、目标换手塘报、`AppContainer.focusObjective(_:)`、`BoardScene.drawFocusedObjective`、hex/region 控制、经济、外交、AI 指令、`Command`、`WarCommandExecutor`、`CommandValidator` 或 `RuleEngine`；目标定位、胜负判定和目标换手仍以既有 `GameState` / `MapState` 权威为准。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.7_ming_victory_record.md`。本机轻量检查通过：`swiftc -parse WWIIHexV0/UI/BattleObjectivePanelView.swift`、`git diff --check`、文档/Swift 尾随空白扫描、行首冲突标记扫描、旧默认测试口径扫描；本轮仍未做本机 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full 或截图验收。
- 2026-07-05：v4.7 明末 AI doctrine 军机复盘展示首片落地：`AgentPanelView` 在每条 `WarDirectiveRecord` 指令卡下读取 `ZoneCommanderDoctrine.profile(for: directive.faction)`，只读展示势力军略、指挥风格、技能标签和战术偏向，让玩家能从军机复盘牌解释明廷谨守京畿粮道、清方旗骑合围截援、大顺破弱城扩粮、大西流动作战夺粮和地方团练自保等 AI 性格。该片只影响 SwiftUI 展示与文档同步，不新增 `GameState` 字段，不改变 `WarDirectiveRecord` / `AgentDecisionRecord` / `CampaignAISummary` / 元帅 schema，不改 AI prompt、`ZoneCommanderDoctrine` 决策逻辑、`BinaryTacticClassifier`、`SimulatedMarshalLLMClient`、`WarCommandExecutor`、`Command`、`CommandValidator`、`RuleEngine`、胜负、经济、外交、塘报写入或 hex/region/theater/front/deploy 权威；最终执行仍必须走 `TheaterDirective -> TheaterDirectiveCompiler -> ZoneDirective -> WarCommandExecutor -> RuleEngine`。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md`、`v4.6_ming_ui_polish_record.md` 和 `v4.7_ming_ai_doctrine_record.md`。本机轻量检查通过：`swiftc -parse WWIIHexV0/UI/AgentPanelView.swift`、`git diff --check`、文档/Swift 尾随空白扫描、行首冲突标记扫描、旧默认测试口径扫描；本轮仍未做本机 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full 或截图验收。
- 2026-07-05：v4.6/v4.7 明末军机五线态势首片落地：`RootGameView` 向 `AgentPanelView` 注入只读 `CampaignAISummary.from(state:)`，军机复盘牌新增“军机五线”区，展示中华世界局势、天下/政策/经济/科技/军事五线压力、告急/主线状态、急务数量和最多 3 条当旬军政钱粮火器任务，让玩家复盘 AI/军机记录时也能看到与目标、朝廷共用的五线来源。该片只影响 SwiftUI 展示，不新增 `GameState` 字段，不改变 `CampaignAISummary` schema、不升级元帅摘要版本、不写塘报、不触发命令、不改变 `ZoneCommanderDoctrine`、AI prompt、`WarCommandExecutor`、`Command`、`CommandValidator`、`RuleEngine`、victory、经济、外交或 hex/region/theater/front/deploy 权威；非明末剧本隐藏该区。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md`、`v4.6_ming_ui_polish_record.md` 和 `v4.7_ming_victory_record.md`。本轮仍未做本机 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full 或截图验收。
- 2026-07-05：v4.6/v4.7 明末朝廷五线态势首片落地：`CourtPanelView` 在明末剧本下复用 `BattleObjectiveSummary.CampaignLineBrief` 新增只读“天下五线态势”区，展示天下、政策、经济、科技、军事五线的战役压力、告急/主线状态、急务数量和当前摘要，让朝廷 tab 的主议、四线压力、朝议争点和中华世界局势来源放在一起扫读。该片只影响 SwiftUI 展示，不新增 `GameState` 字段，不保存任务状态，不写塘报，不执行朝廷项目，不改变 `CourtStrategySummary` 的主议/备议排序，也不改变 `Command.enactCourtProject -> CommandValidator -> CommandExecutor -> EconomyRules -> RuleEngine`、victory、AI、hex/region/theater/front/deploy 或任何规则权威；非明末剧本隐藏该区。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md`、`v4.6_ming_ui_polish_record.md` 和 `v4.7_ming_victory_record.md`。本机轻量检查通过：`swiftc -parse WWIIHexV0/UI/CourtPanelView.swift`、`git diff --check`、文档/Swift 尾随空白扫描、行首冲突标记扫描、旧默认测试口径扫描；本轮仍未做本机 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full 或截图验收，真实视觉密度和窄屏表现仍需后续授权运行检查。
- 2026-07-05：v4.7 明末目标定位舆图反馈首片落地：`AppContainer.focusObjective(_:)` 在目标面板城关 chip 或本旬任务定位触发后额外记录只读 `focusedObjectiveId`，并在普通地图点击、选择部队和新局重置时清除；`BoardRenderState` 将该状态传给 `BoardScene`，`BoardScene.drawFocusedObjective` 只读 `BattleObjectiveSummary` 与 `MapState.objective(id:)`，在舆图上绘制“标”令牌、脉冲圈、目标名、当前控制方和同一胜负线城关连线；`RootGameView` 顶部舆图图例新增“目标定位 / 胜负线城关”；`BoardInteractionTests` 补充 `focusedObjectiveId` 语义断言。该片只强化中华世界局势目标落点和地图代入感，不提交 `Command`，不移动镜头，不改变 objective 控制、hex/region 控制、胜负判定、任务状态、AI 指令、经济或任何规则权威；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.7_ming_victory_record.md`。本轮仍未做本机 Xcode / XCTest / 模拟器重测试，也未做截图或运行时视觉验收；后续可继续做目标镜头居中、目标筛选和授权截图检查。
- 2026-07-05：v4.6 明末整训团练地方驻防首片落地：`CourtProjectKind.trainMilitia` 从单纯军事项目升级为政策/军事兼线项目，收益说明改为整训地方守备、稳定不稳州府并排入募兵队列；`CourtPolicyFocus` 同步显示政策/军事兼线；`EconomyRules.enactCourtProject` 保留 1 回合 `infantryDivision` 地方守备队列，同时优先选择最多 2 个己控不稳州府执行轻量地方驻防，民变 -6、行政 +3，并在塘报中写入“地方驻防”效果。该片仍通过 `Command.enactCourtProject -> CommandValidator -> CommandExecutor -> EconomyRules -> RuleEngine` 执行，不新增独立治安资源、真实驻防层、地图单位直生、hex/region 控制权变化、外交变化、补给判定变化、`WarDeploymentState` 改动或多回合政策/科技树；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。本轮仍未做本机 Xcode / XCTest / 模拟器重测试，完整团练专属生产类型、真实守城治安系统、灾荒/叛乱事件链和视觉验收仍后置。
- 2026-07-05：v4.6 明末舆图军牌图例增强与朝廷兼线展示首片落地：`UnitNode` 在不改变军牌宽高的前提下新增旗色侧条、兵种印面暗纹和兵力小签底板，让地图军牌更容易扫读势力、兵种、兵力与守/退状态；`RootGameView` 的 hex 图层图例从单一“步/军牌”扩展为步/骑/火/城/旗兵种军牌、粮草满/低/断圆点和堆叠数说明，并继续保留城/关/粮、势力旗、军令计划和粮道图例；`CourtPanelView` 的四线项目分组改为读取 `CourtProjectKind.domains`，让农政屯田、红衣炮维护、粮台驿道等交叉项目出现在全部相关线组，并在项目说明中标为“兼线”。该片只影响 SwiftUI/SpriteKit 展示，不改变 `GameState`、`Faction` 控制语义、`Division` 状态、`SupplyRules`、`Command.enactCourtProject`、`EconomyRules`、`WarCommandExecutor`、`RuleEngine` 或任何规则权威；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。本轮仍未做本机 Xcode / XCTest / 模拟器重测试，真实截图验收、触控布局和完整美术资产仍后置。
- 2026-07-05：v4.7 明末 AI doctrine 首片落地：新增 `ZoneCommanderDoctrine`，让默认 `TheaterCommanderPool`、`AppContainer` 空将领 registry fallback、显式 `.zoneDirective` 路径、`MockAICommander` 和 `SimulatedMarshalLLMClient` 不再沿用“德军 aggressive / 其他 balanced”的二战 fallback，而是按明廷谨慎守京畿粮道、清方进取旗骑合围截援、大顺进取破弱城扩粮、大西进取流动作战夺粮、地方中立谨慎自保生成默认配置与 tactic 偏置；`ZoneCommanderAgent` 和模拟元帅 JSON 上游都会按 doctrine 映射 tactic，让同态进攻下明廷偏火器压制、清方偏突骑破阵/合围、大顺偏破围、大西偏流动作战。该片只影响 `BinaryTacticClassifier` 攻守边界、技能标签、模拟元帅 JSON tactic 和 directive 生成偏置，不新增 AI 管线，不直接下发底层 `Command`，不改变 `WarCommandExecutor`、`RuleEngine`、hex/region/economy/victory/外交或事件权威。`CommandSystemTests` 增加明末势力 doctrine 和模拟元帅 tactic 语义用例；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和新增 `v4.7_ming_ai_doctrine_record.md`。本轮仍未做本机 Xcode / XCTest / 模拟器重测试；后续可继续把 doctrine 展示到军机复盘牌，并结合战役五线态势强化清方山海关/北京、大顺中原秦陕、大西湖广粮区目标偏好。
- 2026-07-05：v4.7 明末开封围城压力提示首片落地：`BattleObjectiveSummary` 在大顺控制 `obj_kaifeng` 时只读派生“开封围城压力”战役 cue，并额外生成“救援开封压力”急务任务，目标定位指向 `obj_kaifeng`；`CommandExecutor.appendBattleCueEvents` 与 `appendBattleTaskEvents` 复用现有去重 relatedRecordId 把该 cue/task 写入塘报。该片不新增真实 siege state、城防损耗、历史事件执行器或持久任务进度，不改变 hex/region/economy/victory/AI 指令权威；实际行动仍必须由玩家或 AI 通过 `Command` / `ZoneDirective -> RuleEngine` 执行。`RuleEngineCoreTests` 增加开封压力 cue/task 和结束回合塘报入册语义用例；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.7_ming_victory_record.md`。本轮仍未做本机 Xcode / XCTest / 模拟器重测试，真实多回合围城、开封灾荒/决堤事件和 AI doctrine 偏置仍后置。
- 2026-07-05：v4.6/v4.7 明末粮台驿道朝廷项目增强落地：既有 `CourtProjectKind.grainTransport` 展示名调整为“粮台驿道”，并归入经济/科技/军事交叉项目；`CourtStrategySummary` 会把己控粮道州府的低驿道基础计入粮台驿道主议压力，同时让科技线看到驿道/粮台建设压力。玩家执行仍必须走 `Command.enactCourtProject -> CommandValidator -> EconomyRules -> RuleEngine`；`EconomyRules` 会继续用银两换取粮草、恢复最多 3 支缺粮部队，并额外整修最多 2 个己控粮道州府的 infrastructure / supplyValue，不改变 hex 补给路径判定、hex/region 控制方、外交关系、胜负规则或事件权威。`RuleEngineCoreTests` 增加弱驿道推动主议粮台驿道和执行后粮道州府基础改善的语义用例；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。本轮仍未做本机 Xcode / XCTest / 模拟器重测试，完整漕运/驿道多回合科技树、真实补给路径改造和发布级视觉验收仍后置。
- 2026-07-05：v4.6/v4.7 明末红衣炮维护朝廷项目首片落地：`CourtProjectKind` 与 `CourtPolicyFocus` 新增“红衣炮维护”，作为科技/军事交叉项目进入朝廷面板四线分组和朝议主议排序；`CourtStrategySummary` 会把己方受损攻城炮队、破关入京线和终局名分线压力计入红衣炮维护权重。玩家执行仍必须走 `Command.enactCourtProject -> CommandValidator -> EconomyRules -> RuleEngine`；`EconomyRules` 会优先给最多 2 支己方受损攻城炮队恢复兵力，若无候选则只追加 1 回合造炮队订单，不新增持久科技树、不改变 hex/region 控制、外交关系、胜负、战斗规则或事件权威。`RuleEngineCoreTests` 增加受损红衣炮推动主议和执行红衣炮维护后炮队兵力恢复的语义用例；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。本轮仍未做本机 Xcode / XCTest / 模拟器重测试，完整科技树、火药/军械库存和发布级视觉验收仍后置。
- 2026-07-05：v4.6/v4.7 明末农政屯田朝廷项目首片落地：`CourtProjectKind` 与 `CourtPolicyFocus` 新增“农政屯田”，作为经济/科技交叉项目进入朝廷面板四线分组和朝议主议排序；`CourtStrategySummary` 会把己控低粮草/低基础设施州府、粮草缺口和河南秦陕/湖广粮道战役线压力计入农政主议权重。玩家执行仍必须走 `Command.enactCourtProject -> CommandValidator -> EconomyRules -> RuleEngine`；`EconomyRules` 会优先选择己控低粮草/低基础设施州府，提升 supplyValue 和 infrastructure，并轻微提高行政掌控，但不直接补现粮、不改变 hex/region 控制方、外交关系、胜负或事件权威。`RuleEngineCoreTests` 增加低粮田水利推动主议农政和执行农政后长期粮草基础改善的语义用例；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。本轮仍未做本机 Xcode / XCTest / 模拟器重测试，完整灾荒/农政多回合科技树仍后置。
- 2026-07-05：v4.6/v4.7 明末招抚乡绅朝廷项目首片落地：`CourtProjectKind` 与 `CourtPolicyFocus` 新增“招抚乡绅”，朝廷面板按政策线展示并可通过 `Command.enactCourtProject -> CommandValidator -> EconomyRules -> RuleEngine` 执行；`EconomyRules` 会优先选择己控地方中立、非核心或不稳州府，降低民变并提高行政掌控，但不改变 hex/region 控制方、外交关系、胜负或事件权威；`CourtStrategySummary` 会把地方中立/非核心州府、低行政和大顺/大西战役线压力计入招抚主议排序。`RuleEngineCoreTests` 增加地方压力推动主议招抚和执行招抚后治理改善的语义用例；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。本轮仍未做本机 Xcode / XCTest / 模拟器重测试，完整归降/外交招抚链仍后置。
- 2026-07-05：v4.7 明末战役线影响朝廷主议首片落地：`CourtStrategySummary` 新增只读 `campaignPolicyPressure(from:)` 加权，从 `BattleObjectiveSummary` 读取清破关入京、大顺河南秦陕粮链、大西湖广粮道和终局名分线压力，并把这些局势转成修城固守、粮台转运、火器整备、赈济安民或征饷的主议/备议权重；`rationale` 会追加“战役线提示”，让朝廷、HUD、天下面板和 AI 摘要能解释主议为什么随中华世界局势改变。该片只影响朝廷摘要排序和说明，不自动执行朝廷项目，不改变 hex、region、economy、victory、事件或规则权威；可执行项目仍必须走 `Command.enactCourtProject -> CommandValidator -> EconomyRules`。`RuleEngineCoreTests` 增加破关入京线推动主议修城固守的语义用例；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.7_ming_victory_record.md`。本轮仍未做本机 Xcode / XCTest / 模拟器重测试。
- 2026-07-05：v4.7 明末五线态势入 AI 摘要首片落地：新增 `CampaignAISummary` 和 `CampaignLineAISummary`，从 `BattleObjectiveSummary` 只读派生中华世界局势、天下/政策/经济/科技/军事五线压力、领先势力和急务/主线任务；`AgentContext`、`AgentPromptBuilder`、`TurnManager.contextSummary` 与 `MarshalBattlefieldSummary` 接入同一摘要，元帅摘要 `schemaVersion` 升到 9，模拟元帅 strategic intent 会同时读取钱粮、朝议和战役五线压力。该片只扩展 Agent/军机上下文，不自动生成政策、经济、科技或军事命令，不改变 hex、region、economy、victory、事件或规则权威。`RuleEngineCoreTests` 增加五线态势进入 Agent 与元帅摘要的语义用例；同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.7_ming_victory_record.md`。本轮仍未做本机 Xcode / XCTest / 模拟器重测试，发布级地图、部队、朝廷视觉资产和截图验收继续后置。
- 2026-07-05：v4.7 明末天下五线态势首片落地：`BattleObjectiveSummary` 新增只读 `CampaignLineBrief` 摘要，把既有阶段战局链和本旬任务链聚合为天下、政策、经济、科技、军事五线压力、告急状态、急务数量和当前摘要；`BattleObjectivePanelView` 在“目标”tab 新增“天下五线态势”区，让玩家一眼看到破关入京、河南秦陕粮链、湖广粮道、朝廷取舍、火器修城和终局名分中哪条线最急。该片只读派生，不新增持久政策/科技/任务状态，不新增事件执行器，不改变 hex、region、economy、victory、AI 指令或任何规则权威。`RuleEngineCoreTests` 增加五线态势语义用例，覆盖军事/经济告急聚合。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.7_ming_victory_record.md`。
- 2026-07-05：v4.7 明末本旬任务入塘报首片落地：`BattleObjectiveSummary.CampaignTask` 增加塘报正文、优先级排序和日志分类；`CommandExecutor.endTurn` 新增 `appendBattleTaskEvents`，在明末剧本结束当前势力回合时把急务/主线任务最多 3 条写入 `eventLog`，relatedRecordId 使用 `battle-task-<turn>-<faction>-<task id>` 去重。该片只追加塘报日志，不保存任务进度，不新增事件执行器，不改变 hex、region、economy、victory、AI 指令或任何规则权威。`RuleEngineCoreTests` 增加任务塘报语义用例，覆盖破关/粮链压力任务入册和留意任务不入册。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.7_ming_victory_record.md`。
- 2026-07-05：v4.7 明末本旬任务链首片落地：`BattleObjectiveSummary` 新增只读 `CampaignTask` 摘要，按胜负线压力、当前回合、明廷火器/炮队支点和 objective points 领先方派生军事守关、政策征饷安民、经济粮链、科技火器修城和终局名分等当前任务；`BattleObjectivePanelView` 在“目标”tab 新增“本旬任务链”区，用急务、主线、留意优先级强化 10-20 回合目标引导，任务可复用目标定位回调跳回相关 objective / 州府牌。该片只读派生，不新增持久任务状态、事件执行器、政策/科技效果或规则权威改动。`RuleEngineCoreTests` 增加任务链和压力任务切换语义用例。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.7_ming_victory_record.md`。
- 2026-07-05：v4.7 明末目标换手塘报首片落地：`CommandExecutor.executeMove` 在合法移动占领 objective hex 时记录占领前后的 `HexTile.controller`，并由 `appendObjectiveControlEventIfNeeded` 对 `chongzhen_1642*` 剧本追加 `regionOwnerChange` 类塘报，正文包含目标名、原控制方、新控制方和要冲分；该片只记录已经发生的真实 hex 控制变化，不新增事件执行器，不改变 objective 控制、胜负判定、目标摘要、经济、AI 指令或任何规则权威。`RuleEngineCoreTests` 增加清军占领北京后写入 `objective-control` 塘报的语义用例。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.7_ming_victory_record.md`。
- 2026-07-05：v4.7 明末目标定位首片落地：`BattleObjectivePanelView` 的目标城关 chip 增加 `onFocusObjective` 回调，`RootGameView` 接入后调用 `AppContainer.focusObjective(_:)` 并在紧凑信息面板切到州府牌；定位只更新 `selectedHex`、`selectedRegionId`、清空单位选择/移动攻击高亮并写入交互日志，不提交 `Command`，不改变 objective 控制权、hex 控制、胜负判定、战区/部署或任何规则权威。`BoardInteractionTests` 增加目标定位语义用例。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.7_ming_victory_record.md`。
- 2026-07-05：v4.7 明末阶段战局链首片落地：`BattleObjectiveSummary` 新增只读 `CampaignStage` 摘要，按胜负线进度、当前回合、明廷火器/炮队支点和 objective points 领先方派生山海关屏障、河南秦陕粮链、湖广粮道、朝廷四线取舍、火器修城和终局名分线；`BattleObjectivePanelView` 在“目标”tab 新增“阶段战局链”区，用天下、政策、经济、科技、军事标签解释 1-20 回合可玩重点，强化中华世界局势、政策/经济/科技/军事四线和明末代入感。该片只读派生，不新增事件执行器、持久教程状态、灾荒效果或规则权威改动。`RuleEngineCoreTests` 增加阶段链和压力/火器支点语义用例。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.7_ming_victory_record.md`。
- 2026-07-05：继续强化明末迁移项目 md 大纲：`md/plan/plan.md` 新增“下一轮拆分优先级”，把中华世界局势与代入感、政策/经济/科技/军事四线深化、地图/部队/朝廷和核心面板美观、发布级可玩闭环拆成后续 Agent A/B/C 必须引用的任务主线；`md/prompt/README.md` 同步说明该大纲是后续明末任务的验收硬约束。本次只改文档，不改源码、规则、测试配置或 workflow。
- 2026-07-05：v4.7 明末战役目标面板首片落地：新增 `BattleObjectiveSummary`，从 `GameState` / `MapState` 只读派生清破关入京、大顺据中原秦陕、大西据湖广粮区、明廷守京师关口四条胜负线、目标点控制方、objective points 分值和当前领先方；`VictoryRules` 的明末判定改为读取同一摘要，避免 UI 与规则口径分叉；新增 `BattleObjectivePanelView` 并在 `RootGameView` 信息面板加入“目标”tab，展示各势力胜负线进度、关键城关控制方和终局要冲分。`RuleEngineCoreTests` 增加目标摘要语义用例。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.7_ming_victory_record.md`。本轮仍不新增历史事件、教程触发、目标点击定位、完整政策/科技影响胜负链或发布级截图验收。
- 2026-07-05：v4.7 明末战役提示首片落地：`BattleObjectiveSummary` 新增只读 `Cue` 摘要，按当前回合、当前势力、缺粮部队、AI 指令记录和目标线进度派生松锦余波、催饷安民、粮道告急、军机复盘和目标线压力等最多 4 条提示；`BattleObjectivePanelView` 在“目标”tab 增加“战役提示”区，用史势、政务、钱粮、军务、军机分类帮助新玩家理解明末局势、政策/经济/军事取舍和 AI 复盘入口。`RuleEngineCoreTests` 增加开局提示、缺粮提示和目标压力提示用例。该片只强化 v4.7 教程/历史代入感，不新增事件执行器、持久教程状态、灾荒效果、多回合目标链或规则权威改动。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.7_ming_victory_record.md`。
- 2026-07-05：v4.7 明末战役提示入塘报首片落地：`BattleObjectiveSummary.Cue` 增加塘报正文和分类，`CommandExecutor.endTurn` 在胜负判定后调用 `appendBattleCueEvents`，用 `battle-cue-<turn>-<faction>-<cue id>` 作为 `relatedRecordId` 去重，把当前回合战役提示写入 `eventLog`，让松锦余波、催饷安民、粮道告急、军机复盘和目标线压力进入塘报战记和后续复盘。该片只追加日志，不改变 hex、region、economy、victory、AI 指令或任何规则权威；完整事件执行器、灾荒效果、教程状态和 10-20 回合目标链仍后置。`RuleEngineCoreTests` 增加明末结束回合塘报入册用例。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.7_ming_victory_record.md`。
- 2026-07-05：v4.7 明末胜利条件数据驱动首片落地：`GameState` 新增兼容解码的 `victoryConditions`，`DataLoader.loadGameState` 会把 `ScenarioDefinition.victoryConditions` 从 `chongzhen_1642_scenario.json` 写入运行时；`BattleObjectiveSummary` 优先从运行时剧本条件编译清破关入京、大顺据中原秦陕、大西据湖广粮区、明廷守京师关口四条目标线，缺失时才回退旧内置目标；`VictoryRules` 与“目标”面板继续共用同一摘要。`RuleEngineCoreTests` 增加目标摘要读取剧本条件、说明文字和目标顺序的语义用例。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md` 和 `v4.7_ming_victory_record.md`。本轮仍不新增历史事件、教程触发、目标点击定位、完整政策/科技影响胜负链或发布级截图验收。
- 2026-07-05：v4.7 明末胜负链首片落地：`ScenarioDefinition.ObjectiveDefinition` 与 `Objective` 保留 scenario JSON 的 `points` 并兼容旧数据默认 0，`MapState` 支持按 objective id 查询控制方；`VictoryRules` 对 `chongzhen_1642` 剧本启用明末胜负条件：后金/清控制山海关和北京即胜，大顺控制开封/洛阳/西安即胜，大西控制荆州/武昌即胜，明廷最终回合守住北京/山海关/武昌即胜，否则按 objective points 判定最终关键目标归属；legacy 阿登胜负链继续保留。`HUDView` 胜负 badge 追加胜负理由短语，`RuleEngineCoreTests` 增加明末胜负语义用例。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和新增 `v4.7_ming_victory_record.md`。本轮仍不新增历史事件、教程、战役目标 UI、完整政策/科技树或发布级截图验收。
- 2026-07-05：根据用户补充要求更新明末迁移项目 md 大纲：`md/plan/plan.md` 新增“设计重点与验收口径”，把中华世界局势、政策/经济/科技/军事四线并重，以及地图、部队、朝廷、钱粮、天下、将领、军令、军机复盘和塘报等界面美观可用提升为后续每轮任务必须写入目标和验收的路线原则；同时细化 v4.7 为明末胜负链、历史事件和 10-20 回合可玩目标链，细化 v4.8 为发布候选、视觉验收和云端收口。本次只改文档大纲和维护记录，不改源码、规则、测试配置或云端 workflow。
- 2026-07-05：v4.6 明末势力旗号首片落地：`Faction.bannerGlyph` 为明廷、后金/清、大顺、大西和地方中立提供“明/清/顺/西/乡”短旗号，legacy 德/盟保留兼容；`UnitNode` 在地图军牌顶端显示势力旗号，`UnitInspectorView` 与 `CommandPanelView` 的军牌印面同步显示旗号；`RootGameView` 顶部舆图图例新增“势力旗 / 明 / 清 / 顺”；`PlatformStyles` 提供 `Faction.mingBannerTint` 与 `MingFactionFlagBadge` 复用样式，`DiplomacyPanelView` 改用同一 tint。该片只强化地图、部队和军令面板的势力归属可读性与中华世界局势代入感，不改变 `Faction` 控制语义、`DiplomacyState`、`Division`、`Command`、`ZoneDirective`、`WarCommandExecutor`、`CommandValidator`、`RuleEngine` 或任何规则权威。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。
- 2026-07-05：v4.6 明末军令计划线首片落地：`BoardScene.drawPlannedOperations` 从基础箭头/固守圈升级为只读军令计划线，当前回合玩家进取计划显示朱砂箭头、暗色 glow 和“进”令牌，固守计划显示青绿“守”令牌；`RootGameView` 顶部舆图图例新增“军令计划 / 进取 / 固守”。该片只强化地图计划线可读性和明末军令代入感，不新增计划状态，不创建、删除或执行 `PlayerPlannedOperation`，不改变 `PlayerCommandState`、`ZoneDirective`、`WarCommandExecutor`、`Command`、`CommandValidator`、`RuleEngine` 或任何规则权威。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。
- 2026-07-05：v4.6 明末将领面板首片落地：`GeneralCommandPanelView` 从简单将领列表升级为只读将印军令，顶部显示“将”印、防区状态和本营压力，主体展示防区、压力、战态、目标、主将履历、忠诚、军心、手令干预、麾下军伍和军令计划；`GeneralProfileView` 从将领档案升级为将领名帖，展示印信、官职势力、统兵风格、履历奏记、君臣关系、将略和麾下军伍；`RootGameView` 信息面板日志入口同步改为“塘报”。该片只强化将领/督师界面美观度和明末代入感，不改变 `GeneralData`、`GeneralAssignment`、`WarDeploymentState`、`ZoneDirective`、`WarCommandExecutor`、`Command`、`CommandValidator`、`RuleEngine` 或任何规则权威；固守/进取仍通过原回调进入既有指令链。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。
- 2026-07-05：v4.6 明末塘报战记首片落地：`EventLogView` 从简单战报列表升级为只读塘报战记，顶部显示“报”印、近报数量、最新分类和候报/有军情/粮情/战局/天下状态；摘要区按战事、粮草、州府、天下统计最近 60 条日志；每条塘报展示分类图标、回合、势力、阶段、正文和相关回执，颜色改用 `MingDesignTokens` 口径。该片只强化事件日志界面美观度和明末代入感，不改变 `GameLogEntry` schema、事件写入点、`Command`、`CommandValidator`、`RuleEngine` 或任何规则权威。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。
- 2026-07-05：v4.6 明末军机复盘牌首片落地：`AgentPanelView` 从 LabeledContent 调试字段列表升级为军机复盘牌，顶部显示“机”印、成令/驳回/战区计数和候报/已成令/有驳回/有异常状态；决策摘要区展示主事、来源、意图和局势摘要；最高意志区展示主上、姿态、重心、目标、攻势阈、留营、天下判断和朱批理由；战区指令区展示方面、防御/进攻、势力、军机、督师、战术、目标、指向、成功/驳回数量和 diagnostics；命令回执区整合旧 Agent D 与 `WarDirectiveRecord` 中的命令结果，按已执行、被驳回、映射失败分色，并保留异常塘报和可选择原始 JSON。该片只强化 AI/军机复盘界面美观度和明末代入感，不改变 `AgentDecisionRecord`、`RulerDecisionRecord`、`WarDirectiveRecord` schema，不改变 `MarshalAgent`、`RulerAgent`、`TurnManager`、`WarCommandExecutor`、`Command`、`CommandValidator`、`RuleEngine` 或任何规则权威。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。
- 2026-07-05：v4.6 明末军令牌首片落地：`CommandPanelView` 从简单标题、状态和按钮列表升级为军令牌，顶部显示“令”印、当前势力、阶段和可下令/候令/观战/敌情/已行动状态；选中军情区展示军牌字、部队名称、势力、兵种定位、兵力条、粮草、退守、行动和坐标；战术处置区展示固守、准许退守、就地补给三类按钮及明末化短说明，底部保留结束回合入口和“军令回执”。该片只强化军事指令界面美观度和明末代入感，不改变 `GameState`、`Command`、`CommandValidator`、`RuleEngine`、补给、撤退、回合或任何规则权威；固守、退守、补给和结束回合仍通过 `RootGameView` 注入的 `AppContainer` 原有回调进入命令链。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。
- 2026-07-05：v4.6 明末朝报令条首片落地：`HUDView` 从简单标题和 grid 指标升级为顶部朝报令条，显示“朝”印、崇祯十五年天下裂变、当前势力、阶段、胜负状态、新局和结束回合入口；令条指标展示回合、民力、银两、粮草、营造队列和本回合入账；朝议四线区读取 `CourtStrategySummary.from(faction:state:)` 展示政策、经济、科技、军事四线压力和主议领域。该片只强化第一屏战局中枢和明末代入感，不改变 `GameState`、回合规则、朝廷项目、经济结算、生产规则、`Command` 或任何规则权威；结束回合和新局仍通过 `RootGameView` 注入的 `onEndTurn` / `onNewGame` 回调执行。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。
- 2026-07-05：v4.6 明末府库牌首片落地：`EconomyPanelView` 从总账 grid 和按钮列表升级为只读府库牌，顶部显示“库”印、当前势力和可下令/待本方/观战状态；府库总账区展示民力、银两、粮草库存、本回合入账、军粮维护、补员消耗和更新时间；募兵与筹粮区展示募营兵、募精骑、募哨骑、造炮队、筹粮的明末意图、成本和回合数；营造队列区展示剩余回合、待部署状态和进度条。该片只强化钱粮界面美观度和明末代入感，不改变 `EconomyState`、经济结算、生产规则、补员、补给、`Command` 或任何规则权威；生产按钮仍通过 `onQueueProduction -> AppContainer.queueProduction -> Command.queueProduction -> CommandValidator -> EconomyRules` 执行。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。
- 2026-07-05：v4.6 明末州府牌首片落地：`RegionInspectorView` 从字段列表升级为只读州府牌，顶部显示州府徽记、州府名、控制方、地形和城级；治理区展示民变、行政掌控和钱粮修正；钱粮城防区展示民力、银两、粮草、粮台、工坊、驿道、城池和关隘；战局归属区展示方面、防区、目标、友军和可见敌军；当前格区展示坐标、控制、动态方面和防区。该片只强化州府界面美观度和明末代入感，不改变 hex 控制、region 聚合、经济结算、动态战区、前线、部署、`Command` 或任何规则权威。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。
- 2026-07-05：v4.6 明末部队军情牌首片落地：`UnitInspectorView` 从字段列表升级为只读军情牌，顶部显示军牌字、部队名称、势力、部队定位和控制状态；军情区展示兵力进度条、粮草、退守、行动和状态；指标区展示攻、守、行、程、察五项 `Division.effectiveStats`；编成区按 `DivisionComponent.weight` 绘制兵种条；驻防归属区读取 `UnitInspectorStrategicState` 展示坐标、州府、动态方面、防区、部署和前线。该片只强化部队界面美观度和明末代入感，不改变 `Division`、`CombatRules`、`SupplyRules`、`WarDeploymentState`、`Command` 或任何规则权威。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。
- 2026-07-05：v4.6 明末朝议争点首片落地：`CourtPanelView` 在四线压力之后新增“朝议争点”区，基于只读 `CourtStrategySummary` 展示安民与征饷、火器与团练、粮道与城防三组冲突，并用现有压力值、州府数、不稳州府、火器/炮队数和前线数给出先稳地方、先补军费、先整火器、先固军伍、先保粮台或先守要冲等当前偏向。该片只强化朝廷界面代入感和政策/经济/科技/军事取舍表达，不新增 `GameState` 字段，不改变 `Command.enactCourtProject`、`CommandValidator`、`EconomyRules`、外交关系或任何规则权威。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。
- 2026-07-05：v4.6 明末天下急势首片落地：`DiplomacyPanelView` 新增顶部“天下急势”摘要条，从 `DiplomacyState` 和只读 `CourtStrategySummary` 派生当前势力、战局态势、主要对手、平均战意、朝议主线和政策/经济/科技/军事四线压力；“诸方势力”列表改为势力色、阵营名义和战意进度条展示。`RootGameView` 仅向天下面板传入当前 active faction 的朝议摘要。该片只强化 SwiftUI 展示和中华世界局势代入感，不新增外交状态，不改变 `RulerAgent`、`Command.enactCourtProject`、`EconomyRules`、外交关系判断或任何规则权威。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。
- 2026-07-05：v4.6 明末舆图图例首片落地：`MapDisplayLayer.displayName` 从 `Hex / Province / Initial / Dynamic / Front / Deploy` 改为舆图、州府、初划、战局、前线、布防，并新增图层图标、图例标题和说明；`RootGameView` 顶部地图控件新增“舆图”标题、当前图层说明和横向图例条，在 hex 图层解释“城 / 关 / 粮 / 步”和粮道虚线，在非 hex 图层解释州府、开局方面、动态方面、前线和布防语义。该片只改 SwiftUI 展示与图层元数据，不改变 `MapDisplayLayer` rawValue、`GameState`、`MapDisplayAdapter`、overlay 计算、补给判定或任何规则权威。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`，继续推进地图界面美观度和明末战局代入感。
- 2026-07-05：v4.6 明末粮道开关和图例首片落地：`AppContainer` 新增 `showsSupplyRoutes` UI 状态，`BoardRenderState` 将该状态传给 `BoardScene`，`drawSupplyRoutes` 在关闭时直接跳过绘制；`RootGameView` 顶部地图控件新增按钮式“粮道”开关，并在 hex 图层开启时显示金色虚线图例“粮道 / 可达粮台”。该片只控制 UI 展示，不改变 `SupplyRules.supplyPath`、`hasSupplyLine`、单位 `supplyState`、补给规则或任何 `GameState` 权威状态。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`，继续推进地图界面可读性与明末粮道代入感。
- 2026-07-05：v4.6 明末朝廷四线项目分组首片落地：新增 `CourtProjectDomain`，把征饷、赈济安民、修城固守、整训团练、火器整备、粮台转运归入政策、经济、科技、军事四线；`CourtPanelView` 将“可行项目”改为“四线项目”，按四线展示压力值、关注点、项目成本收益和风险，粮台转运继续显示经济/军事交叉属性。该片只改朝廷项目结构化展示和 UI 分组，不新增多回合政策/科技状态，不改变 `Command.enactCourtProject -> CommandValidator -> EconomyRules -> RuleEngine` 执行权威。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`，继续落实政策、经济、科技、军事四线并重。
- 2026-07-05：v4.6 明末粮道线路可视化首片落地：`SupplyRules` 新增只读 `supplyPath(from:to:for:in:)` 与 `supplyPath(for:in:)`，复用既有 hex 补给通行、河流成本、敌控/ZOC 和最大成本规则返回粮道路径；`hasSupplyLine` 改为使用同一 path helper，避免判定和展示分叉。`BoardScene` 在默认 hex 图层为玩家势力非毁灭部队绘制可达粮台的金色虚线，选中单位路线优先加粗，重复路段去重，线路 zPosition 低于 fog、高于道路/河流，只作展示层，不新增 `GameState` 字段、独立粮道状态、漕运资源或补给规则。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。
- 2026-07-05：v4.6 明末地图标识 polish 首片落地：`BaseTerrain.displayName` 改为平原、林地、山地、丘陵、城池、关隘/堡寨；`HexNode` 为城池、关隘/堡寨和补给源增加“城 / 关 / 粮”舆图 badge，旧主地图 `FORT` 与 `SUP A/G` 文案改为“关隘”“粮台”，粮台 badge 按补给源当前势力染色；`TerrainStyle` 增加地图 badge 样式，关隘与城池同格时下移关隘标识避免重叠。该片只影响 SpriteKit 展示，不改变补给、占领、经济、动态战区、部署层或 `Command` / `RuleEngine` 权威。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`，继续回应地图、部队、朝廷界面需要好看并增强明末代入感的目标。
- 2026-07-05：v4.6 明末朝廷项目首片落地：新增 `CourtProjectKind`，把征饷、赈济安民、修城固守、整训团练、火器整备、粮台转运六类项目挂入朝廷面板；`Command` 新增 `enactCourtProject(kind:)`，由 `CommandValidator` 校验 phase 和资源，`CommandExecutor` 委托 `EconomyRules.enactCourtProject` 执行，`WarCommandExecutor.actingDivisionId` 同步兼容无单位命令。效果保持轻量：项目可影响民力/银两/粮草、地方民变/行政掌控、州府 infrastructure/supplyValue、生产队列、火器/炮队补整和缺粮部队；不新增旧 Cabinet/Minister/StrategicDirective 污染，不做多回合科技树、招抚链或 Ruler 自动政策层。`CourtPanelView` 新增“可行项目”区，按主议置顶并显示成本、收益和风险；`RootGameView` 与 `AppContainer` 接入提交入口。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和 `v4.6_ming_ui_polish_record.md`。
- 2026-07-05：v4.6 明末发布级 UI polish 首片落地：新增 `MingDesignTokens` 统一明末面板圆角、间距、44pt 触控高度和朱砂/金/青瓷色彩；`CourtPanelView` 从 `RootGameView` 拆为独立文件并加入 iOS/macOS source phase，继续只读 `CourtStrategySummary`，用朝印、主议、四线压力、备议和指标网格强化朝廷代入感；`RootGameView`、`GeneralCommandPanelView`、`GeneralProfileView`、`UnitInspectorView`、`UnitTooltipView`、`EventLogView`、`AgentPanelView`、`InfoPanelToggle`、`NewGameButton` 做明末中文 polish；`UnitNode` 移除默认主地图 NATO APP-6 兵牌，改为 `城/旗/火/骑/步` 中文军牌和 `守/退` 状态；`BoardScene` 空态改为“明末棋策舆图”。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md`，新增 `v4.6_ming_ui_polish_record.md`。本轮仍不新增可执行政策/科技命令，不恢复旧 Cabinet/Minister/StrategicDirective 污染，不直接改 `GameState`；真实美术资产、地图纹理、真实旗帜资产、粮道可视化、截图验收和完整移动端/macOS 布局仍后续继续。
- 2026-07-05：v4.5 明末朝廷、政策科技与四线摘要首片落地：新增 `CourtPolicyFocus` 与只读 `CourtStrategySummary`，从钱粮、治理、补给、前线压力、缺粮/被围单位和火器/炮队状态派生政策、经济、科技、军事四线压力，给出征饷、赈济安民、修城固守、整训团练、火器整备、粮台转运等主议/备议；`RootGameView` 信息面板新增“朝廷”tab 和 `CourtPanelView`，展示当前议题、理由、四线压力条、备议收益/风险和州府/前线/火器指标；`AgentContext`、`AgentPromptBuilder`、`TurnManager.contextSummary` 与 `MarshalBattlefieldSummary` 接入同一 `courtSummary`，元帅摘要 schemaVersion 升到 8。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md`、明末迁移总提示词和 `v4.5_ming_court_policy_record.md`，继续强调中华世界局势，以及政策、经济、科技、军事并重。本机轻量检查通过：`swiftc -parse` 改动 Swift 文件、`git diff --check`、文档尾随空白扫描、行首冲突标记扫描、旧默认测试口径扫描。GitHub Actions run `28718334418`（attempt 1）对提交 `3abed2c9eb990d61392a9c0f46358a3db2f63a77` 验证通过，artifact 为 `wwiihexv0-ci-cloud-process-main-3abed2c-run28718334418-attempt1`，manifest 显示 static checks 和 `WWIIHexV0Mac` Debug build 均 success，JUnit 为 2 tests / 0 failures。本轮不新增可执行政策/科技命令，不恢复旧 Cabinet/Minister/StrategicDirective 污染，不直接改 `GameState`，仍未完成发布级地图、部队、朝廷美术与交互收口。
- 2026-07-05：v4.4 明末地方治理与天下局势首片继续推进：`OccupationState.resistance/compliance` 以民变/行政掌控口径解释，并通过 `economicYieldPercent` 轻量修正州府民力、银两、粮草产出；`EconomyRules.incomeContribution(for:faction:map:)` 统一单州府收入口径，州府面板与经济结算共用；`RegionInspectorView` 展示治理摘要和钱粮修正；`GovernanceAISummary` 纳入 AI 钱粮摘要，元帅摘要 schemaVersion 升到 7；`DiplomacyPanelView` 改为“天下局势”，展示当前势力、名义主体、战事态势、主要对手、诸方势力、战和关系和朝议/军议，`RootGameView` 信息面板入口由“外交”改为“天下”。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md` 和明末迁移总提示词，明确后续要侧重中华世界局势，并让政策、经济、科技、军事四线并重；地图、部队、朝廷、钱粮、天下局势等界面需按发布级 UI 目标推进。本机轻量检查通过：`git diff --check`、文档尾随空白扫描、行首冲突标记扫描、旧默认测试口径扫描、改动 Swift 文件 `swiftc -parse`。GitHub Actions run `28717840389`（attempt 1）对提交 `5879d6b17a615bd9cfcfd90755aed7a294e28061` 验证通过，artifact 为 `wwiihexv0-ci-cloud-process-main-5879d6b-run28717840389-attempt1`，manifest 显示 static checks 和 `WWIIHexV0Mac` Debug build 均 success，JUnit 为 2 tests / 0 failures。本轮仍未新增政策/科技/军械命令、灾荒/民心字段、完整军饷士气链、多回合围城链或发布级美术资源；这些必须后续通过统一命令/规则系统继续落地。
- 2026-07-05：v4.4 明末钱粮与地方治理首片落地：`EconomyResources` 继续保留 `manpower/industry/supplies` 兼容字段，但 UI、日志和 AI 摘要显示为民力、银两、粮草；生产项显示为募营兵、募精骑、募哨骑、造炮队、筹粮；明末势力生产完成后生成步军/火器/骑兵、旗骑/骑兵/火器、骑兵/步军/团练、炮队/攻城器械/步军等明末组件单位，legacy Germany / Allies 仍保留旧工厂方法；`GamePhase.allowsHumanCommands` 和 `AppContainer.bootstrap()` 修复默认明廷玩家在 `.humanAction` 阶段的操作入口；HUD、军令、钱粮、州府、军队 tooltip、日志分类和 macOS 菜单做明末中文首片迁移；`AgentContext`、`AgentPromptBuilder`、`MarshalBattlefieldSummary`、`TurnManager.contextSummary` 纳入钱粮摘要，元帅摘要 schemaVersion 升到 6。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md`，新增 `md/prompt/v4.0-明末迁移/v4.4_ming_economy_governance_record.md`。本机轻量检查通过：`git diff --check`、文档尾随空白扫描、行首冲突标记扫描、旧默认测试口径扫描、改动 Swift 文件 `swiftc -parse`。GitHub Actions run `28717148525`（attempt 1）对提交 `211b4f680d3ca894d0f600256007eb7eb5e39377` 验证通过，artifact 为 `wwiihexv0-ci-cloud-process-main-211b4f6-run28717148525-attempt1`，manifest 显示 static checks 和 `WWIIHexV0Mac` Debug build 均 success，JUnit 为 2 tests / 0 failures。本轮仍未完成灾荒/治安/民心、拖欠军饷影响士气/忠诚、修城/赈济/征饷/屯田命令、完整围城链和发布级 UI。
- 2026-07-05：v4.3 明末军队与战术首步落地：`ComponentType` 新增骑兵、火器、旗骑、团练和攻城器械；`unit_templates.json` 追加明廷、后金/清、大顺、大西、地方团练首批模板；`chongzhen_1642_scenario.json` 的 22 个初始单位改用明末 template；`Division` 增加机动、火力支援和攻城 helper，`WarCommandExecutor` / `ZoneCommanderAgent` 改用通用机动判断；`CombatRules` 增加 city / fortress 攻城加成和非邻接火力支援加成；`TacticName.displayName` 和 Agent 面板摘要开始显示明末战术名；MapEditor 默认单位模板和阵营切到明廷口径。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md`，新增 `md/prompt/v4.0-明末迁移/v4.3_ming_units_tactics_record.md`。本机轻量检查通过；GitHub Actions run `28715930163`（attempt 1）对提交 `8910499573ee43395675c98178852090bab8bcca` 验证通过，artifact 为 `wwiihexv0-ci-cloud-process-main-8910499-run28715930163-attempt1`。本轮仍未完成多回合围城状态、粮草/军饷字段、明末胜负链和发布级 UI。
- 2026-07-05：v4.2 明末默认数据首片落地：新增 `chongzhen_1642_scenario.json` 与 `chongzhen_1642_regions.json`，默认剧本为 `崇祯十五年：天下裂变`，包含 120 hex、30 region、69 条 region edge、9 个补给源、12 个 objective、14 个 key location 和 22 个初始单位；`DataLoader.loadInitialGameState()` 优先加载明末 JSON，失败后回退阿登 legacy；`ScenarioDefinition` 支持 `turnOrder`、human / AI 控制数组；`MapEditorGameResourceBridge` 默认读写明末 JSON，`MapEditorExporter` 会按明末势力推导回合与控制数组；`RegionDataSet.toRegions()` 缺省 owner/controller 改为 `.localNeutral`，避免中立 region 回退盟军。同步更新 `README.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/plan/plan.md`、`md/prompt/README.md`，新增 `md/prompt/v4.0-明末迁移/v4.2_ming_scenario_data_record.md`。本轮仍未迁移明末 unit templates、经济资源命名、明末胜负链和发布级 UI。
- 2026-07-05：v4.1 多势力兼容层开始落地：`Faction` 新增明廷、后金/清、大顺、大西、地方中立并保留 Germany / Allies legacy；`DiplomacyState` 增加 `canAttack`、`isHostile`、`isFriendly`、`canEnterTerritory`；`GameState` / `ScenarioDefinition` 增加 `turnOrder`、human / AI 控制数组；`CommandExecutor` 按 turn order 轮转，`CommandValidator` 攻击校验改走外交关系；`AppContainer` AI 运行条件改为读取控制数组；经济/外交 bootstrap 收窄到实际参战/控制数组；`MapEditorExporter` 不再无条件导出所有 `Faction.allCases`；补齐明末势力临时颜色和 legacy 胜利计数 fallback。同步更新 `md/flow/flow.md`、`md/flow/flowchart.md`、`README.md`、`md/plan/plan.md`。本轮未切换默认明末剧本，未迁移兵种/经济/UI，未跑本机重测试。
- 2026-07-05：新增 v4.1 多势力、外交关系和通用回合编排实现提示词，基于 v4.0 审计固定 `Faction` 扩展、关系 helper、`.opponent` 替换、通用 turn order、AI 运行条件、文档同步和轻量检查要求。关键文件：`md/prompt/v4.0-明末迁移/v4.1_powers_turns_prompt.md`、`md/prompt/README.md`、`md/plan/plan.md`、`update_log.md`。
- 2026-07-05：补齐 v4.0 明末迁移首轮只读审计，记录 `Faction.opponent`、`GamePhase.germanAI/alliedPlayer`、阿登默认数据入口、MapEditor 二元导出、二战兵种/经济/UI/NATO 兵牌等迁移阻塞点，并形成 v4.1 最小接口合同草案。本次仍是文档审计，不代表源码已完成多势力或明末剧本迁移。关键文件：`md/prompt/v4.0-明末迁移/v4.0_audit_and_contract.md`、`md/plan/plan.md`、`update_log.md`。
- 2026-07-05：根据明末迁移总提示词重写项目 md 大纲，将 `md/plan/plan.md` 调整为 v4.0-v4.8 明末迁移路线入口，新增 `md/prompt/v4.0-明末迁移/v4.0_audit_and_contract.md`，并同步 `md/prompt/README.md` 与 `README.md` 的文档索引。本次是文档结构维护，不代表源码已完成明末迁移。关键文件：`md/plan/plan.md`、`md/prompt/v4.0-明末迁移/v4.0_audit_and_contract.md`、`md/prompt/README.md`、`README.md`、`update_log.md`。
- 2026-07-04：升级项目协作流程为 `main` 直推 + GitHub Actions 云端验证 + Agent C 下载未加密结果包复判；新增角色召唤与身份标识规则，补齐 `md/prompt/README.md`，新增 `.github/workflows/ci-results.yml`。本次是流程制度和验证骨架变更，不代表业务功能或运行时质量提升。关键文件：`AGENTS.md`、`README.md`、`md/test/test.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md`、`.github/workflows/ci-results.yml`。
- 2026-06-15：重整 `md` 目录，添加 README，补充 v0.1-v1.0 提示词。
- 2026-06-15：打捞 Agent D 与误删代码，恢复 AI 决策管线。
- 2026-06-15：记录 v0.5 擅自编程与回退资料，保留为历史警示；当前主线不得引入 Cabinet/StrategicDirective/Minister 污染。
- 2026-06-18：整理文档结构，将已完成阶段文档迁入 `md/prompt/...（已完成）`。
- 2026-06-24 至 2026-06-25：补充 0.36 提示词、0.355 截止分析、20 回合文档更新。
- 2026-06-27：创建 `AGENT.md`，写入后续 Codex 接手项目时的架构、测试、文档维护和交付规则。
- 2026-07-04：更新当前协作规范：默认禁止 Xcode / XCTest / 模拟器 / 性能类重测试，只做轻量语法/格式检查；新增多版本分支、并发子 Agent 和合并前冲突检查规则。关键文件：`AGENTS.md`、`md/test/test.md`、`md/flow/flow.md`、`README.md`、`md/prompt/v0.f/fable-5-重构优化总提示词.md`。
- 2026-07-04：新增拿破仑战争迁移总提示词，规划 v3.0-v3.8 从 WWIIHexV0 迁移为 AI Agent 驱动拿战游戏的版本路线、最终发布效果、并发子 Agent 分工、轻量检查和风险边界。关键文件：`md/prompt/v3.0-拿战迁移/codex-v3.0-拿战aiagent迁移总提示词.md`。
- 2026-07-04：新增明末迁移总提示词，规划 v4.0-v4.8 从 WWIIHexV0 迁移为 AI Agent 驱动明末历史策略游戏的产品目标、版本路线、最终发布效果、并发子 Agent 分工、轻量检查和风险边界。关键文件：`md/prompt/v4.0-明末迁移/codex-v4.0-明末aiagent迁移总提示词.md`。
- 2026-07-04：新增唐宋迁移总提示词，规划 v5.0-v5.9 从 WWIIHexV0 迁移为 AI Agent 驱动唐宋时代历史策略游戏的首发剧本、产品目标、架构边界、版本路线、并发子 Agent 分工、轻量检查和发布验收标准。关键文件：`md/prompt/v5.0-唐宋迁移/codex-v5.0-唐宋aiagent历史策略迁移总提示词.md`。
- 2026-07-04：新增现代战争迁移总提示词，规划 v6.0-v6.10 从 WWIIHexV0 迁移为 AI Agent 驱动现代联合指挥策略游戏的首发虚构剧本、ISR/EW/火力/无人系统闭环、版本路线、并发子 Agent 分工、轻量检查和发布验收标准。为避免与既有 v5.0 唐宋/维多利亚迁移文档冲突，现代战争路线使用 v6.0 起始版本。关键文件：`md/prompt/v6.0-现代战争迁移/codex-v6.0-现代战争aiagent迁移总提示词.md`。
