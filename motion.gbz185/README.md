# motion.gbz185

L1 协议桥：GB/Z 185-2026 标准协议栈集成（直接 import `walkzzz/gbz185.mbt`，不写桥接层）。

## bridge 包

| API | 职责 |
|-----|------|
| `MotError` | motion 错误类型，实现 `@wire.ProtocolError`（part=gbz185.6，code=MOT-17xx） |
| `mot_envelope` | 构造 AIP 信封（sender/recipient/seq/kind/payload） |
| `mot_tool_descriptor` | 构造工具注册描述符（name/description/schema/binding） |
| `security_error_to_mot` | SecurityError → MotError 转换 |

## 六挂载点

GB/Z 185 的六个集成挂载点（发现/身份/能力/信封/工具/传输）中，P0 覆盖信封与工具；其余见 docs/07-集成设计文档.md。
