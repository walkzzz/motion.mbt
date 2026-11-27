// Example: reaction engine with bounded escalation (I3).
// Run: moon run examples/react --target native

///|
fn decision_name(d : @all.ReactionDecision) -> String {
  match d {
    Continue => "Continue"
    Adjust(_) => "Adjust"
    Avoid(_) => "Avoid"
    Wait(_, _, _) => "Wait"
    SafeHold => "SafeHold"
    Abort(_) => "Abort"
    Replan => "Replan"
    FaultLocked(_) => "FaultLocked"
  }
}

///|
fn mk_feedback(sev : @all.Severity) -> @all.EnvFeedback {
  {
    source: "urn:mot:sensor:lidar:1.0",
    kind: @all.FeedbackKind::Obstacle,
    timestamp: 0L,
    stale_after_ms: 100L,
    severity: sev,
    payload: @all.FeedbackPayload::Obstacle(
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
fn main {
  println("[example] reaction engine (I3 bounded escalation)")
  let policy : @all.ReactionPolicy = {
    id: "p-obstacle",
    scope: @all.ReactionScope::Primitive,
    trigger: {
      kinds: [@all.FeedbackKind::Obstacle],
      severity_min: @all.Severity::Warn,
      source_filter: None,
    },
    guard_expr: None,
    action: @all.ReactionAction::Avoid(@all.AvoidStrategy::StopAndWait(100L)),
    escalation: None,
  }
  let d1 = @all.react([policy], mk_feedback(@all.Severity::Info))
  println(
    "Info obstacle    -> \{decision_name(d1)} (below severity_min, no match)",
  )
  let d2 = @all.react([policy], mk_feedback(@all.Severity::Danger))
  println("Danger obstacle   -> \{decision_name(d2)} (policy matched)")
  let d3 = @all.react([], mk_feedback(@all.Severity::Danger))
  println("no policies      -> \{decision_name(d3)} (default continue)")
}
