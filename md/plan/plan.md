# 明末迁移项目 md 大纲

> 本大纲依据 `md/prompt/v4.0-明末迁移/codex-v4.0-明末aiagent迁移总提示词.md` 整理。它是项目文档入口和阶段路线，不是源码实现记录。当前工程仍是 `WWIIHexV0` 兼容底座，迁移目标是逐步做成 AI Agent 驱动的明末历史策略游戏。

---

## 1. 接手阅读顺序

每轮任务先按项目规则读取：

1. `AGENTS.md`：入口规则、Agent A/B/C 工作流、检查边界。
2. `update_log.md`：历史版本、维护记录、遗留风险。
3. `md/flow/flow.md`：当前真实运行链路。
4. `md/flow/flowchart.md`：核心流程图。
5. `md/test/test.md`：本机轻量检查与禁止项。
6. `md/prompt/v4.0-明末迁移/codex-v4.0-明末aiagent迁移总提示词.md`：明末迁移总合同。
7. 当前版本阶段文档，例如 `md/prompt/v4.0-明末迁移/v4.0_audit_and_contract.md`。

若文档、源码和检查结果冲突，以当前源码和真实检查结果为准，并在本轮结束时同步修正文档。

---

## 2. 当前工程底座

当前代码不是新项目，而是 Swift + SwiftUI + SpriteKit 的 `WWIIHexV0` 战棋工程，已有：

- Hex 战术层：`HexTile.controller`、`Division.coord` 是移动、攻击、占领、补给落点的权威。
- Region 战略聚合层：资源、胜利点、补给、控制比例从 hex 聚合。
- 动态 Theater / FrontLine / WarDeployment：`regionToTheater` 是初始/基础战区，`hexToTheater` 是运行时动态战区权威，`hexToFrontZone` 是部署层动态归属权威。
- 统一命令管线：玩家、AI、未来聊天命令都必须落到 `Command` / `ZoneDirective`，再经 `WarCommandExecutor`、`CommandValidator`、`RuleEngine` 执行。
- Agent 记录链：`WarDirectiveRecord`、`AgentDecisionRecord`、`RulerDecisionRecord` 等用于复盘和审计。
- iOS 主游戏、macOS 主游戏和 macOS MapEditor 方向。

明末迁移必须保留这些工程资产，不能绕过规则系统直接改 `GameState`。

---

## 3. 明末产品目标

暂定产品名：`明末棋策 Agent`，英文工作名可用 `Late Ming Agent Strategy`。

首发目标：

- 默认剧本：`崇祯十五年：天下裂变`。
- 时间范围：约 1642 年，松锦战后前后。
- 地图范围：辽西、山海关、畿辅、山东、河南、陕西、湖广北部的抽象战区。
- 首版规模：约 100-180 个 hex、30-55 个 region、8-14 个方面/防区。
- 主要势力：明廷、后金/清、大顺、大西、地方中立/乡绅团练。
- 玩家默认明廷；清、大顺、大西等由 AI Agent 驱动。
- 第一屏直接进入可玩战役地图，不做营销落地页。
- 玩家可微操军队，也可通过朝廷、督抚、将领面板下达宏观命令。
- 明末代入感必须侧重中华世界局势：明廷、后金/清、大顺、大西、地方势力之间的战和、招抚、粮道、民变和朝议都要能被玩家看见。
- 政策、经济、科技、军事四条线都要有可解释入口；首版可轻量，但不能只做单一战斗或单一经济面板。
- 地图、部队、朝廷、钱粮、天下局势等界面要按发布级 UI 目标推进，避免继续停留在调试板观感。
- AI Agent 只能输出结构化 directive，经 decoder / validator / compiler 后进入规则系统。
- 发布前玩家可见主 UI 不应残留主要二战文案：德国、盟军、阿登、巴斯托涅、Panzer、Division、NATO、Manpower / Industry / Supplies 等。

### 3.1 设计重点与验收口径

后续每轮明末任务都要把下面三件事写进目标、非目标和验收标准，避免只做局部功能而丢掉题材方向。

#### 中华世界局势优先

