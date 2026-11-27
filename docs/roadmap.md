# MOT 通用动作语义规范 —— 路线图 roadmap

| 字段 | 值 |
|------|-----|
| 文档编号 | MOT-DOC-ROADMAP |
| 版本 | v1.0 |
| 日期 | 2026-11-27 |
| 状态 | 正式 |
| 定位 | 长远期规划 + 0.1.x 版本迭代 + Sprint 计划（权威路线文件） |
| 维护规则 | R5（迭代路线）/ R6（提交查证回写）/ R8（文档治理）/ R11（记·锁·回） |
| 模式来源 | walkzzz/image.mbt Sprint 迭代范式 |

---

## 0. 长远期规划（愿景）

MOT（Motion Operation Type）是 GB/Z 185-2026 的具身执行标准 MoonBit 参考实现。长远期按四阶段推进：

| 阶段 | 版本区间 | 定位 | 形象目标 |
|------|----------|------|----------|
| 近期 | **0.1.x** | 参考实现基线 + 安全纵深 + P1 拆分 | 单包→7 子模块工作区，四目标全绿，I1-I6 全证，可发布 |
| 中期 | 0.2.x | 生态集成深化 + 性能基准 + 多包独立发布 | 生态选型全部落地，基准封签，子模块独立发布 |
| 远期 | 0.3.x | GB/Z 185 六挂载点完整集成 + 社区生态 | 六挂载点全接入，第三方可扩展工具注册 |
| 正式 | 1.0.0 | 生产稳定版 | moonbitlang/skills 仓库 + mooncakes.io 正式发布，生产可用 |

### 0.1 阶段依赖关系

```
0.1.0 基线 ──→ 0.1.1 警告清零 ──→ 0.1.2 四目标 ──→ 0.1.3 形式化验证
                                                        │
0.1.9 正式发布 ←─ 0.1.8 生态集成 ←─ 0.1.7 发布门禁 ←─ 0.1.6 CLI+示例 ←─ 0.1.5 门面包+API ←─ 0.1.4 子模块拆分
```

> 0.1.3 形式化验证是安全纵深的收口，须在子模块拆分前完成（拆分后不变式跨包证明更复杂）。0.1.4 拆分依赖 0.1.2/0.1.3 的四目标与不变式已固化的基线。

---

## 1. 版本总览（0.1.x 形象进度一览）

| 版本 | 形象进度 | 状态 | 前置依赖 | 门禁达成 |
|------|----------|------|----------|----------|
| v0.1.0 | 单包基线：20 源文件 + 31 测试绿 | ✅ 已完成 | — | B1(单目标)/B2/B5 |
| v0.1.1 | 0 warning + 门禁 B1-B5 全绿 | ⏳ 待启动 | v0.1.0 | B1-B5 |
| v0.1.2 | native/wasm-gc/js/wasm 四目标全绿 | ⏳ 待启动 | v0.1.1 | B1(四目标)/B2 |
| v0.1.3 | I1-I6 六条不变式 moon prove 全证 | ⏳ 待启动 | v0.1.2 | B6 |
| v0.1.4 | 7 子模块 moon.work 工作区成型 | ⏳ 待启动 | v0.1.3 | B1-B2(多包) |
| v0.1.5 | all 门面包 + pkg.generated.mbti | ⏳ 待启动 | v0.1.4 | B8/B9 |
| v0.1.6 | motc 可运行 + examples/ | ⏳ 待启动 | v0.1.5 | — |
| v0.1.7 | 发布门禁 B12-B14 全绿 | ⏳ 待启动 | v0.1.6 | B12/B13/B14 |
| v0.1.8 | 生态选型落地（yacc/json-schema/async） | ⏳ 待启动 | v0.1.7 | B4/B10/B11 |
| v0.1.9 | v0.1.0 正式版发布 mooncakes.io | ⏳ 待启动 | v0.1.8 | 全部门禁 |

> 状态图例：✅ 已完成 / ⏳ 待启动 / 🔄 进行中 / ⛔ 阻塞

---

## 2. 当前状态回写区（R6 / R11 回）

> 每个 Sprint 完成回写：状态 + commit hash +「已交付 x，下环依赖 Y」。

