---
name: moonbit-mot
description: Use this skill when developing the MOT (Motion Operation Type) universal action semantics specification in MoonBit — the embodied-execution standard implementation of GB/Z 185-2026. Covers the MOT MoonBit reference implementation: core type model (BodyMap/Primitive/Mapping/SAC), four-stage binding engine, six-state safety machine, reaction engine, five-layer intrusion prevention (supply chain/NLI injection/AIP/feedback/output gate), and direct reuse of the walkzzz/gbz185.mbt MoonBit library. Use when working in the mot/ MoonBit module, editing .mbt files under this package, running moon build/check/test on MOT, or following MOT's security-invariant and GB/Z 185 integration conventions.
---

# MOT MoonBit 开发 Skill（可执行文档）

本文件是 `SKILL.md` 的可执行版本：包含可测试的 MoonBit 代码块。用 `moon test --deny-warn` 验证。

## 关键语法事实（已用 moon 0.1.20261126 验证）

以下代码块均通过 `moon check`/`moon test`，是本仓库的权威语法参考。

### 模块清单 moon.mod

```moonbit nocheck
name = "mot/mot"
version = "0.1.0"
description = "MOT (Motion Operation Type) universal action semantics."
import {
  "walkzzz/gbz185.mbt@0.2.2",
}
```

### 包清单 moon.pkg（import 必须在这里）

```moonbit nocheck
///|
import {
  "walkzzz/gbz185.mbt/wire",
  "walkzzz/gbz185.mbt/aip",
  "walkzzz/gbz185.mbt/tooling",
}
```

### struct 字段（无 let）

```moonbit nocheck
///|
pub(all) struct Vec3 {
  x : Double
  y : Double
  z : Double
}
```

### 枚举 + derive Eq

```moonbit nocheck
///|
#derive(Eq)
pub(all) enum FeedbackKind {
  Obstacle
  ContactLoss
  Collision
}
```

### 字符串插值 \{x}

```moonbit nocheck
///|
test "interpolation" {
  let name = "MOT"
  assert_eq("hello \{name}", "hello MOT")
}
```

### 空 Map 用 Map([])

```moonbit nocheck
///|
test "empty map" {
  let m : Map[String, Int32] = Map([])
  assert_eq(m.length(), 0)
}
```

### 数组字面量 = Array[T]

```moonbit nocheck
///|
test "array literal" {
  let a : Array[Int32] = [1, 2, 3]
  assert_eq(a.length(), 3)
  assert_eq(a[0], 1)
}
```

### Unit 值是 ()

```moonbit nocheck
///|
test "unit value" {
  let r : Result[Int32, String] = Ok(1)
  match r {
    Ok(v) => assert_eq(v, 1)
    Err(_) => assert_true(false)
  }
}
```

### Map 赋值用 []=

```moonbit nocheck
///|
test "map assign" {
  let m : Map[String, Int32] = Map([])
  m["x"] = 1
  assert_eq(m.get("x"), Some(1))
}
```

### 直接复用 gbz185 库（不重写桥接层）

```moonbit nocheck
///|
test "gbz185 reuse" {
  let e = MotError::Security_error("test")
  assert_eq(@wire.ProtocolError::part(e), "gbz185.6")
  assert_eq(@wire.ProtocolError::code(e), "MOT-1700")
}
```

### 安全状态机 I5（输出门控）

```moonbit nocheck
///|
test "safety I5" {
  let sm = new_statemachine()
  assert_false(is_action_allowed(sm, "walk"))
  let _ = transition(sm, Reset)
  let _ = transition(sm, TaskStart)
  assert_true(is_action_allowed(sm, "walk"))
}
```

### 绑定引擎四阶段

```moonbit nocheck
///|
test "bind stage 1" {
  let reg = new_registry()
  let p : Primitive = {
    urn: "urn:mot:prim:walk:1.0",
    name: "walk",
    category: PrimCategory::Loc,
    params: [],
    occupancy: { participants: [], exclusive: false, },
    sac: { predicates: [], completeness: CompletenessLevel::Structural, },
    metadata: Map([]),
  }
  register_primitive(reg, p)
  let seq : TargetActionSeq = {
    actions: [
      {
        primitive: "urn:mot:prim:walk:1.0",
        params: Map([]),
        sac_override: None,
        reaction_policies: [],
      },
    ],
    bodymap: "urn:mot:bodymap:human:1.0",
    metadata: Map([]),
  }
  let graph : MappingGraph = { edges: [], }
  match bind(seq, graph, reg) {
    BindResult::Ok(b) => assert_eq(b.actions.length(), 1)
    BindResult::Error(_) => assert_true(false)
  }
}
```

### 反应引擎 escalation 有界（I3）

```moonbit nocheck
///|
test "reaction I3" {
  let fb : EnvFeedback = {
    source: "s",
    kind: FeedbackKind::Obstacle,
    timestamp: 0L,
    stale_after_ms: 100L,
    severity: Severity::Danger,
    payload: FeedbackPayload::Obstacle(
      1.0,
      { x: 0.0, y: 0.0, z: 0.0, },
      0.5,
      None,
    ),
    sac_ref: None,
    action_ref: None,
  }
  let leaf : ReactionPolicy = {
    id: "leaf",
    scope: ReactionScope::Primitive,
    trigger: {
      kinds: [FeedbackKind::Obstacle],
      severity_min: Severity::Warn,
      source_filter: None,
    },
    guard_expr: None,
    action: ReactionAction::Continue,
    escalation: None,
  }
  let root : ReactionPolicy = {
    id: "root",
    scope: ReactionScope::Primitive,
    trigger: {
      kinds: [FeedbackKind::Obstacle],
      severity_min: Severity::Warn,
      source_filter: None,
    },
    guard_expr: None,
    action: ReactionAction::Continue,
    escalation: Some(leaf),
  }
  match react([root], fb) {
    ReactionDecision::Continue => assert_true(true)
    _ => assert_true(false)
  }
}
```

## 验证

```bash
export PATH="$HOME/.moon/bin:$PATH"
cd /workspace/mot
moon check    # 0 错误
moon test     # 31 passed, 0 failed
```
