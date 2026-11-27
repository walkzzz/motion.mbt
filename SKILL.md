---
name: moonbit-mot
description: Use this skill when developing the MOT (Motion Operation Type) universal action semantics specification in MoonBit — the embodied-execution standard implementation of GB/Z 185-2026. Covers the MOT MoonBit reference implementation: core type model (BodyMap/Primitive/Mapping/SAC), four-stage binding engine, six-state safety machine, reaction engine, five-layer intrusion prevention (supply chain/NLI injection/AIP/feedback/output gate), and direct reuse of the walkzzz/gbz185.mbt MoonBit library. Use when working in the mot/ MoonBit module, editing .mbt files under this package, running moon build/check/test on MOT, or following MOT's security-invariant and GB/Z 185 integration conventions.
---

# MOT MoonBit 开发 Skill

本 Skill 是 MOT（Motion Operation Type）通用动作语义规范 MoonBit 参考实现的开发指南。MOT 是 GB/Z 185-2026 智能体国标在"具身执行"维度的标准实现。

## 关键事实（已验证）

- **gbz185 本身就是 MoonBit 库**：`walkzzz/gbz185.mbt@0.2.2`（mooncakes.io）。MOT **直接 import** 它的子包，**不自己写桥接层**。
  - `@walkzzz/gbz185.mbt/wire` → `ProtocolError` trait、`JsonWireError`
  - `@walkzzz/gbz185.mbt/aip` → `AipEnvelope`、`MessageKind`、`AipError`
  - `@walkzzz/gbz185.mbt/tooling` → `ToolDescriptor`、`ToolInvocation`、`ToolBinding`、`ToolingError`
  - `@walkzzz/gbz185.mbt/identity`、`/capability`、`/discovery`、`/registry`
- **现代 MoonBit 清单格式**：`moon.mod`（TOML）+ `moon.pkg`（包清单，含 `import`）。legacy `moon.mod.json`/`moon.pkg.json` 被 hard-reject。
- **import 声明必须在 `moon.pkg` 里**，不能在 `.mbt` 源文件里。
- **struct 字段语法**：`name : Type`（**无 `let`**）。
- **字符串插值**：`\{x}`（**不是 `\(x)`**）。
- **64 位整数**：`Int64`（**不是 `Long`**）。
- **空 Map**：`Map([])`（**不是 `{}`**——空 `{}` 有歧义）。
- **序列类型**：默认用 `Array[T]`（`[a,b,c]` 字面量直接可用），不是 `@list.List`。
- **枚举 `==` 比较**：需 `#derive(Eq)`（单 `#`，不是 `##`）。
- **`#derive(Show)` 已废弃** → 用 `#derive(Debug)` 或手写 `Show` impl。
- **标签参数**：声明 `label~ : Type`，调用 `label~` 或 `label=value`（**不是 `~label`**）。
- **`Unit` 值是 `()`**（不是 `Unit`）。
- **Map 赋值**：`map[key] = value`（**没有 `insert` 方法**）。
- **`guard`/`type` 是关键字**：不能作 struct 字段名（用 `guard_expr`/`ptype`）。
- **测试文件**：黑盒测试用 `@pkg.symbol` 前缀引用；`test "name" { ... }` 块。

## 模块结构（单包，根包）

```
mot/
├── moon.mod              # 模块清单（name= mot/mot, import gbz185）
├── moon.pkg            # 包清单（import wire/aip/tooling）
├── mot.toml            # MOT 项目清单 + 安全策略
├── types.mbt           # URN/ParamValue/Vec3 基础类型
├── bodymap.mbt         # BodyMap 身体语义模型
├── primitive.mbt       # Primitive 动作基元
├── mapping.mbt         # MappingGraph 跨形态映射图
├── sac.mbt             # SAC 语义达成条件
├── env.mbt             # EnvFeedback 环境反馈
├── reaction.mbt        # ReactionPolicy 反应策略
├── safety.mbt          # SafetyStateMachine 安全状态机（I1-I6）
├── nli.mbt             # NLI 自然语言接口
├── targetseq.mbt       # TargetActionSeq/BoundActionSeq
├── diag.mbt            # 诊断系统 + 退出码
├── bind.mbt            # 绑定引擎四阶段
├── reaction_engine.mbt # 反应引擎循环
├── threat.mbt          # 攻击面 AS1-AS8 + SecurityError
├── supply.mbt          # AS1 供应链签名验证
├── nli_guard.mbt       # AS2 NLI 注入防护
├── feedback_auth.mbt   # AS4 反馈来源认证（I6）
├── output_gate.mbt     # AS5 输出门控（I5）
├── gbz185.mbt          # GB/Z 185 薄封装（import gbz185 库）
├── mot_test.mbt        # 31 个测试
└── cmd/main/main.mbt   # motc CLI 入口
```

## 安全架构（五层纵深防御）

| 层 | 职责 | 覆盖 |
|----|------|------|
| L1 来源信任 | 包签名验证、URN 身份、依赖锁定 | AS1 |
| L2 语义校验 | 绑定引擎四阶段 + SAC 校验 | AS2、AS7 |
| L3 运行时认证 | 反馈来源认证、AIP 消息认证 | AS3、AS4、I6 |
| L4 输出门控 | OutputGate 执行门控 | AS5、I5 |
| L5 形式化验证 | Z3 不变式证明 + 测试 | AS8 |

安全不变式 I1-I6 在 `safety.mbt` 断言，`gbz185.mbt` 让 `MotError` 实现 gbz185 的 `ProtocolError` trait。

## 验证命令

```bash
export PATH="$HOME/.moon/bin:$PATH"
cd /workspace/mot
moon check      # 类型检查（0 错误）
moon build      # 构建（wasm/native/js/wasm-gc）
moon test       # 运行测试（31 个）
moon fmt        # 格式化
moon ide doc    # 查 API
```

## 依赖

- `walkzzz/gbz185.mbt@0.2.2` —— GB/Z 185-2026 协议栈（直接 import，不重写）
- `moonbitlang/async@0.22.9` —— 异步（gbz185 传递依赖）
- `cc06b/mooncry@0.95.0` —— gbz185 传递依赖
- P0 核心仅依赖 `moonbitlang/core` + gbz185 库

## 开发约束

1. **不重写 gbz185**：所有 GB/Z 185 能力（AIP envelope、ProtocolError、ToolDescriptor、AIC、ACS、ADP）直接 import `@walkzzz/gbz185.mbt/*` 复用。
2. **安全优先**：安全状态机是唯一权威门控；OutputGate 是 Executor 强制前置。
3. **兼容承诺**：CorePrims 只增不删；BodyMap core 节点 id 不变；Schema 接口向后兼容。
4. **P0 单包**：所有 `.mbt` 在根包（消除跨包 import 风险）；生产版按模块拆包。