| 版本 | Sprint | 状态 | commit hash | 回写（已交付 x / 下环依赖 Y） |
|------|--------|------|-------------|------------------------------|
| v0.1.0 | — | ✅ | （基线） | 已交付单包基线 31 测试绿；下环依赖 v0.1.1 warning 治理 |
| v0.1.1 | S1.1 | ⏳ | | |
| v0.1.1 | S1.2 | ⏳ | | |
| v0.1.1 | S1.3 | ⏳ | | |
| v0.1.2 | S2.1 | ⏳ | | |
| v0.1.2 | S2.2 | ⏳ | | |
| v0.1.2 | S2.3 | ⏳ | | |
| v0.1.3 | S3.1 | ⏳ | | |
| v0.1.3 | S3.2 | ⏳ | | |
| v0.1.3 | S3.3 | ⏳ | | |
| v0.1.3 | S3.4 | ⏳ | | |
| v0.1.4 | S4.1 | ⏳ | | |
| v0.1.4 | S4.2 | ⏳ | | |
| v0.1.4 | S4.3 | ⏳ | | |
| v0.1.4 | S4.4 | ⏳ | | |
| v0.1.5 | S5.1 | ⏳ | | |
| v0.1.5 | S5.2 | ⏳ | | |
| v0.1.5 | S5.3 | ⏳ | | |
| v0.1.6 | S6.1 | ⏳ | | |
| v0.1.6 | S6.2 | ⏳ | | |
| v0.1.6 | S6.3 | ⏳ | | |
| v0.1.7 | S7.1 | ⏳ | | |
| v0.1.7 | S7.2 | ⏳ | | |
| v0.1.7 | S7.3 | ⏳ | | |
| v0.1.8 | S8.1 | ⏳ | | |
| v0.1.8 | S8.2 | ⏳ | | |
| v0.1.8 | S8.3 | ⏳ | | |
| v0.1.9 | S9.1 | ⏳ | | |
| v0.1.9 | S9.2 | ⏳ | | |
| v0.1.9 | S9.3 | ⏳ | | |

---

## 3. 各版本 Sprint 计划

> 迭代流程严格遵循 rules.md §五：查架构 → 实现 → 验证 → Warning 治理(R13) → 文档治理(R8) → 经验沉淀(R9) → 占位检查(R14) → 迭代清理(R16) → 提交(R6) → 回写(R11)。
> 验证命令前缀：`export PATH="/root/.moon/bin:$PATH" && cd /workspace/mot`

---

### 3.0 v0.1.0 基线固化 —— ✅ 已完成

**形象进度**：单包基线，20 源文件 + 31 测试绿。

| 项 | 内容 |
|----|------|
| 范围 | P0 单包全部源码 + 14 份文档套件 + SKILL 文件 |
| 验证 | `moon check` 0 错误 / `moon build` 成功 / `moon test` 31 passed / `security_scan` 0 Critical 0 High |
| 交付 | /workspace/mot 全部 45 文件 |
| 回写 | 已交付单包基线；下环依赖 v0.1.1 warning 治理 |

---

### 3.1 v0.1.1 警告清零 + 门禁补齐 —— ⏳ 待启动

**形象进度**：0 warning + 门禁 B1-B5 全绿。

**前置**：v0.1.0 完成。

#### Sprint S1.1 —— Warning 根因治理

| 项 | 内容 |
|----|------|
| 目标 | `moon check` 9 → 0 warning（R13：修复根因，禁止注释/ignore 压制） |
| 任务 | ① `bind.mbt:85` `find_path_rec` 未使用 → 删除或接入调用路径；② `bind.mbt:228` `graph` 未使用 → 接入或移除参数；③ `diag.mbt:34-37` `Success/Error/Warning/InternalError` 构造子未使用 → `#derive(Show)` 接入诊断输出或移除冗余变体；④ `safety.mbt:65` `action` 未使用 → 接入 `is_action_allowed` 判定逻辑；⑤ `supply.mbt:18` `pkg` 未使用 → 接入签名校验逻辑；⑥ `threat.mbt:4` `#derive(Show)` 废弃 → 改 `#derive(Debug)` |
| 验证 | `moon check --deny-warn` 0 error（warning 即 error，对齐 image.mbt CI） |
| DoD | 0 warning，且无 `@lint:ignore` 压制 |

