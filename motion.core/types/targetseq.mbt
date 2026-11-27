// TargetActionSeq —— target action sequence (bound, executable)
// BoundAction carries an optional SAC override and optional reaction policies.

///|
pub(all) struct BoundAction {
  primitive : PrimRef
  params : ParamMap
  sac_override : SacSpec?
  reaction_policies : Array[ReactionPolicy]
}

///|
pub(all) struct TargetActionSeq {
  actions : Array[BoundAction]
  bodymap : BodyMapRef
  metadata : Map[String, String]
}

// BoundActionSeq —— the executable result after binding (alias of TargetActionSeq).

///|
pub type BoundActionSeq = TargetActionSeq
