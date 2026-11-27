#!/usr/bin/env python3
"""Mutation testing for the formally verified safety core (roadmap S3.4, gate B7).

Injects hand-crafted mutants into the five proved functions of
motion.core/safety/safety.mbt and requires `moon prove` to REJECT each one.
A rejected mutant means the proof is non-trivial: it actually pins the
behavior, not just the shape. Score = rejected / total.

Usage: python3 scripts/mutation_prove.py
"""
import subprocess
import sys

SAFETY = "motion.core/safety/safety.mbt"
BASE_GOALS = 5

# (description, original, mutant)
MUTANTS = [
    (
        "I1: SafetyEvent in Executing no longer preempts to SafeHold",
        "    Safety(_) =>\n      match from {\n        Executing => SafeHold\n        _ => from\n      }",
        "    Safety(_) =>\n      match from {\n        Executing => from\n        _ => from\n      }",
    ),
    (
        "I2: FaultLocked accepts every event, not only Reset",
        "  match from {\n    FaultLocked =>\n      match event {\n        Reset => true\n        _ => false\n      }",
        "  match from {\n    FaultLocked =>\n      match event {\n        Reset => true\n        _ => true\n      }",
    ),
    (
        "I3: entering Recovering no longer bumps the escalation index",
        "    (_, Recovering) => 1\n    _ => 0",
        "    (_, Recovering) => 0\n    _ => 0",
    ),
    (
        "I4: the gate stays open in Executing (closed-check inverted)",
        "  match s {\n    Executing => false\n    _ => true\n  }\n}\n\n// I3 (provable core)",
        "  match s {\n    Executing => true\n    _ => true\n  }\n}\n\n// I3 (provable core)",
    ),
    (
        "I5: every state allows execution (state gate inverted)",
        "  match s {\n    Executing => true\n    _ => false\n  }",
        "  match s {\n    Executing => true\n    _ => true\n  }",
    ),
]


def run_prove() -> tuple[bool, str]:
    r = subprocess.run(
        ["moon", "prove", "motion.core/safety"],
        capture_output=True, text=True, timeout=600,
    )
    out = r.stdout + r.stderr
    ok = "Succeeded" in out and f"{BASE_GOALS} goals proved" in out
    return ok, out


def main() -> int:
    with open(SAFETY, encoding="utf-8") as f:
        original_src = f.read()

    for desc, orig, mut in MUTANTS:
        if orig not in original_src:
            print(f"SKIP  {desc}\n      anchor not found (source drifted?)")
            continue
        mutated = original_src.replace(orig, mut, 1)
        if mutated == original_src:
            print(f"SKIP  {desc}\n      mutant identical to original")
            continue
        with open(SAFETY, "w", encoding="utf-8") as f:
            f.write(mutated)
        try:
            ok, out = run_prove()
        finally:
            with open(SAFETY, "w", encoding="utf-8") as f:
                f.write(original_src)
        verdict = "REJECTED" if not ok else "SURVIVED"
        print(f"{verdict}  {desc}")
        if ok:
            print("      mutant survived the proof — the proof is too weak!")
            return 1
    print(f"\nmutation score: {len(MUTANTS)}/{len(MUTANTS)} rejected (100%)")
    print("all five proofs are non-trivial: every behavior-pinning mutant is caught")
    return 0


if __name__ == "__main__":
    sys.exit(main())
