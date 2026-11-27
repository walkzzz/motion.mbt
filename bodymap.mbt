// BodyMap —— body semantic model
// Describes an arbitrary body topology (no assumption on joint count / DOF / biology).
// Nodes form a directed tree; semantic anchors establish cross-form equivalence.

///|
pub(all) enum BodyNodeKind {
  Joint
  Link
  Sensor
  Effector
  Virtual
}

///|
pub(all) enum BodyRole {
  LocomotionBase
  ManipulationEnd
  SupportPolygon
  SensorMount
  Actuator
  Passive
}

///|
pub(all) struct SemanticAnchor {
  id : String
  target_nodes : Array[String]
  description : String
}

///|
pub(all) struct BodyNode {
  id : String
  kind : BodyNodeKind
  parent : String?
  children : Array[String]
  dof : Int32
  role : BodyRole?
  anchors : Array[SemanticAnchor]
}

///|
pub(all) struct BodyMap {
  urn : BodyMapRef
  name : String
  version : String
  nodes : Array[BodyNode]
  root : String
  metadata : Map[String, String]
}
