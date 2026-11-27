// AS5 output gate (invariant I5) —— mandatory precondition of the Executor.
// Any non-EXECUTING state => do_exec returns false (torque/velocity zeroed, I4).
// Authoritative gate; no intruder may bypass it.

///|
pub struct OutputGate {
  sm : @types.SafetyStateMachine
}

///|
pub fn new_gate(sm : @types.SafetyStateMachine) -> OutputGate {
  { sm, }
}

// I5: gate integrity. Returns true ONLY in EXECUTING state.

///|
pub fn do_exec(gate : OutputGate, action : String) -> Bool {
  @types.is_action_allowed(gate.sm, action)
}

// I4/I5: gate closed check.

///|
pub fn gate_is_closed(gate : OutputGate) -> Bool {
  @types.gate_closed(gate.sm)
}
