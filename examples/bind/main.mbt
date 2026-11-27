// Example: four-stage binding engine (resolve / mapping / conflict / SAC).
// Run: moon run examples/bind --target native

///|
fn main {
  println("[example] four-stage binding engine")
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
  println("registered primitive: \{walk.urn}")
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
  match @all.bind(seq, { edges: [], }, reg) {
    Ok(b) =>
      println("bind OK: \{b.actions.length()} action(s) bound for \{b.bodymap}")
    Error(ds) => {
      println("bind FAILED:")
      for d in ds {
        println("  [code \{d.code}] \{d.message}")
      }
    }
  }
}