#### Sprint S1.2 —— 覆盖率测量 + 门禁 B4

| 项 | 内容 |
|----|------|
| 目标 | 覆盖率可测量，门禁 B4 达标线定义 |
| 任务 | ① 运行 `moon test --coverage`（或等价）获取行/分支覆盖基线；② 定义 MOT 覆盖率达标线（对齐 image.mbt 90.05%，MOT 首期 ≥ 80%）；③ 补 `mot_test.mbt` 缺失分支用例（warning 治理后暴露的未覆盖路径） |
| 验证 | `moon test` 全通过 + 覆盖率报告生成 |
| DoD | 覆盖率报告存在且 ≥ 达标线 |

#### Sprint S1.3 —— 安全门禁 B5 复测 + 格式门禁 B10

| 项 | 内容 |
|----|------|
| 目标 | B5 保持 0 Critical/0 High，B10 格式门禁落地 |
| 任务 | ① `security_scan` 复测确认 0 Critical/0 High；② `moon fmt` 全量格式化；③ 将 `moon fmt` 检查写入 rules.md 验证流程 |
| 验证 | `security_scan` 0/0 / `moon fmt --check` 无差异 |
| DoD | B5 + B10 全绿 |

---

### 3.2 v0.1.2 四目标编译 —— ⏳ 待启动

**形象进度**：native/wasm-gc/js/wasm 四目标全绿。

**前置**：v0.1.1 完成（0 warning 基线）。

#### Sprint S2.1 —— 四目标 moon check

| 项 | 内容 |
|----|------|
| target | native / wasm-gc / js / wasm |
| 任务 | `moon check --target native` / `--target wasm-gc` / `--target js` / `--target wasm` 逐一通过；修复目标特定告警（无条件编译，禁止 `target ==` 分支） |
| 验证 | `moon check --deny-warn --target <t>` 0 error × 4 |
| DoD | 四目标 check 全 0 error |

#### Sprint S2.2 —— 四目标 moon build

| 项 | 内容 |
|----|------|
| 任务 | `moon build --target <t>` × 4；确认 `_build/` 四目标产物齐全 |
| 验证 | `moon build` 成功 × 4 |
| DoD | 四目标构建产物生成 |

#### Sprint S2.3 —— 四目标 moon test

| 项 | 内容 |
|----|------|
| 任务 | `moon test --target <t>` × 4；确认 31 测试四目标全通过 |
| 验证 | `moon test` 31 passed × 4 |
| DoD | 四目标测试全绿 |

---

### 3.3 v0.1.3 形式化验证 I1-I6 —— ⏳ 待启动

**形象进度**：I1-I6 六条不变式 moon prove 全证。

**前置**：v0.1.2 完成（四目标基线）。

> 安全不变式（docs/00 §3）：I1 安全事件抢占 / I2 FAULT_LOCKED 仅 Reset / I3 escalation 单调 / I4 SAFE_HOLD 门控关闭 / I5 输出门控完整性 / I6 反馈来源认证。

#### Sprint S3.1 —— I1 / I2 证明

| 项 | 内容 |
|----|------|
| 目标 | I1（安全事件抢占）+ I2（FAULT_LOCKED 仅 Reset）`moon prove` 通过 |
| 任务 | ① 在 `safety.mbt` 标注证明义务；② `moon prove mot/mot.safety` 跑通；③ 修复证明失败的代码路径 |
| 验证 | `moon prove` 输出 I1/I2 已证 |
| DoD | I1/I2 证明通过 |

#### Sprint S3.2 —— I3 / I4 证明

| 项 | 内容 |
|----|------|
| 目标 | I3（escalation 单调）+ I4（SAFE_HOLD 门控关闭）`moon prove` 通过 |
| 任务 | ① `reaction_engine.mbt` / `safety.mbt` 标注；② `moon prove` 跑通；③ 修复路径 |
| 验证 | `moon prove` 输出 I3/I4 已证 |
| DoD | I3/I4 证明通过 |

#### Sprint S3.3 —— I5 / I6 证明

