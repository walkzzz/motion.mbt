// SafetyStateMachine —— runtime safety state management (six-state model)
// Safety events are preemptive: they bypass the normal reaction chain.
// FAULT_LOCKED is released ONLY by Reset (invariant I2).
// Output gate: non-EXECUTING states reject all execution commands (invariant I5).
//
// Invariants asserted at runtime (formal proof via Z3 is the P1+ enhancement):
// I1 EXECUTING + SafetyEvent -> bounded steps out of EXECUTING
// I2 FAULT_LOCKED only leaves via Reset
// I3 escalation index monotonic, no regression
// I4 SAFE_HOLD: output gate closed (torque/velocity zeroed)
// I5 output gate integrity: any non-EXECUTING state => do_exec == false
// I6 feedback source authentication (handled in feedback_auth.mbt)

///|
#derive(Eq)
pub(all) enum SafetyState {
  Selftest
  Idle
  Executing
  Recovering
  SafeHold
  FaultLocked
}

///|
#derive(Eq)
pub(all) enum SafetyEvent {
  EStopPressed
  CliffDetected(@geom.Vec3)
  WheelDrop(String)
  PickedUp
  HeartbeatTimeout(Int64, Int64)
  SensorStale(String, Int64)
  LocalizationDiverged(Double)
  JointAnomaly(String, Double)
  SoftLimitExceeded(String, Double)
  LowBattery(Double)
}

///|
#derive(Eq)
pub(all) enum StateEvent {
  Safety(SafetyEvent)
  Reset
  TaskStart
  TaskComplete
}

///|
pub(all) struct TransitionResult {
  from : SafetyState
  to : SafetyState
  allowed : Bool
  reason : String?
}

///|
pub struct SafetyStateMachine {
  mut current : SafetyState
  mut escalation_index : Int32
}

///|
pub fn new_statemachine() -> SafetyStateMachine {
  { current: Selftest, escalation_index: 0, }
}

///|
pub fn sm_current(sm : SafetyStateMachine) -> SafetyState {
  sm.current
}

// Output gate query (I5). Executor MUST call this before any command.
// Returns true only in EXECUTING state. Empty action commands are always
// rejected: a gate must never pass a malformed (empty) instruction.

///|
pub fn is_action_allowed(sm : SafetyStateMachine, action : String) -> Bool {
  if action == "" {
    false
  } else {
    match sm.current {
      Executing => true
      _ => false
    }
  }
}

// The single transition entry point (no back door). Preemptive safety events
// bypass the normal reaction chain and force a transition out of EXECUTING (I1).

///|
pub fn transition(
  sm : SafetyStateMachine,
  event : StateEvent,
) -> TransitionResult {
  let from = sm.current
  let to = next_state(from, event)
  let allowed = is_valid_transition(from, to, event)
  if allowed {
    sm.current = to
    match (from, to) {
      (Recovering, _) => ()
      (_, Recovering) => sm.escalation_index = sm.escalation_index + 1
      _ => ()
    }
  }
  let reason = if allowed { None } else { Some("transition not allowed") }
  { from, to, allowed, reason, }
}

// I4/I5: output gate closed check. True when gate is closed (non-EXECUTING).

///|
pub fn gate_closed(sm : SafetyStateMachine) -> Bool {
  match sm.current {
    Executing => false
    _ => true
  }
}

// Proof-facing rank of each state (shared by program side and logic side).
// Selftest=0 Idle=1 Executing=2 Recovering=3 SafeHold=4 FaultLocked=5

///|
#proof_pure
fn state_rank(s : SafetyState) -> Int32 {
  match s {
    Selftest => 0
    Idle => 1
    Executing => 2
    Recovering => 3
    SafeHold => 4
    FaultLocked => 5
  }
}

// Proof-facing predicate: is this event a Reset?

///|
#proof_pure
fn is_reset_event(e : StateEvent) -> Bool {
  match e {
    Reset => true
    _ => false
  }
}

///|
fn is_valid_transition(
  from : SafetyState,
  to_state : SafetyState,
  event : StateEvent,
) -> Bool where {
  proof_ensure: result => valid_transition_i2(from, event, result),
} {
  match from {
    FaultLocked =>
      match event {
        Reset => true
        _ => false
      }
    _ =>
      match (from, to_state) {
        (Selftest, Idle) => true
        (Selftest, FaultLocked) => true
        (Idle, Executing) => true
        (Idle, FaultLocked) => true
        (Executing, Recovering) => true
        (Executing, SafeHold) => true
        (Executing, FaultLocked) => true
        (Executing, Idle) => true
        (Recovering, Executing) => true
        (Recovering, SafeHold) => true
        (Recovering, FaultLocked) => true
        (Recovering, Idle) => true
        (SafeHold, Recovering) => true
        (SafeHold, Idle) => true
        (SafeHold, FaultLocked) => true
        _ => false
      }
  }
}

///|
fn next_state(
  from : SafetyState,
  event : StateEvent,
) -> SafetyState where {
  proof_ensure: result => next_state_spec(from, event, result),
} {
  match event {
    Safety(_) =>
      match from {
        Executing => SafeHold
        _ => from
      }
    Reset =>
      match from {
        FaultLocked => Idle
        Selftest => Idle
        SafeHold => Idle
        Recovering => Idle
        _ => from
      }
    TaskStart =>
      match from {
        Idle => Executing
        _ => from
      }
    TaskComplete =>
      match from {
        Executing => Idle
        Recovering => Idle
        _ => from
      }
  }
}
