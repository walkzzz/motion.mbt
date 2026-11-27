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

///|
test "binding engine: missing required param -> Err 1001 (Stage 1)" {
  let reg = @lib.new_registry()
  let p : @types.Primitive = {
    urn: "urn:mot:prim:walk:1.0",
    name: "walk",
    category: @types.PrimCategory::Loc,
    params: [
      {
        name: "speed",
        ptype: @types.ParamType::PFloatType,
        required: true,
        default: None,
        constraints: "",
      },
    ],
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
    @lib.BindResult::Error(ds) => {
      assert_eq(ds.length(), 1)
      assert_eq(ds[0].code, 1001)
    }
    @lib.BindResult::Ok(_) => assert_true(false)
  }
}

///|
test "binding engine: param type mismatch -> Err 1002 (Stage 1)" {
  let reg = @lib.new_registry()
  let p : @types.Primitive = {
    urn: "urn:mot:prim:walk:1.0",
    name: "walk",
    category: @types.PrimCategory::Loc,
    params: [
      {
        name: "speed",
        ptype: @types.ParamType::PFloatType,
        required: true,
        default: None,
        constraints: "",
      },
    ],
    occupancy: { participants: [], exclusive: false, },
    sac: { predicates: [], completeness: @types.CompletenessLevel::Structural, },
    metadata: Map([]),
  }
  @lib.register_primitive(reg, p)
  let seq : @types.TargetActionSeq = {
    actions: [
      {
        primitive: "urn:mot:prim:walk:1.0",
        params: Map([("speed", @types.ParamValue::PInt(3))]),
        sac_override: None,
        reaction_policies: [],
      },
    ],
    bodymap: "urn:mot:bodymap:human:1.0",
    metadata: Map([]),
  }
  let graph : @types.MappingGraph = { edges: [], }
  match @lib.bind(seq, graph, reg) {
    @lib.BindResult::Error(ds) => {
      assert_eq(ds.length(), 1)
      assert_eq(ds[0].code, 1002)
    }
    @lib.BindResult::Ok(_) => assert_true(false)
  }
}

///|
test "binding engine: optional param missing -> Ok (Stage 1)" {
  let reg = @lib.new_registry()
  let p : @types.Primitive = {
    urn: "urn:mot:prim:walk:1.0",
    name: "walk",
    category: @types.PrimCategory::Loc,
    params: [
      {
        name: "speed",
        ptype: @types.ParamType::PFloatType,
        required: false,
        default: Some(@types.ParamValue::PFloat(1.0)),
        constraints: "",
      },
    ],
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
    @lib.BindResult::Ok(_) => assert_true(true)
    @lib.BindResult::Error(_) => assert_true(false)
  }
}

