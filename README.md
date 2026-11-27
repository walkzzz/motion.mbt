# MOT —— Motion Operation Type 通用动作语义规范

> **MOT 是 GB/Z 185-2026《人工智能 智能体互联》国家标准在"具身执行"维度的标准实现。**
> 它让智能体不仅能"说话"，还能"安全地动起来"——从自然语言理解意图，到跨形态生成动作，
> 再到环境反馈实时避障和急停，全部由一份形态无关的开放规范定义。

本仓库是 MOT 的 **MoonBit 参考实现**，与已交付的 `gbz185.mbt`（GB/Z 185-2026 协议栈，MIT）同栈。

## 定位

| 项 | 值 |
|----|----|
| 规范 | MOT 通用动作语义规范 v1.0 |
| 参考实现语言 | MoonBit（与 gbz185.mbt 同栈） |
| 编译目标 | native / js / wasm / wasm-gc |
| 架构风格 | sans-I/O（与 gbz185.mbt 一致） |
| 安全立场 | 安全优先于功能；安全状态机是唯一权威门控；任何入侵不得绕过输出门控 |
| 仓库定位 | `github.com/moonbitlang/skills` 下的 MOT 子包 |

## 目录结构

```
mot/
├── moon.mod              # 模块清单（name= mot/mot, import gbz185）
├── moon.pkg            # 包清单（import wire/aip/tooling）
├── mot.toml            # MOT 项目清单（含安全策略）
├── rules.md            # 开发规则全集（对齐 image.mbt）
├── SECURITY.md         # 安全策略（入侵防护总纲）
├── SKILL.md            # Skill 定义（moonbitlang/skills 规范）
├── SKILL.mbt.md        # 可执行文档
├── types.mbt ... gbz185.mbt   # MoonBit 源码（核心类型/绑定/反应/安全/防护/gbz185）
├── mot_test.mbt        # 31 测试
├── cmd/main/main.mbt   # motc 工具链入口
└── docs/               # 开发文档套件 00-12
```

## 快速开始

```bash
# 安装 MoonBit 工具链
curl -fsSL https://cli.moonbitlang.cn/install/unix.sh | bash
export PATH="$HOME/.moon/bin:$PATH"

# 构建
moon build

# 运行测试
moon test

# 使用 motc CLI
moon run . -- bind examples/walk_forward.mot
```

## 安全

本仓库实施**五层纵深防御**（来源信任 / 语义校验 / 运行时认证 / 输出门控 / 形式化验证），
覆盖 8 个攻击面（供应链 / NLI 注入 / AIP 消息 / 反馈注入 / 安全状态机绕过 / 工具注册 / 类型注入 / 形式化覆盖）。
详见 [SECURITY.md](./SECURITY.md) 与 `docs/00-生态选型与入侵防护梳理.md`。

**gbz185 直接复用**：MOT 直接 import `walkzzz/gbz185.mbt` 库（AIP envelope、ProtocolError、ToolDescriptor），不自己写桥接层。

## 关联资产

- [walkzzz/gbz185.mbt](https://github.com/walkzzz/gbz185.mbt) —— GB/Z 185-2026 协议栈（MIT，124 测试，91.8% 覆盖，19/19 变异击杀，20 条 Z3 证明）
- [walkzzz/image.mbt](https://github.com/walkzzz/image.mbt) —— MoonBit 架构范式参照
- [moonbitlang/skills](https://github.com/moonbitlang/skills) —— Skill 规范
- [mooncakes.io](https://mooncakes.io) —— MoonBit 包注册表

## 许可证

MIT —— 与 gbz185.mbt 一致。详见 [LICENSE](./LICENSE)。
