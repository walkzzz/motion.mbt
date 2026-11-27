# motion 开发规则全集 / Development Rules

> **用途**：本文件是 motion（通用动作语义规范，GB/Z 185-2026 具身执行层）MoonBit 参考实现所有开发规则的权威汇总，供 agent 与人类协作者复用。
> **维护**：每次新增规则时回写本文件。
> **优先级**：防跑偏规则 > 项目规则 > 个人偏好。
> **模式来源**：对齐 walkzzz/image.mbt rules.md（同作者 MoonBit 标杆）。

---

## 一、项目规则 / Project Rules

### R1 — 源码目录
源代码放在 5 个子模块中（moon.work 工作区）：motion.core/ motion.gbz185/ motion.bind/ motion.reaction/ motion.security/。根包仅门面（motion.mbt：仅 version）。CLI 在 cmd/main/（根模块包）。各子模块实际代码放子包目录：core/types、gbz185/bridge、bind/lib、reaction/engine、security/guard（包别名 @types/@bridge/@lib/@engine/@guard，全局唯一）。

### R2 — 多手段测试
MoonBit 形式化证明 + 多手段测试，确保无 bug。每个 Sprint 交付前 `moon check` 0 error、`moon test` 全通过。

### R3 — 代码文档注释
代码三级文档注释中英文（包级、类型级、方法级）。

### R4 — README 规范
README 中英文，美化，默认中文；每个一级子包也要 README.md。

### R5 — 迭代路线
先制定 `docs/roadmap.md` 迭代路线，按 Sprint 推进。

### R6 — 提交查证
提交历史有迹可循——每个 Sprint 完成回写 `roadmap.md` 状态 + commit hash。

### R7 — 自动迭代触发
没有任务迭代时，自动触发新的路线迭代计划。

### R8 — 文档治理
每次迭代后进行开源项目文档治理：更新根 README、roadmap、CHANGELOG、子包 README。

### R9 — 经验沉淀
开发经验教训沉淀复用：更新 memory。

### R10 — 一级子包文档
一级子包也要 README.md。

### R11 — 防跑偏规则（记/锁/回）
每一步做三件事：
1. **记**：把已确认的"规则/负责人/截止时间"写进固定区块；
2. **锁**：遇到与前序约定冲突的新要求，先停下，标注冲突来源，问"谁有权改"；
3. **回**：每完成一环，回写一句"已交付 x，下环依赖 Y"。
禁止在没确认的情况下，把群聊里的某句话当成最终决定。

### R12 — 根包门面
项目根包（`mot/mot`，根目录 `moon.pkg` + `mot.mbt`）仅含 version + 文档，不做 reexport。用户直接 import 子模块包（如 `import "mot/mot.core/types"`）。

### R13 — Warning 治理
每次迭代完成后都要进行 warning 治理：运行 `moon check` / `moon test`，对所有 warning 逐一处理（修复根因，禁止注释/ignore 压制），目标 0 warning。
**门禁强制**（对齐 image.mbt CI `.github/workflows/ci.yml` quality job）：验证统一用 `moon check --deny-warn`，将 warning 提升为 error，0 warning 门禁不可绕过。四目标分别执行：
```
moon check --deny-warn --target native
moon check --deny-warn --target wasm-gc
moon check --deny-warn --target js
moon check --deny-warn --target wasm
```

### R14 — 占位 todo 检查
所有的占位 todo 项，每次迭代后都要检查是否具备条件完成。

### R15 — 规则输出复用
所有规则输出到 `rules.md`，供 agent 与人类协作者复用。每次新增规则回写。

