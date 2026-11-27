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

///|
test "gbz185 integration: MotError all variants map to ProtocolError codes" {
  let cases : Array[(@bridge.MotError, String)] = [
    (@bridge.MotError::Syntax_error("s"), "MOT-1000"),
    (@bridge.MotError::Resolve_error("r"), "MOT-1100"),
    (@bridge.MotError::Mapping_error("m"), "MOT-1200"),
    (@bridge.MotError::Conflict_error("c"), "MOT-1300"),
    (@bridge.MotError::Sac_error("sa"), "MOT-1400"),
    (@bridge.MotError::Reaction_error("re"), "MOT-1500"),
    (@bridge.MotError::Safety_error("sf"), "MOT-1600"),
    (@bridge.MotError::Nli_error("n"), "MOT-1800"),
    (@bridge.MotError::Security_error("se"), "MOT-1700"),
  ]
  for (err, expected) in cases {
    assert_eq(@wire.ProtocolError::part(err), "gbz185.6")
    assert_eq(@wire.ProtocolError::code(err), expected)
  }
}

///|
test "gbz185 integration: MotError Show output includes prefix" {
  let cases : Array[(@bridge.MotError, String)] = [
    (@bridge.MotError::Syntax_error("x1"), "mot/syntax"),
    (@bridge.MotError::Resolve_error("x2"), "mot/resolve"),
    (@bridge.MotError::Mapping_error("x3"), "mot/mapping"),
    (@bridge.MotError::Conflict_error("x4"), "mot/conflict"),
    (@bridge.MotError::Sac_error("x5"), "mot/sac"),
    (@bridge.MotError::Reaction_error("x6"), "mot/reaction"),
    (@bridge.MotError::Safety_error("x7"), "mot/safety"),
    (@bridge.MotError::Nli_error("x8"), "mot/nli"),
    (@bridge.MotError::Security_error("x9"), "mot/security"),
  ]
  for (err, prefix) in cases {
    let s = Show::to_string(err)
    assert_true(s.contains(prefix))
  }
}
