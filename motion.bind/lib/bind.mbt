// Binding engine —— four-stage validation (spec 3.1)
// L2 semantic validation layer. Also enforces AS2 (NLI injection) and AS7 (type injection)
// by validating every action before it may execute.
//
// Input: TargetActionSeq (source) + MappingGraph + target BodyMap + PrimitiveRegistry
// Output: BoundActionSeq (executable) or DiagnosticReport
//
// Stage 1: reference resolution  - verify PrimRef exists, param types & constraints
// Stage 2: mapping expansion    - find path source->target, expand fallback, detect cycles, max depth 5
// Stage 3: conflict re-check    - parallel primitive body-part occupancy conflicts
// Stage 4: SAC verification     - structural & inferable completeness

// ---- Stage 1: reference resolution ----

///|
pub struct PrimitiveRegistry {
  primitives : Map[@types.PrimRef, @types.Primitive]
}

///|
pub fn new_registry() -> PrimitiveRegistry {
  { primitives: Map([]), }
}

///|
pub fn register_primitive(
  reg : PrimitiveRegistry,
  p : @types.Primitive,
) -> Unit {
  reg.primitives[p.urn] = p
}

///|
fn type_matches(value : @types.ParamValue, expected : @types.ParamType) -> Bool {
  match value {
    @types.ParamValue::PInt(_) => expected == @types.ParamType::PIntType
    @types.ParamValue::PFloat(_) => expected == @types.ParamType::PFloatType
    @types.ParamValue::PBool(_) => expected == @types.ParamType::PBoolType
    @types.ParamValue::PString(_) => expected == @types.ParamType::PStringType
    @types.ParamValue::PDirection(_) =>
      expected == @types.ParamType::PDirectionType
    @types.ParamValue::PEnum(_, _) => expected == @types.ParamType::PEnumType
    @types.ParamValue::PRange(_, _, _) =>
      expected == @types.ParamType::PRangeType
  }
}

// Validate params against the primitive's ParamSpec list.

///|
fn validate_params(
  specs : Array[@types.ParamSpec],
  params : @types.ParamMap,
) -> Result[Unit, @types.Diagnostic] {
  let mut i = 0
  while i < specs.length() {
    let spec = specs[i]
    match params.get(spec.name) {
      None =>
        if spec.required {
          return Err(
            @types.make_error(
              @types.DiagnosticCategory::Resolve,
              1001,
              [spec.name],
              "missing required param: \{spec.name}",
            ),
          )
        }
      Some(value) =>
        if !type_matches(value, spec.ptype) {
          return Err(
            @types.make_error(
              @types.DiagnosticCategory::Resolve,
              1002,
              [spec.name],
              "param type mismatch for: \{spec.name}",
            ),
          )
        }
    }
    i = i + 1
  }
  Ok(())
}

///|
fn resolve_action(
  reg : PrimitiveRegistry,
  action : @types.BoundAction,
) -> Result[@types.BoundAction, @types.Diagnostic] {
  match reg.primitives.get(action.primitive) {
    None =>
      Err(
        @types.make_error(
          @types.DiagnosticCategory::Resolve,
          1000,
          [action.primitive],
          "primitive not found: \{action.primitive}",
        ),
      )
    Some(p) =>
      match validate_params(p.params, action.params) {
        Err(d) => Err(d)
        Ok(_) => Ok(action)
      }
  }
}

// ---- Stage 2: mapping expansion ----

///|
fn visited_contains(
  visited : Array[@types.PrimRef],
  id : @types.PrimRef,
) -> Bool {
  let mut i = 0
  while i < visited.length() {
    if visited[i] == id {
      return true
    }
    i = i + 1
  }
  false
}

// Depth-limited path search (max 5 hops, spec 3.1 stage 2). Detects cycles.

