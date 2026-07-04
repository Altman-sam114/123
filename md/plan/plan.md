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
- AI Agent 只能输出结构化 directive，经 decoder / validator / compiler 后进入规则系统。
- 发布前玩家可见主 UI 不应残留主要二战文案：德国、盟军、阿登、巴斯托涅、Panzer、Division、NATO、Manpower / Industry / Supplies 等。

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
    │   └── v4.4_ming_economy_governance_record.md
    │       v4.4 钱粮、生产 UI 和 AI 摘要首片记录。
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
| v4.4 | 经济、灾荒、军饷和地方治理 | 首片已开始落地：民力/银两/粮草展示、募兵/筹粮生产口径、明末生产单位组件、AI 钱粮摘要；灾荒、治安、完整军饷士气链后续继续 | `v4.4_ming_economy_governance_record.md`、`flow.md`、经济规则记录 |
| v4.5 | 皇帝、朝议、督师、将领和流民军 Agent | 多角色 Agent 分层、Codable directive、fallback、复盘面板 | `flowchart.md`、Agent schema 记录 |
| v4.6 | 发布级明末 UI、美术和交互收口 | 舆图、军令牌、战报、粮道、势力旗色、移动端/macOS 布局 | UI 设计记录、截图检查清单 |
| v4.7 | 历史事件、教程、战役内容和可玩性 | 松锦、催饷、饥荒、开封围城、10-20 回合目标链 | 内容记录、事件 schema |
| v4.8 | 发布候选、存档、设置和验收 | 新局/继续/重置、存档、设置、版本说明、发布前授权重验证清单 | `README.md`、`update_log.md`、发布候选记录 |

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
