// EnvFeedback —— environment feedback message
// Standardized sensor/environment feedback. stale_after_ms is mandatory (safety constraint).

///|
#derive(Eq)
pub(all) enum Severity {
  Info
  Warn
  Danger
  Critical
}

///|
#derive(Eq)
pub(all) enum FeedbackKind {
  Obstacle
  ContactLoss
  Collision
  VisualDrift
  LocalQuality
  JointAnomaly
  HumanProximity
  DoorState
  Battery
  Heartbeat
  Stale
}

///|
pub(all) struct EnvFeedback {
  source : String
  kind : FeedbackKind
  timestamp : Int64
  stale_after_ms : Int64
  severity : Severity
  payload : FeedbackPayload
  sac_ref : String?
  action_ref : String?
}

///|
pub(all) enum FeedbackPayload {
  Obstacle(Double, Vec3, Double, String?)
  ContactLoss(Double, Double)
  Collision(String, Vec3)
  VisualDrift(SpatialDisplacement)
  LocalQuality(Double)
  JointAnomaly(String, Double)
  HumanProximity(Double, Array[Vec3])
  DoorState(Double)
  Battery(Double)
  Heartbeat(Int64, Int64)
  Stale(Int64)
}