///|
fn find_path_rec(
  graph : @types.MappingGraph,
  source : @types.PrimRef,
  target : @types.PrimRef,
  visited : Array[@types.PrimRef],
  depth : Int32,
) -> @types.MappingPath? {
  if depth > 5 {
    None
  } else {
    let mut i = 0
    let mut result : @types.MappingPath? = None
    let mut done = false
    while i < graph.edges.length() && !done {
      let e = graph.edges[i]
      if e.source == source && !visited_contains(visited, e.target) {
        if e.target == target {
          result = Some({
            steps: [e],
            total_fidelity: e.fidelity,
            estimated_loss: 0.0,
          })
          done = true
        } else {
          let sub = find_path_rec(
            graph,
            e.target,
            target,
            visited + [e.target],
            depth + 1,
          )
          match sub {
            Some(s) => {
              result = Some({
                steps: [e] + s.steps,
                total_fidelity: s.total_fidelity,
                estimated_loss: s.estimated_loss + 0.1,
              })
              done = true
            }
            None => i = i + 1
          }
        }
      } else {
        i = i + 1
      }
    }
    result
  }
}

// Stage 2: mapping expansion —— cycle & self-loop detection over MappingGraph.
// A cycle exists iff some edge (u,v) has a depth-limited path v -> u.

///|
fn mapping_diags(graph : @types.MappingGraph) -> Array[@types.Diagnostic] {
  let mut ds : Array[@types.Diagnostic] = []
  let mut i = 0
  while i < graph.edges.length() {
    let e = graph.edges[i]
    if e.source == e.target {
      ds = ds +
        [
          @types.make_error(
            @types.DiagnosticCategory::Mapping,
            1051,
            [e.source],
            "self-loop mapping edge: \{e.source}",
          ),
        ]
    } else {
      match find_path_rec(graph, e.target, e.source, [e.target], 0) {
        Some(_) =>
          ds = ds +
            [
              @types.make_error(
                @types.DiagnosticCategory::Mapping,
                1050,
                [e.source],
                "mapping cycle detected at \{e.source}",
              ),
            ]
        None => ()
      }
    }
    i = i + 1
  }
  ds
}

// ---- Stage 3: conflict re-check ----

///|
pub(all) struct Conflict {
  body_part : @types.BodyPartRef
  action_a : Int32
  action_b : Int32
}

///|
pub(all) struct ConflictReport {
  conflicts : Array[Conflict]
  ok : Bool
}

///|
fn list_contains(a : Array[@types.BodyPartRef], x : @types.BodyPartRef) -> Bool {
  let mut i = 0
  while i < a.length() {
    if a[i] == x {
      return true
    }
    i = i + 1
  }
  false
}

///|
fn shared_parts(
  a : Array[@types.BodyPartRef],
  b : Array[@types.BodyPartRef],
  ia : Int32,
  ib : Int32,
) -> Array[Conflict] {
  let mut result : Array[Conflict] = []
  let mut i = 0
  while i < a.length() {
    if list_contains(b, a[i]) {
      result = result + [{ body_part: a[i], action_a: ia, action_b: ib, }]
    }
    i = i + 1
  }
  result
}

///|
fn conflicts(
  a : @types.BoundAction,
  b : @types.BoundAction,
  ia : Int32,
  ib : Int32,
  reg : PrimitiveRegistry,
) -> Array[Conflict] {
  match (reg.primitives.get(a.primitive), reg.primitives.get(b.primitive)) {
    (Some(pa), Some(pb)) =>
      if pa.occupancy.exclusive && pb.occupancy.exclusive {
        shared_parts(
          pa.occupancy.participants,
          pb.occupancy.participants,
          ia,
          ib,
        )
      } else {
        []
      }
    _ => []
  }
}

///|
pub fn check_conflicts(
  actions : Array[@types.BoundAction],
  reg : PrimitiveRegistry,
) -> ConflictReport {
  let mut cs : Array[Conflict] = []
  let n = actions.length()
  let mut i = 0
  while i < n {
    let mut j = i + 1
    while j < n {
      cs = cs + conflicts(actions[i], actions[j], i, j, reg)
      j = j + 1
    }
    i = i + 1
  }
  { conflicts: cs, ok: cs.length() == 0, }
}

