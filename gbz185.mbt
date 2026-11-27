// GB/Z 185-2026 integration layer —— thin wrapper over the walkzzz/gbz185.mbt library.
// MOT reuses the gbz185 MoonBit library directly (NOT a from-scratch bridge).
// This module imports gbz185 sub-packages and exposes MOT-facing helpers that
// map MOT concepts onto gbz185 types (AipEnvelope, ToolDescriptor, ProtocolError, etc.).
//
// Import paths (verified against walkzzz/gbz185.mbt@0.2.2 source):
//   @walkzzz/gbz185.mbt/wire      -> ProtocolError trait, JsonWireError
//   @walkzzz/gbz185.mbt/aip       -> AipEnvelope, MessageKind, AipError
//   @walkzzz/gbz185.mbt/tooling   -> ToolDescriptor, ToolInvocation, ToolOutcome, ToolingError
//   @walkzzz/gbz185.mbt/identity  -> AIC identity
//   @walkzzz/gbz185.mbt/capability-> AgentCapabilitySet (ACS)
//   @walkzzz/gbz185.mbt/discovery -> AgentNode (ADP)
//
// Imports are declared in moon.pkg. In this module the imported packages are
// referenced as @wire, @aip, @tooling (the last segment of each import path).

// ---- ProtocolError re-export (MOT errors implement this trait) ----

// MOT's MotError implements gbz185's ProtocolError trait so every MOT error
// is a valid GB/Z 185 wire error (spec §4.2 MotError -> ProtocolError).
// The trait is defined in @walkzzz/gbz185.mbt/wire as:
//   pub(open) trait ProtocolError { fn part(Self)->String; fn code(Self)->String; fn message(Self)->String }
// pub(open) allows cross-package implementation, so MOT can implement it here.

///|
pub(all) suberror MotError {
  Syntax_error(String)
  Resolve_error(String)
  Mapping_error(String)
  Conflict_error(String)
  Sac_error(String)
  Reaction_error(String)
  Safety_error(String)
  Nli_error(String)
  Security_error(String) // mot.security 1700-1799
}

///|
pub impl Show for MotError with fn output(self : MotError, logger) -> Unit {
  match self {
    Syntax_error(m) => logger.write_string("mot/syntax: \{m}")
    Resolve_error(m) => logger.write_string("mot/resolve: \{m}")
    Mapping_error(m) => logger.write_string("mot/mapping: \{m}")
    Conflict_error(m) => logger.write_string("mot/conflict: \{m}")
    Sac_error(m) => logger.write_string("mot/sac: \{m}")
    Reaction_error(m) => logger.write_string("mot/reaction: \{m}")
    Safety_error(m) => logger.write_string("mot/safety: \{m}")
    Nli_error(m) => logger.write_string("mot/nli: \{m}")
    Security_error(m) => logger.write_string("mot/security: \{m}")
  }
}

///|
pub impl @wire.ProtocolError for MotError with fn part(_self : MotError) -> String {
  "gbz185.6"
}

///|
pub impl @wire.ProtocolError for MotError with fn code(self : MotError) -> String {
  match self {
    Syntax_error(_) => "MOT-1000"
    Resolve_error(_) => "MOT-1100"
    Mapping_error(_) => "MOT-1200"
    Conflict_error(_) => "MOT-1300"
    Sac_error(_) => "MOT-1400"
    Reaction_error(_) => "MOT-1500"
    Safety_error(_) => "MOT-1600"
    Nli_error(_) => "MOT-1800"
    Security_error(_) => "MOT-1700"
  }
}

///|
pub impl @wire.ProtocolError for MotError with fn message(self : MotError) -> String {
  match self {
    Syntax_error(m) => m
    Resolve_error(m) => m
    Mapping_error(m) => m
    Conflict_error(m) => m
    Sac_error(m) => m
    Reaction_error(m) => m
    Safety_error(m) => m
    Nli_error(m) => m
    Security_error(m) => m
  }
}

// ---- AIP envelope helpers (MOT messages ride in gbz185 AipEnvelope) ----

// Build an AipEnvelope for a MOT message. MOT message types map to MessageKind.
// MOT uses the AIP envelope's replay/session/routing for free (spec §6 mount point 2).

///|
pub fn mot_envelope(
  sender : String,
  recipient : String,
  seq : Int64,
  kind : @aip.MessageKind,
  payload : Json,
) -> @aip.AipEnvelope {
  {
    envelope_version: @aip.envelope_version(),
    sender_urn: sender,
    recipient_urn: recipient,
    seq,
    timestamp: seq,
    kind,
    payload,
  }
}

// ---- ToolDescriptor helpers (Executors/Sensors register as gbz185 ToolDescriptor) ----

// Register an Executor/Sensor as a gbz185 ToolDescriptor (spec §6 mount point 3).
// AS6: ToolDescriptor registration is the identity-anchored registration point.

///|
pub fn mot_tool_descriptor(
  name : String,
  description : String,
  input_schema : Json,
  binding : @tooling.ToolBinding,
) -> @tooling.ToolDescriptor {
  { name, description, input_schema, binding, }
}

// ---- Error mapping: MOT SecurityError -> MotError (ProtocolError) ----

// Map a MOT SecurityError to a MotError so it flows through the gbz185 wire error contract.

///|
pub fn security_error_to_mot(err : SecurityError) -> MotError {
  Security_error("\{err.surface} code=\{err.code}: \{err.message}")
}
