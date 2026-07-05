# WWIIHexV0 — 明末迁移中的 iOS / macOS AI 战略战棋工程

> **当前状态：代码仍以 WWIIHexV0 / 阿登 legacy 底座为兼容主线，文档大纲已切换到 v4.0-v4.8 明末迁移路线。当前工作树已推进到 v4.7 明末胜负链首片和 v4.6 发布级明末 UI、朝廷项目、地图标识首片：`Faction` 可表达明廷、后金/清、大顺、大西和地方中立，`DataLoader.loadInitialGameState()` 优先加载 `崇祯十五年：天下裂变` 明末 JSON，失败才回退阿登；默认明末初始单位已切到关宁铁骑、八旗骑营、红衣炮队、流民军老营、地方团练等明末 template；生产和经济 UI 已以民力、银两、粮草、募营兵、募精骑、造炮队、筹粮口径展示，钱粮面板已升级为府库牌，集中展示库存、入账、军粮维护、补员消耗、募兵筹粮和营造队列；地方治理会影响州府钱粮，州府详情已升级为明末州府牌，集中展示城关粮坊、治理、钱粮修正、战局归属、目标、友敌军和当前格；天下局势面板展示诸方势力、战和关系和朝议/军议，并新增“天下急势”摘要、势力战意条和朝议四线压力；朝廷面板和 AI 摘要开始显示政策、经济、科技、军事四线压力与议题建议，并新增安民与征饷、火器与团练、粮道与城防三组只读朝议争点；顶部 HUD 已升级为朝报令条，前置展示当前势力、回合、胜负、胜负理由、民力、银两、粮草、入账、营造队列和朝议四线压力；部队详情已升级为明末军情牌，显示军牌字、势力旗号、兵力条、粮草/退守/行动、攻守行程察指标、兵种编成条和驻防归属；军令面板已升级为明末军令牌，展示当前势力/阶段、选中军情、势力旗号、兵力、粮草、退守、行动、固守/退守/补给处置和军令回执；将领面板已升级为将印军令和将领名帖，展示防区态势、主将履历、忠诚、军心、手令干预、麾下军伍和军令计划；事件日志已升级为塘报战记，按战事、粮草、州府和天下分类展示最近塘报；朝廷面板还提供征饷、赈济安民、招抚乡绅、修城固守、整训团练、火器整备、粮台转运七类可执行朝廷项目，项目已按政策、经济、科技、军事四线分组显示压力、关注点、成本收益和风险；默认主地图已把地形名切为平原、林地、山地、丘陵、城池、关隘/堡寨，并用“城 / 关 / 粮”标识城池、关隘和粮台；hex 图层会按现有 `SupplyRules` 为玩家势力有路可达的军队绘制粮道虚线，当前回合玩家军令计划会以“进/守”令牌和朱砂/青绿计划线显示，军牌顶端会以“明/清/顺/西/乡”等旗号显示势力归属，顶部图层已改为舆图、州府、初划、战局、前线、布防等中文名，并提供城/关/粮/步、势力旗、军令计划和粮道图例条。明末胜负规则首片已按 `chongzhen_1642` 剧本接入：清破山海关/北京、大顺控开封/洛阳/西安、大西控荆州/武昌、明廷最终守北京/山海关/武昌，以及最终 objective points 归属；“目标”面板还新增只读天下五线态势、本旬任务链和阶段战局链，用天下、政策、经济、科技、军事五线压力提示当前 1-20 回合的中华世界局势重点；同一五线态势已进入 `AgentContext` 和 `MarshalBattlefieldSummary`，元帅摘要 schemaVersion 升到 9，让 legacy Agent prompt 与默认 Marshal strategic intent 都能读取明末名分、粮链、火器和军政压力；朝廷摘要也会读取明末战役线压力，把破关入京、河南秦陕粮链、湖广粮道和终局名分线转成修城、粮台、火器、赈济、招抚或征饷的主议/备议权重；legacy 阿登胜负链保留。军令按钮仍通过 `RootGameView -> AppContainer` 注入的原有回调提交到底层命令链，朝廷项目按钮仍通过 `Command.enactCourtProject -> CommandValidator -> EconomyRules -> RuleEngine` 执行，募兵筹粮按钮仍通过 `Command.queueProduction -> CommandValidator -> EconomyRules` 执行，不绕过规则系统。灾荒、军饷士气链、历史事件执行器、教程、真实美术资产和发布级截图验收仍未完成。历史测试基线曾达到 v0.37 Probe 18/0、Stage Regression 69/0、Full 226/0；当前工作流默认不跑 Xcode / XCTest / 模拟器测试，只按 `md/test/test.md` 做轻量检查。**