| 项 | 内容 |
|----|------|
| 目标 | I5（输出门控完整性）+ I6（反馈来源认证）`moon prove` 通过 |
| 任务 | ① `output_gate.mbt` / `feedback_auth.mbt` 标注；② `moon prove` 跑通；③ 修复路径 |
| 验证 | `moon prove` 输出 I5/I6 已证 |
| DoD | I5/I6 证明通过 |

#### Sprint S3.4 —— 变异测试（门禁 B7）

| 项 | 内容 |
|----|------|
| 目标 | 变异测试验证证明强度（B7） |
| 任务 | ① 对 I1-I6 proof 引入变异体；② `moon prove` 检测变异体失败（证明非平凡）；③ 记录变异得分 |
| 验证 | 变异体被证明拒绝 |
| DoD | 变异测试报告存在，证明强度可量化 |

---

### 3.4 v0.1.4 子模块拆分 —— ⏳ 待启动

**形象进度**：7 子模块 moon.work 工作区成型。

**前置**：v0.1.3 完成（不变式已证基线）。

> 拆分目标结构与依赖方向见 docs/10 §4。单向依赖：下层不可依赖上层，同层不可互相依赖。

#### Sprint S4.1 —— mot.core 拆分

| 项 | 内容 |
|----|------|
| 目标 | mot.core（L0）独立子模块 |
| 任务 | `moon.work` 加 `"mot.core"`；建 `mot.core/moon.mod`+`moon.pkg`+`types/moon.pkg`+`types.mbt`+`bodymap.mbt`+`primitive.mbt`+`mapping.mbt`+`sac.mbt`+`env.mbt`+`reaction.mbt`+`safety.mbt`+`nli.mbt`+`targetseq.mbt`；根包保留门面；`moon check`/`moon test` 全绿 |
| 验证 | `moon check` 0 error / `moon test` 31 passed |
| DoD | mot.core 独立编译通过，根包门面零 import |

#### Sprint S4.2 —— mot.gbz185 + mot.bind 拆分

| 项 | 内容 |
|----|------|
| 目标 | mot.gbz185（L1）+ mot.bind（L2）独立 |
| 任务 | 拆 `gbz185.mbt`→`mot.gbz185/`；拆 `bind.mbt`→`mot.bind/`；依赖方向 mot.bind→core+gbz185；跨包路径 `mot/mot.core/types`；`moon check`/`moon test` 全绿 |
| 验证 | `moon check` 0 error / `moon test` 31 passed |
| DoD | 两子模块独立编译，依赖方向无逆 |

#### Sprint S4.3 —— mot.reaction + mot.safety + mot.security 拆分

| 项 | 内容 |
|----|------|
| 目标 | mot.reaction / mot.safety / mot.security（L2）独立 |
| 任务 | 拆 `reaction_engine.mbt`→`mot.reaction/`；拆 `safety.mbt`→`mot.safety/`；拆 `threat/supply/nli_guard/feedback_auth/output_gate`→`mot.security/`；依赖 mot.security→core+safety；`moon check`/`moon test` 全绿 |
| 验证 | `moon check` 0 error / `moon test` 31 passed |
| DoD | 三子模块独立编译，依赖方向无逆 |

#### Sprint S4.4 —— mot.diag + all 门面包拆分

| 项 | 内容 |
|----|------|
| 目标 | mot.diag（L3）独立 + all 门面包骨架 |
| 任务 | 拆 `diag.mbt`→`mot.diag/`；建 `all/moon.pkg`+`all/all.mbt`（骨架，pub using 待 v0.1.5 填充）；`moon check`/`moon test` 全绿 |
| 验证 | `moon check` 0 error / `moon test` 31 passed |
| DoD | 7 子模块 + all 工作区成型，`moon.work` members 完整 |

---

### 3.5 v0.1.5 门面包 + API 索引 —— ⏳ 待启动

**形象进度**：all 门面包 + pkg.generated.mbti。

**前置**：v0.1.4 完成（工作区成型）。

#### Sprint S5.1 —— all/all.mbt pub using 再导出

