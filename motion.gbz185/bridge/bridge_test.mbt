// GB/Z 185 bridge blackbox tests: MotError ProtocolError, AipEnvelope, ToolDescriptor.

///|
test "gbz185 integration: MotError implements ProtocolError" {
  let e = @bridge.MotError::Security_error("test")
  assert_eq(@wire.ProtocolError::part(e), "gbz185.6")
  assert_eq(@wire.ProtocolError::code(e), "MOT-1700")
  assert_eq(@wire.ProtocolError::message(e), "test")
}

///|
test "gbz185 integration: mot_envelope builds AipEnvelope" {
  let env = @bridge.mot_envelope(
    "urn:mot:a:1.0",
    "urn:mot:b:1.0",
    5L,
    @aip.MessageKind::Event,
    Json::null(),
  )
  assert_eq(env.sender_urn, "urn:mot:a:1.0")
  assert_eq(env.seq, 5L)
  match env.kind {
    @aip.MessageKind::Event => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "gbz185 integration: mot_tool_descriptor builds ToolDescriptor" {
  let desc = @bridge.mot_tool_descriptor(
    "executor.walk",
    "walk executor",
    Json::null(),
    @tooling.ToolBinding::NativeBinding,
  )
  assert_eq(desc.name, "executor.walk")
}

///|
test "gbz185 integration: security_error_to_mot message includes surface tag" {
  let e = @types.sec_error(@types.AttackSurface::AS1_SupplyChain, 1701, "bad")
  match @bridge.security_error_to_mot(e) {
    @bridge.MotError::Security_error(msg) =>
      assert_true(msg.contains("AS1_SupplyChain"))
    _ => assert_true(false)
  }
}
