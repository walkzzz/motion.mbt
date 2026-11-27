// Core types blackbox tests: diagnostics and threat model.
// (Safety state machine tests live in motion.core/safety/safety_test.mbt.)
// Run with: moon test

///|
test "diagnostic: exit_code_of empty -> 0 (Success)" {
  assert_eq(@types.exit_code_of([]), 0)
}

///|
test "diagnostic: exit_code_of with error -> 1" {
  let d = @types.make_error(
    @types.DiagnosticCategory::Syntax,
    1000,
    ["x"],
    "err",
  )
  assert_eq(@types.exit_code_of([d]), 1)
}

///|
test "diagnostic: exit_code_of with warning only -> 2" {
  let d = @types.make_warning(
    @types.DiagnosticCategory::Syntax,
    1000,
    ["x"],
    "warn",
  )
  assert_eq(@types.exit_code_of([d]), 2)
}

///|
test "diag: internal_error_code -> 3" {
  assert_eq(@types.internal_error_code(), 3)
}

///|
test "threat: sec_error carries surface and code" {
  let surfaces : Array[@types.AttackSurface] = [
    @types.AttackSurface::AS1_SupplyChain,
    @types.AttackSurface::AS2_NLIInjection,
    @types.AttackSurface::AS3_AIPMessage,
    @types.AttackSurface::AS4_FeedbackInjection,
    @types.AttackSurface::AS5_SafetyBypass,
    @types.AttackSurface::AS6_ToolRegistration,
    @types.AttackSurface::AS7_TypeInjection,
    @types.AttackSurface::AS8_FormalCoverage,
  ]
  for i, s in surfaces {
    let e = @types.sec_error(s, 1700 + i, "msg \{i}")
    assert_eq(e.code, 1700 + i)
    assert_eq(e.message, "msg \{i}")
  }
}

///|
test "threat: AttackSurface Show renders every variant tag" {
  let pairs : Array[(@types.AttackSurface, String)] = [
    (@types.AttackSurface::AS1_SupplyChain, "AS1_SupplyChain"),
    (@types.AttackSurface::AS2_NLIInjection, "AS2_NLIInjection"),
    (@types.AttackSurface::AS3_AIPMessage, "AS3_AIPMessage"),
    (@types.AttackSurface::AS4_FeedbackInjection, "AS4_FeedbackInjection"),
    (@types.AttackSurface::AS5_SafetyBypass, "AS5_SafetyBypass"),
    (@types.AttackSurface::AS6_ToolRegistration, "AS6_ToolRegistration"),
    (@types.AttackSurface::AS7_TypeInjection, "AS7_TypeInjection"),
    (@types.AttackSurface::AS8_FormalCoverage, "AS8_FormalCoverage"),
  ]
  for (s, tag) in pairs {
    let rendered = Show::to_string(s)
    assert_eq(rendered, tag)
  }
}

///|
test "threat: SecurityError detail field optional" {
  let e = @types.sec_error(@types.AttackSurface::AS2_NLIInjection, 1710, "x")
  match e.detail {
    None => assert_true(true)
    Some(_) => assert_true(false)
  }
}
