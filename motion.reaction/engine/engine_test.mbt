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
