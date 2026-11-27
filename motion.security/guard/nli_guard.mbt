// AS2 NLI injection guard —— prevent prompt injection / dangerous action sequences.
// NLI output MUST pass this guard before binding. Separation of duties: NLI only
// produces TargetActionSeq, never direct execution commands.

///|
pub(all) struct DangerousPrimitive {
  urn : @types.PrimRef
  reason : String
}

// Safety-critical primitives requiring secondary authorization.

///|
fn dangerous_primitives() -> Array[DangerousPrimitive] {
  [
    {
      urn: "urn:mot:prim:safe_hold:1.0",
      reason: "safety-critical: forces safe hold",
    },
    {
      urn: "urn:mot:prim:abort:1.0",
      reason: "safety-critical: aborts execution",
    },
  ]
}

///|
fn list_contains_primitive(
  l : Array[DangerousPrimitive],
  urn : @types.PrimRef,
) -> Bool {
  let mut i = 0
  while i < l.length() {
    if l[i].urn == urn {
      return true
    }
    i = i + 1
  }
  false
}

// Guard an NLI result. Reject dangerous primitives / ambiguous / uninterpretable.

///|
pub fn guard_nli_result(
  result : @types.NLI_Result,
) -> Result[@types.TargetActionSeq, @types.SecurityError] {
  match result {
    @types.NLI_Result::Uninterpretable(r) =>
      Err(
        @types.sec_error(
          @types.AttackSurface::AS2_NLIInjection,
          1710,
          "uninterpretable: \{r}",
        ),
      )
    @types.NLI_Result::Ambiguous(_, _) =>
      Err(
        @types.sec_error(
          @types.AttackSurface::AS2_NLIInjection,
          1711,
          "ambiguous NLI result requires disambiguation",
        ),
      )
    @types.NLI_Result::Success(seq) => {
      let mut i = 0
      while i < seq.actions.length() {
        if list_contains_primitive(
            dangerous_primitives(),
            seq.actions[i].primitive,
          ) {
          return Err(
            @types.sec_error(
              @types.AttackSurface::AS2_NLIInjection,
              1712,
              "dangerous primitive at index \{i}: \{seq.actions[i].primitive}",
            ),
          )
        }
        i = i + 1
      }
      Ok(seq)
    }
  }
}
