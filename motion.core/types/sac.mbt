// SAC —— semantic achievement condition
// Typed declarative design contract: criteria for "the action was done correctly".

///|
pub(all) enum CompletenessLevel {
  Structural
  Inferable
  Full
}

///|
pub(all) enum AspectType {
  Trajectory
  Contact
  Posture
  Spatial
  Count
}

///|
pub(all) struct BuiltinPredicate {
  aspect : AspectType
  expr : String
  params : ParamMap
}

///|
pub(all) struct CustomPredicate {
  backend : String
  config : Json
}

///|
pub(all) enum PredicateExpr {
  Builtin(BuiltinPredicate)
  Custom(CustomPredicate)
}

///|
pub(all) struct SacSpec {
  predicates : Array[PredicateExpr]
  completeness : CompletenessLevel
}
