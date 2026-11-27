// ReactionPolicy —— environment feedback -> control decision
// Declarative rule: on a given env feedback during primitive execution, take a control decision.

///|
pub(all) enum ReactionScope {
  Primitive
  Sequence
  Global
}

///|
pub(all) struct EnvEventPattern {
  kinds : Array[FeedbackKind]
  severity_min : Severity
  source_filter : String?
}

///|
pub type ConditionExpr = String

// Seven reaction actions. Wait is recursive (on_timeout). escalation is recursive (ReactionPolicy).

///|
pub(all) enum ReactionAction {
  Continue
  Adjust(ParamMap)
  Avoid(AvoidStrategy)
  Wait(ConditionExpr, Int64, ReactionAction)
  SafeHold
  Abort(String)
  Replan
}

///|
pub(all) enum AvoidStrategy {
  LateralOffset(Double)
  SpeedReduce(Double)
  StopAndWait(Int64)
  Custom(String)
}

///|
pub(all) struct ReactionPolicy {
  id : String
  scope : ReactionScope
  trigger : EnvEventPattern
  guard_expr : ConditionExpr?
  action : ReactionAction
  escalation : ReactionPolicy?
}
