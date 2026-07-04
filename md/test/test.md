# 云端验证与本机轻量检查规范

> 当前规则：默认云端重验证，本机只跑轻量语法、格式和配置检查。未获人工明确授权时，不在本机运行 Xcode build/test、模拟器、Probe、Smoke、Stage Regression、Dynamic Theater Regression、Full 或性能测试。

## 0. 总原则

- 每轮实现或验收前必须读本文件。
- Agent B 默认在 `main` 上完成本地轻量检查、commit、push 到 `origin/main`，由 GitHub Actions 运行重验证。
- Agent C 默认下载 GitHub Actions 未加密结果包，核对 manifest、JUnit、日志和 failure summary，不只看 Agent B 文字说明。
- 只有人工明确说“本机测试”“本地 build”“本地 xcodebuild”“本地跑探针”时，才把本机构建或模拟器验证作为默认路径。
- 文档-only 修改仍可只跑本地轻量检查；若需要云端闭环，仍按 `main` push 触发 Actions。
- 不得用“已验证”代替具体命令和结果；不得伪造本地或云端测试通过。

## 1. main 直推检查

Agent B 开始实现前默认执行：

```sh
git fetch origin
git switch main
git pull --ff-only origin main
git status --short --branch
```

Agent B push 前必须确认：

```sh
git branch --show-current
git status --short --branch
git remote -v
```

要求：

- 当前分支必须是 `main`。
- 目标远端必须是 `origin/main`。
- commit 范围只包含本轮相关文件。
- 本轮不创建 PR，不设计 `smalldata_test`、`develop`、`codeb/...` 或其他默认分支流。

## 2. 禁止默认本机执行

除非人工在当前任务中明确授权，否则 Agent 不得在本机主动执行：

- `xcodebuild test`
- `xcodebuild build`
- `xcodebuild build-for-testing`
- `xcrun simctl ...`
- Probe / Smoke / Stage Regression / Dynamic Theater Regression / Full
- XCTest、UI test、性能测试、快照测试
- 启动 iOS Simulator
- 启动 app 做人工烟测
- 全项目 Swift 编译、全量 lint、全量格式化
- 会长时间占用 CPU、内存、磁盘或 DerivedData 的命令

GitHub Actions 可以运行 Xcode build 和项目重验证；本机禁止项不等于云端禁止项。

## 3. 默认允许的本机轻量检查

### 3.1 Markdown / 文本

检查改动文档是否存在尾随空白：

```sh
rg -n "[[:blank:]]+$" AGENTS.md README.md update_log.md md/test/test.md md/flow/flow.md md/flow/flowchart.md md/prompt/README.md
```

检查当前规范中是否仍残留旧默认测试口径：

```sh
rg -n "[默]认先跑|默认 P[r]obe|P[r]obe -> Smoke|[S]tage Regression -> Full|代码改动按 .*P[r]obe|本机[默]认.*xcodebuild" AGENTS.md md/test/test.md md/flow/flow.md README.md
```

### 3.2 GitHub Actions YAML

仅当修改 workflow 时运行：

```sh
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'
```

### 3.3 Xcode project / plist

仅当修改了 `WWIIHexV0.xcodeproj/project.pbxproj` 时运行：

```sh
plutil -lint WWIIHexV0.xcodeproj/project.pbxproj
```

仅当修改了 scheme 或 XML 文件时运行：

```sh
xmllint --noout WWIIHexV0.xcodeproj/xcshareddata/xcschemes/WWIIHexV0.xcscheme
xmllint --noout WWIIHexV0.xcodeproj/xcshareddata/xcschemes/WWIIHexV0Probes.xcscheme
```

### 3.4 JSON

仅当修改了 JSON 数据时运行对应文件的解析检查，优先只查改动文件：

```sh
jq empty WWIIHexV0/Data/ardennes_v0_scenario.json
jq empty WWIIHexV0/Data/ardennes_v02_regions.json
jq empty WWIIHexV0/Data/general_agents.json
jq empty WWIIHexV0/Data/generals.json
jq empty WWIIHexV0/Data/terrain_rules.json
jq empty WWIIHexV0/Data/unit_templates.json
```

### 3.5 Swift 单文件语法

默认不做全项目编译。若只改了少量纯 Swift 文件，并且单文件语法检查不会触发项目构建，可以只针对改动文件做轻量 parse；如果命令需要 SDK、SwiftUI/SpriteKit 依赖或变慢，立即停止并记录未检查。

```sh
swiftc -parse path/to/ChangedFile.swift
```

## 4. GitHub Actions 重验证

默认 workflow：`.github/workflows/ci-results.yml`。

触发条件：

- push 到 `main`
- `workflow_dispatch`

