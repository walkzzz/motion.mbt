// Security threat model + SecurityError (spec §4, attack surfaces AS1-AS8)
// Error code range: 1700-1799 (mot.security -> GB/Z 185 ProtocolError)

///|
#derive(Debug)
pub(all) enum AttackSurface {
  AS1_SupplyChain
  AS2_NLIInjection
  AS3_AIPMessage
  AS4_FeedbackInjection
  AS5_SafetyBypass
  AS6_ToolRegistration
  AS7_TypeInjection
  AS8_FormalCoverage
}

///|
/// Render the attack-surface tag (AS1..AS8) for diagnostics and error messages.
pub impl Show for AttackSurface with fn output(self, logger) {
  match self {
    AS1_SupplyChain => logger.write_string("AS1_SupplyChain")
    AS2_NLIInjection => logger.write_string("AS2_NLIInjection")
    AS3_AIPMessage => logger.write_string("AS3_AIPMessage")
    AS4_FeedbackInjection => logger.write_string("AS4_FeedbackInjection")
    AS5_SafetyBypass => logger.write_string("AS5_SafetyBypass")
    AS6_ToolRegistration => logger.write_string("AS6_ToolRegistration")
    AS7_TypeInjection => logger.write_string("AS7_TypeInjection")
    AS8_FormalCoverage => logger.write_string("AS8_FormalCoverage")
  }
}

///|
pub(all) struct SecurityError {
  surface : AttackSurface
  code : Int32
  message : String
  detail : String?
}

///|
pub fn sec_error(
  surface : AttackSurface,
  code : Int32,
  message : String,
) -> SecurityError {
  { surface, code, message, detail: None, }
}
