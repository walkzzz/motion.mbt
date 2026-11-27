// Reaction engine blackbox tests: policy matching, bounded escalation (I3).

///|
test "reaction engine: no matching policy -> Continue" {
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
  match @engine.react([], fb) {
    @engine.ReactionDecision::Continue => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "reaction engine: matching obstacle policy -> Avoid" {
  let fb : @types.EnvFeedback = {
    source: "urn:mot:sensor:lidar:1.0",
    kind: @types.FeedbackKind::Obstacle,
    timestamp: 0L,
    stale_after_ms: 100L,
    severity: @types.Severity::Danger,
    payload: @types.FeedbackPayload::Obstacle(
      1.0,
      { x: 0.0, y: 0.0, z: 0.0, },
      0.5,
      None,
    ),
    sac_ref: None,
    action_ref: None,
  }
  let policy : @types.ReactionPolicy = {
    id: "p1",
    scope: @types.ReactionScope::Primitive,
    trigger: {
      kinds: [@types.FeedbackKind::Obstacle],
      severity_min: @types.Severity::Warn,
      source_filter: None,
    },
    guard_expr: None,
    action: @types.ReactionAction::Avoid(
      @types.AvoidStrategy::StopAndWait(100L),
    ),
    escalation: None,
  }
  match @engine.react([policy], fb) {
    @engine.ReactionDecision::Avoid(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "reaction engine: escalation chain bounded -> FaultLocked (I3)" {
  let fb : @types.EnvFeedback = {
    source: "s",
    kind: @types.FeedbackKind::Obstacle,
    timestamp: 0L,
    stale_after_ms: 100L,
    severity: @types.Severity::Danger,
    payload: @types.FeedbackPayload::Obstacle(
      1.0,
      { x: 0.0, y: 0.0, z: 0.0, },
      0.5,
      None,
    ),
    sac_ref: None,
    action_ref: None,
  }
  fn mk(id : String, esc : @types.ReactionPolicy?) -> @types.ReactionPolicy {
    {
      id,
      scope: @types.ReactionScope::Primitive,
      trigger: {
        kinds: [@types.FeedbackKind::Obstacle],
        severity_min: @types.Severity::Warn,
        source_filter: None,
      },
      guard_expr: None,
      action: @types.ReactionAction::Continue,
      escalation: esc,
    }
  }
  let root = mk(
    "root",
    Some(
      mk(
        "esc1",
        Some(
          mk(
            "esc2",
            Some(
              mk(
                "esc3",
                Some(mk("esc4", Some(mk("esc5", Some(mk("esc6", None)))))),
              ),
            ),
          ),
        ),
      ),
    ),
  )
  match @engine.react([root], fb) {
    @engine.ReactionDecision::FaultLocked(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
fn mk_fb(sev : @types.Severity, src : String) -> @types.EnvFeedback {
  {
    source: src,
    kind: @types.FeedbackKind::Obstacle,
    timestamp: 0L,
    stale_after_ms: 100L,
    severity: sev,
    payload: @types.FeedbackPayload::Obstacle(
      1.0,
      { x: 0.0, y: 0.0, z: 0.0, },
      0.5,
      None,
    ),
    sac_ref: None,
    action_ref: None,
  }
}

///|
fn mk_policy(
  id : String,
  action : @types.ReactionAction,
  filter : String?,
  min : @types.Severity,
) -> @types.ReactionPolicy {
  {
    id,
    scope: @types.ReactionScope::Primitive,
    trigger: {
      kinds: [@types.FeedbackKind::Obstacle],
      severity_min: min,
      source_filter: filter,
    },
    guard_expr: None,
    action,
    escalation: None,
  }
}

///|
test "reaction engine: Adjust / SafeHold / Abort / Replan decisions" {
  let fb = mk_fb(@types.Severity::Danger, "urn:mot:sensor:lidar:1.0")
  let adjust = mk_policy(
    "p-adjust",
    @types.ReactionAction::Adjust(
      Map([("speed", @types.ParamValue::PFloat(0.2))]),
    ),
    None,
    @types.Severity::Info,
  )
  match @engine.react([adjust], fb) {
    @engine.ReactionDecision::Adjust(p) => assert_true(p.contains("speed"))
    _ => assert_true(false)
  }
  let hold = mk_policy(
    "p-hold",
    @types.ReactionAction::SafeHold,
    None,
    @types.Severity::Info,
  )
  match @engine.react([hold], fb) {
    @engine.ReactionDecision::SafeHold => assert_true(true)
    _ => assert_true(false)
  }
  let abort = mk_policy(
    "p-abort",
    @types.ReactionAction::Abort("operator"),
    None,
    @types.Severity::Info,
  )
  match @engine.react([abort], fb) {
    @engine.ReactionDecision::Abort(r) => assert_eq(r, "operator")
    _ => assert_true(false)
  }
  let replan = mk_policy(
    "p-replan",
    @types.ReactionAction::Replan,
    None,
    @types.Severity::Info,
  )
  match @engine.react([replan], fb) {
    @engine.ReactionDecision::Replan => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "reaction engine: Wait decision with condition" {
  let fb = mk_fb(@types.Severity::Danger, "urn:mot:sensor:lidar:1.0")
  let wait = mk_policy(
    "p-wait",
    @types.ReactionAction::Wait("clear", 300L, @types.ReactionAction::Continue),
    None,
    @types.Severity::Info,
  )
  match @engine.react([wait], fb) {
    @engine.ReactionDecision::Wait(c, t, _) => {
      assert_eq(c, "clear")
      assert_eq(t, 300L)
    }
    _ => assert_true(false)
  }
}

///|
test "reaction engine: severity boundary - below min does not match" {
  let fb = mk_fb(@types.Severity::Info, "urn:mot:sensor:lidar:1.0")
  let policy = mk_policy(
    "p1",
    @types.ReactionAction::SafeHold,
    None,
    @types.Severity::Warn,
  )
  match @engine.react([policy], fb) {
    @engine.ReactionDecision::Continue => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "reaction engine: severity boundary - equal to min matches" {
  let fb = mk_fb(@types.Severity::Warn, "urn:mot:sensor:lidar:1.0")
  let policy = mk_policy(
    "p1",
    @types.ReactionAction::SafeHold,
    None,
    @types.Severity::Warn,
  )
  match @engine.react([policy], fb) {
    @engine.ReactionDecision::SafeHold => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "reaction engine: source filter mismatch -> Continue" {
  let fb = mk_fb(@types.Severity::Danger, "urn:mot:sensor:lidar:1.0")
  let policy = mk_policy(
    "p1",
    @types.ReactionAction::SafeHold,
    Some("urn:mot:sensor:other:1.0"),
    @types.Severity::Info,
  )
  match @engine.react([policy], fb) {
    @engine.ReactionDecision::Continue => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "reaction engine: source filter match -> decision" {
  let fb = mk_fb(@types.Severity::Danger, "urn:mot:sensor:lidar:1.0")
  let policy = mk_policy(
    "p1",
    @types.ReactionAction::Avoid(@types.AvoidStrategy::SpeedReduce(0.3)),
    Some("urn:mot:sensor:lidar:1.0"),
    @types.Severity::Info,
  )
  match @engine.react([policy], fb) {
    @engine.ReactionDecision::Avoid(@types.AvoidStrategy::SpeedReduce(_)) =>
      assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "reaction engine: first matching policy wins" {
  let fb = mk_fb(@types.Severity::Danger, "urn:mot:sensor:lidar:1.0")
  let p1 = mk_policy(
    "p1",
    @types.ReactionAction::SafeHold,
    None,
    @types.Severity::Warn,
  )
  let p2 = mk_policy(
    "p2",
    @types.ReactionAction::Abort("x"),
    None,
    @types.Severity::Info,
  )
  match @engine.react([p1, p2], fb) {
    @engine.ReactionDecision::SafeHold => assert_true(true)
    _ => assert_true(false)
  }
}
