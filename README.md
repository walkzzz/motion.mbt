<div align="center">

# **motion**

**具身智能通用动作语义规范** · GB/Z 185-2026 执行层标准实现 · 纯 MoonBit

[![MoonBit](https://img.shields.io/badge/MoonBit-0.1.20261126-6E40C9)](https://www.moonbitlang.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-0.1.0-orange)]()
[![CI](https://github.com/walkzzz/motion.mbt/actions/workflows/ci.yml/badge.svg)](https://github.com/walkzzz/motion.mbt/actions/workflows/ci.yml)

[![Tests](https://img.shields.io/badge/tests-70×4-4CAF50?style=flat-square)]()
[![Coverage](https://img.shields.io/badge/coverage-89.1%25-4CAF50?style=flat-square)]()
[![Targets](https://img.shields.io/badge/targets-native%20%7C%20wasm--gc%20%7C%20js%20%7C%20wasm-2196F3?style=flat-square)]()
[![Deny-warn](https://img.shields.io/badge/0%20warning-den--warn%20gate-4CAF50?style=flat-square)]()
[![主仓库](https://img.shields.io/badge/主仓库-AtomGit-F44336?style=flat-square)](https://atomgit.com/LOOYIABC/motion.mbt)
[![Pages](https://img.shields.io/badge/Pages-walkzzz.github.io-6E40C9?style=flat-square)](https://walkzzz.github.io/motion.mbt/)

**[亮点](#-亮点)** · **[快速上手](#-快速上手)** · **[架构](#-架构)** · **[安全](#-安全)** · **[文档](#-文档)**

</div>

---

> **motion 是 GB/Z 185-2026《人工智能 智能体互联》国家标准在“具身执行”维度的标准实现。**
> 它让智能体不仅能“说话”，还能“安全地动起来”——从自然语言理解意图，到跨形态生成动作，
> 再到环境反馈实时避障和急停，全部由一份形态无关的开放规范定义。
> CLI 工具名为 `mot`；`MOT` 缩写存在歧义（多目标跟踪/软件测试领域同名），已弃用。

## ✨ 亮点

| | |
|---|---|
| 🟢 **形态无关** | BodyMap 身体语义模型 + Primitive 动作基元 + MappingGraph 跨形态映射，人类/机器人/虚拟形象共用一套语义 |
| 🟢 **四阶段绑定引擎** | 引用解析 → 映射扩展（环检测）→ 占用冲突 → SAC 语义达成校验，任何动作未过四阶段不得执行 |
| 🟢 **五层纵深防御** | 来源信任（AS1）→ 语义校验（AS2/AS7）→ 运行时认证（AS3/AS4）→ 输出门控（AS5/I5）→ 形式化验证（AS8/I1-I6） |
| 🟢 **六态安全状态机** | Selftest/Idle/Executing/Recovering/SafeHold/FaultLocked；安全事件抢占（I1）；FAULT_LOCKED 仅 Reset 可出（I2） |
| 🟢 **四目标原生** | native / wasm-gc / js / wasm 共用同一代码库，**无条件编译**，38 测试 × 4 目标全绿 |
| 🟢 **0 warning 门禁** | `moon check --deny-warn` 四目标强制，CI 门禁不可绕过（对齐 image.mbt） |
| 🟢 **GB/Z 185 直连** | 直接 import `walkzzz/gbz185.mbt`（AIP envelope / ProtocolError / ToolDescriptor），不写桥接层 |

## 🚀 快速上手

```bash
# 安装 MoonBit 工具链
curl -fsSL https://cli.moonbitlang.cn/install/unix.sh | bash
export PATH="$HOME/.moon/bin:$PATH"

moon build          # 构建
moon test           # 运行 38 测试
moon check --deny-warn --target native   # 0-warning 门禁

# mot CLI
moon run cmd/main -- bind examples/walk_forward.mot
```

## 🏗️ 架构

```
looyiabc/motion.mbt (根模块)
├── types.mbt        # URN / ParamValue / Vec3 / ParamType
├── bodymap.mbt      # BodyMap 身体语义模型
├── primitive.mbt    # Primitive 动作基元
├── mapping.mbt      # MappingGraph 跨形态映射图
├── sac.mbt          # SAC 语义达成条件
├── env.mbt          # EnvFeedback 环境反馈
├── reaction.mbt     # ReactionPolicy 反应策略
├── safety.mbt       # SafetyStateMachine 六态安全状态机（I1-I6）
├── bind.mbt         # 绑定引擎四阶段（L2 语义校验）
├── reaction_engine.mbt  # 反应引擎（I3 有界升级）
├── threat.mbt       # 攻击面 AS1-AS8 + SecurityError
├── supply.mbt       # AS1 供应链签名验证
├── nli_guard.mbt    # AS2 NLI 注入防护
├── feedback_auth.mbt  # AS4 反馈来源认证（I6）
├── output_gate.mbt  # AS5 输出门控（I5）
├── gbz185.mbt       # GB/Z 185 薄封装（直接 import gbz185 库）
├── diag.mbt         # 诊断系统 + 退出码
├── mot_test.mbt     # 38 测试
└── cmd/main/        # mot CLI 入口
```

### 多目标支持

| 目标 | 后端 | 测试 | 状态 |
|:----:|:----:|-----:|:----:|
| native | 纯 MoonBit | 38 | ✅ |
| wasm-gc | 纯 MoonBit | 38 | ✅ |
| js | 纯 MoonBit | 38 | ✅ |
| wasm | 纯 MoonBit | 38 | ✅ |

> 同一代码库，**无条件编译**，四目标共用所有源码。

## 🛡️ 安全

**安全优先于功能；安全状态机是唯一权威门控；任何入侵不得绕过输出门控。**

五层纵深防御 × 8 攻击面（AS1 供应链 / AS2 NLI 注入 / AS3 AIP 消息 / AS4 反馈注入 / AS5 安全状态机绕过 / AS6 工具注册 / AS7 类型注入 / AS8 形式化覆盖缺失）× 6 条安全不变式（I1-I6）。

详见 [SECURITY.md](./SECURITY.md) 与 `docs/00-生态选型与入侵防护梳理.md`。

## 📄 文档

| 文档 | 说明 |
|------|------|
| [docs/roadmap.md](docs/roadmap.md) | **迭代路线图：0.1.x 九版本 25 Sprint + 长远期规划** |
| [docs/00-文档总览与导航.md](docs/00-文档总览与导航.md) | 文档套件导航 |
| [docs/01-需求规格说明书.md](docs/01-需求规格说明书.md) | SRS（历史档案，沿用 MOT 术语） |
| [docs/02-概要设计文档.md](docs/02-概要设计文档.md) | HLD |
| [docs/03-详细设计文档.md](docs/03-详细设计文档.md) | LLD |
| [rules.md](rules.md) | 开发规则全集（对齐 image.mbt） |
| [SECURITY.md](SECURITY.md) | 安全策略（入侵防护总纲） |

> 历史文档 00-12 沿用 MOT 术语仅作存档，新文档一律使用 motion。

## 🧭 仓库布局

| 仓库 | 角色 |
|------|------|
| **atomgit.com/LOOYIABC/motion.mbt** | **主仓库（权威源）** |
| gitcode.com/LOOYIABC/motion.mbt | 主仓库第二入口（与 AtomGit 同源共享存储） |
| github.com/walkzzz/motion.mbt | 同步镜像（CI/CD） |

## 🧰 关联资产

- [walkzzz/gbz185.mbt](https://github.com/walkzzz/gbz185.mbt) —— GB/Z 185-2026 协议栈（MIT，直接依赖）
- [walkzzz/image.mbt](https://github.com/walkzzz/image.mbt) —— MoonBit 架构范式参照
- [mooncakes.io](https://mooncakes.io) —— MoonBit 包注册表

## 📄 许可证

[MIT](LICENSE) —— 与 gbz185.mbt 一致。
