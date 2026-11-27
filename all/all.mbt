// all —— curated facade of the motion workspace.
// Reexports every public symbol of the five sub-packages so that
// `import "looyiabc/motion/all"` alone is enough for common usage.
// Methods cannot be reexported via `pub using`; thin wrappers are added below.

// ---- root facade version ----

///|
pub using @motion {version}

// ---- motion.core/geom (Array-free geometry) ----

///|
pub using @geom {type Vec3, type SpatialDisplacement}

// ---- motion.core/types ----

///|
pub using @types {
  type ParamValue,
  type ParamType,
  type ParamSpec,
  type Primitive,
  type PrimCategory,
  type OccupancyDecl,
  type BodyMap,
  type BodyNode,
  type BodyNodeKind,
  type BodyRole,
  type SemanticAnchor,
  type MappingGraph,
  type MappingEdge,
  type MappingTransform,
  type MappingPath,
  type FidelityLevel,
  type ParamMapRule,
  type RouteConstraints,
  type SacSpec,
  type PredicateExpr,
  type BuiltinPredicate,
  type CustomPredicate,
  type CompletenessLevel,
  type AspectType,
  type EnvFeedback,
  type FeedbackKind,
  type FeedbackPayload,
  type Severity,
  type EnvEventPattern,
  type ReactionPolicy,
  type ReactionAction,
  type ReactionScope,
  type AvoidStrategy,
  type ConditionExpr,
  type TargetActionSeq,
  type BoundAction,
  type NLI_Result,
  type NLRequest,
  type AudioData,
  type ImageData,
  type ExecutionContext,
  type MOT_FunctionSchema,
  type Diagnostic,
  type DiagnosticCategory,
  type DiagnosticLevel,
  type ExitCode,
  type AttackSurface,
  type SecurityError,
  type ParamMap,
  type URN,
  type PrimRef,
  type BodyMapRef,
  type MappingRef,
  type BodyPartRef,
  type SupportPattern,
  make_error,
  make_warning,
  exit_code_of,
  exit_code_to_int,
  internal_error_code,
  sec_error,
}

// ---- motion.core/safety (provable core, I1/I2 formally verified) ----

///|
pub using @safety {
  type SafetyStateMachine,
  type SafetyState,
  type StateEvent,
  type SafetyEvent,
  type TransitionResult,
  new_statemachine,
  transition,
  sm_current,
  is_action_allowed,
  gate_closed,
}

// ---- motion.bind/lib ----

///|
pub using @lib {
  type BindResult,
  type PrimitiveRegistry,
  type Conflict,
  type ConflictReport,
  type SacResult,
  type SacVerificationReport,
  bind,
  new_registry,
  register_primitive,
  check_conflicts,
  verify_sac_all,
}

// ---- motion.reaction/engine ----

///|
pub using @engine {type ReactionDecision, react}

// ---- motion.security/guard ----

///|
pub using @guard {
  type OutputGate,
  type SensorRegistry,
  type PackageRef,
  type PackageSig,
  type DangerousPrimitive,
  new_gate,
  do_exec,
  gate_is_closed,
  new_sensor_registry,
  register_sensor,
  authenticate_feedback,
  guard_nli_result,
  verify_lock_hash,
  verify_package_signature,
}

// ---- motion.gbz185/bridge ----

///|
pub using @bridge {
  type MotError,
  mot_envelope,
  mot_tool_descriptor,
  security_error_to_mot,
}
