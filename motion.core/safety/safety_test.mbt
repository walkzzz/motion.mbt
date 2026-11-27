// Safety state machine blackbox tests: I1/I2/I4/I5 invariants.
// Run with: moon test

///|
test "safety state machine: initial state is Selftest" {
  let sm = @safety.new_statemachine()
  match @safety.sm_current(sm) {
    @safety.SafetyState::Selftest => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "safety state machine: Reset from Selftest -> Idle (I2)" {
  let sm = @safety.new_statemachine()
  let r = @safety.transition(sm, @safety.StateEvent::Reset)
  assert_true(r.allowed)
  match r.to {
    @safety.SafetyState::Idle => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "safety state machine: TaskStart from Idle -> Executing" {
  let sm = @safety.new_statemachine()
  let _ = @safety.transition(sm, @safety.StateEvent::Reset)
  let r = @safety.transition(sm, @safety.StateEvent::TaskStart)
  assert_true(r.allowed)
  match r.to {
    @safety.SafetyState::Executing => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "safety state machine: is_action_allowed true only in Executing (I5)" {
  let sm = @safety.new_statemachine()
  assert_false(@safety.is_action_allowed(sm, "walk"))
  let _ = @safety.transition(sm, @safety.StateEvent::Reset)
  assert_false(@safety.is_action_allowed(sm, "walk"))
  let _ = @safety.transition(sm, @safety.StateEvent::TaskStart)
  assert_true(@safety.is_action_allowed(sm, "walk"))
}

///|
test "safety state machine: gate_closed true when non-Executing (I4)" {
  let sm = @safety.new_statemachine()
  assert_true(@safety.gate_closed(sm))
  let _ = @safety.transition(sm, @safety.StateEvent::Reset)
  assert_true(@safety.gate_closed(sm))
  let _ = @safety.transition(sm, @safety.StateEvent::TaskStart)
  assert_false(@safety.gate_closed(sm))
}

///|
test "safety state machine: SafetyEvent preempts to SafeHold (I1)" {
  let sm = @safety.new_statemachine()
  let _ = @safety.transition(sm, @safety.StateEvent::Reset)
  let _ = @safety.transition(sm, @safety.StateEvent::TaskStart)
  let r = @safety.transition(
    sm,
    @safety.StateEvent::Safety(@safety.SafetyEvent::EStopPressed),
  )
  assert_true(r.allowed)
  match r.to {
    @safety.SafetyState::SafeHold => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "safety: empty action command rejected even when Executing (I5)" {
  let sm = @safety.new_statemachine()
  let _ = @safety.transition(sm, @safety.StateEvent::Reset)
  let _ = @safety.transition(sm, @safety.StateEvent::TaskStart)
  assert_false(@safety.is_action_allowed(sm, ""))
}

///|
test "safety: TaskComplete Executing -> Idle" {
  let sm = @safety.new_statemachine()
  let _ = @safety.transition(sm, @safety.StateEvent::Reset)
  let _ = @safety.transition(sm, @safety.StateEvent::TaskStart)
  let r = @safety.transition(sm, @safety.StateEvent::TaskComplete)
  assert_true(r.allowed)
  match @safety.sm_current(sm) {
    @safety.SafetyState::Idle => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "safety: SafeHold -> Reset -> Idle -> Executing recovery chain" {
  let sm = @safety.new_statemachine()
  let _ = @safety.transition(sm, @safety.StateEvent::Reset)
  let _ = @safety.transition(sm, @safety.StateEvent::TaskStart)
  let _ = @safety.transition(
    sm,
    @safety.StateEvent::Safety(@safety.SafetyEvent::EStopPressed),
  )
  match @safety.sm_current(sm) {
    @safety.SafetyState::SafeHold => assert_true(true)
    _ => assert_true(false)
  }
  let r1 = @safety.transition(sm, @safety.StateEvent::Reset)
  assert_true(r1.allowed)
  match @safety.sm_current(sm) {
    @safety.SafetyState::Idle => assert_true(true)
    _ => assert_true(false)
  }
  let r2 = @safety.transition(sm, @safety.StateEvent::TaskStart)
  assert_true(r2.allowed)
  assert_false(@safety.gate_closed(sm))
}

///|
test "safety: disallowed transition rejected with reason" {
  let sm = @safety.new_statemachine()
  let r = @safety.transition(sm, @safety.StateEvent::TaskStart)
  assert_false(r.allowed)
  match r.reason {
    Some(_) => assert_true(true)
    None => assert_true(false)
  }
  match @safety.sm_current(sm) {
    @safety.SafetyState::Selftest => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "safety: SafetyEvent in non-Executing state is rejected (no state change)" {
  let sm = @safety.new_statemachine()
  let _ = @safety.transition(sm, @safety.StateEvent::Reset)
  let r = @safety.transition(
    sm,
    @safety.StateEvent::Safety(@safety.SafetyEvent::LowBattery(0.1)),
  )
  assert_false(r.allowed)
  match @safety.sm_current(sm) {
    @safety.SafetyState::Idle => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "safety: all SafetyEvent variants constructible and preemptive (I1)" {
  let events : Array[@safety.SafetyEvent] = [
    @safety.SafetyEvent::EStopPressed,
    @safety.SafetyEvent::CliffDetected(@geom.Vec3::{ x: 1.0, y: 0.0, z: 0.0, }),
    @safety.SafetyEvent::WheelDrop("left"),
    @safety.SafetyEvent::PickedUp,
    @safety.SafetyEvent::HeartbeatTimeout(0L, 100L),
    @safety.SafetyEvent::SensorStale("lidar", 500L),
    @safety.SafetyEvent::LocalizationDiverged(0.5),
    @safety.SafetyEvent::JointAnomaly("knee", 2.0),
    @safety.SafetyEvent::SoftLimitExceeded("arm", 90.0),
    @safety.SafetyEvent::LowBattery(0.15),
  ]
  for i, e in events {
    let sm = @safety.new_statemachine()
    let _ = @safety.transition(sm, @safety.StateEvent::Reset)
    let _ = @safety.transition(sm, @safety.StateEvent::TaskStart)
    let r = @safety.transition(sm, @safety.StateEvent::Safety(e))
    assert_true(r.allowed)
    match @safety.sm_current(sm) {
      @safety.SafetyState::SafeHold => assert_true(true)
      _ => assert_true(false)
    }
    ignore(i)
  }
}

///|
test "safety: TaskComplete in non-Executing rejected (no state change)" {
  let sm = @safety.new_statemachine()
  let _ = @safety.transition(sm, @safety.StateEvent::Reset)
  let r = @safety.transition(sm, @safety.StateEvent::TaskComplete)
  assert_false(r.allowed)
  match @safety.sm_current(sm) {
    @safety.SafetyState::Idle => assert_true(true)
    _ => assert_true(false)
  }
}