- 玩家第一眼应能看见“天下”格局，而不只是局部战棋盘：明廷、后金/清、大顺、大西和地方中立的战和关系、主要对手、战意、名分、招抚空间和地方归属都应在天下面板、舆图图例、势力旗号、塘报和 AI 摘要里可扫读。
- 历史事件、胜负目标和 AI 决策要围绕松锦后辽西失衡、山海关屏障、畿辅压力、河南/陕西流民军扩张、湖广粮道和地方团练等中华世界局势展开，不把明末仅当成换皮地图。
- 地方中立、乡绅团练、民变、行政掌控、粮道、招抚和朝议不应只停留在背景说明；能进入规则的必须走 `Command` / `ZoneDirective` / `RuleEngine`，暂不能进入规则的也要进入只读摘要和 UI 提示。
- 玩家 UI、朝廷面板、Agent prompt、元帅摘要和军机复盘要读取同一套天下态势口径；不能只让目标面板看到五线压力，而让 AI 继续只按局部前线行动。

#### 政策、经济、科技、军事四线并重

- 政策线关注征饷、赈济、招抚、名分、地方治理、朝议争点和民变风险。
- 经济线关注民力、银两、粮草、军粮维护、补员、生产队列、州府收入、粮台和运输效率。
- 科技线不做现代科技树，优先表现火器整备、红衣炮维护、修城、驿道/粮台、水利农政、屯田和训练法度。
- 军事线关注部队编成、攻守行程察、围城、关隘、前线、部署、将领、军令计划和补给状态。
- 新增系统或 UI 时必须说明它影响哪几条线、展示在哪些面板、是否可执行；可执行效果必须经过现有命令和校验链，不允许 SwiftUI 或 Agent 直接改权威状态。

#### 地图、部队、朝廷等界面美观可用

- 第一屏仍以可玩舆图和行动为核心；不要做营销页，也不要把功能堆成调试卡片。
- 地图应突出城池、关隘、粮台、驿道/粮道、势力旗号、军令计划、前线和州府归属；部队应突出军牌、旗号、兵力、粮草、退守、编成和驻防；朝廷应突出奏疏、印信、四线压力、朝议争点、项目成本收益和风险。
- 钱粮、天下、将领、军令、军机复盘和塘报也要保持同一套明末视觉语言，避免单调米色或单调暗色主题，避免文字溢出、遮挡和小触控目标。
- 真实美术资产、截图验收和移动端/macOS 响应式 polish 仍是发布前必要事项；没有视觉验收前，不能声称 UI 已达到发布级。

### 3.2 下一轮拆分优先级

后续 Agent A 写提示词、Agent B 实现、Agent C 验收时，优先把任务拆成下面四条主线；每轮至少说明自己命中了哪条主线，以及没有命中的主线为什么后置。

1. 中华世界局势与代入感：
   - 把松锦战后、山海关屏障、畿辅危局、河南/陕西流民军、湖广粮区、地方团练和招抚/归降做成目标、塘报、天下摘要、AI 摘要或事件链。
   - 继续让 `BattleObjectiveSummary`、`CampaignAISummary`、天下面板、目标面板、朝廷面板和军机复盘共享中华世界局势来源，避免 UI、AI 和胜负规则各讲一套。
   - 优先补 10-20 回合目标链和历史事件 schema；事件如果产生规则效果，必须走 validator / executor，不允许从 UI 或 Agent 直接改 `GameState`。
2. 政策、经济、科技、军事四线深化：
   - 政策线继续扩展征饷、赈济、招抚、名分和朝议争点。
   - 经济线继续扩展民力、银两、粮草、军饷、补员、灾荒、州府收入和粮道效率。
   - 科技线继续扩展火器整备、红衣炮维护、修城、粮台/驿道、水利农政和训练法度。
   - 军事线继续扩展围城、关隘、前线、防区、将领、军令计划和 AI 战术差异。
3. 地图、部队、朝廷和核心面板美观：
   - 地图要继续补舆图底纹、城关层级、粮道密度控制、真实或自制旗号/印信资产，以及目标定位后的镜头居中；当前已补目标定位后的“标”令牌、脉冲圈和同胜负线城关连线视觉反馈。
   - 部队、军令、将领、朝廷、钱粮、天下、军机复盘和塘报要做窄屏/宽屏文本检查，不能出现文字溢出、遮挡或触控区过小。
4. 发布级可玩闭环：
   - 每个功能都要能服务开局、查看天下、看州府、选军队、下军令、看朝廷项目、打仗/围城/占领、AI 回合、塘报复盘和胜负判断。
   - 未获得本机 Xcode / 模拟器授权时，仍按项目规则只做轻量检查并推送云端 CI；发布前另列截图和试玩授权清单。