### R16 — 迭代清理
每次迭代完成后，清理无关文件和临时文件：`moon clean`、删 .tmp/.bak/*.log、git clean。

### R17 — gbz185 直接复用（MOT 特有）
**gbz185 本身就是 MoonBit 库**（`walkzzz/gbz185.mbt@0.2.2`）。MOT 直接 import 其子包（wire/aip/tooling/identity/capability/discovery），**不自己写桥接层**。这是本版核心决策。

### R18 — 安全优先（motion 特有）
安全优先于功能；安全状态机是唯一权威门控；任何入侵不得绕过输出门控。三条不可违背原则：门控不可绕过、来源必须认证、安全事件抢占。

### R19 — 命名规范（2026-11-27 定）
项目名一律 **motion**（`MOT` 缩写在多目标跟踪/软件测试领域有歧义，弃用）；CLI 工具名 **mot**；模块名 `looyiabc/motion`（无 `.mbt` 后缀，mooncakes 惯例：moonbitlang/core、cc06b/mooncry 均无后缀——`.mbt` 后缀会导致黑盒测试 `@别名` 无法推导）。历史文档 01-12 沿用 MOT 术语仅作存档，新文档/新代码/新提交信息一律 motion。

### R20 — 远端仓库布局（2026-11-27 定）
**GitCode 主仓库**（gitcode.com/LOOYIABC/motion.mbt）为权威源，GitHub（github.com/walkzzz/motion.mbt）为同步镜像。流程：本地提交 → 推 GitCode → 同步 GitHub。禁止反向同步。

---

## 二、核心约束 / Core Constraints

> ⚠️ 以下约束不可违反：

- **禁止目标条件编译** — 不使用 `target == "native"` 等条件分支，四目标共用代码（native/wasm-gc/js/wasm）
- **用户直接 import 子模块包** — 根模块仅含 version + 文档，不做 reexport
- **gbz185 直接复用** — 不重写 AIP envelope、ProtocolError、ToolDescriptor 等，直接 import `@walkzzz/gbz185.mbt/*`
- **安全门控不可绕过** — OutputGate 是 Executor 强制前置

---

## 三、架构约束 / Architecture Constraints

### 模块层级依赖

```
mot.core (Layer 0, 零依赖 + gbz185/wire)
  ↑
mot.gbz185 (Layer 1, → core + gbz185/aip/tooling)
  ↑
mot.bind (Layer 2, → core + gbz185)
mot.reaction (Layer 2, → core)
mot.safety (Layer 2, → core)
mot.security (Layer 2, → core + safety)
  ↑
mot.diag (Layer 3, → core)
```

- 下层模块不可依赖上层模块
- 同层模块之间不可互相依赖
- 跨模块引用使用完整路径：`mot/mot.core/types` 等

### moon.work 工作区

```moonbit
members = [".", "mot.core", "mot.gbz185", "mot.bind", "mot.reaction", "mot.safety", "mot.security", "mot.diag"]
```

### 根包门面

- `mot.mbt`：仅含 `pub let version : String = "0.1.0"` + 文档注释
- `moon.pkg`：空（不导入任何子包）
- 用户通过 `import "mot/mot.core/types"` + `@types.Vec3` 直接访问

---

## 四、MoonBit 关键语法约束

> 来源：image.mbt rules.md §四 + moon 0.1.20261126 实测

- `@math.atan2/cos/sin/pow/exp/log2/log10` 接受 `Double`，需 `.to_double()` 转入，`Float::from_double()` 转出
- `@math.lnf(Float)` 用于 Float 自然对数；`@math.log` **不存在**
- `@math.sqrt` **不存在**，用 `.sqrt()` 方法
- `not(expr)` 已弃用，用 `!expr`
- `1e10F` / `1e-10F` **无效**，用 `10000000000.0F` / `0.0000000001F`
- `(0..<n).rev()` **不支持**，用手动反向循环
- `is_empty()` 已弃用（Option），用 `x is None`
- `clamp` 用标签参数：`.clamp(min=0, max=255)`
- `pub(all) enum/struct` 才允许外部构造
- `Bytes` 不可变，用 `Array[Byte]` 构建后 `Bytes::from_array()`
- Int × Float 类型不匹配：需 `Float::from_int(n) * float_val`
- **struct 字段无 `let`**：`name : Type`
- **字符串插值 `\{x}`**：不是 `\(x)`
- **64 位整数 `Int64`**：不是 `Long`
- **空 Map `Map([])`**：不是 `{}`
- **序列默认 `Array[T]`**：`[a,b,c]` 字面量直接可用
- **枚举 `==` 需 `#derive(Eq)`**（单 `#`，不是 `##`）
- **`#derive(Show)` 已废弃** → 用 `#derive(Debug)` 或手写 Show
- **`Unit` 值是 `()`**：不是 `Unit`
- **Map 赋值 `map[k]=v`**：没有 `insert` 方法
- **`type`/`guard` 是关键字**：struct 字段名用 `ptype`/`guard_expr`
- **import 在 `moon.pkg`**：不能在 `.mbt` 源文件里
- **标签参数声明 `label~ : Type`**：不是 `~label`
- **测试用 `@pkg.symbol` 前缀**（黑盒测试）
- **`pub using @pkg { ... }`**：门面包再导出类型和函数
- **`pub using` 不能再导出方法**：方法要包薄函数

---

## 五、迭代流程（每 Sprint 执行步骤）

1. **查架构**：读 `docs/02-概要设计文档.md` 对应章节，明确范围。
2. **实现**：写源码 + 测试（`*_test.mbt`）。
3. **验证**：`moon check --deny-warn` 0 error（warning 即 error，对齐 image.mbt CI）+ `moon test` 全通过。
4. **Warning 治理**（R13）：逐一处理 warning，目标 0 warning。
5. **文档治理**（R8）：更新 README / roadmap / CHANGELOG / 子包 README。
6. **经验沉淀**（R9）：更新 memory。
7. **占位检查**（R14）：检查占位 todo 是否可推进。
8. **迭代清理**（R16）：清理无关文件和临时文件。
9. **提交**（R6）：git commit + 回写 roadmap commit hash。
10. **回写**（R11 回）：回写"已交付 x，下环依赖 Y"。

---

## 六、验证命令

```bash
export PATH="$HOME/.moon/bin:$PATH"
cd /workspace/mot
moon check --deny-warn  # 0 错误（warning 即 error，对齐 image.mbt CI 门禁）
moon build      # 构建成功
moon test       # 全通过
moon info       # 生成 pkg.generated.mbti
moon fmt        # 格式化
```

---

## 七、安全规则（MOT 特有）

1. 门控不可绕过：OutputGate 是 Executor 强制前置。
2. 来源必须认证：所有进入 MOT 的数据必须经过来源认证或签名验证。
3. 安全事件抢占：安全事件绕过普通反应链，直接进 SafetyStateMachine。
4. 供应链：依赖精确版本 + SHA-256 锁定 + 包签名验证（AS1）。
5. NLI 输出必须经绑定引擎四阶段校验（AS2）。
6. 反馈来源认证 I6：ReactionEngine 只处理已认证来源。
7. 输出门控 I5：非 EXECUTING 状态 do_exec 返回 false。
8. 形式化验证：I1-I6 不变式 moon prove（P1+）。

---

## 八、与 image.mbt/ecosystem 关系

| 库 | 关系 |
|----|------|
| walkzzz/image.mbt | 同作者 MoonBit 标杆，架构范式参照（本 rules.md 来源） |
| walkzzz/gbz185.mbt | **直接依赖**，MOT 复用其协议栈 |
| walkzzz/astrolabe | 解析器组合子库，P1+ 可作 .mot 解析器 |
| moonbitlang/core | 基础依赖 |
