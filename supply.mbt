// AS1 supply chain security —— package signature verification (motc install)
// P0: registry whitelist + algorithm check. P1+ integrates chenzehaoo/moon_guard (Ed25519).
// mot.toml dependency lock hashes are pinned (no ^/~ ranges).

///|
pub(all) struct PackageSig {
  algorithm : String
  signature : Array[Byte]
  public_key : String
}

///|
pub(all) struct PackageRef {
  urn : String
  version : String
  sha256 : String
}

// Verify a package signature. P0: lock-integrity + algorithm whitelist;
// P1+ does Ed25519 verify via moon_guard.

///|
pub fn verify_package_signature(
  pkg : PackageRef,
  sig : PackageSig,
) -> Result[Unit, SecurityError] {
  if pkg.sha256 == "" {
    Err(
      sec_error(
        AS1_SupplyChain,
        1703,
        "package sha256 lock missing: \{pkg.urn}",
      ),
    )
  } else if sig.algorithm == "ed25519" && sig.public_key == "" {
    Err(
      sec_error(AS1_SupplyChain, 1704, "ed25519 signature requires public key"),
    )
  } else {
    match sig.algorithm {
      "ed25519" => Ok(())
      "trusted-registry" => Ok(())
      _ =>
        Err(
          sec_error(
            AS1_SupplyChain,
            1701,
            "unsupported signature algorithm: \{sig.algorithm}",
          ),
        )
    }
  }
}

// Dependency lock hash check (AS1): pinned SHA-256 must match. No ranges allowed.

///|
pub fn verify_lock_hash(
  declared : String,
  actual : String,
) -> Result[Unit, SecurityError] {
  if declared == actual {
    Ok(())
  } else {
    Err(sec_error(AS1_SupplyChain, 1702, "dependency lock hash mismatch"))
  }
}
