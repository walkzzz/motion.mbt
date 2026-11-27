// Diagnostic system —— unified errors & warnings (spec section 5)
// Exit codes: 0 success / 1 error / 2 warning / 3 internal error.

///|
pub(all) enum DiagnosticLevel {
  Error
  Warning
  Info
  Hint
}

///|
pub(all) enum DiagnosticCategory {
  Syntax
  Resolve
  Mapping
  Conflict
  Sac
  Reaction
  Safety
  Nli
  Security
}

///|
pub(all) struct Diagnostic {
  level : DiagnosticLevel
  category : DiagnosticCategory
  code : Int32
  path : Array[String]
  message : String
  hint : String?
  related : Array[Diagnostic]
}

///|
pub enum ExitCode {
  Success = 0
  Error = 1
  Warning = 2
  InternalError = 3
}

// Map an ExitCode to the process exit status used by motc.

///|
pub fn exit_code_to_int(code : ExitCode) -> Int32 {
  match code {
    Success => 0
    Error => 1
    Warning => 2
    InternalError => 3
  }
}

// Exit code for unexpected internal failures (motc catch-all).

///|
pub fn internal_error_code() -> Int32 {
  exit_code_to_int(InternalError)
}

///|
pub fn exit_code_of(diagnostics : Array[Diagnostic]) -> Int32 {
  let mut has_error = false
  let mut has_warning = false
  for d in diagnostics {
    match d.level {
      Error => has_error = true
      Warning => has_warning = true
      _ => ()
    }
  }
  let code : ExitCode = if has_error {
    Error
  } else if has_warning {
    Warning
  } else {
    Success
  }
  exit_code_to_int(code)
}

///|
pub fn make_error(
  category : DiagnosticCategory,
  code : Int32,
  path : Array[String],
  message : String,
) -> Diagnostic {
  { level: Error, category, code, path, message, hint: None, related: [], }
}

///|
pub fn make_warning(
  category : DiagnosticCategory,
  code : Int32,
  path : Array[String],
  message : String,
) -> Diagnostic {
  { level: Warning, category, code, path, message, hint: None, related: [], }
}
