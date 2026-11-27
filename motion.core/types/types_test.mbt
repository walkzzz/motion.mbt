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