| 项 | 内容 |
|----|------|
| 目标 | all 门面包高频 API 再导出（对齐 image.mbt all/all.mbt） |
| 任务 | `pub using @types { type Vec3, type ParamValue, type BodyMap, type Primitive, type SacSpec, type EnvFeedback, type ReactionPolicy, type SafetyStateMachine, type TargetActionSeq, ... }`；`pub using @bind { bind }`；`pub using @gbz185 { MotError, mot_envelope, mot_tool_descriptor }`；方法薄函数再导出 |
| 验证 | `moon check` 0 error / 用户 `import "mot/mot/all"` 可用 |
| DoD | 门面包再导出完整，黑盒测试通过 |

#### Sprint S5.2 —— API 索引生成（门禁 B8）

| 项 | 内容 |
|----|------|
| 目标 | `moon info` 生成 pkg.generated.mbti（B8） |
| 任务 | `moon info` 全工作区运行；确认各子模块 pkg.generated.mbti 生成；DON'T EDIT 标记保留 |
| 验证 | 各子模块 pkg.generated.mbti 存在 |
| DoD | B8 全绿 |

#### Sprint S5.3 —— 能力矩阵生成（门禁 B9）

| 项 | 内容 |
|----|------|
| 目标 | 能力矩阵生成（B9） |
| 任务 | 生成子模块能力矩阵（导出符号/目标/依赖）；对齐 image.mbt 能力矩阵 |
| 验证 | 能力矩阵文档存在 |
| DoD | B9 全绿 |

---

### 3.6 v0.1.6 CLI + 示例 —— ⏳ 待启动

**形象进度**：motc 可运行 + examples/。

**前置**：v0.1.5 完成。

#### Sprint S6.1 —— motc 子命令完善

| 项 | 内容 |
|----|------|
| 目标 | motc CLI 子命令可运行 |
| 任务 | `cmd/main/main.mbt` 子命令：`motc check`/`motc bind`/`motc prove`/`motc install`（接入 moon_guard 签名验证）；`moon run cmd/main --target native` 验证 |
| 验证 | `moon run cmd/main --target native` 退出码 0 |
| DoD | motc 四子命令可运行 |

#### Sprint S6.2 —— examples/ 示例集

| 项 | 内容 |
|----|------|
| 目标 | examples/ 示例集 |
| 任务 | 建 `examples/`：bodymap 示例 / bind 示例 / reaction 示例 / security 示例；每个 `moon run` 可运行 |
| 验证 | 每个示例 `moon run` 退出码 0 |
| DoD | ≥ 4 示例可运行 |

#### Sprint S6.3 —— CLI 测试 + 文档

| 项 | 内容 |
|----|------|
| 目标 | CLI 测试 + 子包 README（R10） |
| 任务 | `cmd/main` 黑盒测试；各一级子模块 README.md（R10）；motc 用法写入 README |
| 验证 | `moon test` 含 CLI 用例 / 各子模块 README.md 存在 |
| DoD | CLI 测试通过 + 子包 README 齐全 |

---

### 3.7 v0.1.7 发布门禁 —— ⏳ 待启动

**形象进度**：发布门禁 B12-B14 全绿。

**前置**：v0.1.6 完成。

#### Sprint S7.1 —— 发布 verify（门禁 B12）

| 项 | 内容 |
|----|------|
| 目标 | B12 发布 verify 全绿 |
| 任务 | `moon publish --dry-run` 全工作区；校验 moon.mod 字段完整（name/version/description/import/repository/license/keywords/preferred_target）；修复缺失字段 |
| 验证 | `moon publish --dry-run` 无错误 |
| DoD | B12 全绿 |

#### Sprint S7.2 —— 基准样本封签（门禁 B13）

| 项 | 内容 |
|----|------|
| 目标 | B13 基准样本封签 |
| 任务 | `moon bench --release --target native` 基线采样；封签基准样本写入 mot.toml；CI 基准比对阈值定义 |
| 验证 | 基准报告生成并封签 |
| DoD | B13 全绿 |

#### Sprint S7.3 —— 发布链（门禁 B14）

