// Core types blackbox tests: safety state machine (I1/I2/I4/I5), diagnostics, threat model.
// Run with: moon test

///|
test "safety state machine: initial state is Selftest" {
  let sm = @types.new_statemachine()
  match @types.sm_current(sm) {
    @types.SafetyState::Selftest => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "safety state machine: Reset from Selftest -> Idle (I2)" {
  let sm = @types.new_statemachine()
  let r = @types.transition(sm, @types.StateEvent::Reset)
  assert_true(r.allowed)
  match r.to {
    @types.SafetyState::Idle => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "safety state machine: TaskStart from Idle -> Executing" {
  let sm = @types.new_statemachine()
  let _ = @types.transition(sm, @types.StateEvent::Reset)
  let r = @types.transition(sm, @types.StateEvent::TaskStart)
  assert_true(r.allowed)
  match r.to {
    @types.SafetyState::Executing => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "safety state machine: is_action_allowed true only in Executing (I5)" {
  let sm = @types.new_statemachine()
  assert_false(@types.is_action_allowed(sm, "walk"))
  let _ = @types.transition(sm, @types.StateEvent::Reset)
  assert_false(@types.is_action_allowed(sm, "walk"))
  let _ = @types.transition(sm, @types.StateEvent::TaskStart)
  assert_true(@types.is_action_allowed(sm, "walk"))
}

///|
test "safety state machine: gate_closed true when non-Executing (I4)" {
  let sm = @types.new_statemachine()
  assert_true(@types.gate_closed(sm))
  let _ = @types.transition(sm, @types.StateEvent::Reset)
  assert_true(@types.gate_closed(sm))
  let _ = @types.transition(sm, @types.StateEvent::TaskStart)
  assert_false(@types.gate_closed(sm))
}

///|
test "safety state machine: SafetyEvent preempts to SafeHold (I1)" {
  let sm = @types.new_statemachine()
  let _ = @types.transition(sm, @types.StateEvent::Reset)
  let _ = @types.transition(sm, @types.StateEvent::TaskStart)
  let r = @types.transition(
    sm,
    @types.StateEvent::Safety(@types.SafetyEvent::EStopPressed),
  )
  assert_true(r.allowed)
  match r.to {
    @types.SafetyState::SafeHold => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "safety: empty action command rejected even when Executing (I5)" {
  let sm = @types.new_statemachine()
  let _ = @types.transition(sm, @types.StateEvent::Reset)
  let _ = @types.transition(sm, @types.StateEvent::TaskStart)
  assert_false(@types.is_action_allowed(sm, ""))
}

///|
test "diagnostic: exit_code_of empty -> 0 (Success)" {
  assert_eq(@types.exit_code_of([]), 0)
}

///|
test "diagnostic: exit_code_of with error -> 1" {
  let d = @types.make_error(
    @types.DiagnosticCategory::Syntax,
    1000,
    ["x"],
    "err",
  )
  assert_eq(@types.exit_code_of([d]), 1)
}

///|
test "diagnostic: exit_code_of with warning only -> 2" {
  let d = @types.make_warning(
    @types.DiagnosticCategory::Syntax,
    1000,
    ["x"],
    "warn",
  )
  assert_eq(@types.exit_code_of([d]), 2)
}

///|
test "diag: internal_error_code -> 3" {
  assert_eq(@types.internal_error_code(), 3)
}

///|
test "safety: TaskComplete Executing -> Idle" {
  let sm = @types.new_statemachine()
  let _ = @types.transition(sm, @types.StateEvent::Reset)
  let _ = @types.transition(sm, @types.StateEvent::TaskStart)
  let r = @types.transition(sm, @types.StateEvent::TaskComplete)
  assert_true(r.allowed)
  match @types.sm_current(sm) {
    @types.SafetyState::Idle => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "safety: SafeHold -> Reset -> Idle -> Executing recovery chain" {
  let sm = @types.new_statemachine()
  let _ = @types.transition(sm, @types.StateEvent::Reset)
  let _ = @types.transition(sm, @types.StateEvent::TaskStart)
  let _ = @types.transition(
    sm,
    @types.StateEvent::Safety(@types.SafetyEvent::EStopPressed),
  )
  match @types.sm_current(sm) {
    @types.SafetyState::SafeHold => assert_true(true)
    _ => assert_true(false)
  }
  let r1 = @types.transition(sm, @types.StateEvent::Reset)
  assert_true(r1.allowed)
  match @types.sm_current(sm) {
    @types.SafetyState::Idle => assert_true(true)
    _ => assert_true(false)
  }
  let r2 = @types.transition(sm, @types.StateEvent::TaskStart)
  assert_true(r2.allowed)
  assert_false(@types.gate_closed(sm))
}

///|
test "safety: disallowed transition rejected with reason" {
  let sm = @types.new_statemachine()
  let r = @types.transition(sm, @types.StateEvent::TaskStart)
  assert_false(r.allowed)
  match r.reason {
    Some(_) => assert_true(true)
    None => assert_true(false)
  }
  match @types.sm_current(sm) {
    @types.SafetyState::Selftest => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "safety: SafetyEvent in non-Executing state is rejected (no state change)" {
  let sm = @types.new_statemachine()
  let _ = @types.transition(sm, @types.StateEvent::Reset)
  let r = @types.transition(
    sm,
    @types.StateEvent::Safety(@types.SafetyEvent::LowBattery(0.1)),
  )
  assert_false(r.allowed)
  match @types.sm_current(sm) {
    @types.SafetyState::Idle => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "safety: all SafetyEvent variants constructible and preemptive (I1)" {
  let events : Array[@types.SafetyEvent] = [
    @types.SafetyEvent::EStopPressed,
    @types.SafetyEvent::CliffDetected({ x: 1.0, y: 0.0, z: 0.0, }),
    @types.SafetyEvent::WheelDrop("left"),
    @types.SafetyEvent::PickedUp,
    @types.SafetyEvent::HeartbeatTimeout(0L, 100L),
    @types.SafetyEvent::SensorStale("lidar", 500L),
    @types.SafetyEvent::LocalizationDiverged(0.5),
    @types.SafetyEvent::JointAnomaly("knee", 2.0),
    @types.SafetyEvent::SoftLimitExceeded("arm", 90.0),
    @types.SafetyEvent::LowBattery(0.15),
  ]
  for i, e in events {
    let sm = @types.new_statemachine()
    let _ = @types.transition(sm, @types.StateEvent::Reset)
    let _ = @types.transition(sm, @types.StateEvent::TaskStart)
    let r = @types.transition(sm, @types.StateEvent::Safety(e))
    assert_true(r.allowed)
    match @types.sm_current(sm) {
      @types.SafetyState::SafeHold => assert_true(true)
      _ => assert_true(false)
    }
    ignore(i)
  }
}

///|
test "safety: TaskComplete in non-Executing rejected (no state change)" {
  let sm = @types.new_statemachine()
  let _ = @types.transition(sm, @types.StateEvent::Reset)
  let r = @types.transition(sm, @types.StateEvent::TaskComplete)
  assert_false(r.allowed)
  match @types.sm_current(sm) {
    @types.SafetyState::Idle => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "threat: sec_error carries surface and code" {
  let surfaces : Array[@types.AttackSurface] = [
    @types.AttackSurface::AS1_SupplyChain,
    @types.AttackSurface::AS2_NLIInjection,
    @types.AttackSurface::AS3_AIPMessage,
    @types.AttackSurface::AS4_FeedbackInjection,
    @types.AttackSurface::AS5_SafetyBypass,
    @types.AttackSurface::AS6_ToolRegistration,
    @types.AttackSurface::AS7_TypeInjection,
    @types.AttackSurface::AS8_FormalCoverage,
  ]
  for i, s in surfaces {
    let e = @types.sec_error(s, 1700 + i, "msg \{i}")
    assert_eq(e.code, 1700 + i)
    assert_eq(e.message, "msg \{i}")
  }
}

///|
test "threat: AttackSurface Show renders every variant tag" {
  let pairs : Array[(@types.AttackSurface, String)] = [
    (@types.AttackSurface::AS1_SupplyChain, "AS1_SupplyChain"),
    (@types.AttackSurface::AS2_NLIInjection, "AS2_NLIInjection"),
    (@types.AttackSurface::AS3_AIPMessage, "AS3_AIPMessage"),
    (@types.AttackSurface::AS4_FeedbackInjection, "AS4_FeedbackInjection"),
    (@types.AttackSurface::AS5_SafetyBypass, "AS5_SafetyBypass"),
    (@types.AttackSurface::AS6_ToolRegistration, "AS6_ToolRegistration"),
    (@types.AttackSurface::AS7_TypeInjection, "AS7_TypeInjection"),
    (@types.AttackSurface::AS8_FormalCoverage, "AS8_FormalCoverage"),
  ]
  for (s, tag) in pairs {
    let rendered = Show::to_string(s)
    assert_eq(rendered, tag)
  }
}

///|
test "threat: SecurityError detail field optional" {
  let e = @types.sec_error(@types.AttackSurface::AS2_NLIInjection, 1710, "x")
  match e.detail {
    None => assert_true(true)
    Some(_) => assert_true(false)
  }
}
