# motion 能力矩阵（CAPABILITIES）

> 由 `scripts/gen_capabilities.py` 从 `pkg.generated.mbti`（B8 API 契约）自动生成 —— 手工修改会被覆盖。
> 目标支持：**native / wasm-gc / js / wasm**（无条件编译，四目标共用全部源码）。

## 包能力一览

| 包 | 层级 | 类型 | 函数 | 常量 | 依赖（moon.pkg） | 测试 | 形式化证明 |
|----|------|-----:|-----:|-----:|------------------|-----:|------------|
| `(root)` | 门面 | 0 | 0 | 1 | — | 0 | — |
| `motion.core/geom` | L0 | 2 | 0 | 0 | — | 0 | — |
| `motion.core/types` | L0 | 55 | 6 | 0 | motion.core/geom | 7 | — |
| `motion.core/safety` | L0 | 5 | 5 | 0 | motion.core/geom | 13 | I1-I5 · 5 goals |
| `motion.gbz185/bridge` | L1 | 0 | 3 | 0 | motion.core/types, gbz185.mbt/wire, gbz185.mbt/aip, gbz185.mbt/tooling | 6 | — |
| `motion.bind/lib` | L2 | 6 | 5 | 0 | motion.core/types | 14 | — |
| `motion.reaction/engine` | L2 | 1 | 1 | 0 | motion.core/types | 10 | — |
| `motion.security/guard` | L2 | 5 | 9 | 0 | motion.core/types, motion.core/safety | 14 | I6 运行时覆盖 |
| `all` | 门面 | 8 | 29 | 1 | motion, motion.core/geom, motion.core/types, motion.core/safety, motion.bind/lib, motion.reaction/engine, motion.security/guard, motion.gbz185/bridge | 6 | — |
| `cmd/main` | CLI | 0 | 0 | 0 | — | 0 | — |

**汇总**：82 类型 · 58 函数 · 2 常量 · 70 测试 × 4 目标 · 5 goals proved（I1-I5）

## 说明

- **层级**：L0（零依赖基础）→ L1（协议桥）→ L2（引擎/守卫）→ 门面（all/根包）→ CLI
- **依赖方向**：单向（下层不可依赖上层），`motion.core/safety` 仅依赖无 Array 的 `geom`（Why3 lowering 约束）
- **形式化证明**：`moon prove motion.core/safety` → 5 goals（I1 抢占 / I2 锁死 / I3 单调 / I4 门控 / I5 状态半）；I6 由 guard 包运行时测试覆盖（P2 证明义务）
- **API 契约**：各包 `pkg.generated.mbti` 由 `moon info` 生成，CI 漂移门禁（`git diff --exit-code -- '*.mbti'`）守护
- **变异测试**：`scripts/mutation_prove.py` → 5/5 REJECTED（证明非平凡性 100%）
