// Example: security guards — feedback auth (I6), output gate (I5), NLI guard (AS2).
// Run: moon run examples/security --target native

///|
fn main {
  println("[example] security guards: I6 + I5 + AS2")
  // I6: feedback source authentication
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
      { x: 0.0, y: 0.0, z: 0.0, },
      0.5,
      None,
    ),
    sac_ref: None,
    action_ref: None,
  }
  match @all.authenticate_feedback(reg, fb) {
    Ok(_) => println("I6: registered lidar feedback accepted")
    Err(e) => println("I6: registered lidar feedback rejected (code \{e.code})")
  }
  let ghost : @all.EnvFeedback = { ..fb, source: "urn:mot:sensor:ghost:1.0", }
  match @all.authenticate_feedback(reg, ghost) {
    Ok(_) => println("I6: ghost source accepted (BUG!)")
    Err(e) => println("I6: ghost source rejected (code \{e.code})")
  }
  // I5: output gate
  let sm = @all.new_statemachine()
  let gate = @all.new_gate(sm)
  println("I5: gate in Selftest — do_exec: \{@all.do_exec(gate, "walk")}")
  // AS2: NLI guard
  let safe_seq : @all.TargetActionSeq = {
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
  match @all.guard_nli_result(@all.NLI_Result::Success(safe_seq)) {
    Ok(_) => println("AS2: safe NLI sequence passed the guard")
    Err(e) => println("AS2: safe NLI sequence rejected (code \{e.code})")
  }
  let danger_seq : @all.TargetActionSeq = {
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
  match @all.guard_nli_result(@all.NLI_Result::Success(danger_seq)) {
    Ok(_) => println("AS2: dangerous primitive accepted (BUG!)")
    Err(e) => println("AS2: dangerous primitive rejected (code \{e.code})")
  }
}
