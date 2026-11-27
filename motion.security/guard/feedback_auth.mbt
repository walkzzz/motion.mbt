// AS4 feedback source authentication (invariant I6)
// The ReactionEngine only processes EnvFeedback whose source is a registered sensor URN.
// Stale feedback (stale_after_ms <= 0) is rejected (downgraded to Stale -> SafeHold).

///|
pub struct SensorRegistry {
  sensors : Map[String, Bool]
}

///|
pub fn new_sensor_registry() -> SensorRegistry {
  { sensors: Map([]), }
}

///|
pub fn register_sensor(reg : SensorRegistry, urn : String) -> Unit {
  reg.sensors[urn] = true
}

// Authenticate feedback source. Rejects unregistered sources (I6).

///|
pub fn authenticate_feedback(
  reg : SensorRegistry,
  feedback : @types.EnvFeedback,
) -> Result[@types.EnvFeedback, @types.SecurityError] {
  match reg.sensors.get(feedback.source) {
    None =>
      Err(
        @types.sec_error(
          @types.AttackSurface::AS4_FeedbackInjection,
          1730,
          "unregistered feedback source: \{feedback.source}",
        ),
      )
    Some(_) =>
      if feedback.stale_after_ms <= 0 {
        Err(
          @types.sec_error(
            @types.AttackSurface::AS4_FeedbackInjection,
            1731,
            "invalid stale_after_ms",
          ),
        )
      } else {
        Ok(feedback)
      }
  }
}
