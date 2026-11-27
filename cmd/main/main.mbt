// motion CLI entry point (`mot`).
// Thin dispatch: argparse subcommand tree -> library demos / self-check.

///|
fn state_name(s : @all.SafetyState) -> String {
  match s {
    Selftest => "Selftest"
    Idle => "Idle"
    Executing => "Executing"
    Recovering => "Recovering"
    SafeHold => "SafeHold"
    FaultLocked => "FaultLocked"
  }
}

///|
fn decision_name(d : @all.ReactionDecision) -> String {
  match d {
    Continue => "Continue"
    Adjust(_) => "Adjust"
    Avoid(_) => "Avoid"
    Wait(_, _, _) => "Wait"
    SafeHold => "SafeHold"
    Abort(_) => "Abort"
    Replan => "Replan"
    FaultLocked(_) => "FaultLocked"
  }
}

///|
fn demo_safety() -> Unit {
  let sm = @all.new_statemachine()
  println("== mot safety — SafetyStateMachine demo (I1/I2/I4/I5) ==")
  println("initial state : \{state_name(@all.sm_current(sm))}")
  let _ = @all.transition(sm, @all.StateEvent::Reset)
  println("after Reset   : \{state_name(@all.sm_current(sm))}")
  let _ = @all.transition(sm, @all.StateEvent::TaskStart)
  println("after TaskStart: \{state_name(@all.sm_current(sm))}")
  let gate_open = @all.is_action_allowed(sm, "walk")
  let gate_line = if gate_open { "OPEN (action allowed)" } else { "CLOSED" }
  println("gate           : \{gate_line}")
  let _ = @all.transition(
    sm,
    @all.StateEvent::Safety(@all.SafetyEvent::EStopPressed),
  )
  println("after E-Stop   : \{state_name(@all.sm_current(sm))} (I1 preemption)")
  let gate_closed_line = if @all.gate_closed(sm) {
    "CLOSED (I4/I5 — execution rejected)"
  } else {
    "OPEN"
  }
  println("gate           : \{gate_closed_line}")
}

///|
fn demo_bind() -> Unit {
  println("== mot bind — four-stage binding engine demo ==")
  let reg = @all.new_registry()
  let walk : @all.Primitive = {
    urn: "urn:mot:prim:walk:1.0",
    name: "walk",
    category: @all.PrimCategory::Loc,
    params: [],
    occupancy: { participants: [], exclusive: false, },
    sac: { predicates: [], completeness: @all.CompletenessLevel::Structural, },
    metadata: Map([]),
  }
  @all.register_primitive(reg, walk)
  let seq : @all.TargetActionSeq = {
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
  let graph : @all.MappingGraph = { edges: [], }
  match @all.bind(seq, graph, reg) {
    Ok(b) =>
      println("bound OK: \{b.actions.length()} action(s) ready to execute")
    Error(ds) => {
      println("bound FAILED with \{ds.length()} diagnostic(s):")
      for d in ds {
        println("  [code \{d.code}] \{d.message}")
      }
    }
  }
}

///|
fn demo_react() -> Unit {
  println("== mot react — reaction engine demo (I3) ==")
  let fb : @all.EnvFeedback = {
    source: "urn:mot:sensor:lidar:1.0",
    kind: @all.FeedbackKind::Obstacle,
    timestamp: 0L,
    stale_after_ms: 100L,
    severity: @all.Severity::Danger,
    payload: @all.FeedbackPayload::Obstacle(
      1.0,
      { x: 0.0, y: 0.0, z: 0.0, },
      0.5,
      None,
    ),
    sac_ref: None,
    action_ref: None,
  }
  let policy : @all.ReactionPolicy = {
    id: "p-obstacle",
    scope: @all.ReactionScope::Primitive,
    trigger: {
      kinds: [@all.FeedbackKind::Obstacle],
      severity_min: @all.Severity::Warn,
      source_filter: None,
    },
    guard_expr: None,
    action: @all.ReactionAction::Avoid(@all.AvoidStrategy::StopAndWait(100L)),
    escalation: None,
  }
  let decision = @all.react([policy], fb)
  println("feedback: Obstacle(Danger) -> decision: \{decision_name(decision)}")
}

///|
fn self_check() -> Unit {
  println("== mot check — invariant smoke check ==")
  let mut failures = 0
  // I1: safety event preempts Executing
  let sm = @all.new_statemachine()
  let _ = @all.transition(sm, @all.StateEvent::Reset)
  let _ = @all.transition(sm, @all.StateEvent::TaskStart)
  let _ = @all.transition(
    sm,
    @all.StateEvent::Safety(@all.SafetyEvent::EStopPressed),
  )
  if @all.sm_current(sm) != @all.SafetyState::SafeHold {
    println("FAIL I1: E-Stop did not preempt to SafeHold")
    failures = failures + 1
  }
  // I4/I5: gate closed outside Executing
  if !@all.gate_closed(sm) {
    println("FAIL I4: gate open in SafeHold")
    failures = failures + 1
  }
  if @all.is_action_allowed(sm, "walk") {
    println("FAIL I5: action allowed in SafeHold")
    failures = failures + 1
  }
  // I2: FaultLocked only leaves via Reset — empty bind passes
  let reg = @all.new_registry()
  let empty : @all.TargetActionSeq = {
    actions: [],
    bodymap: "urn:mot:bodymap:human:1.0",
    metadata: Map([]),
  }
  match @all.bind(empty, { edges: [], }, reg) {
    Ok(_) => ()
    Error(_) => {
      println("FAIL bind: empty sequence rejected")
      failures = failures + 1
    }
  }
  if failures == 0 {
    println("all checks passed (I1/I4/I5 + bind pipeline)")
  } else {
    println("\{failures} check(s) FAILED")
  }
}

///|
let root : @argparse.Command = @argparse.Command::Command(
  "mot",
  subcommands=[
    @argparse.Command::Command(
      "safety",
      about="SafetyStateMachine live demo (I1/I2/I4/I5)",
    ),
    @argparse.Command::Command("bind", about="Four-stage binding engine demo"),
    @argparse.Command::Command(
      "react",
      about="Reaction engine demo (I3 bounded escalation)",
    ),
    @argparse.Command::Command(
      "check",
      about="Invariant smoke check (I1/I4/I5 + bind)",
    ),
  ],
  about="motion — universal action semantics toolchain (GB/Z 185-2026)",
  version="0.1.0",
  arg_required_else_help=true,
)

///|
fn main {
  let argv : ArrayView[String] = match @env.args() {
    [_, .. rest] => rest
    [] => []
  }
  match root.parse_outcome(argv~) {
    Parsed(m) =>
      match m.subcommand {
        Some((name, _)) =>
          match name {
            "safety" => demo_safety()
            "bind" => demo_bind()
            "react" => demo_react()
            "check" => self_check()
            _ => println(root.render_help())
          }
        None => println(root.render_help())
      }
    Help(h) => println(h)
    Version(v) => println(v)
    Failed(_) => {
      println("error: invalid usage — see help below")
      println(root.render_help())
    }
  }
}
