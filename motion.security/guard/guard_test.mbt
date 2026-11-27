// Security guard blackbox tests: supply chain (AS1), NLI guard (AS2), feedback auth (I6), output gate (I5).

///|
test "supply: verify_lock_hash matching -> Ok" {
  match @guard.verify_lock_hash("abc", "abc") {
    Ok(_) => assert_true(true)
    Err(_) => assert_true(false)
  }
}

///|
test "supply: verify_lock_hash mismatch -> Err (AS1)" {
  match @guard.verify_lock_hash("abc", "xyz") {
    Ok(_) => assert_true(false)
    Err(e) => assert_eq(e.code, 1702)
  }
}

///|
test "supply: verify_package_signature unsupported algo -> Err" {
  let pkg = @guard.PackageRef::{
    urn: "urn:mot:p:x:1.0",
    version: "1.0",
    sha256: "aa",
  }
  let sig = @guard.PackageSig::{
    algorithm: "bogus",
    signature: [],
    public_key: "k",
  }
  match @guard.verify_package_signature(pkg, sig) {
    Ok(_) => assert_true(false)
    Err(e) => assert_eq(e.code, 1701)
  }
}

///|
test "supply: verify_package_signature trusted-registry -> Ok" {
  let pkg = @guard.PackageRef::{
    urn: "urn:mot:p:x:1.0",
    version: "1.0",
    sha256: "aa",
  }
  let sig = @guard.PackageSig::{
    algorithm: "trusted-registry",
    signature: [],
    public_key: "k",
  }
  match @guard.verify_package_signature(pkg, sig) {
    Ok(_) => assert_true(true)
    Err(_) => assert_true(false)
  }
}

///|
test "supply: verify_package_signature missing sha256 -> Err (AS1)" {
  let pkg = @guard.PackageRef::{
    urn: "urn:mot:p:x:1.0",
    version: "1.0",
    sha256: "",
  }
  let sig = @guard.PackageSig::{
    algorithm: "trusted-registry",
    signature: [],
    public_key: "k",
  }
  match @guard.verify_package_signature(pkg, sig) {
    Ok(_) => assert_true(false)
    Err(e) => assert_eq(e.code, 1703)
  }
}

///|
test "nli guard: uninterpretable -> Err (AS2)" {
  match @guard.guard_nli_result(@types.NLI_Result::Uninterpretable("garbage")) {
    Ok(_) => assert_true(false)
    Err(e) => assert_eq(e.code, 1710)
  }
}

///|
test "nli guard: ambiguous -> Err (AS2)" {
  match @guard.guard_nli_result(@types.NLI_Result::Ambiguous([], [])) {
    Ok(_) => assert_true(false)
    Err(e) => assert_eq(e.code, 1711)
  }
}

///|
test "nli guard: dangerous primitive -> Err (AS2)" {
  let seq : @types.TargetActionSeq = {
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
  match @guard.guard_nli_result(@types.NLI_Result::Success(seq)) {
    Ok(_) => assert_true(false)
    Err(e) => assert_eq(e.code, 1712)
  }
}

///|
test "nli guard: safe primitive -> Ok (AS2)" {
  let seq : @types.TargetActionSeq = {
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
  match @guard.guard_nli_result(@types.NLI_Result::Success(seq)) {
    Ok(s) => assert_eq(s.actions.length(), 1)
    Err(_) => assert_true(false)
  }
}

///|
test "feedback auth: unregistered source -> Err (I6)" {
  let reg = @guard.new_sensor_registry()
  let fb : @types.EnvFeedback = {
    source: "urn:mot:sensor:ghost:1.0",
    kind: @types.FeedbackKind::Obstacle,
    timestamp: 0L,
    stale_after_ms: 100L,
    severity: @types.Severity::Warn,
    payload: @types.FeedbackPayload::Obstacle(
      1.0,
      { x: 0.0, y: 0.0, z: 0.0, },
      0.5,
      None,
    ),
    sac_ref: None,
    action_ref: None,
  }
  match @guard.authenticate_feedback(reg, fb) {
    Ok(_) => assert_true(false)
    Err(e) => assert_eq(e.code, 1730)
  }
}

///|
test "feedback auth: registered source -> Ok (I6)" {
  let reg = @guard.new_sensor_registry()
  @guard.register_sensor(reg, "urn:mot:sensor:lidar:1.0")
  let fb : @types.EnvFeedback = {
    source: "urn:mot:sensor:lidar:1.0",
    kind: @types.FeedbackKind::Obstacle,
    timestamp: 0L,
    stale_after_ms: 100L,
    severity: @types.Severity::Warn,
    payload: @types.FeedbackPayload::Obstacle(
      1.0,
      { x: 0.0, y: 0.0, z: 0.0, },
      0.5,
      None,
    ),
    sac_ref: None,
    action_ref: None,
  }
  match @guard.authenticate_feedback(reg, fb) {
    Ok(_) => assert_true(true)
    Err(_) => assert_true(false)
  }
}

///|
test "feedback auth: stale feedback (stale_after_ms<=0) -> Err (I6)" {
  let reg = @guard.new_sensor_registry()
  @guard.register_sensor(reg, "urn:mot:sensor:lidar:1.0")
  let fb : @types.EnvFeedback = {
    source: "urn:mot:sensor:lidar:1.0",
    kind: @types.FeedbackKind::Obstacle,
    timestamp: 0L,
    stale_after_ms: 0L,
    severity: @types.Severity::Warn,
    payload: @types.FeedbackPayload::Obstacle(
      1.0,
      { x: 0.0, y: 0.0, z: 0.0, },
      0.5,
      None,
    ),
    sac_ref: None,
    action_ref: None,
  }
  match @guard.authenticate_feedback(reg, fb) {
    Ok(_) => assert_true(false)
    Err(e) => assert_eq(e.code, 1731)
  }
}

///|
test "output gate: non-Executing -> do_exec false (I5)" {
  let sm = @safety.new_statemachine()
  let gate = @guard.new_gate(sm)
  assert_false(@guard.do_exec(gate, "walk"))
  assert_true(@guard.gate_is_closed(gate))
}

///|
test "output gate: Executing -> do_exec true (I5)" {
  let sm = @safety.new_statemachine()
  let _ = @safety.transition(sm, @safety.StateEvent::Reset)
  let _ = @safety.transition(sm, @safety.StateEvent::TaskStart)
  let gate = @guard.new_gate(sm)
  assert_true(@guard.do_exec(gate, "walk"))
  assert_false(@guard.gate_is_closed(gate))
}