///|
test "binding engine: param value types all match their specs (Stage 1)" {
  let reg = @lib.new_registry()
  let p : @types.Primitive = {
    urn: "urn:mot:prim:combo:1.0",
    name: "combo",
    category: @types.PrimCategory::Loc,
    params: [
      {
        name: "i",
        ptype: @types.ParamType::PIntType,
        required: false,
        default: None,
        constraints: "",
      },
      {
        name: "f",
        ptype: @types.ParamType::PFloatType,
        required: false,
        default: None,
        constraints: "",
      },
      {
        name: "b",
        ptype: @types.ParamType::PBoolType,
        required: false,
        default: None,
        constraints: "",
      },
      {
        name: "s",
        ptype: @types.ParamType::PStringType,
        required: false,
        default: None,
        constraints: "",
      },
      {
        name: "d",
        ptype: @types.ParamType::PDirectionType,
        required: false,
        default: None,
        constraints: "",
      },
    ],
    occupancy: { participants: [], exclusive: false, },
    sac: { predicates: [], completeness: @types.CompletenessLevel::Structural, },
    metadata: Map([]),
  }
  @lib.register_primitive(reg, p)
  let seq : @types.TargetActionSeq = {
    actions: [
      {
        primitive: "urn:mot:prim:combo:1.0",
        params: Map([
          ("i", @types.ParamValue::PInt(1)),
          ("f", @types.ParamValue::PFloat(0.5)),
          ("b", @types.ParamValue::PBool(true)),
          ("s", @types.ParamValue::PString("x")),
          ("d", @types.ParamValue::PDirection({ x: 0.0, y: 0.0, z: 1.0, })),
        ]),
        sac_override: None,
        reaction_policies: [],
      },
    ],
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
fn mk_exclusive_prim(urn : String, part : String) -> @types.Primitive {
  {
    urn,
    name: urn,
    category: @types.PrimCategory::Man,
    params: [],
    occupancy: { participants: [part], exclusive: true, },
    sac: { predicates: [], completeness: @types.CompletenessLevel::Structural, },
    metadata: Map([]),
  }
}

///|
test "binding engine: exclusive occupancy conflict -> Err 1100 (Stage 3)" {
  let reg = @lib.new_registry()
  @lib.register_primitive(
    reg,
    mk_exclusive_prim("urn:mot:prim:l_arm:1.0", "arm.left"),
  )
  @lib.register_primitive(
    reg,
    mk_exclusive_prim("urn:mot:prim:l_grip:1.0", "arm.left"),
  )
  let seq : @types.TargetActionSeq = {
    actions: [
      {
        primitive: "urn:mot:prim:l_arm:1.0",
        params: Map([]),
        sac_override: None,
        reaction_policies: [],
      },
      {
        primitive: "urn:mot:prim:l_grip:1.0",
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
    @lib.BindResult::Error(ds) => {
      assert_eq(ds.length(), 1)
      assert_eq(ds[0].code, 1100)
    }
    @lib.BindResult::Ok(_) => assert_true(false)
  }
}

///|
test "binding engine: check_conflicts direct API" {
  let reg = @lib.new_registry()
  @lib.register_primitive(
    reg,
    mk_exclusive_prim("urn:mot:prim:a:1.0", "leg.left"),
  )
  @lib.register_primitive(
    reg,
    mk_exclusive_prim("urn:mot:prim:b:1.0", "leg.left"),
  )
  @lib.register_primitive(
    reg,
    mk_exclusive_prim("urn:mot:prim:c:1.0", "leg.right"),
  )
  let actions : Array[@types.BoundAction] = [
    {
      primitive: "urn:mot:prim:a:1.0",
      params: Map([]),
      sac_override: None,
      reaction_policies: [],
    },
    {
      primitive: "urn:mot:prim:b:1.0",
      params: Map([]),
      sac_override: None,
      reaction_policies: [],
    },
    {
      primitive: "urn:mot:prim:c:1.0",
      params: Map([]),
      sac_override: None,
      reaction_policies: [],
    },
  ]
  let report = @lib.check_conflicts(actions, reg)
  assert_false(report.ok)
  assert_eq(report.conflicts.length(), 1)
  assert_eq(report.conflicts[0].body_part, "leg.left")
}

///|
test "binding engine: verify_sac_all direct API (Stage 4)" {
  let ok_action : @types.BoundAction = {
    primitive: "urn:mot:prim:walk:1.0",
    params: Map([]),
    sac_override: Some({
      predicates: [],
      completeness: @types.CompletenessLevel::Full,
    }),
    reaction_policies: [],
  }
  let report = @lib.verify_sac_all([ok_action])
  assert_true(report.ok)
  let empty_builtin : @types.BoundAction = {
    primitive: "urn:mot:prim:walk:1.0",
    params: Map([]),
    sac_override: Some({
      predicates: [
        @types.PredicateExpr::Builtin({
          aspect: @types.AspectType::Contact,
          expr: "",
          params: Map([]),
        }),
      ],
      completeness: @types.CompletenessLevel::Structural,
    }),
    reaction_policies: [],
  }
  let report2 = @lib.verify_sac_all([empty_builtin])
  assert_false(report2.ok)
  assert_false(report2.results[0].passed)
}

///|
test "binding engine: custom predicate empty backend -> SAC fail (Stage 4)" {
  let reg = @lib.new_registry()
  let action : @types.BoundAction = {
    primitive: "urn:mot:prim:walk:1.0",
    params: Map([]),
    sac_override: Some({
      predicates: [
        @types.PredicateExpr::Custom({ backend: "", config: Json::null(), }),
      ],
      completeness: @types.CompletenessLevel::Inferable,
    }),
    reaction_policies: [],
  }
  let seq : @types.TargetActionSeq = {
    actions: [action],
    bodymap: "urn:mot:bodymap:human:1.0",
    metadata: Map([]),
  }
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
  let graph : @types.MappingGraph = { edges: [], }
  match @lib.bind(seq, graph, reg) {
    @lib.BindResult::Error(ds) => assert_eq(ds[0].code, 1200)
    @lib.BindResult::Ok(_) => assert_true(false)
  }
}
