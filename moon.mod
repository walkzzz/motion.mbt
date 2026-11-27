name = "looyiabc/motion"

version = "0.1.0"

license = "MIT"

description = "motion — universal action semantics for embodied agents, the GB/Z 185-2026 execution-layer standard implementation."

repository = "https://gitcode.com/LOOYIABC/motion.mbt"

keywords = [
  "moonbit",
  "motion",
  "embodied-agent",
  "gbz185",
  "action-semantics",
  "safety",
  "multi-target",
  "wasm",
]

preferred_target = "native"

readme = "README.md"

import {
  "looyiabc/motion.core@0.1.0",
  "looyiabc/motion.gbz185@0.1.0",
  "looyiabc/motion.bind@0.1.0",
  "looyiabc/motion.reaction@0.1.0",
  "looyiabc/motion.security@0.1.0",
  "walkzzz/gbz185.mbt@0.2.2",
}