| 项 | 内容 |
|----|------|
| 目标 | B14 发布链全绿 |
| 任务 | 发布链脚本：check→test→prove→info→fmt→publish；依赖签名验证（moon_guard Ed25519）接入；来源白名单 `https://mooncakes.io` |
| 验证 | 发布链 dry-run 全通过 |
| DoD | B14 全绿 |

---

### 3.8 v0.1.8 生态集成 —— ⏳ 待启动

**形象进度**：生态选型落地（yacc/json-schema/async）。

**前置**：v0.1.7 完成。

> 生态选型表见 docs/00 §2。P0 核心仅依赖 moonbitlang/core + gbz185；P1 接入生态库。

#### Sprint S8.1 —— .mot 解析器迁 yacc

| 项 | 内容 |
|----|------|
| 目标 | .mot 解析从手写迁 moonbitlang/yacc |
| 任务 | `moon add moonbitlang/yacc`；建 `mot.core` 内 yacc 语法定义；手写解析器替换；`moon test` 全绿 |
| 验证 | `moon test` 全通过 + yacc 解析器黑盒测试 |
| DoD | .mot 解析器 yacc 化 |

#### Sprint S8.2 —— JSON Schema 校验 + 异步接入

| 项 | 内容 |
|----|------|
| 目标 | colmugx/json-schema + moonbitlang/async 接入 |
| 任务 | `moon add colmugx/json-schema` BoundAction 校验；`moon add moonbitlang/async` ReactionEngine 异步化；`moon test` 全绿 |
| 验证 | `moon test` 全通过 + 四目标 check |
| DoD | JSON Schema 校验 + 异步反应引擎落地 |

#### Sprint S8.3 —— 文档治理 + 弃用清单（B11）

| 项 | 内容 |
|----|------|
| 目标 | B11 弃用清单防漂移 + R8 文档治理 |
| 任务 | `moon info` 弃用清单生成；漂移检测脚本；更新根 README + roadmap + CHANGELOG + 子包 README（R8/R10）；经验沉淀 memory（R9） |
| 验证 | 弃用清单无漂移 / 文档全集一致 |
| DoD | B11 + R8 + R9 + R10 全绿 |

---

### 3.9 v0.1.9 正式发布 —— ⏳ 待启动

**形象进度**：v0.1.0 正式版发布 mooncakes.io。

**前置**：v0.1.8 完成。

#### Sprint S9.1 —— 最终全门禁验证

| 项 | 内容 |
|----|------|
| target | B1-B14 全部门禁 |
| 任务 | 全门禁矩阵复测：B1(四目标)/B2/B3(0 warning)/B4/B5/B6/B7/B8/B9/B10/B11/B12/B13/B14 |
| 验证 | 全部门禁绿 |
| DoD | B1-B14 全绿 |

#### Sprint S9.2 —— CHANGELOG + 版本冻结

| 项 | 内容 |
|----|------|
| target | 版本冻结 |
| 任务 | 生成 CHANGELOG.md（v0.1.0→v0.1.9 全变更）；moon.mod version 冻结 `0.1.0`；mot.toml 版本锁定；git tag `v0.1.0` |
| 验证 | CHANGELOG 完整 / tag 存在 |
| DoD | 版本冻结完成 |

#### Sprint S9.3 —— 发布到 mooncakes.io

| 项 | 内容 |
|----|------|
| target | moonbitlang/skills 仓库 + mooncakes.io |
| 任务 | `moon publish` 全工作区；确认 mooncakes.io 包页；SKILL.md 市场规范校验；仓库 README 最终版 |
| 验证 | mooncakes.io 包页可访问 / `moon add mot/mot` 可安装 |
| DoD | 正式发布完成 |

---

## 4. 门禁对照表（B1-B14）

> 来源 docs/10 §6。MOT 现状与目标版本映射。

