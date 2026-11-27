// Mapping —— cross-form mapping
// A directed graph between primitives of arbitrary body pairs.

///|
pub(all) enum FidelityLevel {
  Exact
  Approximate
  Degraded
}

///|
pub(all) struct ParamMapRule {
  from_param : String
  to_param : String
  converter : String?
}

///|
pub(all) enum MappingTransform {
  Direct
  ParamMap(Array[ParamMapRule])
  Sequence(Array[PrimRef])
  Custom(String, Json)
}

///|
pub(all) struct MappingEdge {
  source : PrimRef
  target : PrimRef
  transform : MappingTransform
  fidelity : FidelityLevel
  fallback_chain : Array[PrimRef]
}

///|
pub(all) struct MappingPath {
  steps : Array[MappingEdge]
  total_fidelity : FidelityLevel
  estimated_loss : Double
}

///|
pub(all) struct RouteConstraints {
  max_fidelity_loss : Double?
  max_hops : Int32?
  preferred_intermediates : Array[BodyMapRef]
}

///|
pub(all) struct MappingGraph {
  edges : Array[MappingEdge]
}