---

## 4. 迁移合同

### 4.1 保留

- Hex 坐标、移动、攻击、占领、视野、补给落点权威。
- Region 作为战略聚合层，不替代 hex。
- 动态战区、前线、部署层从 hex 和单位位置派生。
- `Command` / `ZoneDirective` / `WarCommandExecutor` / `RuleEngine` 统一执行管线。
- MapEditor 的稀疏 hex、region、theater、unit 编辑与导出能力。
- Legacy Agent D 作为回归参考保留，不回退为默认战争 AI 主路径。

### 4.2 替换或抽象

| 当前二战语义 | 明末目标语义 |
|---|---|
| `Faction.germany/allies` | `ming`、`qing`、`dashun`、`daxi`、`localNeutral` 等多势力 |
| `Faction.opponent` | `DiplomacyState` / `PowerRelation` / `WarRelationRules` |
| `GamePhase.germanAI/alliedPlayer` | 通用 active faction 回合阶段 |
| `Division` 玩家可见文案 | 军队、营兵、边军、旗营、流民军、团练 |
| `tank/motorizedInfantry/infantry/artillery` | 步军、骑兵、火器、炮队、旗骑、攻城器械、团练等 |
| `manpower/industry/supplies` | 民力/兵源、银两/军费、粮草 |
| `panzerDivision` 等生产项 | 募营兵、募骑兵、造炮队、整训团练、筹粮、修城、征饷 |
| Theater / FrontZone UI | 方面、防区、军镇、前线军区、镇守区 |
| MarshalAgent / RulerAgent 展示 | 督师/枢辅/军机 Agent、皇帝/摄政王/义军首领 Agent |

### 4.3 禁止

- 不一次性大规模重命名所有类型后凭感觉修编译。
- 不让任何 Agent 直接修改 hex controller、unit coord、dynamic theater、front zone 或 economy ledger。
- 不恢复旧 Cabinet / Minister / StrategicDirective 污染。
- 不把 region 当成战术权威。
- 不把完整 1618-1662 全国沙盒一次塞进首版。
- 不使用受版权保护的影视、游戏、小说人物图或 UI 素材。
- 未获人工授权，不跑 Xcode / XCTest / 模拟器 / Probe / Smoke / Stage Regression / Full / 性能测试。

---

## 5. 文档结构

```text
md/
├── plan/
│   └── plan.md
│       明末迁移项目 md 大纲和阶段路线入口。
├── flow/
│   ├── flow.md
│   │   当前真实运行链路；源码行为变化后必须同步。
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
    │   │   v4.0 审计、兼容层和明末题材合同阶段文档。
    │   ├── v4.1_powers_turns_prompt.md
    │   │   v4.1 多势力、外交关系和通用回合编排实现提示词。
    │   ├── v4.2_ming_scenario_data_record.md
    │   │   v4.2 默认明末剧本、region 数据和 MapEditor 默认桥接记录。
    │   ├── v4.3_ming_units_tactics_record.md
    │   │   v4.3 明末兵种 template、战术显示名和规则首步记录。
    │   ├── v4.4_ming_economy_governance_record.md
    │       v4.4 钱粮、治理、天下局势 UI 和 AI 摘要首片记录。
    │   ├── v4.5_ming_court_policy_record.md
    │   │   v4.5 朝廷、政策科技摘要和 UI 首片记录。
    │   ├── v4.6_ming_ui_polish_record.md
    │   │   v4.6 发布级明末 UI 和朝廷项目首片记录。
    │   └── v4.7_ming_victory_record.md
    │       v4.7 明末胜负链首片记录。
    ├── v0.*（已完成）/
    │   历史 WWIIHexV0 阶段记录。
    ├── v2.0-三国迁移/、v3.0-拿战迁移/、v5.0-唐宋迁移/、v6.0-现代战争迁移/
    │   其他题材迁移参考，不是当前明末主线。
    └── old/、anti生成/、claude生成/
        历史资料和打捞记录；不得把旧污染当作当前主线。
```

---

## 6. v4.0-v4.8 阶段路线

