// Geometry primitives (L0): Vec3 + SpatialDisplacement.
// Kept in a dedicated Array-free package so the provable safety package can
// depend on it without pulling in Array-typed definitions (Why3 lowering).

///|
#derive(Eq)
pub(all) struct Vec3 {
  x : Double
  y : Double
  z : Double
}

///|
pub(all) struct SpatialDisplacement {
  translation : Vec3
  rotation : Vec3
}
