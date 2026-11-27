// Facade blackbox tests: verify `@all.` prefix exposes the full curated API.
// This mirrors the user's view: import "looyiabc/motion/all" only.

///|
test "facade: safety state machine roundtrip via @all (I1/I2/I5)" {
  let sm = @all.new_statemachine()
  assert_false(@all.is_action_allowed(sm, "walk"))
  let _ = @all.transition(sm, @all.StateEvent::Reset)
  let _ = @all.transition(sm, @all.StateEvent::TaskStart)
  assert_true(@all.is_action_allowed(sm, "walk"))
  let r = @all.transition(
    sm,
    @all.StateEvent::Safety(@all.SafetyEvent::EStopPressed),
  )
  assert_true(r.allowed)
  match @all.sm_current(sm) {
    @all.SafetyState::SafeHold => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "facade: bind empty seq via @all" {
  let reg = @all.new_registry()
  let seq : @all.TargetActionSeq = {
    actions: [],
    bodymap: "urn:mot:bodymap:human:1.0",
    metadata: Map([]),
  }
  let graph : @all.MappingGraph = { edges: [], }
  match @all.bind(seq, graph, reg) {
    @all.BindResult::Ok(_) => assert_true(true)
    @all.BindResult::Error(_) => assert_true(false)
  }
}

///|
test "facade: output gate via @all (I5)" {
  let sm = @all.new_statemachine()
  let gate = @all.new_gate(sm)
  assert_false(@all.do_exec(gate, "walk"))
  assert_true(@all.gate_is_closed(gate))
}

///|
test "facade: feedback auth + react via @all (I6/I3)" {
  let reg = @all.new_sensor_registry()
  @all.register_sensor(reg, "urn:mot:sensor:lidar:1.0")
  let fb : @all.EnvFeedback = {
    source: "urn:mot:sensor:lidar:1.0",
    kind: @all.FeedbackKind::Obstacle,
    timestamp: 0L,
    stale_after_ms: 100L,
    severity: @all.Severity::Warn,
    payload: @all.FeedbackPayload::Obstacle(
      1.0,
      @all.Vec3::{ x: 0.0, y: 0.0, z: 0.0, },
      0.5,
      None,
    ),
    sac_ref: None,
    action_ref: None,
  }
  match @all.authenticate_feedback(reg, fb) {
    Ok(authed) =>
      match @all.react([], authed) {
        @all.ReactionDecision::Continue => assert_true(true)
        _ => assert_true(false)
      }
    Err(_) => assert_true(false)
  }
}

///|
test "facade: sec_error -> MotError via @all (gbz185 wire)" {
  let e = @all.sec_error(@all.AttackSurface::AS1_SupplyChain, 1701, "bad")
  match @all.security_error_to_mot(e) {
    @all.MotError::Security_error(msg) =>
      assert_true(msg.contains("AS1_SupplyChain"))
    _ => assert_true(false)
  }
}

///|
test "facade: version constant" {
  assert_eq(@all.version, "0.1.0")
}