当前云端重验证内容：

- `git diff --check` 检查最新提交文本格式。
- `plutil -lint WWIIHexV0.xcodeproj/project.pbxproj`。
- `xmllint --noout` 检查共享 scheme。
- `jq empty` 检查项目 JSON 数据。
- `xcodebuild -project WWIIHexV0.xcodeproj -target WWIIHexV0Mac -configuration Debug CODE_SIGNING_ALLOWED=NO build`。

云端使用 GitHub-hosted macOS runner 的 Xcode 环境和 runner 默认 DerivedData；这不同于本机 DerivedData，也不会启动模拟器。

## 5. CI 结果包

Actions 必须上传未加密 artifact，命名格式：

```text
wwiihexv0-ci-cloud-process-<branch_slug>-<short_sha>-run<run_id>-attempt<run_attempt>
```

最低内容：

- `ci-results/ci-artifact-manifest.json`
- `ci-results/ci-failure-summary.md`
- `ci-results/xcodebuild.log`
- `ci-results/static-checks.log`
- `ci-results/junit.xml`
- `ci-results/WWIIHexV0Mac.xcresult`，若 Xcode 生成成功

manifest 必须至少记录：

- `branch`
- `commitSha`
- `shortSha`
- `runId`
- `runAttempt`
- `workflowName`
- `createdAt`
- `projectName`
- `scheme`
- `destination`
- `resultBundlePath`
- `junitPath`
- `buildLogPath`
- `failureSummaryPath`
- `staticChecksOutcome`
- `buildOutcome`
- `testOutcome`
- `projectSpecificReports`

## 6. Agent C 下载与复判

Agent C 必须先确认 GitHub CLI 已登录：

```sh
gh auth status
```

未登录时先执行：

```sh
gh auth login
```

结果包下载缓存默认放在：

```text
/private/tmp/wwiihexv0-c-review-<run_id>/
```

推荐命令：

```sh
gh run list --workflow "WWIIHexV0 CI Results" --branch main --limit 5
gh run download <run_id> --dir /private/tmp/wwiihexv0-c-review-<run_id>
```

Agent C 必查：

- `origin/main` 最新 commit 与 manifest 的 `commitSha` 一致。
- manifest 的 `branch` 必须是 `main`。
- manifest 的 `runId` / `runAttempt` 与下载的 run 一致。
- `junit.xml`、`xcodebuild.log`、`static-checks.log`、`ci-failure-summary.md` 与 workflow 结论一致。
- 若 workflow 失败，不验收旧 run；写退回清单，由 Agent B 在 `main` 上追加修复 commit 并重新 push。

## 7. 多 Agent / 并发后的整合检查

多子 Agent 并发完成后，主 Agent 必须做轻量整合检查。即使云端会跑 CI，也不能跳过冲突审查。

必查项：

- 同一文件是否被多个子 Agent 修改。
- 同一 public API、类型名、枚举 case、JSON key 是否出现分叉。
- `WWIIHexV0.xcodeproj/project.pbxproj` 是否存在重复文件引用、缺失文件引用或 UUID 冲突。
- `Data/*.json` 与 `ScenarioDefinition` / `RegionDataSet` 是否同时变化但文档未同步。
- `Command` / `ZoneDirective` / `WarCommandExecutor` / `RuleEngine` 管线是否仍保持统一入口。
- `hexToTheater`、`hexToFrontZone`、`regionToTheater` 的权威边界是否被不同文档写成不同口径。
- README、`md/flow/*`、阶段 prompt、`update_log.md` 是否描述同一版本状态。

建议命令：

```sh
rg -n "struct |enum |class |protocol |case |func " WWIIHexV0 MapEditor
rg -n "hexToTheater|hexToFrontZone|regionToTheater|ZoneDirective|WarCommandExecutor|RuleEngine" WWIIHexV0 md README.md AGENTS.md
```

这些命令只用于定位冲突线索，不等于功能测试。

## 8. 历史测试基线

以下记录只用于理解历史状态，不作为当前任务的本机默认执行要求：

- v0.37 Probe：18 tests, 0 failures。
- v0.37 CommandSystemTests：15 tests, 0 failures。
- v0.37 Stage Regression：69 tests, 0 failures。
- v0.37 Full Regression：226 tests, 0 failures。

## 9. 交付写法

最终回复必须区分：

- 本地轻量检查：写具体命令和结果。
- 云端 workflow：写 run id、run attempt、commit SHA、artifact 名称和结论。
- Agent C 复判：说明是否下载并核对结果包。
- 未跑本机重测试：明确说明未授权或按规范改由云端执行。
- 风险：说明哪些功能正确性仍未通过运行时或人工试玩确认。
