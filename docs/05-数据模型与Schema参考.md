# MOT 通用动作语义规范 —— 数据模型与 Schema 参考

| 字段 | 值 |
|------|-----|
| 文档编号 | MOT-DOC-05 |
| 版本 | v1.0 |
| 日期 | 2026-11-27 |
| 状态 | 正式 |

---

## 1. 类型全集

### 1.1 基础类型（types.mbt）

| 类型 | 基类型 | 说明 |
|------|--------|------|
| URN | String | `urn:mot:{category}:{name}:{version}` |
| BodyMapRef | URN | BodyMap 引用 |
| PrimRef | URN | Primitive 引用 |
| MappingRef | URN | Mapping 引用 |
| BodyPartRef | String | 身体部位引用 |
| ParamMap | Map[String, ParamValue] | 参数映射 |
| SupportPattern | Array[BodyPartRef] | 支撑模式 |

### 1.2 ParamValue 多态

| 构造子 | 字段 |
|--------|------|
| PInt | Int32 |
| PFloat | Double |
| PBool | Bool |
| PString | String |
| PDirection | Vec3 |
| PEnum | String, Array[String] |
| PRange | Double, Double, String |

### 1.3 空间类型

| 类型 | 字段 |
|------|------|
| Vec3 | x:Double, y:Double, z:Double |
| SpatialDisplacement | translation:Vec3, rotation:Vec3 |

---

## 2. 领域类型

### 2.1 BodyMap（bodymap.mbt）

| 类型 | 字段 |
|------|------|
| BodyNode | id, kind, parent?, children, dof, role?, anchors |
| SemanticAnchor | id, target_nodes, description |
| BodyMap | urn, name, version, nodes, root, metadata |

BodyNodeKind: Joint|Link|Sensor|Effector|Virtual
BodyRole: LocomotionBase|ManipulationEnd|SupportPolygon|SensorMount|Actuator|Passive

### 2.2 Primitive（primitive.mbt）

| 类型 | 字段 |
|------|------|
| ParamSpec | name, ptype, required, default?, constraints |
| OccupancyDecl | participants, exclusive |
| Primitive | urn, name, category, params, occupancy, sac, metadata |

PrimCategory: Loc|Man|Exp|Pos|Con
**注意**：ParamSpec 字段名是 `ptype`（非 `type`，`type` 是关键字）

### 2.3 Mapping（mapping.mbt）

| 类型 | 字段 |
|------|------|
| ParamMapRule | from_param, to_param, converter? |
| MappingEdge | source, target, transform, fidelity, fallback_chain |
| MappingPath | steps, total_fidelity, estimated_loss |
| MappingGraph | edges |
| RouteConstraints | max_fidelity_loss?, max_hops?, preferred_intermediates |

FidelityLevel: Exact|Approximate|Degraded
MappingTransform: Direct|ParamMap(Array)|Sequence(Array)|Custom(String,Json)

### 2.4 SAC（sac.mbt）

| 类型 | 字段 |
|------|------|
| BuiltinPredicate | aspect, expr, params |
| CustomPredicate | backend, config |
| PredicateExpr | Builtin\|Custom |
| SacSpec | predicates, completeness |

AspectType: Trajectory|Contact|Posture|Spatial|Count
CompletenessLevel: Structural|Inferable|Full

### 2.5 EnvFeedback（env.mbt）

| 类型 | 字段 |
|------|------|
| EnvFeedback | source, kind, timestamp, stale_after_ms, severity, payload, sac_ref?, action_ref? |
| FeedbackPayload | 11 种构造子 |

Severity: Info|Warn|Danger|Critical（#derive(Eq)）
FeedbackKind: Obstacle|ContactLoss|Collision|VisualDrift|LocalQuality|JointAnomaly|HumanProximity|DoorState|Battery|Heartbeat|Stale（#derive(Eq)）

### 2.6 ReactionPolicy（reaction.mbt）

| 类型 | 字段 |
|------|------|
| EnvEventPattern | kinds, severity_min, source_filter? |
| ReactionPolicy | id, scope, trigger, guard_expr?, action, escalation? |
| ReactionAction | 7 种构造子 |
| AvoidStrategy | 4 种构造子 |

ReactionScope: Primitive|Sequence|Global
ConditionExpr = String
**注意**：字段名是 `guard_expr`（非 `guard`，`guard` 是关键字）

ReactionAction: Continue|Adjust(ParamMap)|Avoid(AvoidStrategy)|Wait(ConditionExpr,Int64,ReactionAction)|SafeHold|Abort(String)|Replan
AvoidStrategy: LateralOffset(Double)|SpeedReduce(Double)|StopAndWait(Int64)|Custom(String)

### 2.7 SafetyStateMachine（safety.mbt）

SafetyState: Selftest|Idle|Executing|Recovering|SafeHold|FaultLocked
StateEvent: Safety\|Reset\|TaskStart\|TaskComplete
TransitionResult: from, to, allowed, reason?

### 2.8 NLI（nli.mbt）

NLRequest: text?, audio?, image?, context
NLI_Result: Success\|Ambiguous\|Uninterpretable
MOT_FunctionSchema: name, description, parameters, returns

### 2.9 TargetActionSeq（targetseq.mbt）

BoundAction: primitive, params, sac_override?, reaction_policies
TargetActionSeq: actions, bodymap, metadata
BoundActionSeq = TargetActionSeq（类型别名）

---

## 3. 诊断类型（diag.mbt）

DiagnosticLevel: Error|Warning|Info|Hint
DiagnosticCategory: Syntax|Resolve|Mapping|Conflict|Sac|Reaction|Safety|Nli|Security
Diagnostic: level, category, code, path, message, hint?, related
ExitCode: Success=0|Error=1|Warning=2|InternalError=3

---

## 4. 安全类型

| 类型 | 文件 | 说明 |
|------|------|------|
| AttackSurface | threat | AS1-AS8 枚举 |
| SecurityError | threat | surface, code, message, detail? |
| PackageSig | supply | algorithm, signature, public_key |
| PackageRef | supply | urn, version, sha256 |
| DangerousPrimitive | nli_guard | urn, reason |
| SensorRegistry | feedback_auth | sensors: Map[String, Bool] |
| OutputGate | output_gate | sm: SafetyStateMachine |

---

## 5. GB/Z 185 集成类型（gbz185.mbt）

| 类型 | 来源 |
|------|------|
| MotError | 本库实现 @wire.ProtocolError |
| @aip.AipEnvelope | gbz185 库 |
| @aip.MessageKind | gbz185 库（TaskRequest\|TaskResult\|Event\|Heartbeat） |
| @tooling.ToolDescriptor | gbz185 库 |
| @tooling.ToolBinding | gbz185 库（McpBinding\|NativeBinding） |
| @wire.ProtocolError | gbz185 库 trait |

---

## 6. 序列化格式

### 6.1 JSON 输出（BoundActionSeq）
```json
{"actions":[{"primitive":"urn:mot:prim:walk:1.0","params":{"PFloat":1.0},"sac_override":null,"reaction_policies":[]}],"bodymap":"urn:mot:bodymap:human:1.0","metadata":{}}
```

### 6.2 mot.toml 配置格式
见仓库 `mot.toml`：`[dependencies]` + `[dependencies.lock]`（SHA-256）+ `[security]`。

### 6.3 AIP envelope 映射
MOT 消息 → @aip.MessageKind：MotNlRequest→TaskRequest、MotActionRequest→TaskRequest、MotBoundAction→Event、MotEnvFeedback→Event、MotReactionDecision→Event、MotSafeState→Event、MotActionResult→TaskResult。
