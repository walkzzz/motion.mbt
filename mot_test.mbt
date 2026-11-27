// MOT test suite —— covers core modules: safety state machine, binding engine,
// reaction engine, security layer, diagnostic system, gbz185 integration.
// Run with: moon test
//
// In black-box test files, package symbols are referenced via the @mot prefix.

///|
test "safety state machine: initial state is Selftest" {
  let sm = @motion.new_statemachine()
  match @motion.sm_current(sm) {
    @motion.SafetyState::Selftest => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "safety state machine: Reset from Selftest -> Idle (I2)" {
  let sm = @motion.new_statemachine()
  let r = @motion.transition(sm, @motion.StateEvent::Reset)
  assert_true(r.allowed)
  match r.to {
    @motion.SafetyState::Idle => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "safety state machine: TaskStart from Idle -> Executing" {
  let sm = @motion.new_statemachine()
  let _ = @motion.transition(sm, @motion.StateEvent::Reset)
  let r = @motion.transition(sm, @motion.StateEvent::TaskStart)
  assert_true(r.allowed)
  match r.to {
    @motion.SafetyState::Executing => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "safety state machine: is_action_allowed true only in Executing (I5)" {
  let sm = @motion.new_statemachine()
  assert_false(@motion.is_action_allowed(sm, "walk"))
  let _ = @motion.transition(sm, @motion.StateEvent::Reset)
  assert_false(@motion.is_action_allowed(sm, "walk"))
  let _ = @motion.transition(sm, @motion.StateEvent::TaskStart)
  assert_true(@motion.is_action_allowed(sm, "walk"))
}

///|
test "safety state machine: gate_closed true when non-Executing (I4)" {
  let sm = @motion.new_statemachine()
  assert_true(@motion.gate_closed(sm))
  let _ = @motion.transition(sm, @motion.StateEvent::Reset)
  assert_true(@motion.gate_closed(sm))
  let _ = @motion.transition(sm, @motion.StateEvent::TaskStart)
  assert_false(@motion.gate_closed(sm))
}

///|
test "safety state machine: SafetyEvent preempts to SafeHold (I1)" {
  let sm = @motion.new_statemachine()
  let _ = @motion.transition(sm, @motion.StateEvent::Reset)
  let _ = @motion.transition(sm, @motion.StateEvent::TaskStart)
  let r = @motion.transition(
    sm,
    @motion.StateEvent::Safety(@motion.SafetyEvent::EStopPressed),
  )
  assert_true(r.allowed)
  match r.to {
    @motion.SafetyState::SafeHold => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "diagnostic: exit_code_of empty -> 0 (Success)" {
  assert_eq(@motion.exit_code_of([]), 0)
}

///|
test "diagnostic: exit_code_of with error -> 1" {
  let d = @motion.make_error(
    @motion.DiagnosticCategory::Syntax,
    1000,
    ["x"],
    "err",
  )
  assert_eq(@motion.exit_code_of([d]), 1)
}

///|
test "diagnostic: exit_code_of with warning only -> 2" {
  let d = @motion.make_warning(
    @motion.DiagnosticCategory::Syntax,
    1000,
    ["x"],
    "warn",
  )
  assert_eq(@motion.exit_code_of([d]), 2)
}

///|
test "supply: verify_lock_hash matching -> Ok" {
  match @motion.verify_lock_hash("abc", "abc") {
    Ok(_) => assert_true(true)
    Err(_) => assert_true(false)
  }
}

///|
test "supply: verify_lock_hash mismatch -> Err (AS1)" {
  match @motion.verify_lock_hash("abc", "xyz") {
    Ok(_) => assert_true(false)
    Err(e) => assert_eq(e.code, 1702)
  }
}

///|
test "supply: verify_package_signature unsupported algo -> Err" {
  let pkg = @motion.PackageRef::{
    urn: "urn:mot:p:x:1.0",
    version: "1.0",
    sha256: "aa",
  }
  let sig = @motion.PackageSig::{
    algorithm: "bogus",
    signature: [],
    public_key: "k",
  }
  match @motion.verify_package_signature(pkg, sig) {
    Ok(_) => assert_true(false)
    Err(e) => assert_eq(e.code, 1701)
  }
}

///|
test "supply: verify_package_signature trusted-registry -> Ok" {
  let pkg = @motion.PackageRef::{
    urn: "urn:mot:p:x:1.0",
    version: "1.0",
    sha256: "aa",
  }
  let sig = @motion.PackageSig::{
    algorithm: "trusted-registry",
    signature: [],
    public_key: "k",
  }
  match @motion.verify_package_signature(pkg, sig) {
    Ok(_) => assert_true(true)
    Err(_) => assert_true(false)
  }
}

///|
test "nli guard: uninterpretable -> Err (AS2)" {
  match
    @motion.guard_nli_result(@motion.NLI_Result::Uninterpretable("garbage")) {
    Ok(_) => assert_true(false)
    Err(e) => assert_eq(e.code, 1710)
  }
}

///|
test "nli guard: ambiguous -> Err (AS2)" {
  match @motion.guard_nli_result(@motion.NLI_Result::Ambiguous([], [])) {
    Ok(_) => assert_true(false)
    Err(e) => assert_eq(e.code, 1711)
  }
}

///|
test "nli guard: dangerous primitive -> Err (AS2)" {
  let seq : @motion.TargetActionSeq = {
    actions: [
      {
        primitive: "urn:mot:prim:abort:1.0",
        params: Map([]),
        sac_override: None,
        reaction_policies: [],
      },
    ],
    bodymap: "urn:mot:bodymap:human:1.0",
    metadata: Map([]),
  }
  match @motion.guard_nli_result(@motion.NLI_Result::Success(seq)) {
    Ok(_) => assert_true(false)
    Err(e) => assert_eq(e.code, 1712)
  }
}

///|
test "nli guard: safe primitive -> Ok (AS2)" {
  let seq : @motion.TargetActionSeq = {
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
  match @motion.guard_nli_result(@motion.NLI_Result::Success(seq)) {
    Ok(s) => assert_eq(s.actions.length(), 1)
    Err(_) => assert_true(false)
  }
}

///|
test "feedback auth: unregistered source -> Err (I6)" {
  let reg = @motion.new_sensor_registry()
  let fb : @motion.EnvFeedback = {
    source: "urn:mot:sensor:ghost:1.0",
    kind: @motion.FeedbackKind::Obstacle,
    timestamp: 0L,
    stale_after_ms: 100L,
    severity: @motion.Severity::Warn,
    payload: @motion.FeedbackPayload::Obstacle(
      1.0,
      { x: 0.0, y: 0.0, z: 0.0, },
      0.5,
      None,
    ),
    sac_ref: None,
    action_ref: None,
  }
  match @motion.authenticate_feedback(reg, fb) {
    Ok(_) => assert_true(false)
    Err(e) => assert_eq(e.code, 1730)
  }
}

///|
test "feedback auth: registered source -> Ok (I6)" {
  let reg = @motion.new_sensor_registry()
  @motion.register_sensor(reg, "urn:mot:sensor:lidar:1.0")
  let fb : @motion.EnvFeedback = {
    source: "urn:mot:sensor:lidar:1.0",
    kind: @motion.FeedbackKind::Obstacle,
    timestamp: 0L,
    stale_after_ms: 100L,
    severity: @motion.Severity::Warn,
    payload: @motion.FeedbackPayload::Obstacle(
      1.0,
      { x: 0.0, y: 0.0, z: 0.0, },
      0.5,
      None,
    ),
    sac_ref: None,
    action_ref: None,
  }
  match @motion.authenticate_feedback(reg, fb) {
    Ok(_) => assert_true(true)
    Err(_) => assert_true(false)
  }
}

///|
test "feedback auth: stale feedback (stale_after_ms<=0) -> Err (I6)" {
  let reg = @motion.new_sensor_registry()
  @motion.register_sensor(reg, "urn:mot:sensor:lidar:1.0")
  let fb : @motion.EnvFeedback = {
    source: "urn:mot:sensor:lidar:1.0",
    kind: @motion.FeedbackKind::Obstacle,
    timestamp: 0L,
    stale_after_ms: 0L,
    severity: @motion.Severity::Warn,
    payload: @motion.FeedbackPayload::Obstacle(
      1.0,
      { x: 0.0, y: 0.0, z: 0.0, },
      0.5,
      None,
    ),
    sac_ref: None,
    action_ref: None,
  }
  match @motion.authenticate_feedback(reg, fb) {
    Ok(_) => assert_true(false)
    Err(e) => assert_eq(e.code, 1731)
  }
}

///|
test "output gate: non-Executing -> do_exec false (I5)" {
  let sm = @motion.new_statemachine()
  let gate = @motion.new_gate(sm)
  assert_false(@motion.do_exec(gate, "walk"))
  assert_true(@motion.gate_is_closed(gate))
}

///|
test "output gate: Executing -> do_exec true (I5)" {
  let sm = @motion.new_statemachine()
  let _ = @motion.transition(sm, @motion.StateEvent::Reset)
  let _ = @motion.transition(sm, @motion.StateEvent::TaskStart)
  let gate = @motion.new_gate(sm)
  assert_true(@motion.do_exec(gate, "walk"))
  assert_false(@motion.gate_is_closed(gate))
}

///|
test "binding engine: empty seq -> Ok" {
  let reg = @motion.new_registry()
  let seq : @motion.TargetActionSeq = {
    actions: [],
    bodymap: "urn:mot:bodymap:human:1.0",
    metadata: Map([]),
  }
  let graph : @motion.MappingGraph = { edges: [], }
  match @motion.bind(seq, graph, reg) {
    @motion.BindResult::Ok(_) => assert_true(true)
    @motion.BindResult::Error(_) => assert_true(false)
  }
}

///|
test "binding engine: unregistered primitive -> Err (Stage 1)" {
  let reg = @motion.new_registry()
  let seq : @motion.TargetActionSeq = {
    actions: [
      {
        primitive: "urn:mot:prim:ghost:1.0",
        params: Map([]),
        sac_override: None,
        reaction_policies: [],
      },
    ],
    bodymap: "urn:mot:bodymap:human:1.0",
    metadata: Map([]),
  }
  let graph : @motion.MappingGraph = { edges: [], }
  match @motion.bind(seq, graph, reg) {
    @motion.BindResult::Ok(_) => assert_true(false)
    @motion.BindResult::Error(ds) => assert_eq(ds.length(), 1)
  }
}

///|
test "binding engine: registered primitive -> Ok (Stage 1)" {
  let reg = @motion.new_registry()
  let p : @motion.Primitive = {
    urn: "urn:mot:prim:walk:1.0",
    name: "walk",
    category: @motion.PrimCategory::Loc,
    params: [],
    occupancy: { participants: [], exclusive: false, },
    sac: {
      predicates: [],
      completeness: @motion.CompletenessLevel::Structural,
    },
    metadata: Map([]),
  }
  @motion.register_primitive(reg, p)
  let seq : @motion.TargetActionSeq = {
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
  let graph : @motion.MappingGraph = { edges: [], }
  match @motion.bind(seq, graph, reg) {
    @motion.BindResult::Ok(b) => assert_eq(b.actions.length(), 1)
    @motion.BindResult::Error(_) => assert_true(false)
  }
}

///|
test "reaction engine: no matching policy -> Continue" {
  let fb : @motion.EnvFeedback = {
    source: "urn:mot:sensor:lidar:1.0",
    kind: @motion.FeedbackKind::Obstacle,
    timestamp: 0L,
    stale_after_ms: 100L,
    severity: @motion.Severity::Warn,
    payload: @motion.FeedbackPayload::Obstacle(
      1.0,
      { x: 0.0, y: 0.0, z: 0.0, },
      0.5,
      None,
    ),
    sac_ref: None,
    action_ref: None,
  }
  match @motion.react([], fb) {
    @motion.ReactionDecision::Continue => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "reaction engine: matching obstacle policy -> Avoid" {
  let fb : @motion.EnvFeedback = {
    source: "urn:mot:sensor:lidar:1.0",
    kind: @motion.FeedbackKind::Obstacle,
    timestamp: 0L,
    stale_after_ms: 100L,
    severity: @motion.Severity::Danger,
    payload: @motion.FeedbackPayload::Obstacle(
      1.0,
      { x: 0.0, y: 0.0, z: 0.0, },
      0.5,
      None,
    ),
    sac_ref: None,
    action_ref: None,
  }
  let policy : @motion.ReactionPolicy = {
    id: "p1",
    scope: @motion.ReactionScope::Primitive,
    trigger: {
      kinds: [@motion.FeedbackKind::Obstacle],
      severity_min: @motion.Severity::Warn,
      source_filter: None,
    },
    guard_expr: None,
    action: @motion.ReactionAction::Avoid(
      @motion.AvoidStrategy::StopAndWait(100L),
    ),
    escalation: None,
  }
  match @motion.react([policy], fb) {
    @motion.ReactionDecision::Avoid(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "reaction engine: escalation chain bounded -> FaultLocked (I3)" {
  let fb : @motion.EnvFeedback = {
    source: "s",
    kind: @motion.FeedbackKind::Obstacle,
    timestamp: 0L,
    stale_after_ms: 100L,
    severity: @motion.Severity::Danger,
    payload: @motion.FeedbackPayload::Obstacle(
      1.0,
      { x: 0.0, y: 0.0, z: 0.0, },
      0.5,
      None,
    ),
    sac_ref: None,
    action_ref: None,
  }
  let esc6 : @motion.ReactionPolicy = {
    id: "esc6",
    scope: @motion.ReactionScope::Primitive,
    trigger: {
      kinds: [@motion.FeedbackKind::Obstacle],
      severity_min: @motion.Severity::Warn,
      source_filter: None,
    },
    guard_expr: None,
    action: @motion.ReactionAction::Continue,
    escalation: None,
  }
  let esc5 : @motion.ReactionPolicy = {
    id: "esc5",
    scope: @motion.ReactionScope::Primitive,
    trigger: {
      kinds: [@motion.FeedbackKind::Obstacle],
      severity_min: @motion.Severity::Warn,
      source_filter: None,
    },
    guard_expr: None,
    action: @motion.ReactionAction::Continue,
    escalation: Some(esc6),
  }
  let esc4 : @motion.ReactionPolicy = {
    id: "esc4",
    scope: @motion.ReactionScope::Primitive,
    trigger: {
      kinds: [@motion.FeedbackKind::Obstacle],
      severity_min: @motion.Severity::Warn,
      source_filter: None,
    },
    guard_expr: None,
    action: @motion.ReactionAction::Continue,
    escalation: Some(esc5),
  }
  let esc3 : @motion.ReactionPolicy = {
    id: "esc3",
    scope: @motion.ReactionScope::Primitive,
    trigger: {
      kinds: [@motion.FeedbackKind::Obstacle],
      severity_min: @motion.Severity::Warn,
      source_filter: None,
    },
    guard_expr: None,
    action: @motion.ReactionAction::Continue,
    escalation: Some(esc4),
  }
  let esc2 : @motion.ReactionPolicy = {
    id: "esc2",
    scope: @motion.ReactionScope::Primitive,
    trigger: {
      kinds: [@motion.FeedbackKind::Obstacle],
      severity_min: @motion.Severity::Warn,
      source_filter: None,
    },
    guard_expr: None,
    action: @motion.ReactionAction::Continue,
    escalation: Some(esc3),
  }
  let esc1 : @motion.ReactionPolicy = {
    id: "esc1",
    scope: @motion.ReactionScope::Primitive,
    trigger: {
      kinds: [@motion.FeedbackKind::Obstacle],
      severity_min: @motion.Severity::Warn,
      source_filter: None,
    },
    guard_expr: None,
    action: @motion.ReactionAction::Continue,
    escalation: Some(esc2),
  }
  let root : @motion.ReactionPolicy = {
    id: "root",
    scope: @motion.ReactionScope::Primitive,
    trigger: {
      kinds: [@motion.FeedbackKind::Obstacle],
      severity_min: @motion.Severity::Warn,
      source_filter: None,
    },
    guard_expr: None,
    action: @motion.ReactionAction::Continue,
    escalation: Some(esc1),
  }
  match @motion.react([root], fb) {
    @motion.ReactionDecision::FaultLocked(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "gbz185 integration: MotError implements ProtocolError" {
  let e = @motion.MotError::Security_error("test")
  assert_eq(@wire.ProtocolError::part(e), "gbz185.6")
  assert_eq(@wire.ProtocolError::code(e), "MOT-1700")
  assert_eq(@wire.ProtocolError::message(e), "test")
}

///|
test "gbz185 integration: mot_envelope builds AipEnvelope" {
  let env = @motion.mot_envelope(
    "urn:mot:a:1.0",
    "urn:mot:b:1.0",
    5L,
    @aip.MessageKind::Event,
    Json::null(),
  )
  assert_eq(env.sender_urn, "urn:mot:a:1.0")
  assert_eq(env.seq, 5L)
  match env.kind {
    @aip.MessageKind::Event => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "gbz185 integration: mot_tool_descriptor builds ToolDescriptor" {
  let desc = @motion.mot_tool_descriptor(
    "executor.walk",
    "walk executor",
    Json::null(),
    @tooling.ToolBinding::NativeBinding,
  )
  assert_eq(desc.name, "executor.walk")
}

///|
test "binding engine: cyclic mapping graph -> Err (Stage 2)" {
  let reg = @motion.new_registry()
  let seq : @motion.TargetActionSeq = {
    actions: [],
    bodymap: "urn:mot:bodymap:human:1.0",
    metadata: Map([]),
  }
  let graph : @motion.MappingGraph = {
    edges: [
      {
        source: "urn:mot:prim:a:1.0",
        target: "urn:mot:prim:b:1.0",
        transform: @motion.MappingTransform::Direct,
        fidelity: @motion.FidelityLevel::Exact,
        fallback_chain: [],
      },
      {
        source: "urn:mot:prim:b:1.0",
        target: "urn:mot:prim:a:1.0",
        transform: @motion.MappingTransform::Direct,
        fidelity: @motion.FidelityLevel::Exact,
        fallback_chain: [],
      },
    ],
  }
  match @motion.bind(seq, graph, reg) {
    @motion.BindResult::Error(ds) => assert_true(ds.length() > 0)
    @motion.BindResult::Ok(_) => assert_true(false)
  }
}

///|
test "binding engine: acyclic mapping graph -> Ok (Stage 2)" {
  let reg = @motion.new_registry()
  let seq : @motion.TargetActionSeq = {
    actions: [],
    bodymap: "urn:mot:bodymap:human:1.0",
    metadata: Map([]),
  }
  let graph : @motion.MappingGraph = {
    edges: [
      {
        source: "urn:mot:prim:a:1.0",
        target: "urn:mot:prim:b:1.0",
        transform: @motion.MappingTransform::Direct,
        fidelity: @motion.FidelityLevel::Exact,
        fallback_chain: [],
      },
      {
        source: "urn:mot:prim:b:1.0",
        target: "urn:mot:prim:c:1.0",
        transform: @motion.MappingTransform::Direct,
        fidelity: @motion.FidelityLevel::Approximate,
        fallback_chain: [],
      },
    ],
  }
  match @motion.bind(seq, graph, reg) {
    @motion.BindResult::Ok(_) => assert_true(true)
    @motion.BindResult::Error(_) => assert_true(false)
  }
}

///|
test "binding engine: self-loop mapping edge -> Err (Stage 2)" {
  let reg = @motion.new_registry()
  let seq : @motion.TargetActionSeq = {
    actions: [],
    bodymap: "urn:mot:bodymap:human:1.0",
    metadata: Map([]),
  }
  let graph : @motion.MappingGraph = {
    edges: [
      {
        source: "urn:mot:prim:a:1.0",
        target: "urn:mot:prim:a:1.0",
        transform: @motion.MappingTransform::Direct,
        fidelity: @motion.FidelityLevel::Exact,
        fallback_chain: [],
      },
    ],
  }
  match @motion.bind(seq, graph, reg) {
    @motion.BindResult::Error(ds) => assert_eq(ds.length(), 1)
    @motion.BindResult::Ok(_) => assert_true(false)
  }
}

///|
test "supply: verify_package_signature missing sha256 -> Err (AS1)" {
  let pkg = @motion.PackageRef::{
    urn: "urn:mot:p:x:1.0",
    version: "1.0",
    sha256: "",
  }
  let sig = @motion.PackageSig::{
    algorithm: "trusted-registry",
    signature: [],
    public_key: "k",
  }
  match @motion.verify_package_signature(pkg, sig) {
    Ok(_) => assert_true(false)
    Err(e) => assert_eq(e.code, 1703)
  }
}

///|
test "safety: empty action command rejected even when Executing (I5)" {
  let sm = @motion.new_statemachine()
  let _ = @motion.transition(sm, @motion.StateEvent::Reset)
  let _ = @motion.transition(sm, @motion.StateEvent::TaskStart)
  assert_false(@motion.is_action_allowed(sm, ""))
}

///|
test "diag: internal_error_code -> 3" {
  assert_eq(@motion.internal_error_code(), 3)
}

///|
test "threat: security_error_to_mot message includes surface tag" {
  let e = @motion.sec_error(@motion.AttackSurface::AS1_SupplyChain, 1701, "bad")
  match @motion.security_error_to_mot(e) {
    @motion.MotError::Security_error(msg) =>
      assert_true(msg.contains("AS1_SupplyChain"))
    _ => assert_true(false)
  }
}