| 门禁 | 检查 | 现状 | 目标版本 |
|------|------|------|----------|
| B1 | moon check --deny-warn 0 error（四目标） | ✅ 单目标 | v0.1.2 |
| B2 | moon test 全通过 | ✅ | v0.1.0 |
| B3 | warning 0（--deny-warn 强制） | ⚠️ 9 warning | v0.1.1 |
| B4 | 覆盖率达标 | ⚠️ 未测 | v0.1.1 |
| B5 | security_scan 0 Critical/0 High | ✅ | v0.1.1 |
| B6 | moon prove 证明 | P1+ | v0.1.3 |
| B7 | 变异测试 | P1+ | v0.1.3 |
| B8 | API 索引生成（moon info） | P1+ | v0.1.5 |
| B9 | 能力矩阵生成 | P1+ | v0.1.5 |
| B10 | 格式门禁（moon fmt） | P1+ | v0.1.1 |
| B11 | 弃用清单防漂移 | P1+ | v0.1.8 |
| B12 | 发布 verify | P1+ | v0.1.7 |
| B13 | 基准样本封签 | P1+ | v0.1.7 |
| B14 | 发布链 | P1+ | v0.1.7 |

---

## 5. 风险与依赖

| 风险 | 影响 | 缓解 |
|------|------|------|
| `moon prove` 工具可用性 | v0.1.3 阻塞 | 提前验证 `moon prove` 命令；若不可用则降级为手写证明义务文档 |
| 子模块拆分后跨包 import 路径变更 | v0.1.4 用户 breakage | 根包门面保留过渡期；all 门面包兼容层 |
| 生态库（yacc/json-schema/async）版本漂移 | v0.1.8 依赖冲突 | mot.toml `[dependencies.lock]` SHA-256 锁定 + 精确版本（AS1） |
| 四目标特定告警 | v0.1.2 延期 | 无条件编译，禁止 `target ==` 分支；用 `@pkg` 抽象 |
| 形式化证明不可判定 | v0.1.3 阻塞 | 降级为不变式测试 + 文档证明义务，标注 P2 补全 |

### 5.1 外部依赖锁定

| 依赖 | 版本 | 用途 | 锁定 |
|------|------|------|------|
| walkzzz/gbz185.mbt | 0.2.2 | GB/Z 185 协议栈 | SHA-256 |
| cc06b/mooncry | 0.95.0 | （gbz185 传递） | 精确 |
| moonbitlang/async | 0.22.9 | （gbz185 传递） | 精确 |
| moonbitlang/yacc | [P1+] | .mot 解析 | 精确 |
| colmugx/json-schema | [P1+] | BoundAction 校验 | 精确 |
| chenzehaoo/moon_guard | [P1+] | Ed25519 签名 | 精确 |
| zhangbowen2006/moongate | [P1+] | 工具策略 | 精确 |

---

## 6. 迭代流程（引用 rules.md §五）

每个 Sprint 严格按以下 10 步执行：

1. **查架构**：读 `docs/02-概要设计文档.md` 对应章节，明确范围。
2. **实现**：写源码 + 测试（`*_test.mbt`）。
3. **验证**：`moon check --deny-warn` 0 error（warning 即 error，对齐 image.mbt CI）+ `moon test` 全通过。
4. **Warning 治理**（R13）：逐一处理 warning，目标 0 warning。
5. **文档治理**（R8）：更新 README / roadmap / CHANGELOG / 子包 README。
6. **经验沉淀**（R9）：更新 memory。
7. **占位检查**（R14）：检查占位 todo 是否可推进。
8. **迭代清理**（R16）：`moon clean` + 删 .tmp/.bak/*.log。
9. **提交**（R6）：git commit + 回写 roadmap commit hash。
10. **回写**（R11）：回写「已交付 x，下环依赖 Y」。

---

## 7. 版本-形象进度速查

```
v0.1.0  ✅ 单包基线 31测试绿
v0.1.1  ⏳ 0 warning + B1-B5
v0.1.2  ⏳ 四目标全绿
v0.1.3  ⏳ I1-I6 全证
v0.1.4  ⏳ 7子模块工作区
v0.1.5  ⏳ all门面包 + API索引
v0.1.6  ⏳ motc + examples
v0.1.7  ⏳ 发布门禁 B12-14
v0.1.8  ⏳ 生态集成
v0.1.9  ⏳ 正式发布 mooncakes.io
```

---

## 8. 变更记录

| 版本 | 日期 | 变更 | 作者 |
|------|------|------|------|
| v1.0 | 2026-11-27 | 初始 roadmap 创建：长远期规划 + 0.1.x 九版本 + 25 Sprint | CodeArts |
