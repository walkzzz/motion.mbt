// Binding engine blackbox tests: four-stage pipeline (resolve / mapping / conflict / SAC).

///|
test "binding engine: empty seq -> Ok" {
  let reg = @lib.new_registry()
  let seq : @types.TargetActionSeq = {
    actions: [],
    bodymap: "urn:mot:bodymap:human:1.0",
    metadata: Map([]),
  }
  let graph : @types.MappingGraph = { edges: [], }
  match @lib.bind(seq, graph, reg) {
    @lib.BindResult::Ok(_) => assert_true(true)
    @lib.BindResult::Error(_) => assert_true(false)
  }
}

///|
test "binding engine: unregistered primitive -> Err (Stage 1)" {
  let reg = @lib.new_registry()
  let seq : @types.TargetActionSeq = {
    actions: [
      {
        primitive: "urn:mot:prim:ghost:1.0",
        params: Map([]),
        sac_override: None,
        reaction_policies: [],
      },
    ],
    bodymap: "urn:mot:bodymap:human:1.0",
    metadata: Map([]),
  }
  let graph : @types.MappingGraph = { edges: [], }
  match @lib.bind(seq, graph, reg) {
    @lib.BindResult::Ok(_) => assert_true(false)
    @lib.BindResult::Error(ds) => assert_eq(ds.length(), 1)
  }
}

///|
test "binding engine: registered primitive -> Ok (Stage 1)" {
  let reg = @lib.new_registry()
  let p : @types.Primitive = {
    urn: "urn:mot:prim:walk:1.0",
    name: "walk",
    category: @types.PrimCategory::Loc,
    params: [],
    occupancy: { participants: [], exclusive: false, },
    sac: { predicates: [], completeness: @types.CompletenessLevel::Structural, },
    metadata: Map([]),
  }
  @lib.register_primitive(reg, p)
  let seq : @types.TargetActionSeq = {
    actions: [
      {
        primitive: "urn:mot:prim:walk:1.0",
        params: Map([]),
        sac_override: None,
        reaction_policies: [],
      },
    ],
    bodymap: "urn:mot:bodymap:human:1.0",
    metadata: Map([]),
  }
  let graph : @types.MappingGraph = { edges: [], }
  match @lib.bind(seq, graph, reg) {
    @lib.BindResult::Ok(b) => assert_eq(b.actions.length(), 1)
    @lib.BindResult::Error(_) => assert_true(false)
  }
}

///|
test "binding engine: cyclic mapping graph -> Err (Stage 2)" {
  let reg = @lib.new_registry()
  let seq : @types.TargetActionSeq = {
    actions: [],
    bodymap: "urn:mot:bodymap:human:1.0",
    metadata: Map([]),
  }
  let graph : @types.MappingGraph = {
    edges: [
      {
        source: "urn:mot:prim:a:1.0",
        target: "urn:mot:prim:b:1.0",
        transform: @types.MappingTransform::Direct,
        fidelity: @types.FidelityLevel::Exact,
        fallback_chain: [],
      },
      {
        source: "urn:mot:prim:b:1.0",
        target: "urn:mot:prim:a:1.0",
        transform: @types.MappingTransform::Direct,
        fidelity: @types.FidelityLevel::Exact,
        fallback_chain: [],
      },
    ],
  }
  match @lib.bind(seq, graph, reg) {
    @lib.BindResult::Error(ds) => assert_true(ds.length() > 0)
    @lib.BindResult::Ok(_) => assert_true(false)
  }
}

///|
test "binding engine: acyclic mapping graph -> Ok (Stage 2)" {
  let reg = @lib.new_registry()
  let seq : @types.TargetActionSeq = {
    actions: [],
    bodymap: "urn:mot:bodymap:human:1.0",
    metadata: Map([]),
  }
  let graph : @types.MappingGraph = {
    edges: [
      {
        source: "urn:mot:prim:a:1.0",
        target: "urn:mot:prim:b:1.0",
        transform: @types.MappingTransform::Direct,
        fidelity: @types.FidelityLevel::Exact,
        fallback_chain: [],
      },
      {
        source: "urn:mot:prim:b:1.0",
        target: "urn:mot:prim:c:1.0",
        transform: @types.MappingTransform::Direct,
        fidelity: @types.FidelityLevel::Approximate,
        fallback_chain: [],
      },
    ],
  }
  match @lib.bind(seq, graph, reg) {
    @lib.BindResult::Ok(_) => assert_true(true)
    @lib.BindResult::Error(_) => assert_true(false)
  }
}

///|
test "binding engine: self-loop mapping edge -> Err (Stage 2)" {
  let reg = @lib.new_registry()
  let seq : @types.TargetActionSeq = {
    actions: [],
    bodymap: "urn:mot:bodymap:human:1.0",
    metadata: Map([]),
  }
  let graph : @types.MappingGraph = {
    edges: [
      {
        source: "urn:mot:prim:a:1.0",
        target: "urn:mot:prim:a:1.0",
        transform: @types.MappingTransform::Direct,
        fidelity: @types.FidelityLevel::Exact,
        fallback_chain: [],
      },
    ],
  }
  match @lib.bind(seq, graph, reg) {
    @lib.BindResult::Error(ds) => assert_eq(ds.length(), 1)
    @lib.BindResult::Ok(_) => assert_true(false)
  }
}