| 阶段 | 主题 | 交付重点 | 主要文档 |
|---|---|---|---|
| v4.0 | 迁移审计、兼容层和明末题材合同 | 硬编码审计、术语表、版本边界、子 Agent 分工、风险清单；当前已完成首轮只读审计，未改源码 | `v4.0_audit_and_contract.md`、`update_log.md` |
| v4.1 | 多势力、外交关系和通用回合编排 | `Faction` 多势力、敌我判断、通用 active faction、AI 回合不再绑定德国；当前兼容层源码已部分落地 | `v4.1_powers_turns_prompt.md`、`flow.md`、`flowchart.md`、阶段实现记录 |
| v4.2 | 明末地图、剧本数据和 MapEditor 迁移 | `崇祯十五年：天下裂变` 默认数据首片已落地：120 hex、30 region、5 势力、22 初始单位；`DataLoader` 和 MapEditor 默认桥接优先明末 JSON | `v4.2_ming_scenario_data_record.md`、`flow.md`、数据 schema 记录 |
| v4.3 | 明末军队、围城、粮草和战术规则 | 首批明末 unit template、默认单位 templateId、ComponentType 兼容 case、攻城/火器首步修正和战术展示名已开始落地；完整围城状态、粮草命名和经济资源仍后置 | `v4.3_ming_units_tactics_record.md`、`flow.md`、战术规则记录 |
| v4.4 | 经济、灾荒、军饷和地方治理 | 已开始落地：民力/银两/粮草展示、募兵/筹粮生产口径、明末生产单位组件、民变/行政掌控收入修正、AI 钱粮与治理摘要、天下局势入口；灾荒、完整政策/军饷士气链后续继续 | `v4.4_ming_economy_governance_record.md`、`flow.md`、经济规则记录 |
| v4.5 | 皇帝、朝议、政策科技、督师和将领 Agent | 首片已开始落地：`CourtStrategySummary` 只读派生政策/经济/科技/军事四线压力，朝廷 tab 和 AI/元帅摘要可见；朝廷项目已在 v4.6 作为一次性 `Command` 入口先行落地；多回合政策/科技 directive、Codable schema、fallback、复盘面板后续继续 | `v4.5_ming_court_policy_record.md`、`flowchart.md`、Agent schema 记录 |
| v4.6 | 发布级明末 UI、美术、交互和朝廷项目收口 | 首片已开始落地：明末设计 token、独立朝廷面板、军令/将领名帖/塘报战记/AI 面板中文 polish、单位军牌中文徽记和明末舆图空态；第二片新增征饷、赈济、招抚、农政、修城、团练、火器、红衣炮、粮台驿道九类朝廷项目，统一走 `CommandValidator` / `EconomyRules`；招抚乡绅只改善己控地方州府治理，不直接改变归属；农政屯田只改善己控州府粮草和基础设施，不直接补现粮或新增科技树；红衣炮维护只校修受损攻城炮队或追加造炮队订单，不新增持久科技树；粮台驿道只补粮、恢复缺粮部队并整修己控粮道州府 infrastructure / supplyValue，不改变 hex 补给路径判定；朝报令条首片已把顶部 HUD 升级为当前势力、回合、胜负、民力/银两/粮草、入账、营造队列和政策/经济/科技/军事四线压力展示；军令牌首片已把军令面板升级为当前势力/阶段、选中军情、兵力、粮草、退守、行动、固守/退守/补给处置和军令回执展示；将领面板首片已把将领军令升级为防区态势、主将履历、忠诚、军心、麾下军伍、军令计划和只读帷幄四线展示，并把弹出档案升级为将领名帖；军机复盘牌首片已把 AI 面板升级为最高意志、决策摘要、战区指令、命令回执、异常塘报和原始 JSON 展示；塘报战记首片已把事件日志升级为最近塘报、战事/粮草/州府/天下计数、分类图标和回执展示；府库牌首片已把钱粮面板升级为民力/银两/粮草库存、入账、维护、补员、募兵筹粮和营造队列展示；部队军情牌首片已把单位详情升级为军牌字、势力旗号、兵力条、粮草/退守/行动、攻守行程察、兵种编成和驻防归属展示；州府牌首片已把州府详情升级为城关粮坊、治理、钱粮城防、战局归属、友敌军和当前格展示；地图标识首片已把地形名、城池、关隘/堡寨和粮台标识中文化为平原/林地/山地/丘陵/城池/关隘/粮台与“城 / 关 / 粮”badge；粮道线路首片已复用 `SupplyRules` 在 hex 图层绘制玩家势力可达粮台的虚线，并新增“粮道”开关和图例；军令计划线首片已把当前回合玩家进取/固守计划显示为“进/守”令牌和计划箭头，并在舆图图例中说明；势力旗号首片已把地图军牌、部队军情牌和军令牌的势力归属显示为“明/清/顺/西/乡”等短旗号，并在舆图图例中说明；四线项目分组首片已用 `CourtProjectDomain` 将项目按政策、经济、科技、军事显示压力、关注点、成本收益和风险；朝议争点首片已把安民与征饷、火器与团练、粮道与城防三组冲突做成只读摘要；朝廷面板还会复用 `BattleObjectiveSummary.CampaignLineBrief` 展示只读天下五线态势；舆图图例首片已把图层名改为舆图、州府、初划、战局、前线、布防，并在顶部解释城/关/粮/步、势力旗、军令计划和粮道符号；天下急势首片已在天下面板展示当前势力、主要对手、战意和四线压力；真实资产、地图纹理、截图验收和完整移动端/macOS 交互收口仍后续继续 | `v4.6_ming_ui_polish_record.md`、UI 设计记录、截图检查清单 |
| v4.7 | 明末胜负链、历史事件、教程、战役内容和可玩性 | 胜负链首片已落地：`Objective.points` 保留 JSON 分值，`BattleObjectiveSummary` 统一派生清破关入京、大顺控开封/洛阳/西安、大西控荆州/武昌、明廷最终守北京/山海关/武昌和 objective points 领先方，`VictoryRules` 与“目标”面板共用该摘要；目标面板已增加只读本旬任务链和阶段战局链，把军事守关、政策征饷安民、经济粮链、科技火器修城和终局名分线做成当前目标引导；同一五线态势现在也进入朝廷面板，帮助朝议与中华世界局势对齐；后续继续以中华世界局势驱动 10-20 回合可执行目标链、历史事件 schema、教程和 AI 摘要，让政策、经济、科技、军事四线都能影响可玩目标 | `v4.7_ming_victory_record.md`、内容记录、事件 schema、胜负规则记录 |
| v4.8 | 发布候选、存档、设置、视觉验收和云端收口 | 新局/继续/重置、存档、设置、版本说明、发布前授权重验证清单；补齐地图、部队、朝廷、钱粮、天下、将领、军令、军机复盘和塘报的截图验收与响应式检查，确认默认 UI 无主要二战文案和调试感残留 | `README.md`、`update_log.md`、发布候选记录、截图检查清单 |

