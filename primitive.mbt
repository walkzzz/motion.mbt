// Primitive —— minimal semantic action unit
// Contains: parameter model, occupancy declaration, semantic achievement condition (SAC).

///|
pub(all) enum PrimCategory {
  Loc
  Man
  Exp
  Pos
  Con
}

///|
pub(all) struct ParamSpec {
  name : String
  ptype : ParamType
  required : Bool
  default : ParamValue?
  constraints : String
}

///|
pub(all) struct OccupancyDecl {
  participants : Array[BodyPartRef]
  exclusive : Bool
}

///|
pub(all) struct Primitive {
  urn : PrimRef
  name : String
  category : PrimCategory
  params : Array[ParamSpec]
  occupancy : OccupancyDecl
  sac : SacSpec
  metadata : Map[String, String]
}
