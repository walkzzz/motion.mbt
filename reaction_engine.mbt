// ReactionEngine —— environment feedback -> control decision (spec 3.2)
// L3 runtime authentication layer. Feedback source authentication (I6) is enforced
// in feedback_auth.mbt BEFORE this engine runs.
//
// Loop: receive EnvFeedback -> match policy (scope + trigger + guard) -> execute action
//       -> if escalation, recurse (bounded, I3 monotonic) -> chain exhausted => FAULT_LOCKED
//
// NOTE: safety events (SafetyEvent) are preemptive and bypass this engine entirely;
// they go directly to SafetyStateMachine.transition (see safety.mbt).

///|
pub(all) enum ReactionDecision {
  Continue
  Adjust(ParamMap)
  Avoid(AvoidStrategy)
  Wait(ConditionExpr, Int64, ReactionAction)
  SafeHold
  Abort(String)
  Replan
  FaultLocked(String)
}

///|
const MAX_ESCALATION : Int32 = 5

///|
fn severity_rank(s : Severity) -> Int32 {
  match s {
    Info => 0
    Warn => 1
    Danger => 2
    Critical => 3
  }
}

///|
fn severity_ge(a : Severity, b : Severity) -> Bool {
  severity_rank(a) >= severity_rank(b)
}

///|
fn kind_in_list(kinds : Array[FeedbackKind], k : FeedbackKind) -> Bool {
  let mut i = 0
  while i < kinds.length() {
    if kinds[i] == k {
      return true
    }
    i = i + 1
  }
  false
}

// Match a policy against feedback: trigger (kind + severity_min + source_filter).

///|
fn matches(policy : ReactionPolicy, feedback : EnvFeedback) -> Bool {
  let kind_ok = kind_in_list(policy.trigger.kinds, feedback.kind)
  let sev_ok = severity_ge(feedback.severity, policy.trigger.severity_min)
  let src_ok = match policy.trigger.source_filter {
    None => true
    Some(f) => feedback.source == f
  }
  kind_ok && sev_ok && src_ok
}

///|
fn find_policy(
  policies : Array[ReactionPolicy],
  feedback : EnvFeedback,
) -> ReactionPolicy? {
  let mut i = 0
  while i < policies.length() {
    if matches(policies[i], feedback) {
      return Some(policies[i])
    }
    i = i + 1
  }
  None
}

///|
fn decide(action : ReactionAction) -> ReactionDecision {
  match action {
    Continue => Continue
    Adjust(p) => Adjust(p)
    Avoid(s) => Avoid(s)
    Wait(c, t, o) => Wait(c, t, o)
    SafeHold => SafeHold
    Abort(r) => Abort(r)
    Replan => Replan
  }
}

// Walk the escalation chain (bounded, I3 monotonic index). Chain exhausted -> FaultLocked.

///|
fn react_rec(
  policy : ReactionPolicy,
  feedback : EnvFeedback,
  depth : Int32,
) -> ReactionDecision {
  if depth > MAX_ESCALATION {
    FaultLocked("escalation chain exhausted (I3)")
  } else {
    match policy.escalation {
      None => decide(policy.action)
      Some(esc) => react_rec(esc, feedback, depth + 1)
    }
  }
}

// Top-level entry: match policy, then walk the escalation chain.

///|
pub fn react(
  policies : Array[ReactionPolicy],
  feedback : EnvFeedback,
) -> ReactionDecision {
  match find_policy(policies, feedback) {
    None => Continue
    Some(p) => react_rec(p, feedback, 0)
  }
}