---

## 7. 并发 Agent 边界

默认仍使用项目当前 `main` 直推 + GitHub Actions + Agent C 结果包复判流程。若启用并发子 Agent，主 Agent 必须先定义文件边界：

- Data / Scenario Agent：`WWIIHexV0/Data/`、DataLoader 和数据 schema。
- Rules / Core Agent：`Core/`、`Commands/`、`Rules/`。
- AI Agent：`Agents/`、`Turn/`，只读核心规则。
- UI / Art Agent：`UI/`、`SpriteKit/`、资产目录。
- MapEditor Agent：`MapEditor/`，只读数据 schema。
- Docs / QA Agent：`README.md`、`update_log.md`、`md/flow/`、`md/test/`、`md/prompt/v4.0-明末迁移/`。

没有完成同文件冲突、public API、JSON schema、project 文件和文档口径检查前，不得声称并发结果可合并。

---

## 8. 轻量检查口径

文档-only 修改默认只跑本机轻量检查：

```sh
rg -n "[[:blank:]]+$" AGENTS.md README.md update_log.md md/test/test.md md/flow/flow.md md/flow/flowchart.md md/prompt/README.md md/plan/plan.md md/prompt/v4.0-明末迁移
```

```sh
rg -n "<<<<<<<|=======|>>>>>>>" AGENTS.md README.md update_log.md md
```

若修改 workflow、project、JSON、scheme 或 Swift 文件，再按 `md/test/test.md` 追加对应 YAML / `plutil` / `jq` / `xmllint` / 可行的单文件 parse。未获人工授权，不跑本机 Xcode build/test、模拟器、Probe、Smoke、Stage Regression、Dynamic Theater Regression、Full 或性能测试。
