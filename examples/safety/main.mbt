// Example: safety state machine roundtrip (I1/I2/I4/I5).
// Run: moon run examples/safety --target native

///|
fn state_name(s : @all.SafetyState) -> String {
  match s {
    Selftest => "Selftest"
    Idle => "Idle"
    Executing => "Executing"
    Recovering => "Recovering"
    SafeHold => "SafeHold"
    FaultLocked => "FaultLocked"
  }
}

///|
fn main {
  let sm = @all.new_statemachine()
  println("[example] safety state machine roundtrip")
  println("initial : \{state_name(@all.sm_current(sm))}")
  let _ = @all.transition(sm, @all.StateEvent::Reset)
  println("reset   : \{state_name(@all.sm_current(sm))}")
  let _ = @all.transition(sm, @all.StateEvent::TaskStart)
  println(
    "start   : \{state_name(@all.sm_current(sm))} — gate open: \{!@all.gate_closed(sm)}",
  )
  let _ = @all.transition(
    sm,
    @all.StateEvent::Safety(@all.SafetyEvent::WheelDrop("left")),
  )
  println(
    "e-stop  : \{state_name(@all.sm_current(sm))} — gate open: \{!@all.gate_closed(sm)} (I1 preempt, I4/I5 closed)",
  )
  let _ = @all.transition(sm, @all.StateEvent::Reset)
  println("recover : \{state_name(@all.sm_current(sm))} (Reset exits SafeHold)")
}
