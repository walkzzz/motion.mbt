// MOT core primitive types
// Language-agnostic types expressed in MoonBit. P0 core depends only on moonbitlang/core.
// URN format: "urn:mot:{category}:{name}:{version}"

///|
pub type URN = String

///|
pub type BodyMapRef = URN

///|
pub type PrimRef = URN

///|
pub type MappingRef = URN

///|
pub type BodyPartRef = String

// Parameter value (polymorphic). Mirrors the TS-style ParamValue in the spec.

///|
pub(all) enum ParamValue {
  PInt(Int32)
  PFloat(Double)
  PBool(Bool)
  PString(String)
  PDirection(@geom.Vec3)
  PEnum(String, Array[String])
  PRange(Double, Double, String)
}

///|
pub type ParamMap = Map[String, ParamValue]

// Parameter type discriminator (mirrors ParamValue variants) for ParamSpec.type.

///|
#derive(Eq)
pub(all) enum ParamType {
  PIntType
  PFloatType
  PBoolType
  PStringType
  PDirectionType
  PEnumType
  PRangeType
}

///|
pub type SupportPattern = Array[BodyPartRef]