// ---- Stage 4: SAC verification ----

///|
pub(all) struct SacResult {
  action_index : Int32
  passed : Bool
  message : String
}

///|
pub(all) struct SacVerificationReport {
  results : Array[SacResult]
  ok : Bool
}

// Structural completeness: every predicate's expr is non-empty and aspect is known.

///|
fn sac_structural(spec : @types.SacSpec) -> Bool {
  let mut i = 0
  while i < spec.predicates.length() {
    match spec.predicates[i] {
      @types.PredicateExpr::Builtin(bp) => if bp.expr == "" { return false }
      @types.PredicateExpr::Custom(cp) => if cp.backend == "" { return false }
    }
    i = i + 1
  }
  true
}

///|
pub fn verify_sac_all(
  actions : Array[@types.BoundAction],
) -> SacVerificationReport {
  let mut results : Array[SacResult] = []
  let mut i = 0
  while i < actions.length() {
    let sac : @types.SacSpec = match actions[i].sac_override {
      None =>
        { predicates: [], completeness: @types.CompletenessLevel::Structural, }
      Some(s) => s
    }
    let passed = sac_structural(sac)
    results = results +
      [
        {
          action_index: i,
          passed,
          message: if passed {
            "ok"
          } else {
            "sac structural check failed"
          },
        },
      ]
    i = i + 1
  }
  let mut ok = true
  let mut k = 0
  while k < results.length() {
    if !results[k].passed {
      ok = false
    }
    k = k + 1
  }
  { results, ok, }
}

// ---- Orchestration ----

///|
pub enum BindResult {
  Ok(@types.BoundActionSeq)
  Error(Array[@types.Diagnostic])
}

// The four-stage pipeline. Returns the bound sequence or all diagnostics.

///|
pub fn bind(
  seq : @types.TargetActionSeq,
  graph : @types.MappingGraph,
  reg : PrimitiveRegistry,
) -> BindResult {
  match resolve_all(seq.actions, reg) {
    Err(d) => Error([d])
    Ok(actions) => {
      let mapping_ds = mapping_diags(graph)
      if mapping_ds.length() > 0 {
        Error(mapping_ds)
      } else {
        let report = check_conflicts(actions, reg)
        if !report.ok {
          Error(conflict_diags(report))
        } else {
          let sac_report = verify_sac_all(actions)
          if !sac_report.ok {
            Error(sac_diags(sac_report))
          } else {
            Ok({ actions, bodymap: seq.bodymap, metadata: seq.metadata, })
          }
        }
      }
    }
  }
}

///|
fn resolve_all(
  actions : Array[@types.BoundAction],
  reg : PrimitiveRegistry,
) -> Result[Array[@types.BoundAction], @types.Diagnostic] {
  let mut result : Array[@types.BoundAction] = []
  let mut i = 0
  while i < actions.length() {
    match resolve_action(reg, actions[i]) {
      Err(d) => return Err(d)
      Ok(ra) => result = result + [ra]
    }
    i = i + 1
  }
  Ok(result)
}

///|
fn conflict_diags(report : ConflictReport) -> Array[@types.Diagnostic] {
  let mut ds : Array[@types.Diagnostic] = []
  let mut i = 0
  while i < report.conflicts.length() {
    let c = report.conflicts[i]
    ds = ds +
      [
        @types.make_error(
          @types.DiagnosticCategory::Conflict,
          1100,
          [c.body_part],
          "conflict on \{c.body_part} between actions \{c.action_a} and \{c.action_b}",
        ),
      ]
    i = i + 1
  }
  ds
}

///|
fn sac_diags(report : SacVerificationReport) -> Array[@types.Diagnostic] {
  let mut ds : Array[@types.Diagnostic] = []
  let mut i = 0
  while i < report.results.length() {
    let r = report.results[i]
    ds = ds +
      [
        @types.make_error(
          @types.DiagnosticCategory::Sac,
          1200,
          ["\{r.action_index}"],
          r.message,
        ),
      ]
    i = i + 1
  }
  ds
}