> v4.7 最新增量：`DataLoader` 会把 `ScenarioDefinition.victoryConditions` 写入 `GameState.victoryConditions`，`BattleObjectiveSummary` 优先从剧本条件编译明末胜负线和 objective points 领先方，并额外派生松锦余波、催饷安民、粮道告急、军机复盘和目标线压力等只读战役提示；结束回合时这些 cue 会以去重 `relatedRecordId` 入塘报日志；同一摘要还派生只读天下五线态势、本旬任务链和阶段战局链，让目标面板用天下、政策、经济、科技、军事五线压力，以及守山海关与京师、定征饷安民尺度、巡河南湖广粮根、补火器与城防、终局名分线等任务解释当前可玩重点。`CampaignAISummary` 会把同一五线态势转成 Codable 摘要，进入 `AgentContext`、`AgentPromptBuilder`、`TurnManager.contextSummary` 和 `MarshalBattlefieldSummary`，使 AI/军机链路也能看到当前中华世界局势压力；`CourtStrategySummary` 也会读取同一胜负线压力，把破关入京、河南秦陕粮链、湖广粮道和终局名分线加权到朝廷主议与备议。回合末还会把急务/主线任务最多 3 条写入任务塘报，帮助玩家在塘报战记里复盘当旬军政钱粮火器重点，但不执行事件效果。`VictoryRules` 与新增“目标”信息面板共用该摘要，玩家现在可在局内查看清破关入京、大顺据中原秦陕、大西据湖广粮区和明廷守京师关口各差哪些城关，并可点击目标城关 chip 或任务定位按钮定位对应 hex / 州府，便于从胜负线回到舆图和州府牌。明末 objective 因真实移动占领换手时，`CommandExecutor` 还会追加目标换手塘报，让北京、山海关、开封等关键城关变化进入复盘。

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
- v4.6 首片开始发布级 UI 收口：`MingDesignTokens` 统一明末面板色彩/圆角/间距；`CourtPanelView` 从 `RootGameView` 拆出并改为奏疏/印玺风格；军令、将领名帖、单位详情、单位浮窗、塘报战记、AI 决策、信息按钮和新局按钮继续中文化；`UnitNode` 不再绘制 NATO APP-6 兵牌，改为“城/旗/火/骑/步”和“守/退”中文军牌；地图空态标题改为“明末棋策舆图”。
- v4.6 朝报令条首片继续 polish 顶部 HUD：`HUDView` 从普通指标 grid 升级为朝报令条，读取 `FactionEconomyLedger` 和只读 `CourtStrategySummary` 展示当前势力、回合、胜负、民力、银两、粮草、入账、营造队列和政策/经济/科技/军事四线压力；结束回合和新局按钮仍使用原回调，不直接改规则状态。
- v4.6 府库牌首片继续 polish 钱粮界面：`EconomyPanelView` 从表格/按钮列表升级为府库牌，读取 `FactionEconomyLedger` 展示民力、银两、粮草库存、本回合入账、军粮维护、补员消耗、募兵筹粮和营造队列；生产按钮仍只调用 `onQueueProduction -> AppContainer.queueProduction -> Command.queueProduction`，不直接改经济账本。
- v4.6 部队军情牌首片继续 polish 部队界面：`UnitInspectorView` 以军情牌展示选中部队，读取 `Division` 的兵力、补给、退守、行动、`effectiveStats` 和兵种组件，以及 `UnitInspectorStrategicState` 的州府、动态方面、防区、部署和前线归属；该片只影响 SwiftUI 展示，不改变战斗、补给、部署或命令规则。
- v4.6 军令牌首片继续 polish 军事指令界面：`CommandPanelView` 从简单按钮列表升级为军令牌，展示当前势力/阶段、选中军情、兵力、粮草、退守、行动、固守/退守/补给处置和最近军令回执；固守、准许退守、就地补给和结束回合仍只调用 `RootGameView` 注入的 `AppContainer` 回调，不直接改 `GameState`。
- v4.6 将领面板首片继续 polish 督师/总兵界面：`GeneralCommandPanelView` 升级为将印军令，展示防区、压力、战态、主将履历、忠诚、军心、干预、麾下军伍、目标和军令计划；`GeneralProfileView` 升级为将领名帖，展示印信、统兵风格、履历奏记、君臣关系、将略和麾下军伍；固守/进取仍只调用原回调，不直接改规则状态。
- v4.6 军机复盘牌首片继续 polish AI 决策界面：`AgentPanelView` 从调试字段列表升级为军机复盘牌，展示最高意志、决策摘要、战区指令、命令回执、异常塘报和原始 JSON；它只读取 `AgentDecisionRecord`、`RulerDecisionRecord` 与 `WarDirectiveRecord`，不改变 AI、命令或规则执行链。
- v4.6 塘报战记首片继续 polish 事件日志界面：`EventLogView` 从简单战报列表升级为塘报战记，展示最近塘报数量、战事/粮草/州府/天下分类计数、最新分类、回合/势力/阶段和相关回执；该片只读取 `GameLogEntry`，不改变日志 schema、命令执行或规则权威。
- v4.6 州府牌首片继续 polish 州府界面：`RegionInspectorView` 从字段列表升级为州府牌，读取 `RegionInspectorState` 展示城关粮坊、地方治理、钱粮城防、方面/防区/目标、友敌军和当前格；该片只影响 SwiftUI 展示，不改变 hex 控制、region 聚合、经济结算、动态战区、前线或命令规则。
- v4.6 天下急势首片继续 polish 天下局势面板：顶部摘要从 `DiplomacyState` 和只读 `CourtStrategySummary` 派生当前势力、战局态势、主要对手、战意和政策/经济/科技/军事四线压力；诸方势力列表改为带势力色和战意条，仍不改变外交规则或朝廷项目执行链。
- v4.6 第二片新增 `CourtProjectKind` 与 `Command.enactCourtProject(kind:)`，朝廷面板可按主议推荐执行征饷、赈济、招抚、修城、团练、火器和粮台项目；执行层统一走 `CommandValidator` 与 `EconomyRules`，轻量影响民力/银两/粮草、地方治理、城防/粮道、生产队列、火器/炮队补整和缺粮部队，其中招抚乡绅只改善己控地方州府的民变/行政，不直接改变控制归属。第五片新增 `CourtProjectDomain`，把可行项目按政策、经济、科技、军事四线分组展示；后续片新增只读“朝议争点”，把安民与征饷、火器与团练、粮道与城防的压力差做成可扫读摘要，让玩家更快看出朝廷项目的取舍。
- v4.6 地图标识首片继续 polish 默认主地图：`BaseTerrain.displayName` 改为明末中文地形名，`HexNode` 为城池、关隘/堡寨和补给源增加“城 / 关 / 粮”舆图 badge，并把旧 `FORT` 与 `SUP A/G` 主地图标记改为“关隘”“粮台”；该变化只影响 SpriteKit 展示，不改补给、占领或战区规则。
- v4.6 粮道线路首片复用 `SupplyRules` 的 hex 级补给路径，在默认 hex 图层为玩家势力有有效补给线的军队绘制粮道虚线；路线位于战争迷雾下方、军牌下方，只作可视化，不新增粮道状态或改变补给判定。后续片新增 `showsSupplyRoutes` UI 状态、顶部“粮道”按钮和舆图图例，玩家可在 hex 图层切换粮道显示；`MapDisplayLayer.displayName` 已改为舆图、州府、初划、战局、前线、布防，顶部控件会提示当前图层的明末语义。
- v4.6 军令计划线首片继续 polish 地图可读性：`BoardScene.drawPlannedOperations` 只读 `PlayerCommandState.plannedOperations`，把当前回合玩家进取/固守计划画成朱砂进取箭头、青绿固守令牌和“进/守”小令牌；`RootGameView` 顶部舆图图例新增“军令计划 / 进取 / 固守”，不改变计划记录、战区指令或规则执行。
- v4.6 势力旗号首片继续 polish 地图和部队归属：`Faction.bannerGlyph` 为明廷、后金/清、大顺、大西和地方中立提供“明/清/顺/西/乡”短旗号，`UnitNode` 在地图军牌顶端显示势力旗，`UnitInspectorView` 与 `CommandPanelView` 的军牌印面同步显示旗号，`RootGameView` 舆图图例新增“势力旗”。该片只影响 UI/SpriteKit 展示，不改变阵营、外交、单位、命令或规则执行。
- v4.7 目标定位首片补齐目标面板到舆图的交互：`BattleObjectivePanelView` 的目标城关 chip 可调用 `AppContainer.focusObjective(_:)`，只更新 `selectedHex`、`selectedRegionId` 和 UI 高亮，并在紧凑信息面板切到州府牌；它不会提交 `Command`、不会改变 objective 控制权、hex 控制、胜负判定或任何规则权威。
- v4.7 目标换手塘报首片补齐关键城关变化反馈：明末剧本中单位通过合法移动占领 objective hex 后，`CommandExecutor` 按占领前后的 `HexTile.controller` 追加 `regionOwnerChange` 类塘报，记录原控制方、新控制方和要冲分；该片只追加日志，不新增事件效果，不改变胜负判定、占领规则或目标摘要来源。
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
| `Agents/GameAgent.swift` | 运行时 agent 模型 | `GameAgent`（精简版，无 Cabinet/DirectiveDomain，v0.5 污染已剔除） |
| `Agents/AgentConfiguration.swift` | agent 加载 | `GameAgent.guderian(from:state:)`，优先 `general_agents.json`，失败 fallback |
| `Agents/AgentContexts.swift` | agent 能看到的摘要 | `AgentContext` + `AgentContextBuilder`（无 organization，适配 v0.1） |
| `Agents/AgentDecision.swift` | 结构化决策 DTO | `AgentDecisionEnvelope` / `AgentOrder` / `AgentOrderType`（move/attack/hold/resupply） |
| `Agents/AgentDecisionParser.swift` | JSON → envelope | 校验 schemaVersion / agentId / turn，malformed 抛 typed error |
| `Agents/AgentCommandMapper.swift` | order → Command | `AgentCommandMapper.map(_:agentId:) -> IssuedCommand`，缺字段抛 error |
| `Agents/AgentDecisionRecord.swift` | 决策记录 | `AgentDecisionRecord` / `CommandResultSummary`（UI 读） |
| `Agents/MockAIClient.swift` | Legacy Agent D fallback provider | 启发式：resupply → attack → objective-oriented move → hold；默认战争 AI 主路径不回退到旧 Agent D |
| `Agents/LLMClient.swift` | Legacy LLM 接口预留 | `protocol LLMClient` + `LLMRequest`（旧 Agent D 用，默认不启用） |
| `Agents/LocalLLMDecisionProvider.swift` | 本地 LLM provider | 注入 `LLMClient` + `AgentPromptBuilder` + parser，失败由上层 fallback MockAI |
| `Agents/AgentPromptBuilder.swift` | prompt 构造 | system + user prompt，强制 JSON 输出 |
| `Turn/TurnManager.swift` | legacy 方法名下的 AI 回合编排 | `runGermanAITurn(state:) async -> AgentTurnOutcome` 仍保留兼容名，实际调用方按当前 active faction 构造 commander pool 并推进 endTurn |
| `App/AppContainer.swift` | AI 接线 | `runAIIfNeeded()` 读取 `activeFaction`、`phase`、`aiControlledFactions` / `humanControlledFactions`，为当前 AI 势力触发 Task 并写 state/record |
| `UI/AgentPanelView.swift` | 军机复盘 | 读 `AgentDecisionRecord`、`RulerDecisionRecord`、`WarDirectiveRecord`，展示最高意志、战区指令、命令回执、异常和原始 JSON |
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
| `MockAIClient`（guderian 启发式，向 Bastogne 推进） | ✅ |
| `LLMClient` / `LocalLLMDecisionProvider` / `AgentPromptBuilder`（预留，v0 默认关） | ✅ |
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
