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
- v4.6 明末 UI polish 与朝廷项目记录：`md/prompt/v4.0-明末迁移/v4.6_ming_ui_polish_record.md`；当前已落地明末设计 token、独立朝廷面板、军令/将领名帖/塘报战记/AI 中文 polish、单位中文军牌、明末舆图空态、城/关/粮地图 badge、粮道虚线可视化，以及征饷、赈济、招抚、农政、修城、团练、火器、红衣炮、粮台驿道九类 `Command.enactCourtProject` 轻量执行入口；粮台驿道会补粮、恢复缺粮部队并整修己控粮道州府基础，但不改变 hex 补给路径判定；粮道可通过顶部“粮道”按钮和图例控制显示，图层名已中文化为舆图、州府、初划、战局、前线、布防，顶部舆图控件已新增只读“天下急势”条，显示领先方、急务/主线任务数和天下/政策/经济/科技/军事五线压力，顶部舆图图例解释城/关/粮、步/骑/火/城/旗兵种军牌、粮草与堆叠、势力旗、军令计划和粮道符号；地图上当前回合玩家进取/固守计划已显示为“进/守”令牌和计划箭头，地图军牌、部队详情和军令面板已用“明/清/顺/西/乡”等势力旗号标识归属，地图军牌新增旗色侧条、兵种印面和兵力小签底板；顶部 HUD 已升级为明末朝报令条，展示当前势力、回合、胜负、民力/银两/粮草、入账、营造队列和朝议四线压力；军令面板已升级为明末军令牌，展示当前势力/阶段、选中军情、势力旗号、兵力、粮草、退守、行动、固守/退守/补给处置和军令回执；将领面板已升级为明末将印军令和将领名帖，展示防区态势、主将履历、忠诚、军心、麾下军伍和军令计划；AI 面板已升级为明末军机复盘牌，展示最高意志、决策摘要、军机五线态势、势力军略、战区指令、命令回执、异常塘报和原始 JSON；事件日志已升级为明末塘报战记，展示最近塘报、战事/粮草/州府/天下计数、分类图标和回执；钱粮面板已升级为明末府库牌，展示民力/银两/粮草库存、入账、维护、补员、收支急报、净民力/银两/粮草、募兵筹粮和营造队列；部队详情已升级为明末军情牌，展示军牌字、势力旗号、兵力、粮草、退守、军令战备、攻守行程察、兵种编成和驻防归属；州府详情已升级为明末州府牌，展示城关粮坊、治理、钱粮城防、控制方旗号、原属章、战局归属、目标、友敌军和当前格旗号；朝廷项目已按政策、经济、科技、军事四线分组展示压力、关注点、成本收益和风险，交叉项目会出现在全部相关线组并标为兼线；朝廷面板已新增安民与征饷、火器与团练、粮道与城防三组只读朝议争点，并复用 `BattleObjectiveSummary.CampaignLineBrief` 展示只读“天下五线态势”；天下面板已新增“天下急势”、势力战意条、朝议四线压力摘要、诸方势力旗号、主战标记、阵营名义卡和战和张力条，强化中华世界局势扫读；真实美术资产、截图验收、完整响应式交互、多回合政策和科技树仍后置。
- v4.6 整训团练地方驻防增强：整训团练现在作为政策/军事兼线项目展示，玩家执行仍走 `Command.enactCourtProject -> CommandValidator -> EconomyRules -> RuleEngine`；效果保留 1 回合地方守备队列，并轻量稳定最多 2 个己控不稳州府的民变/行政，不新增独立治安资源、真实驻防层、控制权变化、外交变化、补给判定变化或多回合政策状态。
- v4.7 明末胜负链记录：`md/prompt/v4.0-明末迁移/v4.7_ming_victory_record.md`；当前已落地明末胜负规则和目标面板首片，`Objective.points` 保留剧本分值，`DataLoader` 会把 `ScenarioDefinition.victoryConditions` 写入 `GameState.victoryConditions`，`BattleObjectiveSummary` 优先从剧本条件派生清破关入京、大顺据中原秦陕、大西据湖广粮区、明廷最终守住京师关口和 objective points 归属，并派生松锦余波、催饷安民、粮道告急、军机复盘、开封围城压力和目标线压力等只读战役提示；同一摘要还派生天下五线态势、本旬任务链和阶段战局链，按当前压力给出天下、政策、经济、科技、军事五线压力，以及军事守关、救援开封压力、政策征饷安民、经济粮链、科技火器修城和终局名分等任务，并派生山海关屏障、河南秦陕粮链、湖广粮道、朝廷四线取舍、火器修城和终局名分线等只读阶段战局链；`CourtPanelView` 在明末剧本中也复用同一 `CampaignLineBrief` 展示朝廷五线态势；`CampaignAISummary` 已把同一五线态势转入 `AgentContext`、`AgentPromptBuilder`、`TurnManager.contextSummary`、`MarshalBattlefieldSummary` 和 `AgentPanelView`，元帅摘要 `schemaVersion` 升到 9，让 AI/军机链路和军机复盘牌都能读取中华世界局势、名分、粮链、火器和军政压力；`CourtStrategySummary` 也会读取同一胜负线压力，把破关入京、河南秦陕粮链、湖广粮道和终局名分线加权到朝廷主议/备议；目标面板的城关 chip 会只读显示当前控制方旗号和要冲分，城关 chip 和任务定位按钮可定位对应 hex / 州府并切到州府牌，`BoardScene` 会只读 `focusedObjectiveId` 与同一摘要显示“标”令牌、脉冲圈、目标名、当前控制方和同胜负线城关连线；`CommandExecutor` 会在结束回合时把这些 cue 去重写入塘报日志，并把急务/主线任务最多 3 条写入任务塘报；明末 objective hex 因合法移动占领换手时记录目标换手塘报；开封围城压力当前只读派生，不新增真实 siege state；`VictoryRules` 与“目标”面板共用该摘要；legacy 阿登胜负链继续保留。
- v4.7 明末 AI doctrine 记录：`md/prompt/v4.0-明末迁移/v4.7_ming_ai_doctrine_record.md`；当前已新增 `ZoneCommanderDoctrine`，让 `TheaterCommanderPool` fallback、`AppContainer` 空将领 registry fallback、显式 `.zoneDirective` 路径、`MockAICommander` 和 `SimulatedMarshalLLMClient` 默认配置/战术选择按明廷谨慎、清/大顺/大西进取、地方中立自保生成差异：`ZoneCommanderAgent` 和模拟元帅 JSON 都会按 doctrine 把同态进攻映射为明廷火器压制、清方突骑破阵/合围、大顺破围、大西流动作战；`AgentPanelView` 也会在军机复盘牌中只读展示该 doctrine 的势力军略、风格、技能标签和战术偏向；该片只改变 directive 生成偏置和 UI 解释，不新增 AI 管线，不绕过 `TheaterDirective -> TheaterDirectiveCompiler -> ZoneDirective -> WarCommandExecutor -> RuleEngine`。
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
