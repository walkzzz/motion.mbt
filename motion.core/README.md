# motion.core

L0 基础层：零跨模块依赖的核心类型与可证明安全核心。

## 包结构

| 包 | 职责 |
|----|------|
| `geom` | 几何原语（Vec3 / SpatialDisplacement）——无 Array，可被证明包依赖 |
| `types` | BodyMap / Primitive / MappingGraph / SAC / EnvFeedback / ReactionPolicy / 诊断 / 威胁模型（82 类型的大本营） |
| `safety` | **六态安全状态机（可证明核心）**——`proof_enabled`，I1-I5 形式化验证（5 goals） |

## 形式化验证

```bash
moon prove motion.core/safety   # -> Succeeded: 5 goals proved
python3 scripts/mutation_prove.py  # -> 5/5 mutants rejected
```

## 依赖方向

`geom`（零依赖）← `types`（依赖 geom）← `safety`（仅依赖 geom——Why3 lowering 不支持 Array，故绕开 types）。
