# 安全策略 —— MOT 入侵防护

> **安全立场：安全优先于功能；安全状态机是唯一权威门控；任何入侵不得绕过输出门控。**

本文件是 MOT MoonBit 参考实现的安全策略总纲，面向用户、贡献者与审计者。
详细设计依据见 `docs/00-生态选型与入侵防护梳理.md` §4。

## 不可违背原则

1. **门控不可绕过**：`OutputGate` 是 Executor 强制前置，非 `EXECUTING` 状态指令一律拒绝。
2. **来源必须认证**：所有进入 MOT 的数据（NL 文本、EnvFeedback、AIP 消息、安装包）必须经过来源认证或签名验证。
3. **安全事件抢占**：安全事件绕过普通反应链，直接进入 `SafetyStateMachine`；环境反馈无权解锁 `FAULT_LOCKED`。

## 攻击面与防护层

### 8 个攻击面

| # | 攻击面 | 入口 |
|---|--------|------|
| AS1 | 供应链 | `motc install <pkg>` |
| AS2 | NLI 注入 | NLRequest 文本 |
| AS3 | AIP 网络消息 | AIP 信封 |
| AS4 | 反馈注入 | EnvFeedback |
| AS5 | 安全状态机绕过 | StateEvent |
| AS6 | 工具/执行器注册 | ToolDescriptor |
| AS7 | 数据/类型注入 | ParamValue / JSON 反序列化 |
| AS8 | 形式化覆盖缺失 | 证明义务 |

### 5 层纵深防御

| 层 | 职责 | 覆盖 |
|----|------|------|
| L1 来源信任层 | 包签名验证、URN 身份、依赖锁定 | AS1、AS2 入口 |
| L2 语义校验层 | 绑定引擎四阶段 + SAC 校验 + 参数约束 | AS2、AS7 |
| L3 运行时认证层 | 反馈来源认证、AIP 消息认证、工具策略 | AS3、AS4、AS6 |
| L4 输出门控层 | OutputGate 执行门控 | AS5、AS6 |
| L5 形式化验证层 | Z3 不变式证明 + TLA+ 模型检查 + fuzzing | AS8 |

## 安全不变式（6 条，可形式化证明）

| 不变式 | 描述 | 证明方法 |
|--------|------|----------|
| I1 | EXECUTING 状态下收到 SafetyEvent → 有界步数内离开 EXECUTING | Z3 |
| I2 | FAULT_LOCKED 只能由 Reset 离开 | Z3 |
| I3 | escalation 索引单调递增，不回退 | 静态分析 |
| I4 | SAFE_HOLD 期间输出门控关闭（力矩/速度归零） | 运行时断言 + Z3 |
| I5 | 输出门控完整性：任何非 EXECUTING 状态，OutputGate.do_exec 返回 false | Z3 + 运行时断言 |
| I6 | 反馈来源认证：ReactionEngine 仅处理 source 已认证的 EnvFeedback | 静态分析 + 运行时断言 |

## 报告安全问题

发现安全漏洞请**不要**在公开 issue 中披露。请直接联系维护者，并附：
- 复现步骤
- 影响范围（攻击面编号）
- 建议修复

## 依赖安全策略

- **P0 核心仅依赖 `moonbitlang/core`**（零第三方风险）。
- 依赖版本**精确匹配**，禁止 `^`/`~` 范围（AS1）。
- `motc install` **强制包签名验证**（Ed25519，接入 `chenzehaoo/moon_guard`）。
- 来源白名单：仅 `https://mooncakes.io` 官方 + 已签名镜像。
- `mot.toml` 依赖锁定哈希（SHA-256）。

## 安全错误码

`mot.security` 段：1700-1799（映射到 GB/Z 185 ProtocolError）。
